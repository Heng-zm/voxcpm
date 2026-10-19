// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CloneVoice",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18), // Base platform compatibility layer with iOS 26 forward APIs
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "CloneVoice",
            targets: ["CloneVoice"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CloneVoice",
            dependencies: [],
            path: "Sources/CloneVoice",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency=complete"),
                .define("SWIFT_STRICT_CONCURRENCY"),
                .define("SWIFT_PACKAGE")
            ]
        ),
        .testTarget(
            name: "CloneVoiceTests",
            dependencies: ["CloneVoice"],
            path: "Tests/CloneVoiceTests",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency=complete")
            ]
        )
    ]
)
