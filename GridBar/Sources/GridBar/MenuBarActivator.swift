import AppKit
import ApplicationServices

enum MenuBarActivator {

    static var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibilityIfNeeded() {
        guard !isAccessibilityGranted else { return }
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }

    /// Finds the app's status-bar item via AX, then simulates a real mouse
    /// click at its screen position so the menu opens and dismisses normally.
    static func activate(_ item: MenuBarItem) {
        requestAccessibilityIfNeeded()
        guard isAccessibilityGranted else { return }

        let axApp = AXUIElementCreateApplication(item.pid)
        if clickStatusItem(in: axApp) { return }

        // Fallback for system items with no accessible menu bar
        NSRunningApplication(processIdentifier: item.pid)?
            .activate(options: .activateIgnoringOtherApps)
    }

    // MARK: - Private

    private static func clickStatusItem(in axApp: AXUIElement) -> Bool {
        guard let menuBar = axAttribute(kAXMenuBarAttribute, of: axApp),
              let children = axChildren(of: menuBar),
              !children.isEmpty else { return false }

        let screenWidth = NSScreen.main?.frame.width ?? 0

        // Status items sit on the right half of the menu bar
        let candidate = children
            .compactMap { child -> (AXUIElement, CGFloat)? in
                guard let pos = axPosition(of: child) else { return nil }
                return (child, pos.x)
            }
            .filter { $0.1 > screenWidth / 2 }
            .min(by: { $0.1 < $1.1 })  // leftmost of the right-side items
            .map(\.0)

        guard let target = candidate,
              let pos = axPosition(of: target),
              let sz = axSize(of: target) else { return false }

        let center = CGPoint(x: pos.x + sz.width / 2, y: pos.y + sz.height / 2)
        postMouseClick(at: center)
        return true
    }

    /// Posts a left-click event pair at the given global screen point.
    /// Using CGEvent (real hardware-level events) means the resulting menu
    /// behaves normally and can be dismissed by clicking elsewhere.
    private static func postMouseClick(at point: CGPoint) {
        let src = CGEventSource(stateID: .hidSystemState)
        let down = CGEvent(mouseEventSource: src, mouseType: .leftMouseDown,
                           mouseCursorPosition: point, mouseButton: .left)
        let up   = CGEvent(mouseEventSource: src, mouseType: .leftMouseUp,
                           mouseCursorPosition: point, mouseButton: .left)
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)
    }

    // MARK: - AX helpers

    private static func axAttribute(_ key: String, of element: AXUIElement) -> AXUIElement? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &ref) == .success else { return nil }
        return (ref as! AXUIElement)
    }

    private static func axChildren(of element: AXUIElement) -> [AXUIElement]? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &ref) == .success else { return nil }
        return ref as? [AXUIElement]
    }

    private static func axPosition(of element: AXUIElement) -> CGPoint? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &ref) == .success,
              let value = ref else { return nil }
        var point = CGPoint.zero
        AXValueGetValue(value as! AXValue, .cgPoint, &point)
        return point
    }

    private static func axSize(of element: AXUIElement) -> CGSize? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &ref) == .success,
              let value = ref else { return nil }
        var size = CGSize.zero
        AXValueGetValue(value as! AXValue, .cgSize, &size)
        return size
    }
}
