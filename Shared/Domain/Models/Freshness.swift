import Foundation

/// Urgency bucket for an item, ordered from most to least urgent.
enum Freshness: Int, Sendable, Hashable, CaseIterable, Comparable {
    /// Use-by date has passed (fewer than 0 days left).
    case expired
    /// Use by today (0 days left).
    case today
    /// Use within 1–3 days.
    case soon
    /// More than 3 days left.
    case fresh

    static let soonThresholdDays = 3

    init(daysRemaining: Int) {
        switch daysRemaining {
        case ..<0: self = .expired
        case 0: self = .today
        case 1...Self.soonThresholdDays: self = .soon
        default: self = .fresh
        }
    }

    static func < (lhs: Freshness, rhs: Freshness) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
