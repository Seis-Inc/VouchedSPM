// swift-tools-version:5.7
// Synced from vouched-ios v1.9.9
// TensorFlowLite built from CocoaPods (no external dependencies)

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
            checksum: "fbfbb26c6f725b7b3ed91bcd1cb27b77d48f1dc769663c72f358a175f7347066"
        ),
        .binaryTarget(
            name: "TensorFlowLite",
            url: "https://github.com/Seis-Inc/VouchedSPM/releases/download/v1.9.9/TensorFlowLite.xcframework.zip",
            checksum: "11ade2a1f73422c43478786015b5f60986069a83f35505a2f4c8b65ec2aa2420"
        ),
    ]
)
