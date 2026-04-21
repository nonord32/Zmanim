// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ZmanimKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "ZmanimKit", targets: ["ZmanimKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/MosheBerman/KosherCocoa", from: "3.6.0")
    ],
    targets: [
        .target(
            name: "ZmanimKit",
            dependencies: [
                .product(name: "KosherCocoa", package: "KosherCocoa")
            ]
        ),
        .testTarget(
            name: "ZmanimKitTests",
            dependencies: ["ZmanimKit"]
        )
    ]
)
