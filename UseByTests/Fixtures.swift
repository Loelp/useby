import Foundation
@testable import UseBy

enum Fixtures {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Australia/Sydney")!
        calendar.locale = Locale(identifier: "en_AU")
        return calendar
    }()

    // Tue 10 Mar 2026, 10am Sydney
    static let now: Date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 10))!

    static let fridge = StorageLocation(id: UUID(), name: "Fridge", kind: .fridge)
    static let produce = FoodCategory(id: UUID(), name: "Produce", symbolName: "carrot")
    static let dairy = FoodCategory(id: UUID(), name: "Dairy & Eggs", symbolName: "waterbottle")

    static func date(daysFromNow days: Int, hour: Int = 12) -> Date {
        let day = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: now))!
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
    }

    static func item(
        _ name: String,
        daysFromNow days: Int,
        priceCents: Int = 500,
        status: ItemStatus = .active,
        category: FoodCategory = produce
    ) -> PantryItem {
        PantryItem(
            id: UUID(),
            name: name,
            quantity: 1,
            priceCents: priceCents,
            addedOn: date(daysFromNow: -2),
            useBy: date(daysFromNow: days),
            barcode: nil,
            status: status,
            location: fridge,
            category: category
        )
    }

    static func draft(
        name: String = "Greek yoghurt",
        quantity: Int = 1,
        priceCents: Int = 650,
        useByDaysFromNow: Int = 3
    ) -> NewPantryItemDraft {
        NewPantryItemDraft(
            name: name,
            quantity: quantity,
            priceCents: priceCents,
            useBy: date(daysFromNow: useByDaysFromNow),
            barcode: nil,
            location: fridge,
            category: dairy
        )
    }

    static func event(_ outcome: ConsumptionOutcome, cents: Int, daysAgo: Int, category: String = "Produce") -> ConsumptionEvent {
        ConsumptionEvent(
            id: UUID(),
            itemID: UUID(),
            itemName: "Item \(cents)",
            categoryName: category,
            outcome: outcome,
            valueCents: cents,
            date: date(daysFromNow: -daysAgo)
        )
    }
}
