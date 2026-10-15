// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ShySharing",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ShySharing",
            path: "Sources/ShySharing",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
            ]
        ),
    ]
)
