import Foundation

/// Unvalidated input for a new pantry item, as typed or scanned by the user.
struct NewPantryItemDraft: Sendable, Hashable {
    var name: String
    var quantity: Int
    var priceCents: Int
    var useBy: Date
    var barcode: String?
    var location: StorageLocation?
    var category: FoodCategory?
}
