import Charts
import SwiftUI

struct InsightsView: View {
    @State var viewModel: InsightsViewModel

    @ScaledMetric(relativeTo: .body) private var barRowHeight = 44

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Period", selection: $viewModel.period) {
                        ForEach(SummaryPeriod.allCases) { period in
                            Text(period.title).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.isEmpty {
                        ContentUnavailableView {
                            Label("No History Yet", systemImage: "chart.bar.xaxis")
                        } description: {
                            Text(viewModel.errorMessage ?? viewModel.emptyMessage)
                        }
                        .padding(.top, 40)
                    } else {
                        statCards
                        categoryChart
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Insights")
            .onAppear { viewModel.load() }
            .onChange(of: viewModel.period) { viewModel.load() }
        }
    }

    private var statCards: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                savedCard
                wastedCard
                wasteRateCard
            }
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    savedCard
                    wastedCard
                }
                wasteRateCard
            }
            VStack(spacing: 12) {
                savedCard
                wastedCard
                wasteRateCard
            }
        }
    }

    private var savedCard: some View {
        StatCard(title: "Saved", value: viewModel.savedText, systemImage: "checkmark.circle.fill", tint: .green)
    }

    private var wastedCard: some View {
        StatCard(title: "Wasted", value: viewModel.wastedText, systemImage: "trash.fill", tint: .orange)
    }

    private var wasteRateCard: some View {
        StatCard(title: "Waste rate", value: viewModel.wasteRateText, systemImage: "percent", tint: .secondary)
    }

    private var categoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Eaten vs Binned by Category")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Chart(viewModel.chartBars) { bar in
                BarMark(
                    x: .value("Items", bar.count),
                    y: .value("Category", bar.categoryName)
                )
                .foregroundStyle(by: .value("Outcome", bar.outcomeTitle))
                .position(by: .value("Outcome", bar.outcomeTitle))
                .accessibilityLabel(bar.categoryName)
                .accessibilityValue("\(bar.count) \(bar.outcomeTitle.lowercased())")
            }
            .chartForegroundStyleScale(["Eaten": Color.green, "Binned": Color.orange])
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartLegend(position: .top, alignment: .leading)
            .frame(height: CGFloat(max(viewModel.summary.categoryBreakdown.count, 1)) * barRowHeight + 60)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
