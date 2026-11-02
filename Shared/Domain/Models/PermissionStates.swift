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
    case unsupported
}
