import Foundation

enum Freshness: Int, Sendable, Hashable, CaseIterable, Comparable {
    case expired
    case today
    case soon
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
