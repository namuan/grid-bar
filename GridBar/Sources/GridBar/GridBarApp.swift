import SwiftUI

@main
struct GridBarApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 700, height: 520)
    }
}
