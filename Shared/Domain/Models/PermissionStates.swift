import Foundation

enum ReminderAuthorization: Sendable, Hashable {
    case authorized
    case notDetermined
    case denied
}

enum CameraAccess: Sendable, Hashable {
    case authorized
    case notDetermined
    case denied
    /// The device can't scan barcodes (for example, the Simulator).
    case unsupported
}
