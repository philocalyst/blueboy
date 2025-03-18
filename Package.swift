// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "bluetooth",
    platforms: [
        .macOS(.v12) // Specify the minimum macOS version if applicable
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .executable(
            name: "bluetooth", // Keep the executable name as "bluetooth"
            targets: ["bluetooth"]), // Update the target name to match the product name
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "bluetooth",
            dependencies: [.product(name: "ArgumentParser", package: "swift-argument-parser")]), // Update the target name to "bluetooth"
    ]
)
