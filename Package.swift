// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ContinuityPanel",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ContinuityPanel", targets: ["ContinuityPanel"])
    ],
    targets: [
        .executableTarget(
            name: "ContinuityPanel",
            path: "Sources/ContinuityPanel",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "ContinuityPanelTests",
            dependencies: ["ContinuityPanel"],
            path: "Tests/ContinuityPanelTests"
        )
    ]
)
