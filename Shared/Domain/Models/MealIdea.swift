import Foundation

struct MealIdea: Sendable, Hashable {
    let title: String
    let minutes: Int
    let ingredients: [String]
    let steps: [String]
    /// Names of the pantry items this meal is meant to use up.
    var usesItems: [String]
}

enum MealSuggestionAvailability: Sendable, Hashable {
    case available
    case unavailable(reason: String)
}
