import SwiftUI

struct RootView: View {
    @State private var selectedTab: AppTab = .today
    @State private var todayViewModel: TodayViewModel

    init(container: AppContainer) {
        _todayViewModel = State(initialValue: container.makeTodayViewModel())
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "list.bullet.clipboard", value: AppTab.today) {
                TodayView(viewModel: todayViewModel)
            }
        }
        .onOpenURL { url in
            if let tab = DeepLink.tab(for: url) {
                selectedTab = tab
            }
        }
    }
}
