// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "native_push",
    platforms: [
        .iOS("13.0"),
        .macOS("10.15")
    ],
    products: [
        .library(name: "native-push", targets: ["native_push"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "native_push",
            dependencies: [],
            resources: []
        )
    ]
)