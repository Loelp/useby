import Foundation

enum ItemStatus: String, Sendable, Hashable, CaseIterable, Codable {
    case active
    case eaten
    case binned
}

/// How an active item left the pantry.
enum ConsumptionOutcome: String, Sendable, Hashable, CaseIterable, Codable {
    case eaten
    case binned

    var resultingStatus: ItemStatus {
        switch self {
        case .eaten: .eaten
        case .binned: .binned
        }
    }
}
