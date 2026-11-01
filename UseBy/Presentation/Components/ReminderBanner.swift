import SwiftUI

struct ReminderBanner: View {
    let authorization: ReminderAuthorization
    let onTurnOn: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                message
                Spacer(minLength: 8)
                actionButton
            }
            VStack(alignment: .leading, spacing: 12) {
                message
                actionButton
            }
        }
        .padding(.vertical, 4)
    }

    private var message: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text("Reminders are off")
                    .font(.headline)
                Text(authorization == .denied
                     ? "Allow notifications in Settings to hear about food the day before it expires."
                     : "Get a heads-up the day before food expires.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "bell.badge")
                .foregroundStyle(.tint)
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if authorization == .denied {
            Button("Open Settings", action: onOpenSettings)
                .buttonStyle(.bordered)
                .frame(minHeight: 44)
        } else {
            Button("Turn On", action: onTurnOn)
                .buttonStyle(.borderedProminent)
                .frame(minHeight: 44)
        }
    }
}
