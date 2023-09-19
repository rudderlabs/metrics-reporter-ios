// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "MetricsReporter",
    platforms: [
        .iOS(.v12), .tvOS(.v11), .macOS("10.13"), .watchOS("7.0")
    ],
    products: [
        .library(
            name: "MetricsReporter",
            targets: ["MetricsReporter"]
        )
    ],
    dependencies: [
        .package(name: "RudderKit", url: "https://github.com/rudderlabs/rudder-ios-kit", from: "1.4.0"),
        .package(name: "RSCrashReporter", url: "https://github.com/rudderlabs/crash-reporter-ios", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "MetricsReporter",
            dependencies: [
                .product(name: "RudderKit", package: "RudderKit"),
                .product(name: "RSCrashReporter", package: "RSCrashReporter"),
            ],
            path: "Sources",
            sources: ["Classes/"]
        ),
        .testTarget(
            name: "MetricsReporterTests",
            dependencies: ["MetricsReporter", "RudderKit", "RSCrashReporter"],
            path: "MetricsReporterTests"
        ),
    ]
)
