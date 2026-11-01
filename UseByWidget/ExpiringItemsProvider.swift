import Foundation
import WidgetKit

struct WidgetItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let symbolName: String
    let daysRemaining: Int

    var freshness: Freshness { Freshness(daysRemaining: daysRemaining) }
}

struct ExpiringItemsEntry: TimelineEntry {
    let date: Date
    let items: [WidgetItem]

    var isEmpty: Bool { items.isEmpty }

    static let sample = ExpiringItemsEntry(date: .now, items: [
        WidgetItem(id: UUID(), name: "Greek yoghurt", symbolName: "waterbottle", daysRemaining: 0),
        WidgetItem(id: UUID(), name: "Lebanese cucumbers", symbolName: "carrot", daysRemaining: 1),
        WidgetItem(id: UUID(), name: "Chicken thigh fillets", symbolName: "fish", daysRemaining: 2),
        WidgetItem(id: UUID(), name: "Sourdough loaf", symbolName: "birthday.cake", daysRemaining: 3),
    ])
}

struct ExpiringItemsProvider: TimelineProvider {
    private let reader = WidgetPantryReader()

    func placeholder(in context: Context) -> ExpiringItemsEntry {
        .sample
    }

    func getSnapshot(in context: Context, completion: @escaping (ExpiringItemsEntry) -> Void) {
        completion(context.isPreview ? .sample : makeEntry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ExpiringItemsEntry>) -> Void) {
        let now = Date.now
        let calendar = Calendar.autoupdatingCurrent
        let entry = makeEntry(at: now, calendar: calendar)
        // Days-remaining changes at midnight, so refresh just after it.
        let nextMidnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime) ?? now.addingTimeInterval(86_400)
        let refresh = nextMidnight.addingTimeInterval(60)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func makeEntry(at now: Date, calendar: Calendar = .autoupdatingCurrent) -> ExpiringItemsEntry {
        let items = reader.urgentItems(now: now, calendar: calendar).map { item in
            WidgetItem(
                id: item.id,
                name: item.name,
                symbolName: item.category.symbolName,
                daysRemaining: item.daysRemaining(from: now, calendar: calendar)
            )
        }
        return ExpiringItemsEntry(date: now, items: items)
    }
}
