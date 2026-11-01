import Foundation
import Synchronization
@testable import UseBy

@MainActor
final class MockPantryRepository: PantryRepository {
    var items: [UUID: PantryItem] = [:]
    var storedEvents: [ConsumptionEvent] = []
    /// When set, every call throws this error.
    var errorToThrow: Error?
    private(set) var insertedItems: [PantryItem] = []
    private(set) var deletedIDs: [UUID] = []

    init(items: [PantryItem] = [], events: [ConsumptionEvent] = []) {
        self.items = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        self.storedEvents = events
    }

    func activeItems() throws -> [PantryItem] {
        try throwIfNeeded()
        return items.values.filter { $0.status == .active }
    }

    func item(id: UUID) throws -> PantryItem? {
        try throwIfNeeded()
        return items[id]
    }

    func insert(_ item: PantryItem) throws {
        try throwIfNeeded()
        items[item.id] = item
        insertedItems.append(item)
    }

    func resolve(itemID: UUID, outcome: ConsumptionOutcome, on date: Date) throws -> ConsumptionEvent {
        try throwIfNeeded()
        guard var item = items[itemID] else { throw PantryError.itemNotFound }
        item.status = outcome.resultingStatus
        items[itemID] = item
        let event = ConsumptionEvent(
            id: UUID(),
            itemID: itemID,
            itemName: item.name,
            categoryName: item.category.name,
            outcome: outcome,
            valueCents: item.priceCents,
            date: date
        )
        storedEvents.append(event)
        return event
    }

    func delete(itemID: UUID) throws {
        try throwIfNeeded()
        items[itemID] = nil
        deletedIDs.append(itemID)
    }

    func events(since date: Date?) throws -> [ConsumptionEvent] {
        try throwIfNeeded()
        guard let date else { return storedEvents }
        return storedEvents.filter { $0.date >= date }
    }

    private func throwIfNeeded() throws {
        if let errorToThrow { throw errorToThrow }
    }
}

@MainActor
final class MockReminderScheduler: ReminderScheduling {
    var authorizationStatus: ReminderAuthorization = .authorized
    var statusAfterRequest: ReminderAuthorization = .authorized
    private(set) var scheduledIDs: [UUID] = []
    private(set) var cancelledIDs: [UUID] = []

    func authorization() async -> ReminderAuthorization { authorizationStatus }

    func requestAuthorization() async -> ReminderAuthorization {
        authorizationStatus = statusAfterRequest
        return statusAfterRequest
    }

    func scheduleReminder(for item: PantryItem) { scheduledIDs.append(item.id) }
    func cancelReminder(for itemID: UUID) { cancelledIDs.append(itemID) }
}

final class StubMealService: MealSuggestionService {
    let availability: MealSuggestionAvailability
    private let result: Result<MealIdea, MealSuggestionError>
    private let received = Mutex<[String]?>(nil)

    init(
        availability: MealSuggestionAvailability = .available,
        result: Result<MealIdea, MealSuggestionError> = .success(StubMealService.sampleIdea)
    ) {
        self.availability = availability
        self.result = result
    }

    /// Ingredients passed to the last `suggestMeal(using:)` call.
    var receivedIngredients: [String]? { received.withLock { $0 } }

    func suggestMeal(using ingredients: [String]) async throws -> MealIdea {
        received.withLock { $0 = ingredients }
        return try result.get()
    }

    static let sampleIdea = MealIdea(
        title: "Yoghurt chicken wraps",
        minutes: 25,
        ingredients: ["Chicken", "Yoghurt", "Cucumber"],
        steps: ["Cook chicken", "Slice cucumber", "Wrap it up"],
        usesItems: []
    )
}

struct StubProductLookup: ProductLookupRepository {
    var result: Result<ProductInfo, ProductLookupError> = .success(ProductInfo(barcode: "9300633603031", name: "Greek Yoghurt", brand: "Chobani"))

    func product(forBarcode barcode: String) async throws -> ProductInfo {
        try result.get()
    }
}
