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
    targets: [
        .target(name: "ZmanimKit"),
        .testTarget(
            name: "ZmanimKitTests",
            dependencies: ["ZmanimKit"]
        )
    ]
)
