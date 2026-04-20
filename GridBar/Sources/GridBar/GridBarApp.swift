import SwiftUI

@main
struct GridBarApp: App {
    @StateObject private var permissions = PermissionManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(permissions)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

struct RootView: View {
    @EnvironmentObject var permissions: PermissionManager
    @State private var onboardingDone = false

    var showOnboarding: Bool { !onboardingDone && !permissions.allGranted }

    var body: some View {
        ZStack {
            ContentView()
                .frame(minWidth: 600, minHeight: 420)
                .opacity(showOnboarding ? 0 : 1)

            if showOnboarding {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showOnboarding)
        .onChange(of: permissions.allGranted) { _, granted in
            if granted {
                withAnimation(.easeInOut(duration: 0.5)) {
                    onboardingDone = true
                }
            }
        }
        .onReceive(
            NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
        ) { _ in
            permissions.refresh()
        }
    }
}
