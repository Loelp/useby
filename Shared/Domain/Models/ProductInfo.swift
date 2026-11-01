import Foundation

struct ProductInfo: Sendable, Hashable {
    let barcode: String
    let name: String
    let brand: String?

    /// Name suitable for the item name field, prefixed by brand unless the name already includes it.
    var displayName: String {
        guard let brand, !brand.isEmpty, name.range(of: brand, options: .caseInsensitive) == nil else {
            return name
        }
        return "\(brand) \(name)"
    }
}
