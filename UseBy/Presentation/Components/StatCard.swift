import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .labelStyle(TintedIconLabelStyle(tint: tint))
            Text(value)
                .font(.title2.weight(.semibold).monospacedDigit())
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }
}

private struct TintedIconLabelStyle: LabelStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(tint)
            configuration.title
        }
    }
}
