import Foundation
import Observation

enum MealSuggestionState: Equatable {
    case idle
    case loading
    case loaded(MealIdea)
    case failed(String)
}

@MainActor
@Observable
final class CookViewModel {
    private(set) var availability: MealSuggestionAvailability = .available
    private(set) var expiringItemNames: [String] = []
    private(set) var state: MealSuggestionState = .idle

    private let suggestMeal: SuggestMealUseCase

    init(suggestMeal: SuggestMealUseCase) {
        self.suggestMeal = suggestMeal
    }

    var unavailableReason: String? {
        if case .unavailable(let reason) = availability { return reason }
        return nil
    }

    var hasNothingExpiring: Bool { expiringItemNames.isEmpty }

    var noExpiringItemsMessage: String {
        MealSuggestionError.noExpiringItems.userMessage
    }

    func refresh() {
        availability = suggestMeal.availability
        expiringItemNames = (try? suggestMeal.expiringItems().map(\.name)) ?? []
        if case .loaded(let idea) = state, Set(idea.usesItems) != Set(expiringItemNames) {
            state = .idle
        }
    }

    func suggest() async {
        guard state != .loading else { return }
        state = .loading
        do {
            state = .loaded(try await suggestMeal.execute())
        } catch {
            state = .failed(error.userMessage)
        }
        refresh()
    }
}
