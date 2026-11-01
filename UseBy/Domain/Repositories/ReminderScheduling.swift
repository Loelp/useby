import Foundation

@MainActor
protocol ReminderScheduling {
    func authorization() async -> ReminderAuthorization
    @discardableResult
    func requestAuthorization() async -> ReminderAuthorization
    /// Best-effort: silently does nothing if reminders aren't allowed.
    func scheduleReminder(for item: PantryItem)
    func cancelReminder(for itemID: UUID)
}
