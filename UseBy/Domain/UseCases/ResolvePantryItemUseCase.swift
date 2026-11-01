import Foundation

@MainActor
struct ResolvePantryItemUseCase {
    private let pantry: any PantryRepository
    private let reminders: any ReminderScheduling
    private let now: () -> Date

    init(pantry: any PantryRepository, reminders: any ReminderScheduling, now: @escaping () -> Date = Date.init) {
        self.pantry = pantry
        self.reminders = reminders
        self.now = now
    }

    @discardableResult
    func execute(itemID: UUID, outcome: ConsumptionOutcome) throws -> ConsumptionEvent {
        guard let item = try pantry.item(id: itemID) else { throw PantryError.itemNotFound }
        guard item.status == .active else { throw PantryError.itemAlreadyResolved }
        let event = try pantry.resolve(itemID: itemID, outcome: outcome, on: now())
        reminders.cancelReminder(for: itemID)
        return event
    }
}
