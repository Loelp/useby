import Foundation
import Testing
@testable import UseBy

@MainActor
@Suite("Add pantry item")
struct AddPantryItemUseCaseTests {
    let pantry = MockPantryRepository()
    let reminders = MockReminderScheduler()

    var useCase: AddPantryItemUseCase {
        AddPantryItemUseCase(pantry: pantry, reminders: reminders, now: { Fixtures.now }, calendar: Fixtures.calendar)
    }

    @Test("Rejects a blank or whitespace-only name and saves nothing", arguments: ["", "   ", "\n\t "])
    func rejectsBlankName(name: String) {
        #expect(throws: PantryError.emptyName) {
            try useCase.execute(Fixtures.draft(name: name))
        }
        #expect(pantry.insertedItems.isEmpty)
        #expect(reminders.scheduledIDs.isEmpty)
    }

    @Test("Rejects a name longer than 60 characters")
    func rejectsLongName() {
        #expect(throws: PantryError.nameTooLong(max: 60)) {
            try useCase.execute(Fixtures.draft(name: String(repeating: "a", count: 61)))
        }
    }

    @Test("Rejects a use-by date before today")
    func rejectsPastUseBy() {
        #expect(throws: PantryError.useByInPast) {
            try useCase.execute(Fixtures.draft(useByDaysFromNow: -1))
        }
        #expect(pantry.insertedItems.isEmpty)
    }

    @Test("Accepts a use-by date earlier today, compared as start of day")
    func acceptsEarlierToday() throws {
        var draft = Fixtures.draft()
        draft.useBy = Fixtures.date(daysFromNow: 0, hour: 1)
        try useCase.execute(draft)
        #expect(pantry.insertedItems.count == 1)
    }

    @Test("Rejects quantities outside 1–99", arguments: [0, 100])
    func rejectsInvalidQuantity(quantity: Int) {
        #expect(throws: PantryError.invalidQuantity) {
            try useCase.execute(Fixtures.draft(quantity: quantity))
        }
    }

    @Test("Rejects a negative price")
    func rejectsNegativePrice() {
        #expect(throws: PantryError.negativePrice) {
            try useCase.execute(Fixtures.draft(priceCents: -1))
        }
    }

    @Test("Requires a location and category")
    func requiresCatalogEntries() {
        var draft = Fixtures.draft()
        draft.location = nil
        #expect(throws: PantryError.catalogEntryMissing) {
            try useCase.execute(draft)
        }
    }

    @Test("Saves the trimmed name and schedules exactly one reminder")
    func savesTrimmedName() throws {
        let item = try useCase.execute(Fixtures.draft(name: "  Greek yoghurt \n"))

        #expect(item.name == "Greek yoghurt")
        #expect(item.status == .active)
        #expect(item.addedOn == Fixtures.now)
        #expect(pantry.insertedItems.map(\.name) == ["Greek yoghurt"])
        #expect(reminders.scheduledIDs == [item.id])
    }

    @Test("Propagates persistenceFailed and does not schedule a reminder")
    func propagatesPersistenceFailure() {
        pantry.errorToThrow = PantryError.persistenceFailed
        #expect(throws: PantryError.persistenceFailed) {
            try useCase.execute(Fixtures.draft())
        }
        #expect(reminders.scheduledIDs.isEmpty)
    }
}
