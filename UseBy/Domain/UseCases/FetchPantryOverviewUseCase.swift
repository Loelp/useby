import Foundation

@MainActor
struct FetchPantryOverviewUseCase {
    private let pantry: any PantryRepository
    private let now: () -> Date
    private let calendar: Calendar

    init(pantry: any PantryRepository, now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.pantry = pantry
        self.now = now
        self.calendar = calendar
    }

    /// Active items grouped by freshness, most urgent section first. Empty sections are omitted.
    func execute() throws -> [FreshnessSection] {
        let today = now()
        let grouped = Dictionary(grouping: try pantry.activeItems()) { item in
            item.freshness(on: today, calendar: calendar)
        }
        return Freshness.allCases.compactMap { freshness in
            guard let items = grouped[freshness], !items.isEmpty else { return nil }
            return FreshnessSection(freshness: freshness, items: items.sortedByUrgency())
        }
    }
}
