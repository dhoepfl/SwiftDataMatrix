// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftDataMatrix",
    products: [
        .library(
            name: "SwiftDataMatrix",
            targets: ["SwiftDataMatrix"]),
    ],
    targets: [
        .target(
            name: "SwiftDataMatrix"),
        .testTarget(
            name: "SwiftDataMatrixTests",
            dependencies: ["SwiftDataMatrix"]),
    ],
)
