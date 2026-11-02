// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Sprout",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-nio.git",
            from: "2.81.0"
        ),
    ],
    targets: [
        .executableTarget(
            name: "Sprout",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
            ]
        ),
    ]
)
