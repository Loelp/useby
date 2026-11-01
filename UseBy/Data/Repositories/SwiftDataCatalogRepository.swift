import Foundation
import OSLog
import SwiftData

@MainActor
final class SwiftDataCatalogRepository: CatalogRepository {
    private let context: ModelContext
    private let logger = Logger(subsystem: "com.usebyapp.UseBy", category: "CatalogRepository")

    init(context: ModelContext) {
        self.context = context
    }

    func locations() throws -> [StorageLocation] {
        try perform {
            try context.fetch(FetchDescriptor<StorageLocationEntity>(sortBy: [SortDescriptor(\.sortOrder)])).map { $0.toDomain() }
        }
    }

    func categories() throws -> [FoodCategory] {
        try perform {
            try context.fetch(FetchDescriptor<CategoryEntity>(sortBy: [SortDescriptor(\.sortOrder)])).map { $0.toDomain() }
        }
    }

    func seedDefaultsIfNeeded() throws {
        try perform {
            var inserted = false
            if try context.fetchCount(FetchDescriptor<StorageLocationEntity>()) == 0 {
                for (index, location) in DefaultCatalog.locations.enumerated() {
                    context.insert(StorageLocationEntity(name: location.name, kind: location.kind, sortOrder: index))
                }
                inserted = true
            }
            if try context.fetchCount(FetchDescriptor<CategoryEntity>()) == 0 {
                for (index, category) in DefaultCatalog.categories.enumerated() {
                    context.insert(CategoryEntity(name: category.name, symbolName: category.symbolName, sortOrder: index))
                }
                inserted = true
            }
            if inserted {
                try context.save()
            }
        }
    }

    private func perform<T>(_ work: () throws -> T) throws -> T {
        do {
            return try work()
        } catch let error as PantryError {
            throw error
        } catch {
            logger.error("Catalog operation failed: \(error.localizedDescription, privacy: .public)")
            context.rollback()
            throw PantryError.persistenceFailed
        }
    }
}
