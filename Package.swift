// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MIKMIDI",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .macCatalyst(.v13),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "MIKMIDI",
            targets: ["MIKMIDI"]
        ),
    ],
    targets: [
        .target(
            name: "MIKMIDI",
            path: "Source",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("../Framework"),
                .define("MIKMIDI_SWIFT_PACKAGE", to: "1")
            ],
            linkerSettings: [
                .linkedFramework("CoreMIDI"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("AudioUnit", .when(platforms: [.macOS])),
                .linkedLibrary("xml2", .when(platforms: [.iOS, .visionOS, .macCatalyst]))
            ]
        ),
    ]
) 