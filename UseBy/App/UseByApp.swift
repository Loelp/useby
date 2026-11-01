import OSLog
import SwiftUI

@main
struct UseByApp: App {
    private let container: AppContainer?

    init() {
        do {
            container = try AppContainer.make()
        } catch {
            Logger(subsystem: "com.usebyapp.UseBy", category: "Launch")
                .fault("Failed to build app container: \(error.localizedDescription, privacy: .public)")
            container = nil
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                RootView(container: container)
            } else {
                StartupErrorView()
            }
        }
    }
}
