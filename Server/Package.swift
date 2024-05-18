// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "messanger-api",
    platforms: [
        .macOS(.v13),
        .iOS(.v13) // This doesn't make any sense!
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.3"),
        .package(url: "https://github.com/Malien/raw-dawg.swift", from: "0.0.5"),
        .package(url: "https://github.com/chrisaljoudi/swift-log-oslog.git", from: "0.2.1")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "RawDawg", package: "raw-dawg.swift"),
                .product(name: "LoggingOSLog", package: "swift-log-oslog", condition: .when(platforms: [.macOS]))
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            swiftSettings: swiftSettings
        ),
    ]
)

var swiftSettings: [SwiftSetting] {
    [
        .enableUpcomingFeature("DisableOutwardActorInference"),
        .enableExperimentalFeature("StrictConcurrency"),
    ]
}
