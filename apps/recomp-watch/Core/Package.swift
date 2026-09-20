// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RecompCore",
    defaultLocalization: "es",
    platforms: [.watchOS(.v10), .iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "RecompCore", targets: ["RecompCore"])
    ],
    targets: [
        .target(name: "RecompCore"),
        .testTarget(
            name: "RecompCoreTests",
            dependencies: ["RecompCore"],
            resources: [.process("Recursos")]
        )
    ]
)
