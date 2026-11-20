// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AWSConnectorTests",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "awstest",
            targets: ["AWSConnectorTestFlows"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/leviouwendijk/TestFlows.git", branch: "master"),
        .package(path: ".."),
    ],
    targets: [
        .executableTarget(
            name: "AWSConnectorTestFlows",
            dependencies: [
                .product(name: "AWSConnector", package: "AWSConnector"),
                .product(name: "TestFlows", package: "TestFlows"),
            ]
        ),
    ]
)
