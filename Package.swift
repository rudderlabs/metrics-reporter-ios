// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "<package-name>",
    platforms: [
        .iOS(.v9), .tvOS(.v10), .macOS("10.13"), .watchOS("7.0")
    ],
    products: [
        .library(
            name: "<library-name>",
            targets: ["<target-name>"]
        )
    ],
    targets: [
        .target(
            name: "<target-name>",
            path: "Sources",
            sources: ["Classes/"]
        ),
        .testTarget(
            name: "<test-target-name>",
            dependencies: ["<dependency-name>"],
            path: "Tests"
        ),
    ]
)
