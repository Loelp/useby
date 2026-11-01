import SwiftUI
import WidgetKit

struct ExpiringItemsEntry: TimelineEntry {
    let date: Date
}

struct ExpiringItemsProvider: TimelineProvider {
    func placeholder(in context: Context) -> ExpiringItemsEntry {
        ExpiringItemsEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (ExpiringItemsEntry) -> Void) {
        completion(ExpiringItemsEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ExpiringItemsEntry>) -> Void) {
        completion(Timeline(entries: [ExpiringItemsEntry(date: .now)], policy: .never))
    }
}

struct ExpiringItemsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.expiringItems, provider: ExpiringItemsProvider()) { _ in
            Text("Nothing expiring — nice!")
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Expiring Soon")
        .description("See what to use up first.")
    }
}
