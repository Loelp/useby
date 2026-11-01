import SwiftUI

struct ReminderBanner: View {
    let authorization: ReminderAuthorization
    let onTurnOn: () -> Void
    let onOpenSettings: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    // ViewThatFits always accepts the HStack because text can wrap, so switch explicitly.
    private var isStacked: Bool { dynamicTypeSize.isAccessibilitySize }

    var body: some View {
        let layout = isStacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        layout {
            if isStacked {
                Image(systemName: "bell.badge")
                    .font(.title2)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                messageText
            } else {
                Label {
                    messageText
                } icon: {
                    Image(systemName: "bell.badge")
                        .foregroundStyle(.tint)
                }
                Spacer(minLength: 8)
            }
            actionButton
        }
        .padding(.vertical, 4)
    }

    private var messageText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Reminders are off")
                .font(.headline)
            Text(authorization == .denied
                 ? "Allow notifications in Settings to hear about food the day before it expires."
                 : "Get a heads-up the day before food expires.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var actionButton: some View {
        if authorization == .denied {
            Button(action: onOpenSettings) {
                Text("Open Settings")
                    .frame(maxWidth: isStacked ? .infinity : nil, minHeight: 44)
            }
            .buttonStyle(.bordered)
        } else {
            Button(action: onTurnOn) {
                Text("Turn On")
                    .frame(maxWidth: isStacked ? .infinity : nil, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}
