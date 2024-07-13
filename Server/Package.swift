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
        .package(url: "https://github.com/Malien/raw-dawg.swift", from: "0.2.0"),
        .package(url: "https://github.com/chrisaljoudi/swift-log-oslog.git", from: "0.2.1"),
        .package(path: "../Interface"),
        .package(url: "https://github.com/apple/swift-system.git", revision: "318d2159d1441c8daadd1fb19e457f5ece598de4")
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
                .product(name: "SystemPackage", package: "swift-system")
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
