// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GridBar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "GridBar",
            path: "GridBar/Sources/GridBar",
            exclude: ["Info.plist", "GridBar.entitlements"]
        )
    ]
)
