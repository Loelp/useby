import Foundation

struct PantryItem: Identifiable, Sendable, Hashable {
    let id: UUID
    var name: String
    var quantity: Int
    /// Total amount paid for this item, in cents. Used as its value when eaten or binned.
    var priceCents: Int
    var addedOn: Date
    var useBy: Date
    var barcode: String?
    var status: ItemStatus
    var location: StorageLocation
    var category: FoodCategory

    /// Whole calendar days from `date` until the use-by date. Negative once expired.
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
    /// Soonest use-by first, then alphabetical so ties are stable.
    func sortedByUrgency() -> [PantryItem] {
        sorted { lhs, rhs in
            if lhs.useBy != rhs.useBy { return lhs.useBy < rhs.useBy }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }
}
