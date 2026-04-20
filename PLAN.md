Here's a complete **plan** and **implementation** for a SwiftUI macOS app that collects all currently visible menu bar apps (status items) and displays their icons in a rectangular grid.

### Important Limitations (as of macOS 15/16 in 2026)
- Apple provides **no public API** to directly enumerate all `NSStatusItem`s from other apps.
- The best reliable, public way is to use **CoreGraphics** to scan on-screen windows: menu bar status items appear as tiny windows pinned to the top of the screen (`bounds.origin.y == 0` and very small height).
- This method captures **most** status items (including system ones like Wi-Fi, battery, clock, and third-party ones), but it can miss some hidden/collapsed items (e.g., behind Bartender) or include a few false positives.
- You cannot easily get the original app name or full-resolution icon for every item — you get the window owner name and a screenshot of the visible icon.
- For better icons, you can fall back to `NSWorkspace` to get the app's icon by bundle identifier or name.

This approach is commonly used (e.g., in tools that manage or hide menu bar items).

### App Architecture Plan
1. **Project Type**: macOS App (SwiftUI).
2. **Main UI**: A regular window (or optional MenuBarExtra) showing a **scrollable rectangular grid** of menu bar icons.
3. **Data Model**: A struct holding `ownerName`, screenshot/image of the icon, bounds, and optionally the owning app's icon.
4. **Refresh Mechanism**: A button + Timer to re-scan the menu bar (menu bar items can appear/disappear dynamically).
5. **Grid**: Use `LazyVGrid` with adaptive columns for a nice responsive rectangular layout.
6. **Extras**:
   - Click an icon → show a popover with details (owner, bounds, larger preview).
   - Option to hide the app from Dock (`LSUIElement = YES` in Info.plist) if you want a utility feel.
   - Refresh every 5–10 seconds or on demand.

### Step-by-Step Implementation

#### 1. Create the Project
- Xcode → New Project → macOS App → SwiftUI + Swift.
- Set minimum deployment to macOS 14.0+ (for best SwiftUI support).

#### 2. Info.plist (optional but recommended)
Add this key to hide the app from the Dock (makes it feel more like a utility):
```xml
<key>LSUIElement</key>
<true/>
```

#### 3. Data Model
```swift
import SwiftUI
import AppKit

struct MenuBarItem: Identifiable {
    let id = UUID()
    let ownerName: String
    let image: NSImage?          // Screenshot of the status item
    let appIcon: NSImage?        // Icon of the owning application (if found)
    let bounds: CGRect
}
```

#### 4. Menu Bar Scanner (CoreGraphics-based)
```swift
class MenuBarScanner: ObservableObject {
    @Published var items: [MenuBarItem] = []
    
    func scan() {
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return
        }
        
        var newItems: [MenuBarItem] = []
        
        for window in windowList {
            guard let boundsDict = window[kCGWindowBounds as String] as? CFDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDict),
                  let ownerName = window[kCGWindowOwnerName as String] as? String,
                  let windowName = window[kCGWindowName as String] as? String else {
                continue
            }
            
            // Filter for menu bar items: pinned to top + very small height (typically < 30pt)
            if bounds.origin.y == 0 && bounds.height < 40 && bounds.width < 200 {
                // Capture screenshot of the status item
                let screenshot = captureWindowImage(windowID: window[kCGWindowNumber as String] as? CGWindowID ?? 0)
                
                // Try to get the owning app's icon
                let appIcon = getAppIcon(for: ownerName)
                
                let item = MenuBarItem(
                    ownerName: ownerName,
                    image: screenshot,
                    appIcon: appIcon,
                    bounds: bounds
                )
                newItems.append(item)
            }
        }
        
        // Remove duplicates (sometimes the same item appears multiple times)
        self.items = newItems.unique(by: \.ownerName)
    }
    
    private func captureWindowImage(windowID: CGWindowID) -> NSImage? {
        guard let cgImage = CGWindowListCreateImage(.null, .optionIncludingWindow, windowID, [.boundsIgnoreFraming, .bestResolution]) else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
    
    private func getAppIcon(for ownerName: String) -> NSImage? {
        // Simple heuristic: try to find running app by name
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == ownerName }) {
            return app.icon
        }
        return nil
    }
}

extension Array {
    func unique<T: Hashable>(by keyPath: KeyPath<Element, T>) -> [Element] {
        var seen: Set<T> = []
        return filter { seen.insert($0[keyPath: keyPath]).inserted }
    }
}
```

#### 5. Main Content View (Rectangular Grid)
```swift
struct ContentView: View {
    @StateObject private var scanner = MenuBarScanner()
    @State private var selectedItem: MenuBarItem?
    
    let columns = [
        GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 16)
    ]
    
    var body: some View {
        VStack {
            HStack {
                Text("Menu Bar Items")
                    .font(.largeTitle)
                    .bold()
                Spacer()
                Button("Refresh") {
                    scanner.scan()
                }
                .keyboardShortcut("r")
            }
            .padding()
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(scanner.items) { item in
                        VStack {
                            if let image = item.image ?? item.appIcon {
                                Image(nsImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 48, height: 48)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "questionmark.square")
                                    .font(.system(size: 48))
                            }
                            
                            Text(item.ownerName)
                                .font(.caption)
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                        }
                        .onTapGesture {
                            selectedItem = item
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            scanner.scan()
            // Auto-refresh every 8 seconds
            Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { _ in
                scanner.scan()
            }
        }
        .sheet(item: $selectedItem) { item in
            DetailView(item: item)
        }
    }
}

struct DetailView: View {
    let item: MenuBarItem
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = item.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 120, maxHeight: 120)
            }
            
            Text(item.ownerName)
                .font(.title)
            
            Text("Bounds: \(item.bounds)")
                .font(.caption)
                .monospaced()
        }
        .padding(40)
    }
}
```

#### 6. App Entry Point
```swift
import SwiftUI

@main
struct MenuBarCollectorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 600, minHeight: 500)
        }
        .windowStyle(.hiddenTitleBar)   // Optional clean look
        // .windowResizability(.contentSize)
    }
}
```

### Enhancements You Can Add
- **Better filtering**: Ignore known system items like "ControlCenter", "Menu Bar", etc.
- **Search bar** to filter the grid.
- **Export** the list or screenshots.
- **Make the app itself a MenuBarExtra** that opens this grid window on click.
- **Dark mode support** — SwiftUI handles most of it automatically.
- **Error handling** / permission checks (CoreGraphics window list usually works without extra entitlements).

### Potential Improvements (Advanced)
- Combine with `NSRunningApplication` for more accurate app icons.
- Use private APIs (via `dlopen` / Objective-C runtime) if you need full `NSStatusItem` access — but this risks App Store rejection and future breakage.
- Watch for menu bar changes via accessibility or other observers (more complex).
