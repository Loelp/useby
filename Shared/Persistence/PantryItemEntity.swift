import Foundation
import SwiftData

@Model
final class PantryItemEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Int
    var priceCents: Int
    var addedOn: Date
    var useBy: Date
    var barcode: String?
    var statusRaw: String
    var resolvedOn: Date?
    var location: StorageLocationEntity?
    var category: CategoryEntity?

    /// Deleting an item nullifies `event.item` so consumption history is kept.
    @Relationship(deleteRule: .nullify, inverse: \ConsumptionEventEntity.item)
    var events: [ConsumptionEventEntity] = []

    init(
        id: UUID,
        name: String,
        quantity: Int,
        priceCents: Int,
        addedOn: Date,
        useBy: Date,
        barcode: String?,
        status: ItemStatus,
        location: StorageLocationEntity,
        category: CategoryEntity
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.priceCents = priceCents
        self.addedOn = addedOn
        self.useBy = useBy
        self.barcode = barcode
        self.statusRaw = status.rawValue
        self.location = location
        self.category = category
    }
}
