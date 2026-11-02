import Foundation

@MainActor
protocol PantryRepository {
    func activeItems() throws -> [PantryItem]
    func item(id: UUID) throws -> PantryItem?
    func insert(_ item: PantryItem) throws
    func resolve(itemID: UUID, outcome: ConsumptionOutcome, on date: Date) throws -> ConsumptionEvent
    func delete(itemID: UUID) throws
    func events(since date: Date?) throws -> [ConsumptionEvent]
}
