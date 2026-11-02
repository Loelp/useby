import SwiftUI

extension Freshness {
    var color: Color {
        switch self {
        case .expired: .red
        case .today: .orange
        case .soon: .yellow
        case .fresh: .green
        }
    }

    var sectionTitle: String {
        switch self {
        case .expired: "Expired"
        case .today: "Use Today"
        case .soon: "Use Soon"
        case .fresh: "Fresh"
        }
    }

    static func badgeText(daysRemaining days: Int) -> String {
        switch days {
        case ..<0: "Expired \(dayCount(-days)) ago"
        case 0: "Today"
        default: dayCount(days)
        }
    }

    static func spokenText(daysRemaining days: Int) -> String {
        switch days {
        case ..<0: "expired \(dayCount(-days)) ago"
        case 0: "use today"
        case 1: "use by tomorrow"
        default: "use within \(dayCount(days))"
        }
    }

    private static func dayCount(_ days: Int) -> String {
        days == 1 ? "1 day" : "\(days) days"
    }
}
