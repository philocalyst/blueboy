// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Blue",
  platforms: [
    .macOS(.v10_15)
  ],
  products: [
    .executable(
      name: "bboy",
      targets: ["BlueBoy"])
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    .package(url: "https://github.com/apple/swift-log.git", from: "1.4.0"),
    .package(url: "https://github.com/philocalyst/BlueKit.git", from: "0.6.8"),
  ],
  targets: [
    .executableTarget(
      name: "BlueBoy",
      dependencies: [
        "BlueKit",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Logging", package: "swift-log"),
      ])
  ]
)
