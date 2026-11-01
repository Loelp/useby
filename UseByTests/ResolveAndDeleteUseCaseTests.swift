import Foundation
import Testing
@testable import UseBy

@MainActor
@Suite("Resolve and delete pantry items")
struct ResolveAndDeleteUseCaseTests {
    let reminders = MockReminderScheduler()

    @Test("Resolve records an eaten event with the item's value and cancels its reminder")
    func resolveEaten() throws {
        let yoghurt = Fixtures.item("Greek yoghurt", daysFromNow: 1, priceCents: 650, category: Fixtures.dairy)
        let pantry = MockPantryRepository(items: [yoghurt])
        let useCase = ResolvePantryItemUseCase(pantry: pantry, reminders: reminders, now: { Fixtures.now })

        let event = try useCase.execute(itemID: yoghurt.id, outcome: .eaten)

        #expect(event.outcome == .eaten)
        #expect(event.valueCents == 650)
        #expect(event.itemID == yoghurt.id)
        #expect(event.itemName == "Greek yoghurt")
        #expect(event.categoryName == "Dairy & Eggs")
        #expect(event.date == Fixtures.now)
        #expect(pantry.items[yoghurt.id]?.status == .eaten)
        #expect(reminders.cancelledIDs == [yoghurt.id])
    }

    @Test("Resolve throws itemAlreadyResolved for an item that is already binned")
    func resolveAlreadyBinned() {
        let binned = Fixtures.item("Coriander", daysFromNow: -1, status: .binned)
        let pantry = MockPantryRepository(items: [binned])
        let useCase = ResolvePantryItemUseCase(pantry: pantry, reminders: reminders, now: { Fixtures.now })

        #expect(throws: PantryError.itemAlreadyResolved) {
            try useCase.execute(itemID: binned.id, outcome: .eaten)
        }
        #expect(pantry.storedEvents.isEmpty)
        #expect(reminders.cancelledIDs.isEmpty)
    }

    @Test("Resolve throws itemNotFound for an unknown ID")
    func resolveUnknown() {
        let useCase = ResolvePantryItemUseCase(pantry: MockPantryRepository(), reminders: reminders, now: { Fixtures.now })
        #expect(throws: PantryError.itemNotFound) {
            try useCase.execute(itemID: UUID(), outcome: .binned)
        }
    }

    @Test("Delete removes the item and cancels its reminder")
    func deleteItem() throws {
        let item = Fixtures.item("Cheddar block", daysFromNow: 20)
        let pantry = MockPantryRepository(items: [item])
        try DeletePantryItemUseCase(pantry: pantry, reminders: reminders).execute(itemID: item.id)

        #expect(pantry.deletedIDs == [item.id])
        #expect(reminders.cancelledIDs == [item.id])
    }

    @Test("Delete throws itemNotFound for an unknown ID")
    func deleteUnknown() {
        let useCase = DeletePantryItemUseCase(pantry: MockPantryRepository(), reminders: reminders)
        #expect(throws: PantryError.itemNotFound) {
            try useCase.execute(itemID: UUID())
        }
    }
}
