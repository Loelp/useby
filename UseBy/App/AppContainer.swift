import Foundation
import SwiftData

/// Composition root: builds every dependency once and hands out ViewModels.
@MainActor
final class AppContainer {
    let modelContainer: ModelContainer
    let pantryRepository: any PantryRepository
    let catalogRepository: any CatalogRepository
    let reminderScheduler: any ReminderScheduling

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        let context = modelContainer.mainContext
        pantryRepository = SwiftDataPantryRepository(context: context)
        catalogRepository = SwiftDataCatalogRepository(context: context)
        reminderScheduler = LocalReminderScheduler()
    }

    static func make(arguments: [String] = ProcessInfo.processInfo.arguments) throws -> AppContainer {
        let container = AppContainer(modelContainer: try PersistenceController.makeContainer())
        #if DEBUG
        let seeder = SampleDataSeeder(context: container.modelContainer.mainContext)
        if arguments.contains(SampleDataSeeder.resetArgument) {
            try seeder.wipe()
        }
        try container.catalogRepository.seedDefaultsIfNeeded()
        if arguments.contains(SampleDataSeeder.seedArgument) {
            try seeder.seedSampleData()
        }
        #else
        try container.catalogRepository.seedDefaultsIfNeeded()
        #endif
        return container
    }
}
