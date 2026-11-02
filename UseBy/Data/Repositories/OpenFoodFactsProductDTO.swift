import Foundation

struct OpenFoodFactsProductResponse: Codable, Sendable {
    struct Product: Codable, Sendable {
        let productName: String?
        let brands: String?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case brands
        }
    }

    // 0 for an unknown barcode (still HTTP 200)
    let status: Int?
    let product: Product?
}
