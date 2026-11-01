import SwiftUI
import UIKit

struct TodayView: View {
    @State var viewModel: TodayViewModel

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                if let banner = viewModel.reminderBanner {
                    Section {
                        ReminderBanner(
                            authorization: banner,
                            onTurnOn: { Task { await viewModel.turnOnReminders() } },
                            onOpenSettings: openSettings
                        )
                    }
                }
                ForEach(viewModel.sections) { section in
                    Section {
                        ForEach(section.items) { item in
                            row(for: item)
                        }
                    } header: {
                        FreshnessSectionHeader(freshness: section.freshness, count: section.items.count)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay {
                if viewModel.isEmpty {
                    emptyState
                }
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Item", systemImage: "plus", action: viewModel.startAddingItem)
                }
            }
            .refreshable {
                viewModel.load()
                await viewModel.refreshReminderStatus()
            }
            .task {
                viewModel.load()
                await viewModel.refreshReminderStatus()
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                viewModel.load()
                Task { await viewModel.refreshReminderStatus() }
            }
            .sensoryFeedback(.success, trigger: viewModel.eatenCount)
            .sensoryFeedback(.impact(weight: .light), trigger: viewModel.binnedCount)
            .sheet(item: $viewModel.addItemViewModel, onDismiss: {
                viewModel.load()
                Task { await viewModel.refreshReminderStatus() }
            }) { addItemViewModel in
                AddItemView(viewModel: addItemViewModel)
            }
            .confirmationDialog(
                "Delete \(viewModel.itemPendingDeletion?.name ?? "item")?",
                isPresented: $viewModel.isConfirmingDeletion,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive, action: viewModel.confirmDelete)
            } message: {
                Text("It won't count as eaten or binned.")
            }
            .alert("Something Went Wrong", isPresented: $viewModel.isShowingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func row(for item: PantryItem) -> some View {
        PantryItemRow(item: item, daysRemaining: viewModel.daysRemaining(for: item))
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button("Eaten", systemImage: "checkmark.circle") { viewModel.markEaten(item) }
                    .tint(.green)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button("Binned", systemImage: "trash") { viewModel.markBinned(item) }
                    .tint(.orange)
            }
            .contextMenu {
                Button("Eaten", systemImage: "checkmark.circle") { viewModel.markEaten(item) }
                Button("Binned", systemImage: "trash") { viewModel.markBinned(item) }
                Divider()
                Button("Delete", systemImage: "xmark.bin", role: .destructive) { viewModel.requestDelete(item) }
            }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Nothing to Use Up", systemImage: "refrigerator")
        } description: {
            Text("Add your groceries after the weekly shop and UseBy will sort them by what to eat first.")
        } actions: {
            Button("Add an item", action: viewModel.startAddingItem)
                .buttonStyle(.borderedProminent)
                .frame(minHeight: 44)
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}
