import Foundation

struct MealIdea: Sendable, Hashable {
    let title: String
    let minutes: Int
    let ingredients: [String]
    let steps: [String]
    var usesItems: [String]
}

enum MealSuggestionAvailability: Sendable, Hashable {
    case available
    case unavailable(reason: String)
}
