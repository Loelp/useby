import SwiftUI

struct StartupErrorView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Your Pantry Couldn't Load", systemImage: "exclamationmark.triangle")
        } description: {
            Text("UseBy couldn't open your saved items. Close and reopen the app. If this keeps happening, free up some storage on your iPhone and try again.")
        }
    }
}

#Preview {
    StartupErrorView()
}
