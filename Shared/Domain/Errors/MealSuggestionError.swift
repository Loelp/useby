import Foundation

enum MealSuggestionError: Error, Equatable, LocalizedError {
    case noExpiringItems
    case modelUnavailable(reason: String)
    case generationFailed

    var errorDescription: String? {
        switch self {
        case .noExpiringItems:
            "Nothing needs using up in the next few days, so there's nothing to cook around yet."
        case .modelUnavailable(let reason):
            reason
        case .generationFailed:
            "A meal idea couldn't be made this time. Try again."
        }
    }
}
