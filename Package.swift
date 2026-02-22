// swift-tools-version: 5.10
import PackageDescription

let strictConcurrency: [SwiftSetting] = [
    .enableUpcomingFeature("StrictConcurrency"),
    .unsafeFlags(["-warnings-as-errors"]),
]

let package = Package(
    name: "pulse5ctl",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "pulse5ctl", targets: ["pulse5ctl"])
    ],
    targets: [
        .target(
            name: "CoreElm",
            path: "Sources/core/elm",
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "CorePlatform",
            path: "Sources/core/platform",
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "CoreLocalization",
            path: "Sources/core/localization",
            resources: [.process("Resources")],
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "FeaturePulseDomain",
            dependencies: ["CorePlatform", "CoreLocalization"],
            path: "Sources/feature/pulse/domain",
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "FeaturePulseData",
            dependencies: ["FeaturePulseDomain", "CoreLocalization"],
            path: "Sources/feature/pulse/data",
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "FeaturePulsePresentation",
            dependencies: ["CoreElm", "FeaturePulseDomain", "CoreLocalization"],
            path: "Sources/feature/pulse/presentation",
            swiftSettings: strictConcurrency
        ),
        .target(
            name: "FeatureHomescreen",
            dependencies: ["FeaturePulseData", "FeaturePulsePresentation"],
            path: "Sources/feature/homescreen",
            swiftSettings: strictConcurrency
        ),
        .executableTarget(
            name: "pulse5ctl",
            dependencies: ["FeatureHomescreen", "FeaturePulseDomain"],
            path: "Sources/app/macos",
            exclude: ["Info.plist"],
            swiftSettings: strictConcurrency,
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/app/macos/Info.plist",
                ])
            ]
        ),
        .testTarget(
            name: "CoreElmTests",
            dependencies: ["CoreElm"],
            path: "Tests/CoreElmTests",
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "PulseProtocolTests",
            dependencies: ["FeaturePulseData", "FeaturePulseDomain"],
            path: "Tests/PulseProtocolTests",
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "PulseReducerTests",
            dependencies: ["CoreElm", "FeaturePulsePresentation", "FeaturePulseDomain"],
            path: "Tests/PulseReducerTests",
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "PulseDomainTests",
            dependencies: ["FeaturePulseDomain", "FeaturePulseData", "CoreLocalization"],
            path: "Tests/PulseDomainTests",
            swiftSettings: strictConcurrency
        ),
        .testTarget(
            name: "PulseDataTests",
            dependencies: ["FeaturePulseData"],
            path: "Tests/PulseDataTests",
            swiftSettings: strictConcurrency
        ),
    ]
)
