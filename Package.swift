// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "GitAccountBinder",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.10.0")
    ],
    targets: [
        .executableTarget(
            name: "GitAccountBinder",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
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
