import SwiftUI

struct CookView: View {
    @State var viewModel: CookViewModel

    var body: some View {
        NavigationStack {
            Group {
                if let reason = viewModel.unavailableReason {
                    ContentUnavailableView {
                        Label("Meal Ideas Unavailable", systemImage: "apple.intelligence")
                    } description: {
                        Text(reason)
                    }
                } else if viewModel.hasNothingExpiring, viewModel.state == .idle {
                    ContentUnavailableView {
                        Label("Nothing to Cook Around", systemImage: "frying.pan")
                    } description: {
                        Text(viewModel.noExpiringItemsMessage)
                    }
                } else {
                    content
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Cook")
            .onAppear { viewModel.refresh() }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !viewModel.expiringItemNames.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Use these up soon")
                            .font(.headline)
                        ItemChips(names: viewModel.expiringItemNames)
                    }
                }

                switch viewModel.state {
                case .idle:
                    suggestButton(title: "Suggest a Meal")
                case .loading:
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Thinking up a meal…")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .accessibilityElement(children: .combine)
                case .loaded(let idea):
                    MealCard(idea: idea)
                    suggestButton(title: "Suggest Another")
                case .failed(let message):
                    Label {
                        Text(message)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    }
                    suggestButton(title: "Try Again")
                }

                Text("Generated on your iPhone. Check ingredients before cooking.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }

    private func suggestButton(title: String) -> some View {
        Button {
            Task { await viewModel.suggest() }
        } label: {
            Label(title, systemImage: "sparkles")
                .frame(maxWidth: .infinity, minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.hasNothingExpiring)
    }
}
