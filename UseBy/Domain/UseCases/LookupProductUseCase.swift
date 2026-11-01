import Foundation

@MainActor
struct LookupProductUseCase {
    static let barcodeLengths = 8...14

    private let lookup: any ProductLookupRepository

    init(lookup: any ProductLookupRepository) {
        self.lookup = lookup
    }

    func execute(barcode: String) async throws -> ProductInfo {
        let code = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.barcodeLengths.contains(code.count), code.allSatisfy({ $0.isASCII && $0.isNumber }) else {
            throw ProductLookupError.invalidBarcode
        }
        return try await lookup.product(forBarcode: code)
    }
}
