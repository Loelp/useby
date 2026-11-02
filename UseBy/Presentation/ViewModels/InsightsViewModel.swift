import Foundation
import Observation

struct CategoryOutcomeBar: Identifiable, Hashable {
    let categoryName: String
    let outcome: ConsumptionOutcome
    let count: Int

    var id: String { "\(categoryName)-\(outcome.rawValue)" }
    var outcomeTitle: String { outcome == .eaten ? "Eaten" : "Binned" }
}

@MainActor
@Observable
final class InsightsViewModel {
    var period: SummaryPeriod = .week
    private(set) var summary: WasteSummary = .empty
    private(set) var hasLoaded = false
    private(set) var errorMessage: String?

    private let calculateSummary: CalculateWasteSummaryUseCase

    init(calculateSummary: CalculateWasteSummaryUseCase) {
        self.calculateSummary = calculateSummary
    }

    var isEmpty: Bool { hasLoaded && !summary.hasHistory }

    var savedText: String { Money.string(cents: summary.savedCents) }
    var wastedText: String { Money.string(cents: summary.wastedCents) }
    var wasteRateText: String { summary.wasteRate.formatted(.percent.precision(.fractionLength(0))) }

    var chartBars: [CategoryOutcomeBar] {
        summary.categoryBreakdown.flatMap { category in
            [
                CategoryOutcomeBar(categoryName: category.categoryName, outcome: .eaten, count: category.eatenCount),
                CategoryOutcomeBar(categoryName: category.categoryName, outcome: .binned, count: category.binnedCount),
            ]
        }
    }

    var emptyMessage: String {
        switch period {
        case .week: "Nothing marked as eaten or binned in the last 7 days. Swipe items on the Today tab to start tracking."
        case .month: "Nothing marked as eaten or binned in the last 30 days. Swipe items on the Today tab to start tracking."
        case .allTime: "Mark items as Eaten or Binned on the Today tab to see how much you're saving."
        }
    }

    func load() {
        do {
            summary = try calculateSummary.execute(period: period)
            errorMessage = nil
        } catch {
            summary = .empty
            errorMessage = error.userMessage
        }
        hasLoaded = true
    }
}
