// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "GitAccountBinder",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "GitAccountBinder",
            path: "GitAccountBinder"
        ),
        .testTarget(
            name: "GitAccountBinderTests",
            dependencies: ["GitAccountBinder"],
            path: "GitAccountBinderTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
