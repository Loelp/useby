import Foundation
import Observation

@MainActor
@Observable
final class BarcodeScannerViewModel: Identifiable {
    private(set) var access: CameraAccess
    private var hasDeliveredCode = false

    private let cameraAccess: any CameraAccessProviding

    init(cameraAccess: any CameraAccessProviding) {
        self.cameraAccess = cameraAccess
        self.access = cameraAccess.currentAccess()
    }

    func refreshAccess() {
        access = cameraAccess.currentAccess()
    }

    func requestAccessIfNeeded() async {
        guard access == .notDetermined else { return }
        access = await cameraAccess.requestAccess()
    }

    func accept(_ code: String) -> Bool {
        guard !hasDeliveredCode, !code.isEmpty else { return false }
        hasDeliveredCode = true
        return true
    }
}
