// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "AidokuRunner",
    platforms: [.macOS(.v12), .iOS(.v15)], // .tvOS(.v15), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "AidokuRunner",
            targets: ["AidokuRunner"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Skittyblock/Wasm3", branch: "main"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.10.1"),
        .package(url: "https://github.com/SimplyDanny/SwiftLintPlugins", from: "0.59.1")
    ],
    targets: [
        .target(
            name: "AidokuRunner",
            dependencies: ["Wasm3", "SwiftSoup"],
            plugins: [.plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")]
        ),

        .testTarget(
            name: "AidokuRunnerTests",
            dependencies: ["AidokuRunner"]
        )
    ],
    swiftLanguageModes: [.v6]
)
