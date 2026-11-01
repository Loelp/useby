import Foundation

/// Wire format for `GET /api/v2/product/{barcode}.json?fields=product_name,brands`.
struct OpenFoodFactsProductResponse: Codable, Sendable {
    struct Product: Codable, Sendable {
        let productName: String?
        let brands: String?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case brands
        }
    }

    /// 1 when found, 0 when the barcode is unknown.
    let status: Int?
    let product: Product?
}
