// swift-tools-version:5.7
// Synced from vouched-ios v1.9.9
// TensorFlowLite v2.17.0 bundled (no external dependencies)

import PackageDescription

let package = Package(
    name: "VouchedSPM",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "VouchedCore", targets: ["VouchedCoreFramework", "TensorFlowLite", "TensorFlowLiteC"]),
        .library(name: "VouchedBarcode", targets: ["VouchedBarcodeFramework", "VouchedCoreFramework", "TensorFlowLite", "TensorFlowLiteC"]),
    ],
    targets: [
        .binaryTarget(
            name: "VouchedCoreFramework",
            url: "https://github.com/Seis-Inc/VouchedSPM/releases/download/v1.9.9/VouchedCore.xcframework.zip",
            checksum: "0d7b885d43ddafa02ed59b57433a8da4379eccd3210f7bb96f963d1fd54bb7bc"
        ),
        .binaryTarget(
            name: "VouchedBarcodeFramework",
            url: "https://github.com/Seis-Inc/VouchedSPM/releases/download/v1.9.9/VouchedBarcode.xcframework.zip",
            checksum: "0a384bc3048b45ef544ce8a025488a092a8dcc2b4271e537d990b3509de1832f"
        ),
        .binaryTarget(
            name: "TensorFlowLiteC",
            url: "https://github.com/Seis-Inc/VouchedSPM/releases/download/v1.9.9/TensorFlowLiteC.xcframework.zip",
            checksum: "aaf799a6bd82500a6d4f5445a886ff0024a43c6a1fbbbdaa048470a4b9d90432"
        ),
        .binaryTarget(
            name: "TensorFlowLite",
            url: "https://github.com/Seis-Inc/VouchedSPM/releases/download/v1.9.9/TensorFlowLite.xcframework.zip",
            checksum: "02bc182e39462456a5a310b32f7698eef33f25047c3a9c032bbf606eb2445d45"
        ),
    ]
)
