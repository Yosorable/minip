// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MinipRuntime",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(name: "MinipRuntime", targets: ["MinipRuntime"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        .package(url: "https://github.com/agisboye/SwiftLMDB", from: "2.0.0"),
        .package(url: "https://github.com/swhitty/FlyingFox.git", from: "0.20.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
        .package(url: "https://github.com/Yosorable/ProgressHUD.git", branch: "master"),
        .package(url: "https://github.com/weichsel/ZIPFoundation", from: "0.9.19"),
    ],
    targets: [
        .target(
            name: "MinipRuntime",
            dependencies: [
                "Alamofire",
                "SwiftLMDB",
                "Kingfisher",
                "ProgressHUD",
                "ZIPFoundation",
                .product(name: "FlyingFox", package: "FlyingFox"),
                .product(name: "FlyingSocks", package: "FlyingFox"),
            ],
            path: "ios/Sources/MinipRuntime",
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)
