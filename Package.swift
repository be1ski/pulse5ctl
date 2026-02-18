// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "pulse5ctl",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "pulse5ctl", targets: ["pulse5ctl"])
    ],
    targets: [
        .target(
            name: "CoreElm",
            path: "Sources/core/elm"
        ),
        .target(
            name: "CorePlatform",
            path: "Sources/core/platform"
        ),
        .target(
            name: "FeaturePulseDomain",
            dependencies: ["CorePlatform"],
            path: "Sources/feature/pulse/domain"
        ),
        .target(
            name: "FeaturePulseData",
            dependencies: ["FeaturePulseDomain"],
            path: "Sources/feature/pulse/data"
        ),
        .target(
            name: "FeaturePulsePresentation",
            dependencies: ["CoreElm", "FeaturePulseDomain"],
            path: "Sources/feature/pulse/presentation"
        ),
        .target(
            name: "FeatureHomescreen",
            dependencies: ["FeaturePulseData", "FeaturePulsePresentation"],
            path: "Sources/feature/homescreen"
        ),
        .executableTarget(
            name: "pulse5ctl",
            dependencies: ["FeatureHomescreen", "FeaturePulseDomain"],
            path: "Sources/app/macos",
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/app/macos/Info.plist",
                ])
            ]
        )
    ]
)
