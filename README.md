# GridBar

A native macOS app that displays all menu bar applications in a clean grid view and lets you activate them with a single click.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-silver)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![License](https://img.shields.io/badge/License-MIT-blue)

## Features

- **Grid view** — Scans and displays every running menu bar app in a responsive adaptive grid.
- **One-click activation** — Tap any app icon to open (and close) its menu bar item, just like a real click.
- **Auto-refresh** — The scan runs on launch and repeats every 8 seconds, keeping the grid in sync with your menu bar.
- **Onboarding flow** — Guides you through the one-time Accessibility permission grant with a polished UI.
- **Detail view** — Inspect an app's bundle ID, PID, and type by selecting "Show Info".
- **System item filtering** — Filters out background agents and helpers while keeping genuine menu bar extras (Wi-Fi, Control Center, Siri, etc.).

## How It Works

GridBar uses **Apple's Accessibility API (AXUIElement)** to locate status items on the menu bar, computes their screen coordinates, and posts real `CGEvent` mouse click events. This means the opened menus behave exactly like a physical click — you can dismiss them by clicking elsewhere.

## Requirements

- macOS 14 Sonoma or later
- Accessibility permission (granted via the onboarding screen or System Settings)

## Installation

Build and install GridBar using the included install script:

```bash
# Release build (default)
./install.command

# Debug build
./install.command --debug

# Build, install, and open immediately
./install.command --open
```

The app is installed to `~/Applications/GridBar.app` and ad-hoc signed for immediate launch.

### Manual build

```bash
swift build -c release
```

The built executable is at `.build/release/GridBar`. You can assemble a `.app` bundle manually or use Xcode's `project.yml` for a full build.

## Usage

1. Launch **GridBar**.
2. Grant **Accessibility** permission when prompted on the onboarding screen.
3. Browse the grid of menu bar apps.
4. **Click** any icon to toggle its menu bar item.
5. Right-click (or Control-click) for a context menu with **Activate App** and **Show Info**.

Keyboard shortcut: press **R** to re-scan the menu bar.

## Project Structure

```
GridBar/
├── Sources/GridBar/
│   ├── GridBarApp.swift        # App entry point & root view
│   ├── ContentView.swift       # Main grid UI
│   ├── DetailView.swift        # App info sheet
│   ├── OnboardingView.swift    # Permission onboarding flow
│   ├── PermissionManager.swift # Accessibility permission state
│   ├── MenuBarScanner.swift    # Scans running menu bar apps
│   ├── MenuBarActivator.swift  # AX-based click simulation
│   ├── MenuBarItem.swift       # Data model
│   ├── Info.plist              # App metadata
│   └── GridBar.entitlements    # Code entitlements
├── project.yml                 # Project configuration (XcodeGen)
└── install.command             # Build & install script
```

## License

MIT License — see [LICENSE](LICENSE) for details.
Copyright © 2025 Namuan.
