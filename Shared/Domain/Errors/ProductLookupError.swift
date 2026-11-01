import Foundation

enum ProductLookupError: Error, Equatable, LocalizedError {
    case invalidBarcode
    case notFound
    case offline
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidBarcode:
            "That doesn't look like a grocery barcode. Barcodes have 8 to 14 digits."
        case .notFound:
            "This product isn't in Open Food Facts yet. Type the name instead."
        case .offline:
            "You're offline. Type the name instead, or try again when you're connected."
        case .serviceUnavailable:
            "Product lookup isn't working right now. Type the name instead."
        }
    }
}
