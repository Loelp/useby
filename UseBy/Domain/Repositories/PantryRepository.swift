import Foundation

@MainActor
protocol PantryRepository {
    func activeItems() throws -> [PantryItem]
    func item(id: UUID) throws -> PantryItem?
    /// Persists a validated item. Throws `PantryError.catalogEntryMissing` if its location or category no longer exists.
    func insert(_ item: PantryItem) throws
    /// Marks the item eaten or binned and records the matching consumption event.
    func resolve(itemID: UUID, outcome: ConsumptionOutcome, on date: Date) throws -> ConsumptionEvent
    func delete(itemID: UUID) throws
    /// Events on or after `date`, newest first. Pass `nil` for all history.
    func events(since date: Date?) throws -> [ConsumptionEvent]
}
