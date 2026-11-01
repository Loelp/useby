import Foundation
import Testing
@testable import UseBy

@MainActor
@Suite("Barcode lookup")
struct ProductLookupTests {
    @Test("Rejects malformed barcodes", arguments: ["12AB", "12345", "", "123456789012345"])
    func rejectsInvalidBarcode(code: String) async {
        let useCase = LookupProductUseCase(lookup: StubProductLookup())
        await #expect(throws: ProductLookupError.invalidBarcode) {
            try await useCase.execute(barcode: code)
        }
    }

    @Test("Accepts an EAN-13 barcode and returns the product")
    func acceptsValidBarcode() async throws {
        let product = try await LookupProductUseCase(lookup: StubProductLookup()).execute(barcode: " 9300633603031 ")
        #expect(product.displayName == "Chobani Greek Yoghurt")
    }

    @Test("Display name skips a brand already in the name")
    func displayNameAvoidsDuplicateBrand() {
        #expect(ProductInfo(barcode: "1", name: "Nutella", brand: "Nutella").displayName == "Nutella")
    }

    @Test("Open Food Facts status 0 or a blank name maps to notFound")
    func mapsNotFound() {
        let unknown = OpenFoodFactsProductResponse(status: 0, product: nil)
        #expect(throws: ProductLookupError.notFound) {
            try OpenFoodFactsProductLookupRepository.productInfo(from: unknown, barcode: "00000000")
        }
        let blank = OpenFoodFactsProductResponse(status: 1, product: .init(productName: "  ", brands: nil))
        #expect(throws: ProductLookupError.notFound) {
            try OpenFoodFactsProductLookupRepository.productInfo(from: blank, barcode: "00000000")
        }
    }

    @Test("Open Food Facts keeps only the first brand")
    func mapsFirstBrand() throws {
        let response = OpenFoodFactsProductResponse(status: 1, product: .init(productName: "Nutella", brands: "Nutella, Ferrero"))
        let product = try OpenFoodFactsProductLookupRepository.productInfo(from: response, barcode: "3017620422003")
        #expect(product.brand == "Nutella")
    }

    @Test("Network errors map to offline or serviceUnavailable")
    func mapsURLErrors() {
        #expect(OpenFoodFactsProductLookupRepository.map(URLError(.notConnectedToInternet)) == .offline)
        #expect(OpenFoodFactsProductLookupRepository.map(URLError(.timedOut)) == .offline)
        #expect(OpenFoodFactsProductLookupRepository.map(URLError(.badServerResponse)) == .serviceUnavailable)
    }
}
