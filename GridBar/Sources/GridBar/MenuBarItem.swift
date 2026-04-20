import AppKit

struct MenuBarItem: Identifiable {
    let id = UUID()
    let ownerName: String
    let bundleIdentifier: String
    let appIcon: NSImage
    let pid: pid_t
    let isSystemItem: Bool
}
