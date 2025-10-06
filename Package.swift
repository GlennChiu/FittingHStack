// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "FittingHStack",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "FittingHStack",
            targets: ["FittingHStack"]
        )
    ],
    targets: [
        .target(
            name: "FittingHStack",
            dependencies: []
        )
    ]
)
