// swift-tools-version:5.0

import PackageDescription

let package = Package.init(
    name: "Clappr",
    platforms: [
        .tvOS(.v11)
    ],
    products: [
        .library(
            name: "Clappr",
            targets: [
                "ClapprObjC",
                "Clappr"
            ]
        )
    ],
    targets: [
        .target(
            name: "ClapprObjC"
        ),
        .target(
            name: "Clappr",
            dependencies: [
                "ClapprObjC",
            ],
            path: ".",
            exclude: [
                "Sources/ClapprObjC",
                "Sources/Clappr_iOS"
            ],
            sources: [
                "Sources/Clappr",
                "Sources/Clappr_tvOS"
            ]
        )
    ]
)
