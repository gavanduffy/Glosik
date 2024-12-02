// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "GlosikUI",
  platforms: [
    .iOS(.v16),
    .macOS(.v14),
    .visionOS(.v1)
  ],
  products: [
    .library(
      name: "GlosikUI",
      targets: ["GlosikUI"]),
  ],
  targets: [
    .target(
      name: "GlosikUI",
      dependencies: []),
    .testTarget(
      name: "GlosikUITests",
      dependencies: ["GlosikUI"]),
  ]
) 