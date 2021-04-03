// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Authorization",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        .library(name: "Authorization", targets: ["Authorization"])
    ],
    dependencies: [
        .package(name: "Mocker", url: "https://github.com/andybezaire/Mocker.git", from: "2.3.0"),
        .package(name: "CombineExtras", url: "https://github.com/andybezaire/CombineExtras.git", from: "1.2.0")
    ],
    targets: [
        .target(name: "Authorization", dependencies: ["CombineExtras"]),
        .target(name: "AuthorizationTestUtils", dependencies: ["Authorization"], path: "Tests/AuthorizationTestUtils"),
        .testTarget(name: "AuthorizationTests", dependencies: ["Authorization", "AuthorizationTestUtils", "Mocker"])
    ]
)
