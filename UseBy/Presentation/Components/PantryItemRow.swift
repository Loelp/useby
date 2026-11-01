import SwiftUI

struct PantryItemRow: View {
    let item: PantryItem
    let daysRemaining: Int

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title3) private var iconWidth = 32

    private var layout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
    }

    var body: some View {
        layout {
            Image(systemName: item.category.symbolName)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: iconWidth)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                Text(detailText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            FreshnessBadge(daysRemaining: daysRemaining)
        }
        .padding(.vertical, 4)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var detailText: String {
        item.quantity > 1 ? "\(item.location.name) · Qty \(item.quantity)" : item.location.name
    }

    private var accessibilityText: String {
        var parts = [item.name]
        if item.quantity > 1 { parts.append("quantity \(item.quantity)") }
        parts.append(item.location.name)
        parts.append(Freshness.spokenText(daysRemaining: daysRemaining))
        return parts.joined(separator: ", ")
    }
}
