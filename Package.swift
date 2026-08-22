// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "APIQuotaDashboard",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "APIQuotaDashboard",
            path: "Sources/APIQuotaDashboard"
        ),
        .testTarget(
            name: "APIQuotaDashboardTests",
            dependencies: ["APIQuotaDashboard"]
        )
    ]
)
