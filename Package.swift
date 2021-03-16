// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Authentication",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(name: "Authentication", targets: ["Authentication"]),
    ],
    dependencies: [
        .package(name: "Mocker", url: "https://github.com/WeTransfer/Mocker.git", from: "2.3.0"),
        .package(name: "CombineExtras", url: "https://github.com/andybezaire/CombineExtras.git", from: "1.2.0")
    ],
    targets: [
        .target(name: "Authentication", dependencies: ["CombineExtras"]),
        .target(name: "AuthenticationTestUtils", dependencies: ["Authentication"], path: "Tests/AuthenticationTestUtils"),
        .testTarget(name: "AuthenticationTests", dependencies: ["Authentication", "AuthenticationTestUtils", "Mocker"]),
    ]
)
