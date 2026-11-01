import SwiftUI

struct RootView: View {
    @State private var selectedTab: AppTab
    @State private var todayViewModel: TodayViewModel
    @State private var insightsViewModel: InsightsViewModel

    init(container: AppContainer) {
        _selectedTab = State(initialValue: container.initialTab)
        _todayViewModel = State(initialValue: container.makeTodayViewModel())
        _insightsViewModel = State(initialValue: container.makeInsightsViewModel())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "list.bullet.clipboard", value: AppTab.today) {
                TodayView(viewModel: todayViewModel)
            }
            Tab("Insights", systemImage: "chart.bar.xaxis", value: AppTab.insights) {
                InsightsView(viewModel: insightsViewModel)
            }
        }
        .onOpenURL { url in
            if let tab = DeepLink.tab(for: url) {
                selectedTab = tab
            }
        }
    }
}
