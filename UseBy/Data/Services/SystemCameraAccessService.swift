import AVFoundation
import VisionKit

@MainActor
final class SystemCameraAccessService: CameraAccessProviding {
    func currentAccess() -> CameraAccess {
        guard DataScannerViewController.isSupported else { return .unsupported }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: return .authorized
        case .notDetermined: return .notDetermined
        case .denied, .restricted: return .denied
        @unknown default: return .denied
        }
    }

    func requestAccess() async -> CameraAccess {
        guard DataScannerViewController.isSupported else { return .unsupported }
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        return granted ? .authorized : .denied
    }
}
