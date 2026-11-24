// swift-tools-version: 5.9
// KabeBaseCore：画面（UI）に依存しない「計算エンジン」と「日本DIY規格マスタ」。
// Foundation だけで書いているので、Mac の `swift test` でも Xcode でもテストできる。
import PackageDescription

let package = Package(
    name: "KabeBaseCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KabeBaseCore", targets: ["KabeBaseCore"]),
    ],
    targets: [
        .target(name: "KabeBaseCore"),
        .testTarget(name: "KabeBaseCoreTests", dependencies: ["KabeBaseCore"]),
    ]
)
