import Foundation

@MainActor
struct SuggestMealUseCase {
    static let maxIngredients = 6
    static let horizonDays = 5

    private let pantry: any PantryRepository
    private let mealService: any MealSuggestionService
    private let now: () -> Date
    private let calendar: Calendar

    init(
        pantry: any PantryRepository,
        mealService: any MealSuggestionService,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .current
    ) {
        self.pantry = pantry
        self.mealService = mealService
        self.now = now
        self.calendar = calendar
    }

    var availability: MealSuggestionAvailability { mealService.availability }

    func expiringItems() throws -> [PantryItem] {
        let today = now()
        let due = try pantry.activeItems().filter { item in
            (0...Self.horizonDays).contains(item.daysRemaining(from: today, calendar: calendar))
        }
        return Array(due.sortedByUrgency().prefix(Self.maxIngredients))
    }

    func execute() async throws -> MealIdea {
        if case .unavailable(let reason) = mealService.availability {
            throw MealSuggestionError.modelUnavailable(reason: reason)
        }
        let names = try expiringItems().map(\.name)
        guard !names.isEmpty else { throw MealSuggestionError.noExpiringItems }

        var idea: MealIdea
        do {
            idea = try await mealService.suggestMeal(using: names)
        } catch let error as MealSuggestionError {
            throw error
        } catch {
            throw MealSuggestionError.generationFailed
        }
        idea.usesItems = names
        return idea
    }
}
