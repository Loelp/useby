import Foundation
import FoundationModels

/// On-device meal ideas from Apple Intelligence. Nothing leaves the iPhone.
struct FoundationModelMealSuggestionService: MealSuggestionService {
    static let instructions = """
        You are a practical home cook helping someone use up food before it expires. \
        Suggest one simple meal that uses mostly the ingredients provided, plus common pantry staples \
        such as oil, salt, pepper, garlic, onion, rice, pasta or spices. Keep steps short and clear.
        """

    var availability: MealSuggestionAvailability {
        let model = SystemLanguageModel.default
        if case .unavailable(let reason) = model.availability {
            return .unavailable(reason: Self.message(for: reason))
        }
        return .available
    }

    func suggestMeal(using ingredients: [String]) async throws -> MealIdea {
        let session = LanguageModelSession(instructions: Self.instructions)
        let prompt = "Ingredients to use up: \(ingredients.joined(separator: ", ")). Suggest one meal."
        do {
            let response = try await session.respond(to: prompt, generating: GeneratedMeal.self)
            let meal = response.content
            return MealIdea(
                title: meal.title,
                minutes: min(max(meal.minutes, 5), 60),
                ingredients: meal.ingredients,
                steps: meal.steps,
                usesItems: ingredients
            )
        } catch {
            throw MealSuggestionError.generationFailed
        }
    }

    private static func message(for reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            "Meal ideas need an iPhone that supports Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            "Turn on Apple Intelligence in Settings to get meal ideas."
        case .modelNotReady:
            "Apple Intelligence is still getting ready. Try again in a little while."
        @unknown default:
            "Meal ideas aren't available on this iPhone right now."
        }
    }
}

@Generable
struct GeneratedMeal {
    @Guide(description: "A short, appetising name for the meal")
    var title: String

    @Guide(description: "Total time to cook, in minutes", .range(5...60))
    var minutes: Int

    @Guide(description: "Ingredients with rough amounts, e.g. '2 chicken thigh fillets'", .count(3...8))
    var ingredients: [String]

    @Guide(description: "Short cooking steps in order, without numbering", .count(3...6))
    var steps: [String]
}
