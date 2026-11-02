import Foundation

enum AppTab: Hashable {
    case today
    case insights
    case cook
}

enum DeepLink {
    static let scheme = "useby"
    static let today = WidgetLink.today

    static func tab(for url: URL) -> AppTab? {
        guard url.scheme?.lowercased() == scheme else { return nil }
        switch url.host()?.lowercased() {
        case "today": return .today
        case "insights": return .insights
        case "cook": return .cook
        default: return nil
        }
    }
}
