import Foundation
import Testing
@testable import UseBy

@Suite("Presentation helpers")
struct PresentationHelperTests {
    @Test("Parses prices locale-aware into cents")
    func parsesPrices() {
        let australia = Locale(identifier: "en_AU")
        #expect(Money.cents(from: "4.50", locale: australia) == 450)
        #expect(Money.cents(from: "12", locale: australia) == 1200)
        #expect(Money.cents(from: "", locale: australia) == 0)
        #expect(Money.cents(from: "abc", locale: australia) == nil)
        #expect(Money.cents(from: "4,50", locale: Locale(identifier: "de_DE")) == 450)
    }

    @Test("Formats cents in the locale's currency")
    func formatsCurrency() {
        #expect(Money.string(cents: 2810, locale: Locale(identifier: "en_AU")) == "$28.10")
    }

    @Test("Badge text reads naturally", arguments: [(-1, "Expired 1 day ago"), (-3, "Expired 3 days ago"), (0, "Today"), (1, "1 day"), (2, "2 days")])
    func badgeText(days: Int, expected: String) {
        #expect(Freshness.badgeText(daysRemaining: days) == expected)
    }

    @Test("Deep links route to tabs")
    func deepLinks() {
        #expect(DeepLink.tab(for: URL(string: "useby://today")!) == .today)
        #expect(DeepLink.tab(for: URL(string: "useby://cook")!) == .cook)
        #expect(DeepLink.tab(for: URL(string: "https://today")!) == nil)
    }
}
