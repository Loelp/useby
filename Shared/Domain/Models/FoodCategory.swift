import Foundation

struct FoodCategory: Identifiable, Sendable, Hashable {
    let id: UUID
    let name: String
    let symbolName: String
}
