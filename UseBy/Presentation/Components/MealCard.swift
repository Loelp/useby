import SwiftUI

struct MealCard: View {
    let idea: MealIdea

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(idea.title)
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Label("\(idea.minutes) min", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("\(idea.minutes) minutes")
            }

            if !idea.usesItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Uses up")
                        .font(.headline)
                    ItemChips(names: idea.usesItems)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Ingredients")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(idea.ingredients.enumerated()), id: \.offset) { _, ingredient in
                    Label {
                        Text(ingredient)
                    } icon: {
                        Image(systemName: "circle.fill")
                            .font(.system(.caption2))
                            .foregroundStyle(.tint)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Steps")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                ForEach(Array(idea.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(index + 1).")
                            .font(.body.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.tint)
                        Text(step)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct ItemChips: View {
    let names: [String]

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(names, id: \.self) { name in
                Text(name)
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews: subviews, maxWidth: proposal.width ?? .infinity)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews: subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: min(size.width, bounds.width), height: size.height))
                x += min(size.width, bounds.width) + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            let itemWidth = min(size.width, maxWidth)
            let proposedWidth = current.indices.isEmpty ? itemWidth : current.width + spacing + itemWidth
            if proposedWidth > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? itemWidth : current.width + spacing + itemWidth
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
