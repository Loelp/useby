import Foundation

extension Error {
    var userMessage: String {
        if let description = (self as? LocalizedError)?.errorDescription {
            return description
        }
        return "Something went wrong. Please try again."
    }
}
