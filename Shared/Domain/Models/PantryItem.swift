import Foundation

struct PantryItem: Identifiable, Sendable, Hashable {
    let id: UUID
    var name: String
    var quantity: Int
    // Total paid, in cents.
    var priceCents: Int
    var addedOn: Date
    var useBy: Date
    var barcode: String?
    var status: ItemStatus
    var location: StorageLocation
    var category: FoodCategory

    func daysRemaining(from date: Date, calendar: Calendar) -> Int {
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: useBy)
        return calendar.dateComponents([.day], from: start, to: end).day ?? 0
    }

    func freshness(on date: Date, calendar: Calendar) -> Freshness {
        Freshness(daysRemaining: daysRemaining(from: date, calendar: calendar))
    }
}

extension Sequence where Element == PantryItem {
    func sortedByUrgency() -> [PantryItem] {
        sorted { lhs, rhs in
            if lhs.useBy != rhs.useBy { return lhs.useBy < rhs.useBy }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}
