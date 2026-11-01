import SwiftUI

struct AddItemView: View {
    @State var viewModel: AddItemViewModel

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    private enum Field: Hashable {
        case name
        case price
    }

    var body: some View {
        NavigationStack {
            Form {
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .accessibilityAddTraits(.isStaticText)
                    }
                }

                Section("Item") {
                    TextField("Name", text: $viewModel.name)
                        .focused($focusedField, equals: .name)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                        .onSubmit { focusedField = nil }
                    Button("Scan Barcode", systemImage: "barcode.viewfinder") {
                        focusedField = nil
                        viewModel.startScanning()
                    }
                    .frame(minHeight: 44)
                    lookupStatus
                }

                Section("Use By") {
                    quickPicks
                    DatePicker("Use-by date", selection: $viewModel.useBy, in: viewModel.minimumUseByDate..., displayedComponents: .date)
                }

                Section("Details") {
                    Stepper(value: $viewModel.quantity, in: AddPantryItemUseCase.quantityRange) {
                        LabeledContent("Quantity", value: viewModel.quantity, format: .number)
                    }
                    LabeledContent("Price") {
                        TextField("0.00", text: $viewModel.priceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .price)
                            .accessibilityLabel("Price paid")
                    }
                    Picker("Location", selection: $viewModel.location) {
                        ForEach(viewModel.locations) { location in
                            Label(location.name, systemImage: location.kind.symbolName)
                                .tag(Optional(location))
                        }
                    }
                    Picker("Category", selection: $viewModel.category) {
                        ForEach(viewModel.categories) { category in
                            Label(category.name, systemImage: category.symbolName)
                                .tag(Optional(category))
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        focusedField = nil
                        Task { await viewModel.save() }
                    }
                    .disabled(viewModel.isSaving)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
            .task { viewModel.loadCatalog() }
            .onChange(of: viewModel.isFinished) { _, finished in
                if finished { dismiss() }
            }
            .sheet(item: $viewModel.scannerViewModel) { scannerViewModel in
                BarcodeScannerSheet(viewModel: scannerViewModel) { code in
                    Task { await viewModel.handleScannedBarcode(code) }
                }
            }
            .alert("Get a Reminder Before Food Expires?", isPresented: $viewModel.showsReminderExplainer) {
                Button("Not Now", role: .cancel, action: viewModel.declineReminders)
                Button("Allow Reminders") {
                    Task { await viewModel.allowReminders() }
                }
            } message: {
                Text("UseBy can send a notification at 9 am the day before something's use-by date. You can change this anytime in Settings.")
            }
        }
    }

    @ViewBuilder
    private var lookupStatus: some View {
        switch viewModel.lookupState {
        case .idle:
            EmptyView()
        case .searching:
            HStack(spacing: 8) {
                ProgressView()
                Text("Looking up barcode…")
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        case .found(let productName):
            Label {
                Text("Found \(productName)")
            } icon: {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            }
        case .failed(let message):
            Label {
                Text(message)
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            }
        }
    }

    private var quickPicks: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { quickPickButtons }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) { quickPickButtons }
            VStack(spacing: 8) { quickPickButtons }
        }
        .padding(.vertical, 4)
    }

    private var quickPickButtons: some View {
        ForEach(QuickUseBy.allCases) { pick in
            let isSelected = viewModel.isSelected(pick)
            Button {
                viewModel.applyQuickPick(pick)
            } label: {
                Text(pick.title)
                    .fixedSize()
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.bordered)
            .tint(isSelected ? .accentColor : .secondary)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }
}
