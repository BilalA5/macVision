// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "macVision",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "macVision", targets: ["macVision"])
    ],
    targets: [
        .executableTarget(name: "macVision")
    ]
)