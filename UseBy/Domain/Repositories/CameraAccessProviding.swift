import Foundation

@MainActor
protocol CameraAccessProviding {
    func currentAccess() -> CameraAccess
    @discardableResult
    func requestAccess() async -> CameraAccess
}
