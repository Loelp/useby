import Foundation
import OSLog
import SwiftData
import WidgetKit

@MainActor
final class SwiftDataPantryRepository: PantryRepository {
    private let context: ModelContext
    private let logger = Logger(subsystem: "com.usebyapp.UseBy", category: "PantryRepository")

    init(context: ModelContext) {
        self.context = context
    }

    func activeItems() throws -> [PantryItem] {
        try perform {
            let active = ItemStatus.active.rawValue
            let descriptor = FetchDescriptor<PantryItemEntity>(
                predicate: #Predicate { $0.statusRaw == active },
                sortBy: [SortDescriptor(\.useBy), SortDescriptor(\.name)]
            )
            return try context.fetch(descriptor).compactMap { $0.toDomain() }
        }
    }

    func item(id: UUID) throws -> PantryItem? {
        try perform { try entity(id: id)?.toDomain() }
    }

    func insert(_ item: PantryItem) throws {
        try perform {
            let locationID = item.location.id
            let categoryID = item.category.id
            guard
                let location = try context.fetch(FetchDescriptor<StorageLocationEntity>(predicate: #Predicate { $0.id == locationID })).first,
                let category = try context.fetch(FetchDescriptor<CategoryEntity>(predicate: #Predicate { $0.id == categoryID })).first
            else {
                throw PantryError.catalogEntryMissing
            }
            context.insert(PantryItemEntity(
                id: item.id,
                name: item.name,
                quantity: item.quantity,
                priceCents: item.priceCents,
                addedOn: item.addedOn,
                useBy: item.useBy,
                barcode: item.barcode,
                status: item.status,
                location: location,
                category: category
            ))
            try save()
        }
    }

    func resolve(itemID: UUID, outcome: ConsumptionOutcome, on date: Date) throws -> ConsumptionEvent {
        try perform {
            guard let entity = try entity(id: itemID) else { throw PantryError.itemNotFound }
            guard entity.statusRaw == ItemStatus.active.rawValue else { throw PantryError.itemAlreadyResolved }

            entity.statusRaw = outcome.resultingStatus.rawValue
            entity.resolvedOn = date
            let event = ConsumptionEventEntity(
                outcome: outcome,
                valueCents: entity.priceCents,
                date: date,
                itemName: entity.name,
                categoryName: entity.category?.name ?? "Other",
                item: entity
            )
            context.insert(event)
            try save()
            return event.toDomain()
        }
    }

    func delete(itemID: UUID) throws {
        try perform {
            guard let entity = try entity(id: itemID) else { throw PantryError.itemNotFound }
            context.delete(entity)
            try save()
        }
    }

    func events(since date: Date?) throws -> [ConsumptionEvent] {
        try perform {
            var descriptor = FetchDescriptor<ConsumptionEventEntity>(sortBy: [SortDescriptor(\.date, order: .reverse)])
            if let date {
                descriptor.predicate = #Predicate { $0.date >= date }
            }
            return try context.fetch(descriptor).map { $0.toDomain() }
        }
    }

    // MARK: - Helpers

    private func entity(id: UUID) throws -> PantryItemEntity? {
        var descriptor = FetchDescriptor<PantryItemEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func save() throws {
        try context.save()
        WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.expiringItems)
    }

    /// Rethrows domain errors unchanged; maps any storage error to `PantryError.persistenceFailed`.
    private func perform<T>(_ work: () throws -> T) throws -> T {
        do {
            return try work()
        } catch let error as PantryError {
            throw error
        } catch {
            logger.error("Storage operation failed: \(error.localizedDescription, privacy: .public)")
            context.rollback()
            throw PantryError.persistenceFailed
        }
    }
}
