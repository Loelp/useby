import SwiftUI

@main
struct UseByApp: App {
    var body: some Scene {
        WindowGroup {
            ContentUnavailableView("UseBy", systemImage: "leaf", description: Text("Track what's in your fridge before it expires."))
        }
    }
}
