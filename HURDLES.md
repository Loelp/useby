# Hurdles Log

Running log of real build errors, concurrency problems, API surprises and design trade-offs.
Format: **Problem → Cause → Fix → Files changed.**

---

## Phase 1 — Project setup

### 1. Existing Xcode template conflicted with the XcodeGen requirement
- **Problem:** The folder already held an Xcode-generated template (`ContentView.swift`, Swift 5 mode, iOS 26.5 target, bundle ID `lucastohmeh.UseBy`). The brief requires an XcodeGen-generated project with Swift 6, an iOS 26.0 target and `com.usebyapp.UseBy`.
- **Cause:** The project was created in Xcode before the brief was finalised.
- **Fix:** Backed up the template outside the repo, deleted the hand-made `.xcodeproj`, and wrote `project.yml` as the single source of truth. Kept the existing development team ID and the asset catalog (moved to `UseBy/Resources/`). The `.xcodeproj` is now git-ignored and regenerated with `xcodegen generate`.
- **Files changed:** `project.yml`, `.gitignore`, `UseBy/Resources/Assets.xcassets/*`, removed `UseBy/ContentView.swift`.

### 2. Template AppIcon had three slots (light, dark, tinted)
- **Problem:** The brief asks for a single 1024×1024 slot, but Xcode 26 templates create light, dark and tinted variants. Empty variant slots are noise in the asset catalog.
- **Cause:** Xcode 26 default template.
- **Fix:** Reduced `AppIcon.appiconset/Contents.json` to a single universal 1024×1024 entry. Gave `AccentColor` an explicit green with a lighter dark-appearance variant so it keeps contrast on black.
- **Files changed:** `UseBy/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json`, `.../AccentColor.colorset/Contents.json`.

### 3. A "warning:" line that isn't a build warning
- **Problem:** `xcodebuild` output contains `appintentsmetadataprocessor ... warning: Metadata extraction skipped. No AppIntents.framework dependency found.`, which looked like a breach of the zero-warnings rule.
- **Cause:** It's a log line from Xcode's App Intents metadata tool, printed for every target that doesn't link App Intents. It isn't a compiler diagnostic.
- **Fix:** Verified with the result bundle (`xcrun xcresulttool get build-results`): `warningCount 0`, `errorCount 0`. From now on, warnings are checked against the result bundle rather than by grepping logs.
- **Files changed:** none.

### 4. App Group entitlements look missing from simulator builds
- **Problem:** `codesign -d --entitlements -` on the simulator `.app` printed an empty dictionary, which looked like the App Group wasn't applied.
- **Cause:** Simulator builds are ad-hoc signed. Xcode embeds entitlements as "simulated" entitlements (`*-Simulated.xcent`, linked into the binary) instead of in the code signature.
- **Fix:** Confirmed `group.com.usebyapp.UseBy` is present in both `UseBy.app-Simulated.xcent` and `UseByWidget.appex-Simulated.xcent`. Device builds need the App Group registered for the signing team (see README).
- **Files changed:** none.

---

## Phase 3: Data layer

### 5. Open Food Facts returns HTTP 200 for unknown barcodes
- **Problem:** The brief maps a 404 to `notFound`. A live request for an unknown code (`00000000`) returned `HTTP 200` with `{"status":0,"status_verbose":"no code or invalid code"}`, so checking only for 404 would show "found" with an empty name.
- **Cause:** The OFF v2 API reports "not found" in the JSON body, not the HTTP status.
- **Fix:** `productInfo(from:barcode:)` treats `status == 0`, a missing product or a blank `product_name` as `notFound`. 404 is still handled for safety. Brands come back comma-separated (`"Nutella, Ferrero"`), so only the first brand is kept, and `displayName` skips the brand when the name already contains it.
- **Files changed:** `UseBy/Data/Repositories/OpenFoodFactsProductLookupRepository.swift`, `OpenFoodFactsProductDTO.swift`.

### 6. Notification callbacks and Swift 6 isolation
- **Problem:** `LocalReminderScheduler` is `@MainActor`, but `UNUserNotificationCenter` calls its completion handlers on a background queue. A closure created in a main-actor context is inferred as main-actor isolated, and Swift 6 inserts a runtime isolation check that crashes when the closure runs off the main thread.
- **Cause:** Closure isolation inference plus non-`Sendable` `UNNotificationSettings`, which is also why the async `notificationSettings()` variant was avoided.
- **Fix:** Used the completion-handler APIs wrapped in `withCheckedContinuation`. Marked the closures explicitly `@Sendable` and mapped `UNAuthorizationStatus` to the domain enum inside the closure through a `nonisolated static` helper, so only a `Sendable` value crosses actors.
- **Files changed:** `UseBy/Data/Services/LocalReminderScheduler.swift`.

### 7. Keeping history when an item is deleted
- **Problem:** `ConsumptionEvent` history must survive deleting the item it came from.
- **Cause:** SwiftData's default cascade behaviour depends on the relationship's delete rule, and the rule that matters is on the *item's* side of the inverse.
- **Fix:** `PantryItemEntity.events` uses `.nullify` with an explicit inverse to `ConsumptionEventEntity.item`, which is optional. Events also snapshot `itemName` and `categoryName`, so Insights never needs the item.
- **Files changed:** `Shared/Persistence/PantryItemEntity.swift`, `ConsumptionEventEntity.swift`.

### 8. SwiftData would silently use the App Group anyway
- **Problem:** With the App Group entitlement present, `ModelConfiguration`'s default `groupContainer: .automatic` already picks the group container. On a free personal team, where the group isn't provisioned, behaviour was unclear.
- **Cause:** Implicit default.
- **Fix:** `PersistenceController` resolves `containerURL(forSecurityApplicationGroupIdentifier:)` itself and passes an explicit store URL. If that returns `nil`, it logs a warning and uses `groupContainer: .none`, so the app still works and only the widget loses data. Verified on the simulator that `UseBy.store` lives in the App Group container.
- **Files changed:** `Shared/Persistence/PersistenceController.swift`.

---

## Phase 4: Presentation

### 9. Re-seeding crashed into the startup error screen
- **Problem:** The second launch with `-seedSampleData` showed "Your Pantry Couldn't Load". The log said: `Constraint trigger violation: Batch delete failed due to mandatory OTO nullify inverse on ConsumptionEventEntity/item`.
- **Cause:** `ModelContext.delete(model:)` runs a Core Data *batch* delete (`NSBatchDeleteRequest`). Batch deletes skip the object graph, so they can't apply the `.nullify` rule on the item ↔ event relationship and refuse to run. The first seed worked because the store was empty.
- **Fix:** The seeder now fetches and deletes each object individually (`deleteAll(_:)`), which goes through normal relationship handling. The startup error screen did its job: the app showed a friendly message instead of crashing.
- **Files changed:** `UseBy/App/SampleDataSeeder.swift`.

### 10. Long freshness badges wrapped in rows
- **Problem:** "Expired 1 day ago" wrapped onto two lines because the item name took the width first.
- **Cause:** Both children of the row's `HStack` had equal layout priority.
- **Fix:** `FreshnessBadge` gets `.layoutPriority(1)`, so the name wraps instead. At accessibility sizes the row switches to a `VStack` through `AnyLayout`, so the badge always has full width.
- **Files changed:** `UseBy/Presentation/Components/PantryItemRow.swift`.
