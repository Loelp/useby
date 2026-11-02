import Foundation

struct NewPantryItemDraft: Sendable, Hashable {
    var name: String
    var quantity: Int
    var priceCents: Int
    var useBy: Date
    var barcode: String?
    var location: StorageLocation?
    var category: FoodCategory?
}
