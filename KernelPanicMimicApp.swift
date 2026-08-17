import SwiftUI

@main
struct KernelPanicMimicApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .statusBar(hidden: true)
                .preferredColorScheme(.dark)
                .persistentSystemOverlays(.hidden)
        }
    }
}
