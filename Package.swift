// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "mp4Clipper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "mp4Clipper", targets: ["mp4Clipper"])
    ],
    targets: [
        .executableTarget(
            name: "mp4Clipper",
            path: "Sources/mp4Clipper"
        )
    ]
)
