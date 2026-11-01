import Foundation
import Testing
@testable import UseBy

@MainActor
@Suite("Pantry overview and waste summary")
struct OverviewAndSummaryTests {
    @Test("Overview groups items by freshness in urgency order and omits empty sections")
    func overviewGrouping() throws {
        let pantry = MockPantryRepository(items: [
            Fixtures.item("Sourdough loaf", daysFromNow: 3),
            Fixtures.item("Baby spinach", daysFromNow: -2),
            Fixtures.item("Cheddar block", daysFromNow: 20),
            Fixtures.item("Greek yoghurt", daysFromNow: 0),
            Fixtures.item("Lebanese cucumbers", daysFromNow: 1),
            Fixtures.item("Bananas", daysFromNow: 1),
            Fixtures.item("Old milk", daysFromNow: -1, status: .binned),
        ])
        let useCase = FetchPantryOverviewUseCase(pantry: pantry, now: { Fixtures.now }, calendar: Fixtures.calendar)

        let sections = try useCase.execute()

        #expect(sections.map(\.freshness) == [.expired, .today, .soon, .fresh])
        #expect(sections[0].items.map(\.name) == ["Baby spinach"])
        #expect(sections[1].items.map(\.name) == ["Greek yoghurt"])
        #expect(sections[2].items.map(\.name) == ["Bananas", "Lebanese cucumbers", "Sourdough loaf"])
        #expect(sections[3].items.map(\.name) == ["Cheddar block"])

        pantry.items = Dictionary(uniqueKeysWithValues: [Fixtures.item("Cheddar block", daysFromNow: 20)].map { ($0.id, $0) })
        #expect(try useCase.execute().map(\.freshness) == [.fresh])
    }

    @Test("Freshness boundaries", arguments: [(-1, Freshness.expired), (0, .today), (1, .soon), (3, .soon), (4, .fresh)])
    func freshnessBoundaries(days: Int, expected: Freshness) {
        #expect(Freshness(daysRemaining: days) == expected)
    }

    @Test("Days remaining counts calendar days, not 24-hour periods")
    func daysRemainingUsesCalendarDays() {
        var item = Fixtures.item("Milk", daysFromNow: 1)
        item.useBy = Fixtures.date(daysFromNow: 1, hour: 1)
        #expect(item.daysRemaining(from: Fixtures.now, calendar: Fixtures.calendar) == 1)
    }

    @Test("Weekly summary totals saved vs wasted, excludes older events and calculates the waste rate")
    func weeklySummary() throws {
        let pantry = MockPantryRepository(events: [
            Fixtures.event(.eaten, cents: 500, daysAgo: 2, category: "Produce"),
            Fixtures.event(.eaten, cents: 300, daysAgo: 6, category: "Dairy & Eggs"),
            Fixtures.event(.binned, cents: 200, daysAgo: 3, category: "Produce"),
            Fixtures.event(.binned, cents: 1000, daysAgo: 8, category: "Bakery"),
        ])
        let useCase = CalculateWasteSummaryUseCase(pantry: pantry, now: { Fixtures.now }, calendar: Fixtures.calendar)

        let summary = try useCase.execute(period: .week)

        #expect(summary.savedCents == 800)
        #expect(summary.wastedCents == 200)
        #expect(summary.eatenCount == 2)
        #expect(summary.binnedCount == 1)
        #expect(summary.wasteRate == 0.2)
        #expect(summary.categoryBreakdown.map(\.categoryName) == ["Produce", "Dairy & Eggs"])
        let produce = try #require(summary.categoryBreakdown.first)
        #expect(produce.eatenCount == 1 && produce.binnedCount == 1)

        let allTime = try useCase.execute(period: .allTime)
        #expect(allTime.wastedCents == 1200)
    }

    @Test("Waste rate is zero with no history")
    func emptySummary() {
        #expect(WasteSummary.empty.wasteRate == 0)
        #expect(!WasteSummary.empty.hasHistory)
    }
}
