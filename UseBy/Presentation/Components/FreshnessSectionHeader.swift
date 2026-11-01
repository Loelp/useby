import SwiftUI

struct FreshnessSectionHeader: View {
    let freshness: Freshness
    let count: Int

    @ScaledMetric(relativeTo: .headline) private var dotSize = 10

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(freshness.color)
                .frame(width: dotSize, height: dotSize)
            Text(freshness.sectionTitle)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            Text(count, format: .number)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(freshness.sectionTitle), \(count == 1 ? "1 item" : "\(count) items")")
        .accessibilityAddTraits(.isHeader)
    }
}
