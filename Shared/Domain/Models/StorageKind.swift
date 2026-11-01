import Foundation

/// Where an item physically lives. Drives the default icon for a storage location.
enum StorageKind: String, Sendable, Hashable, CaseIterable, Codable {
    case fridge
    case freezer
    case pantry

    var symbolName: String {
        switch self {
        case .fridge: "refrigerator"
        case .freezer: "snowflake"
        case .pantry: "cabinet"
        }
    }
}
