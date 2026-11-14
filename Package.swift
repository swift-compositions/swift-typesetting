// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "swift-typesetting",
    platforms: [.macOS(.v27), .iOS(.v27), .tvOS(.v27), .watchOS(.v27), .visionOS(.v27)],
    products: [
        .library(name: "Typesetting", targets: ["Typesetting"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-angle.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-byte.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-cardinal.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-direction.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-geometry.git", branch: "main", traits: ["Affine"]),
        .package(url: "https://github.com/swift-atoms/swift-matrix.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-numeric.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-vector.git", branch: "main"),
        .package(url: "https://github.com/swift-iso/swift-iso-14496-22.git", branch: "main"),
        .package(url: "https://github.com/swift-molecules/swift-layout.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Typesetting",
            dependencies: [
                .product(name: "Angle", package: "swift-angle"),
                .product(name: "Byte", package: "swift-byte"),
                .product(name: "Cardinal", package: "swift-cardinal"),
                .product(name: "Direction", package: "swift-direction"),
                .product(name: "Geometry", package: "swift-geometry"),
                .product(name: "ISO 14496-22", package: "swift-iso-14496-22"),
                .product(name: "Layout", package: "swift-layout"),
                .product(name: "Matrix", package: "swift-matrix"),
                .product(name: "Numeric", package: "swift-numeric"),
                .product(name: "Vector", package: "swift-vector"),
            ]
        ),
        .testTarget(
            name: "Typesetting Tests",
            dependencies: [
                .target(name: "Typesetting"),
                .product(name: "ISO 14496-22 Test Support", package: "swift-iso-14496-22"),
                .product(name: "Numeric", package: "swift-numeric"),
                .product(name: "Vector", package: "swift-vector"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
