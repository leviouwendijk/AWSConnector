// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AWSConnector",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AWSConnector",
            targets: ["AWSConnector"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/plate.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "AWSConnector",
            dependencies: [
                .product(name: "plate", package: "plate"),
            ]
        ),
        .testTarget(
            name: "AWSConnectorTests",
            dependencies: ["AWSConnector"]
        ),
    ]
)
