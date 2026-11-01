import Foundation

struct FreshnessSection: Identifiable, Sendable, Hashable {
    let freshness: Freshness
    let items: [PantryItem]

    var id: Freshness { freshness }
}
