// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HaltungCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "HaltungCore", targets: ["HaltungCore"])
    ],
    targets: [
        .target(
            name: "HaltungCore",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "HaltungCoreTests",
            dependencies: ["HaltungCore"],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
