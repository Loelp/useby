import Foundation

protocol ProductLookupRepository: Sendable {
    func product(forBarcode barcode: String) async throws -> ProductInfo
}
