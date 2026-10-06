import SwiftUI

@main
struct SendaApp: App {
    @State private var store = TripStore()
    @State private var recorder = Recorder()

    var body: some Scene {
        WindowGroup {
            RootView(store: store, recorder: recorder)
                .preferredColorScheme(.light)
                .tint(Palette.ink)
        }
    }
}
