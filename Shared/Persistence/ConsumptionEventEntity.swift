import Foundation
import SwiftData

@Model
final class ConsumptionEventEntity {
    @Attribute(.unique) var id: UUID
    var outcomeRaw: String
    var valueCents: Int
    var date: Date
    var itemName: String
    var categoryName: String
    /// Optional so the event outlives a deleted item.
    @Relationship(deleteRule: .nullify)
    var item: PantryItemEntity?

    init(
        id: UUID = UUID(),
        outcome: ConsumptionOutcome,
        valueCents: Int,
        date: Date,
        itemName: String,
        categoryName: String,
        item: PantryItemEntity?
    ) {
        self.id = id
        self.outcomeRaw = outcome.rawValue
        self.valueCents = valueCents
        self.date = date
        self.itemName = itemName
        self.categoryName = categoryName
        self.item = item
    }
}
