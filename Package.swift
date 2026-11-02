// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "OverlapCore",
  platforms: [.macOS(.v13)],
  products: [.library(name: "OverlapCore", targets: ["OverlapCore"])],
  targets: [
    .target(name: "OverlapCore"),
    .testTarget(name: "OverlapCoreTests", dependencies: ["OverlapCore"]),
  ]
)
