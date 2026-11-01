import Foundation
import SwiftData

@Model
final class CategoryEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var symbolName: String
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \PantryItemEntity.category)
    var items: [PantryItemEntity] = []

    init(id: UUID = UUID(), name: String, symbolName: String, sortOrder: Int) {
        self.id = id
        self.name = name
        self.symbolName = symbolName
        self.sortOrder = sortOrder
    }
}
