import SwiftUI
import UIKit

struct BarcodeScannerSheet: View {
    @State var viewModel: BarcodeScannerViewModel
    let onScan: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Scan Barcode")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
        .task { await viewModel.requestAccessIfNeeded() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { viewModel.refreshAccess() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.access {
        case .authorized:
            DataScannerView { code in
                guard viewModel.accept(code) else { return }
                onScan(code)
                dismiss()
            }
            .ignoresSafeArea(edges: .bottom)
            .overlay(alignment: .bottom) {
                Text("Point the camera at a barcode")
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.bottom, 32)
            }
        case .notDetermined:
            ProgressView("Asking for camera access…")
        case .denied:
            ContentUnavailableView {
                Label("Camera Access Is Off", systemImage: "camera.badge.ellipsis")
            } description: {
                Text("Allow camera access in Settings to scan barcodes, or type the product name instead.")
            } actions: {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(minHeight: 44)
            }
        case .unsupported:
            ContentUnavailableView {
                Label("Scanning Isn't Available", systemImage: "barcode.viewfinder")
            } description: {
                Text("This device can't scan barcodes. Type the product name instead.")
            }
        }
    }
}
