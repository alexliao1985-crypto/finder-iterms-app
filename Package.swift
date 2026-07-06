// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FinderLauncher",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "FinderLauncher",
            path: "Sources/FinderLauncher"
        )
    ]
)
