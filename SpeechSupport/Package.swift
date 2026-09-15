// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpeechSupport",
    platforms: [
        .iOS(.v15),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SpeechSupport",
            targets: ["SpeechSupport"]
        )
    ],
    targets: [
        .target(
            name: "SpeechSupport",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "SpeechSupportTests",
            dependencies: ["SpeechSupport"]
        )
    ]
)
