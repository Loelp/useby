# UseBy: Food Expiry Tracker

UseBy is a pantry expiry tracker for share houses and young couples who do one big weekly shop and keep binning forgotten food. Scan or type your groceries, see them sorted by urgency, mark each one **Eaten** or **Binned**, and watch the dollars you save. When things are about to turn, ask for an on-device meal idea.

- iPhone only, iOS 26.0+, Swift 6 (strict concurrency), SwiftUI + SwiftData
- No accounts, analytics or tracking. Privacy label: **Data Not Collected**
- The only network call is the Open Food Facts barcode lookup

## Setup

1. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. Generate the project. `project.yml` is the source of truth, and the `.xcodeproj` is git-ignored:
   ```sh
   xcodegen generate
   open UseBy.xcodeproj
   ```
3. **Signing:** `project.yml` sets `DEVELOPMENT_TEAM`. Change it to your own team ID, or pick your team under *Signing & Capabilities* for both the **UseBy** and **UseByWidget** targets. Re-running `xcodegen generate` resets this, so edit `project.yml` to make it stick.
4. **App Group:** both targets use `group.com.usebyapp.UseBy` so the widget can read the app's SwiftData store. On a paid team, Xcode registers it automatically. On a free personal team, App Groups may not be provisioned. The app still runs and falls back to a private store (`PersistenceController`), but the widget will show the empty state.
5. **App icon:** drop a 1024×1024 PNG into `UseBy/Resources/Assets.xcassets/AppIcon.appiconset` and reference it in `Contents.json`.

## Running

Select the **UseBy** scheme and an iPhone simulator, then run.

**Demo data (DEBUG only).** In *Product ▸ Scheme ▸ Edit Scheme ▸ Run ▸ Arguments*, tick:

| Argument | Effect |
| --- | --- |
| `-seedSampleData` | Replaces the store with realistic Australian groceries across all four freshness levels, plus about 2 weeks of eaten/binned history with real prices. Used for App Store screenshots and the demo video. |
| `-resetData` | Wipes the store, then re-seeds the default locations and categories. |
| `-initialTab insights` | Opens on a given tab (`today`, `insights`, `cook`). Handy for screenshots. |

From the command line:

```sh
xcrun simctl launch booted com.usebyapp.UseBy -seedSampleData -initialTab today
```

The deep link `useby://today` opens the Today tab, and it's what the widget uses.

**Cook It Now** needs Apple Intelligence: an eligible iPhone with Apple Intelligence turned on in Settings. Otherwise the Cook tab explains why it's unavailable. On the simulator it uses the host Mac's model, if the Mac has Apple Intelligence enabled.

## Testing

Unit tests use **Swift Testing** (`import Testing`) and live in `UseByTests/`.

```sh
xcodegen generate
xcodebuild test -project UseBy.xcodeproj -scheme UseBy \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

Or press **⌘U** in Xcode. The suite covers every use-case business rule with in-memory mocks (`Mocks.swift`) and a fixed date and `Australia/Sydney` calendar (`Fixtures.swift`). It also runs a real `SwiftDataPantryRepository` against an in-memory container and checks the Open Food Facts response mapping and the presentation helpers.

## Architecture

MVVM + Use Case layer + Repository pattern. Dependencies point inwards: Presentation → Domain ← Data.

```
UseBy/
  App/                    UseByApp, AppContainer (composition root), SampleDataSeeder (DEBUG)
  Domain/UseCases/        Business rules: @MainActor structs with injected repositories, clock and calendar
  Domain/Repositories/    Protocols only
  Data/Repositories/      SwiftData + Open Food Facts implementations
  Data/Services/          Foundation Models, local notifications, camera access
  Presentation/
    Views/                SwiftUI screens; talk only to their ViewModel
    ViewModels/           @MainActor @Observable final classes
    Components/           Reusable views (rows, badges, cards, scanner wrapper)
    Support/              Money, error messages, deep links
Shared/                   Compiled into both app and widget
  Domain/Models/          Value-type domain models (Sendable)
  Domain/Errors/          PantryError, MealSuggestionError, ProductLookupError
  Persistence/            SwiftData @Model entities, mappers, PersistenceController
  Presentation/           Freshness colours and badge text
UseByWidget/              WidgetKit extension (small, medium, lock screen)
UseByTests/               Swift Testing suite
```

| Layer | Knows about | Never touches |
| --- | --- | --- |
| Views | Their ViewModel, components | SwiftData, URLSession, AVFoundation, UserNotifications, FoundationModels |
| ViewModels | Use cases, repository protocols | Concrete repositories, frameworks |
| Use cases | Domain models, repository protocols | Any framework beyond Foundation |
| Repositories and services | Frameworks, entities, mappers | Views |

`AppContainer` builds every dependency once and exposes `make…ViewModel()` factories. If the SwiftData container can't be created, `UseByApp` shows a friendly error screen instead of crashing.

### Data flow: marking an item as Eaten

1. **View:** the user swipes right on a row in `TodayView` and taps **Eaten**. The view calls `viewModel.markEaten(item)`.
2. **ViewModel:** `TodayViewModel` calls `ResolvePantryItemUseCase.execute(itemID:outcome: .eaten)`.
3. **Use case:** checks that the item exists (`itemNotFound`) and is still active (`itemAlreadyResolved`), then calls `PantryRepository.resolve(itemID:outcome:on:)` with the injected clock.
4. **Repository:** `SwiftDataPantryRepository` sets `statusRaw`, creates a `ConsumptionEventEntity` that snapshots the item's name, category and price, and saves the main `ModelContext`. Storage errors become `PantryError.persistenceFailed`.
5. **Side effects:** after the save, the repository calls `WidgetCenter.shared.reloadTimelines(ofKind:)`, so the widget refreshes. Back in the use case, `ReminderScheduling.cancelReminder(for:)` removes the pending notification.
6. **UI update:** the ViewModel bumps `eatenCount`, which triggers `.sensoryFeedback(.success)`. It then reloads the overview through `FetchPantryOverviewUseCase`, and `@Observable` re-renders the list without the item. The Insights tab picks up the new event the next time it appears.

## Third-party attribution

- **Open Food Facts:** product names come from the [Open Food Facts](https://world.openfoodfacts.org) database, available under the [Open Database Licence (ODbL)](https://opendatacommons.org/licenses/odbl/1-0/). Individual database contents are under the [Database Contents Licence](https://opendatacommons.org/licenses/dbcl/1-0/).
- **No Swift Package Manager dependencies.** UseBy uses only Apple frameworks: SwiftUI, SwiftData, WidgetKit, Swift Charts, VisionKit, AVFoundation, UserNotifications and FoundationModels.

## AI assistance

Claude Code (Anthropic) was used to assist in the planning of code, and the writing of the readme file.

<!-- Team: describe how AI assistance was used, what you reviewed or changed, and how you verified the output. -->

## Development notes

See [`HURDLES.md`](HURDLES.md) for a log of build errors, concurrency problems, API surprises and design trade-offs encountered during development.
