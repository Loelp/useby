import Foundation
import SwiftData

@Model
final class StorageLocationEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var kindRaw: String
    var sortOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \PantryItemEntity.location)
    var items: [PantryItemEntity] = []

    init(id: UUID = UUID(), name: String, kind: StorageKind, sortOrder: Int) {
        self.id = id
        self.name = name
        self.kindRaw = kind.rawValue
        self.sortOrder = sortOrder
    }
}
