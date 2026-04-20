import AppKit
import ApplicationServices

class PermissionManager: ObservableObject {
    @Published private(set) var accessibilityGranted = false

    private var pollingTimer: Timer?

    init() { refresh() }

    var allGranted: Bool { accessibilityGranted }

    func refresh() {
        accessibilityGranted = AXIsProcessTrusted()
    }

    func startPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.refresh() }
        }
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    func requestAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }
}
