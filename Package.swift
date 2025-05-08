// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "Blue",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "BlueKit",
            targets: ["BlueKit"]),
        .executable(
            name: "blueutil",
            targets: ["Blue"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
    ],
    targets: [
        .target(
            name: "BlueKit",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]),
        .executableTarget(
            name: "Blue",
            dependencies: [
                "BlueKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
            ]),
    ]
)
