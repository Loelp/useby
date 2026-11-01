import Foundation
import Testing
@testable import UseBy

@MainActor
@Suite("Suggest a meal")
struct SuggestMealUseCaseTests {
    func makeUseCase(items: [PantryItem], service: StubMealService) -> SuggestMealUseCase {
        SuggestMealUseCase(
            pantry: MockPantryRepository(items: items),
            mealService: service,
            now: { Fixtures.now },
            calendar: Fixtures.calendar
        )
    }

    @Test("Throws noExpiringItems when nothing is due within 5 days")
    func noExpiringItems() async {
        let service = StubMealService()
        let useCase = makeUseCase(items: [
            Fixtures.item("Cheddar block", daysFromNow: 20),
            Fixtures.item("Baby spinach", daysFromNow: -1),
        ], service: service)

        await #expect(throws: MealSuggestionError.noExpiringItems) {
            try await useCase.execute()
        }
        #expect(service.receivedIngredients == nil)
    }

    @Test("Passes at most 6 of the soonest items to the service and records them on the idea")
    func passesSoonestItems() async throws {
        let service = StubMealService()
        let due = (0...7).map { Fixtures.item("Item \($0)", daysFromNow: min($0, 5)) }
        let useCase = makeUseCase(items: due + [
            Fixtures.item("Expired spinach", daysFromNow: -1),
            Fixtures.item("Frozen peas", daysFromNow: 30),
        ], service: service)

        let idea = try await useCase.execute()

        let expected = ["Item 0", "Item 1", "Item 2", "Item 3", "Item 4", "Item 5"]
        #expect(service.receivedIngredients == expected)
        #expect(idea.usesItems == expected)
        #expect(idea.title == StubMealService.sampleIdea.title)
    }

    @Test("Throws modelUnavailable when Apple Intelligence is off")
    func modelUnavailable() async {
        let service = StubMealService(availability: .unavailable(reason: "Turn on Apple Intelligence"))
        let useCase = makeUseCase(items: [Fixtures.item("Milk", daysFromNow: 1)], service: service)

        await #expect(throws: MealSuggestionError.modelUnavailable(reason: "Turn on Apple Intelligence")) {
            try await useCase.execute()
        }
    }

    @Test("Passes through generationFailed from the service")
    func generationFailed() async {
        let service = StubMealService(result: .failure(.generationFailed))
        let useCase = makeUseCase(items: [Fixtures.item("Milk", daysFromNow: 1)], service: service)

        await #expect(throws: MealSuggestionError.generationFailed) {
            try await useCase.execute()
        }
    }
}
