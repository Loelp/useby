import Foundation
import OSLog
import SwiftData

enum PersistenceController {
    static let schema = Schema([
        PantryItemEntity.self,
        StorageLocationEntity.self,
        CategoryEntity.self,
        ConsumptionEventEntity.self,
    ])

    private static let storeFileName = "UseBy.store"
    private static let logger = Logger(subsystem: "com.usebyapp.UseBy", category: "Persistence")

    /// Store location shared by the app and widget, or `nil` when the App Group isn't provisioned
    /// (for example, a free personal signing team).
    static var sharedStoreURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)?
            .appending(path: storeFileName)
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if let url = sharedStoreURL {
            configuration = ModelConfiguration(schema: schema, url: url)
        } else {
            logger.warning("App Group container unavailable; using the app's private store. The widget won't see data.")
            configuration = ModelConfiguration(schema: schema, groupContainer: .none)
        }
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
