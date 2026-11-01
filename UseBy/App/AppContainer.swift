import Foundation
import SwiftData

/// Composition root: builds every dependency once and hands out ViewModels.
@MainActor
final class AppContainer {
    let modelContainer: ModelContainer
    let pantryRepository: any PantryRepository
    let catalogRepository: any CatalogRepository
    let reminderScheduler: any ReminderScheduling
    let productLookup: any ProductLookupRepository
    let cameraAccess: any CameraAccessProviding
    let calendar: Calendar = .autoupdatingCurrent

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        let context = modelContainer.mainContext
        pantryRepository = SwiftDataPantryRepository(context: context)
        catalogRepository = SwiftDataCatalogRepository(context: context)
        reminderScheduler = LocalReminderScheduler(calendar: calendar)
        productLookup = OpenFoodFactsProductLookupRepository()
        cameraAccess = SystemCameraAccessService()
    }

    // MARK: - ViewModel factories

    func makeTodayViewModel() -> TodayViewModel {
        TodayViewModel(
            fetchOverview: FetchPantryOverviewUseCase(pantry: pantryRepository, calendar: calendar),
            resolveItem: ResolvePantryItemUseCase(pantry: pantryRepository, reminders: reminderScheduler),
            deleteItem: DeletePantryItemUseCase(pantry: pantryRepository, reminders: reminderScheduler),
            reminders: reminderScheduler,
            makeAddItem: { [unowned self] in self.makeAddItemViewModel() },
            calendar: calendar
        )
    }

    func makeAddItemViewModel() -> AddItemViewModel {
        AddItemViewModel(
            addItem: AddPantryItemUseCase(pantry: pantryRepository, reminders: reminderScheduler, calendar: calendar),
            lookupProduct: LookupProductUseCase(lookup: productLookup),
            catalog: catalogRepository,
            reminders: reminderScheduler,
            makeScanner: { [unowned self] in self.makeBarcodeScannerViewModel() },
            calendar: calendar
        )
    }

    func makeBarcodeScannerViewModel() -> BarcodeScannerViewModel {
        BarcodeScannerViewModel(cameraAccess: cameraAccess)
    }

    // MARK: - Launch

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
