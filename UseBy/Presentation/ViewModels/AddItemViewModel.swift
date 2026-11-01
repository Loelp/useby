import Foundation
import Observation

enum QuickUseBy: Int, CaseIterable, Identifiable {
    case tomorrow = 1
    case threeDays = 3
    case oneWeek = 7
    case twoWeeks = 14

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .tomorrow: "Tomorrow"
        case .threeDays: "3 Days"
        case .oneWeek: "1 Week"
        case .twoWeeks: "2 Weeks"
        }
    }
}

enum ProductLookupState: Equatable {
    case idle
    case searching
    case found(String)
    case failed(String)
}

@MainActor
@Observable
final class AddItemViewModel: Identifiable {
    var name = ""
    var quantity = 1
    var priceText = ""
    var useBy: Date
    var location: StorageLocation?
    var category: FoodCategory?
    private(set) var barcode: String?
    private(set) var locations: [StorageLocation] = []
    private(set) var categories: [FoodCategory] = []
    private(set) var lookupState: ProductLookupState = .idle
    private(set) var errorMessage: String?
    private(set) var isSaving = false
    var showsReminderExplainer = false
    var scannerViewModel: BarcodeScannerViewModel?
    /// Set once the item is saved and any reminder prompt is handled; the view dismisses.
    private(set) var isFinished = false

    private let addItem: AddPantryItemUseCase
    private let lookupProduct: LookupProductUseCase
    private let catalog: any CatalogRepository
    private let reminders: any ReminderScheduling
    private let makeScanner: () -> BarcodeScannerViewModel
    private let now: () -> Date
    private let calendar: Calendar
    private var autoFilledName: String?
    private var savedItem: PantryItem?

    init(
        addItem: AddPantryItemUseCase,
        lookupProduct: LookupProductUseCase,
        catalog: any CatalogRepository,
        reminders: any ReminderScheduling,
        makeScanner: @escaping () -> BarcodeScannerViewModel,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.addItem = addItem
        self.lookupProduct = lookupProduct
        self.catalog = catalog
        self.reminders = reminders
        self.makeScanner = makeScanner
        self.now = now
        self.calendar = calendar
        self.useBy = calendar.date(byAdding: .day, value: QuickUseBy.threeDays.rawValue, to: calendar.startOfDay(for: now())) ?? now()
    }

    var minimumUseByDate: Date { calendar.startOfDay(for: now()) }

    func isSelected(_ pick: QuickUseBy) -> Bool {
        calendar.isDate(useBy, inSameDayAs: date(for: pick))
    }

    func applyQuickPick(_ pick: QuickUseBy) {
        useBy = date(for: pick)
    }

    func loadCatalog() {
        do {
            locations = try catalog.locations()
            categories = try catalog.categories()
            if location == nil { location = locations.first }
            if category == nil { category = categories.first { $0.name == "Other" } ?? categories.first }
        } catch {
            errorMessage = error.userMessage
        }
    }

    func startScanning() {
        scannerViewModel = makeScanner()
    }

    func handleScannedBarcode(_ code: String) async {
        scannerViewModel = nil
        barcode = code
        lookupState = .searching
        do {
            let product = try await lookupProduct.execute(barcode: code)
            let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedName.isEmpty || trimmedName == autoFilledName {
                name = String(product.displayName.prefix(AddPantryItemUseCase.maxNameLength))
                autoFilledName = name
            }
            lookupState = .found(product.displayName)
        } catch {
            lookupState = .failed(error.userMessage)
        }
    }

    func save() async {
        guard !isSaving else { return }
        guard let priceCents = Money.cents(from: priceText) else {
            errorMessage = "Enter the price as a number, like 4.50."
            return
        }
        isSaving = true
        defer { isSaving = false }

        let draft = NewPantryItemDraft(
            name: name,
            quantity: quantity,
            priceCents: priceCents,
            useBy: useBy,
            barcode: barcode,
            location: location,
            category: category
        )
        do {
            savedItem = try addItem.execute(draft)
            errorMessage = nil
        } catch {
            errorMessage = error.userMessage
            return
        }

        if await reminders.authorization() == .notDetermined {
            showsReminderExplainer = true
        } else {
            isFinished = true
        }
    }

    func allowReminders() async {
        if await reminders.requestAuthorization() == .authorized, let savedItem {
            // The first reminder was queued before permission existed; schedule it again now it can fire.
            reminders.scheduleReminder(for: savedItem)
        }
        isFinished = true
    }

    func declineReminders() {
        isFinished = true
    }

    private func date(for pick: QuickUseBy) -> Date {
        calendar.date(byAdding: .day, value: pick.rawValue, to: calendar.startOfDay(for: now())) ?? now()
    }
}
