import Foundation

// Names are copied so history survives the item being deleted.
struct ConsumptionEvent: Identifiable, Sendable, Hashable {
    let id: UUID
    let itemID: UUID?
    let itemName: String
    let categoryName: String
    let outcome: ConsumptionOutcome
    let valueCents: Int
    let date: Date
}
