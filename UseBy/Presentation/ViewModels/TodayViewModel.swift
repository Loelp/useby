import Foundation
import Observation

@MainActor
@Observable
final class TodayViewModel {
    private(set) var sections: [FreshnessSection] = []
    private(set) var hasLoaded = false
    private(set) var reminderAuthorization: ReminderAuthorization?
    private(set) var eatenCount = 0
    private(set) var binnedCount = 0
    var errorMessage: String?
    var itemPendingDeletion: PantryItem?
    var addItemViewModel: AddItemViewModel?

    private let fetchOverview: FetchPantryOverviewUseCase
    private let resolveItem: ResolvePantryItemUseCase
    private let deleteItem: DeletePantryItemUseCase
    private let reminders: any ReminderScheduling
    private let makeAddItem: () -> AddItemViewModel
    private let now: () -> Date
    private let calendar: Calendar

    init(
        fetchOverview: FetchPantryOverviewUseCase,
        resolveItem: ResolvePantryItemUseCase,
        deleteItem: DeletePantryItemUseCase,
        reminders: any ReminderScheduling,
        makeAddItem: @escaping () -> AddItemViewModel,
        now: @escaping () -> Date = Date.init,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        self.fetchOverview = fetchOverview
        self.resolveItem = resolveItem
        self.deleteItem = deleteItem
        self.reminders = reminders
        self.makeAddItem = makeAddItem
        self.now = now
        self.calendar = calendar
    }

    var isEmpty: Bool { hasLoaded && sections.isEmpty }

    var isShowingError: Bool {
        get { errorMessage != nil }
        set { if !newValue { errorMessage = nil } }
    }

    var isConfirmingDeletion: Bool {
        get { itemPendingDeletion != nil }
        set { if !newValue { itemPendingDeletion = nil } }
    }

    var reminderBanner: ReminderAuthorization? {
        switch reminderAuthorization {
        case .notDetermined, .denied: reminderAuthorization
        case .authorized, nil: nil
        }
    }

    func load() {
        do {
            sections = try fetchOverview.execute()
        } catch {
            errorMessage = error.userMessage
        }
        hasLoaded = true
    }

    func refreshReminderStatus() async {
        reminderAuthorization = await reminders.authorization()
    }

    func turnOnReminders() async {
        reminderAuthorization = await reminders.requestAuthorization()
    }

    func daysRemaining(for item: PantryItem) -> Int {
        item.daysRemaining(from: now(), calendar: calendar)
    }

    func markEaten(_ item: PantryItem) {
        resolve(item, outcome: .eaten)
    }

    func markBinned(_ item: PantryItem) {
        resolve(item, outcome: .binned)
    }

    func requestDelete(_ item: PantryItem) {
        itemPendingDeletion = item
    }

    func confirmDelete() {
        guard let item = itemPendingDeletion else { return }
        itemPendingDeletion = nil
        do {
            try deleteItem.execute(itemID: item.id)
        } catch {
            errorMessage = error.userMessage
        }
        load()
    }

    func startAddingItem() {
        addItemViewModel = makeAddItem()
    }

    private func resolve(_ item: PantryItem, outcome: ConsumptionOutcome) {
        do {
            try resolveItem.execute(itemID: item.id, outcome: outcome)
            switch outcome {
            case .eaten: eatenCount += 1
            case .binned: binnedCount += 1
            }
        } catch {
            errorMessage = error.userMessage
        }
        load()
    }
}
