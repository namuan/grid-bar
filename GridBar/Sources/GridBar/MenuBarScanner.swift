import AppKit

class MenuBarScanner: ObservableObject {
    @Published var items: [MenuBarItem] = []
    @Published var isScanning = false

    // Apple bundle IDs that are genuine menu bar status items
    private static let knownSystemMenuBarItems: Set<String> = [
        "com.apple.controlcenter",
        "com.apple.systemuiserver",
        "com.apple.wifi.WiFiAgent",
        "com.apple.Siri",
        "com.apple.Spotlight",
        "com.apple.Passwords.MenuBarExtra",
        "com.apple.TextInputMenuAgent",
        "com.apple.dock",
    ]

    // Apple background agents to skip (not visible in menu bar)
    private static let systemExclusions: [String] = [
        "com.apple.WebKit",
        "com.apple.Virtualization",
        "com.apple.loginwindow",
        "com.apple.talagent",
        "com.apple.WindowManager",
        "com.apple.notificationcenterui",
        "com.apple.AppSSOAgent",
        "com.apple.SoftwareUpdate",
        "com.apple.backgroundtaskmanagement",
        "com.apple.wallpaper",
        "com.apple.universalcontrol",
        "com.apple.dock.extra",
        "com.apple.nbagent",
        "com.apple.universalAccessAuthWarn",
        "com.apple.storeuid",
        "com.apple.UserNotification",
        "com.apple.PowerChime",
        "com.apple.LocalAuthentication",
        "org.sparkle-project",
        "com.apple.WorkflowKit",
        "com.apple.AirPlayUIAgent",
        "com.apple.TextInputSwitcher",
        "com.apple.CoreServicesUIAgent",
        "com.apple.CoreLocationAgent",
        "com.apple.security.Keychain",
        "com.apple.accessibility",
        "com.apple.AppSSOAgent",
        "com.apple.Single-Sign-On",
        "com.apple.ActivityBeacon",
    ]

    func scan() {
        isScanning = true
        DispatchQueue.global(qos: .userInitiated).async {
            let found = self.collectMenuBarApps()
            DispatchQueue.main.async {
                self.items = found
                self.isScanning = false
            }
        }
    }

    private func collectMenuBarApps() -> [MenuBarItem] {
        NSWorkspace.shared.runningApplications
            .filter { isMenuBarApp($0) }
            .compactMap { app in
                guard
                    let name = app.localizedName, !name.isEmpty,
                    let bundleId = app.bundleIdentifier,
                    let icon = app.icon
                else { return nil }

                return MenuBarItem(
                    ownerName: name,
                    bundleIdentifier: bundleId,
                    appIcon: icon,
                    pid: app.processIdentifier,
                    isSystemItem: bundleId.hasPrefix("com.apple.")
                )
            }
            .sorted { a, b in
                // System items last
                if a.isSystemItem != b.isSystemItem { return !a.isSystemItem }
                return a.ownerName.localizedCaseInsensitiveCompare(b.ownerName) == .orderedAscending
            }
    }

    private func isMenuBarApp(_ app: NSRunningApplication) -> Bool {
        guard app.activationPolicy == .accessory,
              let bundleId = app.bundleIdentifier else { return false }

        // Explicitly keep known system menu bar items
        if Self.knownSystemMenuBarItems.contains(bundleId) { return true }

        // Drop all other com.apple.* (they're background agents)
        if bundleId.hasPrefix("com.apple.") { return false }

        // Drop helpers and background services for any vendor
        for excluded in Self.systemExclusions {
            if bundleId.hasPrefix(excluded) || bundleId.contains(excluded) { return false }
        }

        return true
    }
}
