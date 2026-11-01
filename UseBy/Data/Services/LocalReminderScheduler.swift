import Foundation
import UserNotifications

/// Schedules a local notification at 9:00 am the day before an item's use-by date.
/// Uses completion-handler APIs: the async variants trip Swift 6 sendability checks
/// on `UNNotificationSettings`.
@MainActor
final class LocalReminderScheduler: ReminderScheduling {
    static let reminderHour = 9

    private let center: UNUserNotificationCenter
    private let now: () -> Date
    private let calendar: Calendar

    init(center: UNUserNotificationCenter = .current(), now: @escaping () -> Date = Date.init, calendar: Calendar = .current) {
        self.center = center
        self.now = now
        self.calendar = calendar
    }

    func authorization() async -> ReminderAuthorization {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { @Sendable settings in
                continuation.resume(returning: Self.map(settings.authorizationStatus))
            }
        }
    }

    func requestAuthorization() async -> ReminderAuthorization {
        await withCheckedContinuation { continuation in
            center.requestAuthorization(options: [.alert, .sound, .badge]) { @Sendable granted, _ in
                continuation.resume(returning: granted ? .authorized : .denied)
            }
        }
    }

    func scheduleReminder(for item: PantryItem) {
        guard let fireDate = reminderDate(for: item.useBy), fireDate > now() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Use it tomorrow"
        content.body = "\(item.name) is due tomorrow. Eat it before it ends up in the bin."
        content.sound = .default

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    func cancelReminder(for itemID: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [itemID.uuidString])
        center.removeDeliveredNotifications(withIdentifiers: [itemID.uuidString])
    }

    func reminderDate(for useBy: Date) -> Date? {
        guard let dayBefore = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: useBy)) else { return nil }
        return calendar.date(bySettingHour: Self.reminderHour, minute: 0, second: 0, of: dayBefore)
    }

    private nonisolated static func map(_ status: UNAuthorizationStatus) -> ReminderAuthorization {
        switch status {
        case .authorized, .provisional, .ephemeral: .authorized
        case .denied: .denied
        case .notDetermined: .notDetermined
        @unknown default: .denied
        }
    }
}
