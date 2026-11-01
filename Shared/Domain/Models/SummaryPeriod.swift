import Foundation

enum SummaryPeriod: String, Sendable, Hashable, CaseIterable, Identifiable {
    case week
    case month
    case allTime

    var id: Self { self }

    var dayCount: Int? {
        switch self {
        case .week: 7
        case .month: 30
        case .allTime: nil
        }
    }

    var title: String {
        switch self {
        case .week: "Week"
        case .month: "Month"
        case .allTime: "All Time"
        }
    }

    /// Earliest event date included in this period, or `nil` for all time.
    func startDate(endingAt now: Date, calendar: Calendar) -> Date? {
        guard let dayCount else { return nil }
        return calendar.date(byAdding: .day, value: -dayCount, to: now)
    }
}
