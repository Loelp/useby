import SwiftUI

/// Coloured dot plus primary-coloured text, so colour is never the only signal.
struct FreshnessBadge: View {
    let daysRemaining: Int

    @ScaledMetric(relativeTo: .subheadline) private var dotSize = 10

    private var freshness: Freshness { Freshness(daysRemaining: daysRemaining) }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(freshness.color)
                .frame(width: dotSize, height: dotSize)
                .accessibilityHidden(true)
            Text(Freshness.badgeText(daysRemaining: daysRemaining))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(freshness.color.opacity(0.15), in: Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Freshness.spokenText(daysRemaining: daysRemaining))
    }
}

#Preview {
    VStack(alignment: .leading) {
        FreshnessBadge(daysRemaining: -1)
        FreshnessBadge(daysRemaining: 0)
        FreshnessBadge(daysRemaining: 2)
        FreshnessBadge(daysRemaining: 9)
    }
}
