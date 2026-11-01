import SwiftUI
import WidgetKit

struct ExpiringItemsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetKind.expiringItems, provider: ExpiringItemsProvider()) { entry in
            ExpiringItemsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(WidgetLink.today)
        }
        .configurationDisplayName("Use It Up")
        .description("See what to eat first, before it expires.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryInline])
    }
}

struct ExpiringItemsWidgetView: View {
    let entry: ExpiringItemsEntry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium: MediumView(entry: entry)
        case .accessoryRectangular: RectangularView(entry: entry)
        case .accessoryInline: InlineView(entry: entry)
        default: SmallView(entry: entry)
        }
    }
}

private enum WidgetCopy {
    static let empty = "Nothing expiring — nice!"

    static func countTitle(_ count: Int) -> String {
        count == 1 ? "1 to use up" : "\(count) to use up"
    }

    static func leadPhrase(for freshness: Freshness) -> String {
        switch freshness {
        case .expired: "Expired"
        case .today: "Use today"
        case .soon, .fresh: "Use soon"
        }
    }
}

private struct SmallView: View {
    let entry: ExpiringItemsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if entry.isEmpty {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                Spacer(minLength: 0)
                Text(WidgetCopy.empty)
                    .font(.headline)
            } else {
                Text(entry.items.count, format: .number)
                    .font(.largeTitle.weight(.bold).monospacedDigit())
                Text("to use up")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                ForEach(entry.items.prefix(2)) { item in
                    HStack(spacing: 6) {
                        Circle().fill(item.freshness.color).frame(width: 8, height: 8)
                        Text(item.name)
                            .font(.caption.weight(.medium))
                            .lineLimit(1)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

private struct MediumView: View {
    let entry: ExpiringItemsEntry

    var body: some View {
        if entry.isEmpty {
            Label(WidgetCopy.empty, systemImage: "checkmark.seal.fill")
                .font(.headline)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text(WidgetCopy.countTitle(entry.items.count))
                    .font(.headline)
                ForEach(entry.items.prefix(4)) { item in
                    HStack(spacing: 8) {
                        Image(systemName: item.symbolName)
                            .font(.caption)
                            .foregroundStyle(.tint)
                            .frame(width: 18)
                        Text(item.name)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        HStack(spacing: 4) {
                            Circle().fill(item.freshness.color).frame(width: 7, height: 7)
                            Text(Freshness.badgeText(daysRemaining: item.daysRemaining))
                                .font(.caption.weight(.medium))
                                .lineLimit(1)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct RectangularView: View {
    let entry: ExpiringItemsEntry

    var body: some View {
        if let first = entry.items.first {
            VStack(alignment: .leading, spacing: 2) {
                Text(WidgetCopy.leadPhrase(for: first.freshness))
                    .font(.headline)
                    .widgetAccentable()
                Text(first.name)
                    .lineLimit(1)
                if entry.items.count > 1 {
                    Text("+\(entry.items.count - 1) more")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(WidgetCopy.empty)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct InlineView: View {
    let entry: ExpiringItemsEntry

    var body: some View {
        if let first = entry.items.first {
            let extra = entry.items.count > 1 ? " +\(entry.items.count - 1)" : ""
            Text("\(WidgetCopy.leadPhrase(for: first.freshness)): \(first.name)\(extra)")
        } else {
            Text(WidgetCopy.empty)
        }
    }
}

#Preview(as: .systemSmall) {
    ExpiringItemsWidget()
} timeline: {
    ExpiringItemsEntry.sample
    ExpiringItemsEntry(date: .now, items: [])
}

#Preview(as: .systemMedium) {
    ExpiringItemsWidget()
} timeline: {
    ExpiringItemsEntry.sample
}

#Preview(as: .accessoryRectangular) {
    ExpiringItemsWidget()
} timeline: {
    ExpiringItemsEntry.sample
}
