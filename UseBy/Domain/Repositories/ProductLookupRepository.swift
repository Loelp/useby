import Foundation

protocol ProductLookupRepository: Sendable {
    /// Throws `ProductLookupError`.
    func product(forBarcode barcode: String) async throws -> ProductInfo
}
