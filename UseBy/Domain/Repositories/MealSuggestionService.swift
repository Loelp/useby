import Foundation

protocol MealSuggestionService: Sendable {
    var availability: MealSuggestionAvailability { get }
    func suggestMeal(using ingredients: [String]) async throws -> MealIdea
}
