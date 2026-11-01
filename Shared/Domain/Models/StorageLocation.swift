import Foundation

struct StorageLocation: Identifiable, Sendable, Hashable {
    let id: UUID
    let name: String
    let kind: StorageKind
}
