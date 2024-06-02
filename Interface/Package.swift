// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "messenger-interface",
    products: [
        .library(
            name: "MessengerInterface",
            targets: ["MessengerInterface"]),
    ],
    targets: [
        .target(
            name: "MessengerInterface"),
    ]
)
