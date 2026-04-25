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
        .executable(
            name: "awstest",
            targets: ["AWSConnectorTestFlows"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/Methods.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Milieu.git", branch: "master"),
        .package(url: "https://github.com/leviouwendijk/Primitives.git", branch: "master"),

        .package(url: "https://github.com/leviouwendijk/TestFlows.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "AWSConnector",
            dependencies: [
                .product(name: "Methods", package: "Methods"),
                .product(name: "Milieu", package: "Milieu"),
                .product(name: "Primitives", package: "Primitives"),
            ]
        ),
        .executableTarget(
            name: "AWSConnectorTestFlows",
            dependencies: [
                "AWSConnector",
                .product(name: "TestFlows", package: "TestFlows"),
            ]
        ),
    ]
)
