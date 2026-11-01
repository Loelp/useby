import Foundation
import SwiftData
import Testing
@testable import UseBy

@MainActor
@Suite("SwiftData pantry repository")
struct SwiftDataPantryRepositoryTests {
    let container: ModelContainer
    let pantry: SwiftDataPantryRepository
    let catalog: SwiftDataCatalogRepository

    init() throws {
        container = try PersistenceController.makeContainer(inMemory: true)
        pantry = SwiftDataPantryRepository(context: container.mainContext)
        catalog = SwiftDataCatalogRepository(context: container.mainContext)
        try catalog.seedDefaultsIfNeeded()
    }

    @Test("Seeds the default catalog once")
    func seedsDefaults() throws {
        try catalog.seedDefaultsIfNeeded()
        #expect(try catalog.locations().map(\.name) == ["Fridge", "Freezer", "Pantry"])
        #expect(try catalog.categories().count == 6)
    }

    @Test("Maps a missing catalog entry to catalogEntryMissing")
    func missingCatalogEntry() {
        let orphan = Fixtures.item("Greek yoghurt", daysFromNow: 2)
        #expect(throws: PantryError.catalogEntryMissing) {
            try pantry.insert(orphan)
        }
    }

    @Test("Round-trips insert, resolve and events(since:)")
    func roundTrip() throws {
        var item = Fixtures.item("Greek yoghurt", daysFromNow: 2, priceCents: 650)
        item.location = try #require(try catalog.locations().first)
        item.category = try #require(try catalog.categories().first { $0.name == "Dairy & Eggs" })

        try pantry.insert(item)
        #expect(try pantry.activeItems().map(\.id) == [item.id])

        let event = try pantry.resolve(itemID: item.id, outcome: .eaten, on: Fixtures.now)
        #expect(event.valueCents == 650)
        #expect(try pantry.activeItems().isEmpty)
        #expect(try pantry.item(id: item.id)?.status == .eaten)

        let recent = try pantry.events(since: Fixtures.date(daysFromNow: -7))
        #expect(recent.map(\.id) == [event.id])
        #expect(recent.first?.categoryName == "Dairy & Eggs")
        #expect(try pantry.events(since: Fixtures.date(daysFromNow: 1)).isEmpty)

        #expect(throws: PantryError.itemAlreadyResolved) {
            try pantry.resolve(itemID: item.id, outcome: .binned, on: Fixtures.now)
        }
    }

    @Test("History survives deleting the item")
    func historySurvivesDelete() throws {
        var item = Fixtures.item("Strawberries", daysFromNow: 1, priceCents: 550)
        item.location = try #require(try catalog.locations().first)
        item.category = try #require(try catalog.categories().first)
        try pantry.insert(item)
        _ = try pantry.resolve(itemID: item.id, outcome: .binned, on: Fixtures.now)

        try pantry.delete(itemID: item.id)

        let events = try pantry.events(since: nil)
        #expect(events.count == 1)
        #expect(events.first?.itemName == "Strawberries")
        #expect(events.first?.itemID == nil)
    }
}
