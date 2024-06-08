// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "messenger-server",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),  // This doesn't make any sense!
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.99.3"),
        .package(url: "https://github.com/Malien/raw-dawg.swift", exact: "0.1.1"),
        .package(url: "https://github.com/chrisaljoudi/swift-log-oslog.git", from: "0.2.1"),
        .package(path: "../Interface"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "RawDawg", package: "raw-dawg.swift"),
                .product(
                    name: "LoggingOSLog", package: "swift-log-oslog",
                    condition: .when(platforms: [.macOS])),
                .product(name: "MessengerInterface", package: "Interface"),
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
