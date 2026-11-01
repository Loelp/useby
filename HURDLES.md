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
