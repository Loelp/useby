import Foundation

@MainActor
struct CalculateWasteSummaryUseCase {
    private let pantry: any PantryRepository
    private let now: () -> Date
    private let calendar: Calendar

    init(pantry: any PantryRepository, now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.pantry = pantry
        self.now = now
        self.calendar = calendar
    }

    func execute(period: SummaryPeriod) throws -> WasteSummary {
        let events = try pantry.events(since: period.startDate(endingAt: now(), calendar: calendar))
        var saved = 0, wasted = 0, eaten = 0, binned = 0
        var byCategory: [String: CategoryWaste] = [:]

        for event in events {
            var entry = byCategory[event.categoryName]
                ?? CategoryWaste(categoryName: event.categoryName, eatenCount: 0, binnedCount: 0, savedCents: 0, wastedCents: 0)
            switch event.outcome {
            case .eaten:
                saved += event.valueCents
                eaten += 1
                entry.savedCents += event.valueCents
                entry.eatenCount += 1
            case .binned:
                wasted += event.valueCents
                binned += 1
                entry.wastedCents += event.valueCents
                entry.binnedCount += 1
            }
            byCategory[event.categoryName] = entry
        }

        let breakdown = byCategory.values.sorted { lhs, rhs in
            let lhsTotal = lhs.eatenCount + lhs.binnedCount
            let rhsTotal = rhs.eatenCount + rhs.binnedCount
            if lhsTotal != rhsTotal { return lhsTotal > rhsTotal }
            return lhs.categoryName < rhs.categoryName
        }
        return WasteSummary(savedCents: saved, wastedCents: wasted, eatenCount: eaten, binnedCount: binned, categoryBreakdown: breakdown)
    }
}
