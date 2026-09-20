// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RyRCore",
    defaultLocalization: "es",
    platforms: [.watchOS(.v10), .iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "RyRCore", targets: ["RyRCore"])
    ],
    targets: [
        .target(name: "RyRCore"),
        .testTarget(name: "RyRCoreTests", dependencies: ["RyRCore"])
    ]
)
