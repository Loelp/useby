import Foundation

enum PantryError: Error, Equatable, LocalizedError {
    case emptyName
    case nameTooLong(max: Int)
    case invalidQuantity
    case negativePrice
    case useByInPast
    case itemNotFound
    case itemAlreadyResolved
    case catalogEntryMissing
    case persistenceFailed

    var errorDescription: String? {
        switch self {
        case .emptyName:
            "Give the item a name."
        case .nameTooLong(let max):
            "Keep the name to \(max) characters or fewer."
        case .invalidQuantity:
            "Quantity must be between 1 and 99."
        case .negativePrice:
            "Price can't be less than zero."
        case .useByInPast:
            "The use-by date can't be in the past."
        case .itemNotFound:
            "That item isn't in your pantry any more."
        case .itemAlreadyResolved:
            "That item has already been marked as eaten or binned."
        case .catalogEntryMissing:
            "Choose a location and category for this item."
        case .persistenceFailed:
            "Your change couldn't be saved. Please try again."
        }
    }
}
