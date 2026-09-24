// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FinderLauncher",
    platforms: [.macOS(.v13)],
    targets: [
        // 纯逻辑（转义等），不依赖 AppKit，可单元测试
        .target(
            name: "LauncherCore",
            path: "Sources/LauncherCore"
        ),
        .executableTarget(
            name: "FinderLauncher",
            dependencies: ["LauncherCore"],
            path: "Sources/FinderLauncher"
        ),
        .testTarget(
            name: "LauncherCoreTests",
            dependencies: ["LauncherCore"],
            path: "Tests/LauncherCoreTests"
        )
    ]
)
