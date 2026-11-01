import Foundation

@MainActor
struct DeletePantryItemUseCase {
    private let pantry: any PantryRepository
    private let reminders: any ReminderScheduling

    init(pantry: any PantryRepository, reminders: any ReminderScheduling) {
        self.pantry = pantry
        self.reminders = reminders
    }

    func execute(itemID: UUID) throws {
        guard try pantry.item(id: itemID) != nil else { throw PantryError.itemNotFound }
        try pantry.delete(itemID: itemID)
        reminders.cancelReminder(for: itemID)
    }
}
