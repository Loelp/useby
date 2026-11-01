import SwiftUI

struct RootView: View {
    let container: AppContainer

    var body: some View {
        ContentUnavailableView("UseBy", systemImage: "leaf", description: Text("Track what's in your fridge before it expires."))
    }
}
