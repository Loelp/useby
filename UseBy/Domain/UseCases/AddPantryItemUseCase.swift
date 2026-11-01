import Foundation

@MainActor
struct AddPantryItemUseCase {
    static let maxNameLength = 60
    static let quantityRange = 1...99

    private let pantry: any PantryRepository
    private let reminders: any ReminderScheduling
    private let now: () -> Date
    private let calendar: Calendar

    init(
        pantry: any PantryRepository,
        reminders: any ReminderScheduling,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current
    ) {
        self.pantry = pantry
        self.reminders = reminders
        self.now = now
        self.calendar = calendar
    }

    @discardableResult
    func execute(_ draft: NewPantryItemDraft) throws -> PantryItem {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { throw PantryError.emptyName }
        guard name.count <= Self.maxNameLength else { throw PantryError.nameTooLong(max: Self.maxNameLength) }
        guard Self.quantityRange.contains(draft.quantity) else { throw PantryError.invalidQuantity }
        guard draft.priceCents >= 0 else { throw PantryError.negativePrice }

        let today = now()
        guard calendar.startOfDay(for: draft.useBy) >= calendar.startOfDay(for: today) else {
            throw PantryError.useByInPast
        }
        guard let location = draft.location, let category = draft.category else {
            throw PantryError.catalogEntryMissing
        }

        let barcode = draft.barcode?.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = PantryItem(
            id: UUID(),
            name: name,
            quantity: draft.quantity,
            priceCents: draft.priceCents,
            addedOn: today,
            useBy: draft.useBy,
            barcode: barcode?.isEmpty == false ? barcode : nil,
            status: .active,
            location: location,
            category: category
        )
        try pantry.insert(item)
        reminders.scheduleReminder(for: item)
        return item
    }
}
