import Foundation

protocol MealSuggestionService: Sendable {
    var availability: MealSuggestionAvailability { get }
    /// Throws `MealSuggestionError`.
    func suggestMeal(using ingredients: [String]) async throws -> MealIdea
}
