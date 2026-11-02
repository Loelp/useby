import Foundation

struct CategoryWaste: Identifiable, Sendable, Hashable {
    let categoryName: String
    var eatenCount: Int
    var binnedCount: Int
    var savedCents: Int
    var wastedCents: Int

    var id: String { categoryName }
}

struct WasteSummary: Sendable, Hashable {
    let savedCents: Int
    let wastedCents: Int
    let eatenCount: Int
    let binnedCount: Int
    let categoryBreakdown: [CategoryWaste]

    static let empty = WasteSummary(savedCents: 0, wastedCents: 0, eatenCount: 0, binnedCount: 0, categoryBreakdown: [])

    var hasHistory: Bool { eatenCount + binnedCount > 0 }

    var wasteRate: Double {
        let total = savedCents + wastedCents
        guard total > 0 else { return 0 }
        return Double(wastedCents) / Double(total)
    }
}
