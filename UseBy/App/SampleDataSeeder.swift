#if DEBUG
import Foundation
import SwiftData

/// Demo data for App Store screenshots and the demo video.
/// `-seedSampleData` replaces the store with realistic Australian groceries; `-resetData` wipes it.
@MainActor
struct SampleDataSeeder {
    static let seedArgument = "-seedSampleData"
    static let resetArgument = "-resetData"

    private struct SampleItem {
        let name: String
        let category: String
        let kind: StorageKind
        let quantity: Int
        let priceCents: Int
        let daysUntilUseBy: Int
    }

    private struct SampleEvent {
        let name: String
        let category: String
        let kind: StorageKind
        let priceCents: Int
        let outcome: ConsumptionOutcome
        let daysAgo: Int
    }

    private let context: ModelContext
    private let now: Date
    private let calendar: Calendar

    init(context: ModelContext, now: Date = .now, calendar: Calendar = .current) {
        self.context = context
        self.now = now
        self.calendar = calendar
    }

    func wipe() throws {
        try context.delete(model: ConsumptionEventEntity.self)
        try context.delete(model: PantryItemEntity.self)
        try context.delete(model: StorageLocationEntity.self)
        try context.delete(model: CategoryEntity.self)
        try context.save()
    }

    /// Replaces items and history with sample data. Expects the default catalog to exist.
    func seedSampleData() throws {
        try context.delete(model: ConsumptionEventEntity.self)
        try context.delete(model: PantryItemEntity.self)

        let locations = try context.fetch(FetchDescriptor<StorageLocationEntity>())
        let categories = try context.fetch(FetchDescriptor<CategoryEntity>())
        func location(_ kind: StorageKind) -> StorageLocationEntity? { locations.first { $0.kindRaw == kind.rawValue } }
        func category(_ name: String) -> CategoryEntity? { categories.first { $0.name == name } }

        for sample in Self.activeItems {
            guard let location = location(sample.kind), let category = category(sample.category) else { continue }
            context.insert(PantryItemEntity(
                id: UUID(),
                name: sample.name,
                quantity: sample.quantity,
                priceCents: sample.priceCents,
                addedOn: date(daysFromNow: min(sample.daysUntilUseBy, 0) - 3),
                useBy: date(daysFromNow: sample.daysUntilUseBy),
                barcode: nil,
                status: .active,
                location: location,
                category: category
            ))
        }

        for sample in Self.history {
            guard let location = location(sample.kind), let category = category(sample.category) else { continue }
            let resolvedOn = date(daysFromNow: -sample.daysAgo, hour: 19)
            let item = PantryItemEntity(
                id: UUID(),
                name: sample.name,
                quantity: 1,
                priceCents: sample.priceCents,
                addedOn: date(daysFromNow: -sample.daysAgo - 5),
                useBy: date(daysFromNow: -sample.daysAgo),
                barcode: nil,
                status: sample.outcome.resultingStatus,
                location: location,
                category: category
            )
            item.resolvedOn = resolvedOn
            context.insert(item)
            context.insert(ConsumptionEventEntity(
                outcome: sample.outcome,
                valueCents: sample.priceCents,
                date: resolvedOn,
                itemName: sample.name,
                categoryName: sample.category,
                item: item
            ))
        }
        try context.save()
    }

    private func date(daysFromNow days: Int, hour: Int = 12) -> Date {
        let day = calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: now)) ?? now
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day) ?? day
    }

    private static let activeItems: [SampleItem] = [
        SampleItem(name: "Baby spinach", category: "Produce", kind: .fridge, quantity: 1, priceCents: 350, daysUntilUseBy: -1),
        SampleItem(name: "Greek yoghurt", category: "Dairy & Eggs", kind: .fridge, quantity: 1, priceCents: 650, daysUntilUseBy: 0),
        SampleItem(name: "Leftover spaghetti bolognese", category: "Leftovers", kind: .fridge, quantity: 2, priceCents: 800, daysUntilUseBy: 1),
        SampleItem(name: "Lebanese cucumbers", category: "Produce", kind: .fridge, quantity: 3, priceCents: 450, daysUntilUseBy: 2),
        SampleItem(name: "Chicken thigh fillets", category: "Meat & Seafood", kind: .fridge, quantity: 1, priceCents: 1120, daysUntilUseBy: 3),
        SampleItem(name: "Sourdough loaf", category: "Bakery", kind: .pantry, quantity: 1, priceCents: 700, daysUntilUseBy: 4),
        SampleItem(name: "Free-range eggs", category: "Dairy & Eggs", kind: .fridge, quantity: 12, priceCents: 720, daysUntilUseBy: 16),
        SampleItem(name: "Cheddar block", category: "Dairy & Eggs", kind: .fridge, quantity: 1, priceCents: 900, daysUntilUseBy: 24),
        SampleItem(name: "Beef mince", category: "Meat & Seafood", kind: .freezer, quantity: 1, priceCents: 1050, daysUntilUseBy: 60),
    ]

    private static let history: [SampleEvent] = [
        SampleEvent(name: "Bananas", category: "Produce", kind: .pantry, priceCents: 320, outcome: .eaten, daysAgo: 1),
        SampleEvent(name: "Full cream milk 2L", category: "Dairy & Eggs", kind: .fridge, priceCents: 360, outcome: .eaten, daysAgo: 2),
        SampleEvent(name: "Fresh coriander", category: "Produce", kind: .fridge, priceCents: 300, outcome: .binned, daysAgo: 2),
        SampleEvent(name: "Atlantic salmon fillets", category: "Meat & Seafood", kind: .fridge, priceCents: 1300, outcome: .eaten, daysAgo: 3),
        SampleEvent(name: "Hummus dip", category: "Other", kind: .fridge, priceCents: 450, outcome: .eaten, daysAgo: 4),
        SampleEvent(name: "Strawberries", category: "Produce", kind: .fridge, priceCents: 550, outcome: .binned, daysAgo: 5),
        SampleEvent(name: "Wholemeal wraps", category: "Bakery", kind: .pantry, priceCents: 380, outcome: .eaten, daysAgo: 6),
        SampleEvent(name: "Broccoli", category: "Produce", kind: .fridge, priceCents: 280, outcome: .eaten, daysAgo: 8),
        SampleEvent(name: "Leftover fried rice", category: "Leftovers", kind: .fridge, priceCents: 600, outcome: .binned, daysAgo: 9),
        SampleEvent(name: "Mixed salad leaves", category: "Produce", kind: .fridge, priceCents: 400, outcome: .binned, daysAgo: 10),
        SampleEvent(name: "Pork sausages", category: "Meat & Seafood", kind: .fridge, priceCents: 850, outcome: .eaten, daysAgo: 11),
        SampleEvent(name: "Turkish bread", category: "Bakery", kind: .pantry, priceCents: 450, outcome: .binned, daysAgo: 12),
        SampleEvent(name: "Natural yoghurt", category: "Dairy & Eggs", kind: .fridge, priceCents: 550, outcome: .eaten, daysAgo: 13),
        SampleEvent(name: "Avocados", category: "Produce", kind: .pantry, priceCents: 500, outcome: .eaten, daysAgo: 14),
    ]
}
#endif
