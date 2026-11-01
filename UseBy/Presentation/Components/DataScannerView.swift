import SwiftUI
import Vision
import VisionKit

/// Wraps `DataScannerViewController`. Results are read from the `recognizedItems` async stream
/// instead of a delegate, which keeps everything on the main actor under Swift 6.
struct DataScannerView: UIViewControllerRepresentable {
    let onBarcode: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce, .code128])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        context.coordinator.observe(scanner)
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        context.coordinator.onBarcode = onBarcode
        if !scanner.isScanning {
            try? scanner.startScanning()
        }
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        coordinator.stop()
        scanner.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onBarcode: onBarcode)
    }

    @MainActor
    final class Coordinator {
        var onBarcode: (String) -> Void
        private var task: Task<Void, Never>?

        init(onBarcode: @escaping (String) -> Void) {
            self.onBarcode = onBarcode
        }

        func observe(_ scanner: DataScannerViewController) {
            task = Task { [weak self, weak scanner] in
                guard let stream = scanner?.recognizedItems else { return }
                for await items in stream {
                    for item in items {
                        if case .barcode(let barcode) = item, let payload = barcode.payloadStringValue {
                            self?.onBarcode(payload)
                            return
                        }
                    }
                }
            }
        }

        func stop() {
            task?.cancel()
            task = nil
        }
    }
}
