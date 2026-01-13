// swift-tools-version:5.7
// Synced from vouched-ios v1.9.9

import PackageDescription

let package = Package(
    name: "VouchedSPM",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "VouchedCore", targets: ["VouchedCoreWrapper"]),
        .library(name: "VouchedBarcode", targets: ["VouchedBarcodeWrapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kewlbear/TensorFlowLiteSwift.git", exact: "2.17.0"),
    ],
    targets: [
        // Binary targets from upstream
        .binaryTarget(
            name: "VouchedCore",
            url: "https://github.com/Seis-Inc/VouchedSPM/releases/download/v1.9.9/VouchedCore.xcframework.zip",
            checksum: "0d7b885d43ddafa02ed59b57433a8da4379eccd3210f7bb96f963d1fd54bb7bc"
        ),
        .binaryTarget(
            name: "VouchedBarcode",
            url: "https://github.com/Seis-Inc/VouchedSPM/releases/download/v1.9.9/VouchedBarcode.xcframework.zip",
            checksum: "0a384bc3048b45ef544ce8a025488a092a8dcc2b4271e537d990b3509de1832f"
        ),
        // Wrapper targets to link dependencies
        .target(
            name: "VouchedCoreWrapper",
            dependencies: [
                "VouchedCore",
                .product(name: "TensorFlowLiteSwift", package: "TensorFlowLiteSwift"),
            ],
            path: "Sources/VouchedCoreWrapper"
        ),
        .target(
            name: "VouchedBarcodeWrapper",
            dependencies: [
                "VouchedBarcode",
                "VouchedCoreWrapper",
            ],
            path: "Sources/VouchedBarcodeWrapper"
        ),
    ]
)
