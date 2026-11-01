import Foundation

extension StorageLocationEntity {
    func toDomain() -> StorageLocation {
        StorageLocation(id: id, name: name, kind: StorageKind(rawValue: kindRaw) ?? .pantry)
    }
}

extension CategoryEntity {
    func toDomain() -> FoodCategory {
        FoodCategory(id: id, name: name, symbolName: symbolName)
    }
}

extension PantryItemEntity {
    /// `nil` only if the item's location or category has been removed from the store.
    func toDomain() -> PantryItem? {
        guard let location, let category else { return nil }
        return PantryItem(
            id: id,
            name: name,
            quantity: quantity,
            priceCents: priceCents,
            addedOn: addedOn,
            useBy: useBy,
            barcode: barcode,
            status: ItemStatus(rawValue: statusRaw) ?? .active,
            location: location.toDomain(),
            category: category.toDomain()
        )
    }
}

extension ConsumptionEventEntity {
    func toDomain() -> ConsumptionEvent {
        ConsumptionEvent(
            id: id,
            itemID: item?.id,
            itemName: itemName,
            categoryName: categoryName,
            outcome: ConsumptionOutcome(rawValue: outcomeRaw) ?? .binned,
            valueCents: valueCents,
            date: date
        )
    }
}
