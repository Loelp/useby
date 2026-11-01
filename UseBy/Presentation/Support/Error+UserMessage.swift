import Foundation

extension Error {
    /// Friendly message for display. Domain errors supply their own wording.
    var userMessage: String {
        if let description = (self as? LocalizedError)?.errorDescription {
            return description
        }
        return "Something went wrong. Please try again."
    }
}
