import Foundation

@MainActor
protocol ReminderScheduling {
    func authorization() async -> ReminderAuthorization
    @discardableResult
    func requestAuthorization() async -> ReminderAuthorization
    func scheduleReminder(for item: PantryItem)
    func cancelReminder(for itemID: UUID)
}
