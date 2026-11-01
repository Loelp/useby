import Foundation

/// A record of an item being eaten or binned.
/// Names are snapshotted so history survives the item being deleted.
struct ConsumptionEvent: Identifiable, Sendable, Hashable {
    let id: UUID
    let itemID: UUID?
    let itemName: String
    let categoryName: String
    let outcome: ConsumptionOutcome
    let valueCents: Int
    let date: Date
}
