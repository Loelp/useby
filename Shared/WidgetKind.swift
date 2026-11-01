import Foundation

/// WidgetKit kind strings, shared so the app can reload exactly the timelines it affects.
enum WidgetKind {
    static let expiringItems = "com.usebyapp.UseBy.ExpiringItems"
}

enum WidgetLink {
    /// Opens the app on the Today tab.
    static let today = URL(string: "useby://today")!
}
