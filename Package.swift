// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "DeskCal",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .target(name: "DeskCalCore"),
        .executableTarget(
            name: "DeskCal",
            dependencies: ["DeskCalCore"]
        ),
        .testTarget(
            name: "DeskCalTests",
            dependencies: ["DeskCalCore"]
        ),
    ]
)
