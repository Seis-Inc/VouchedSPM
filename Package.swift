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
            checksum: "4c9e888c7a1fc074bd68acbea91404c83f392f9b8e75a93ddee2f862a43733f3"
        ),
        .binaryTarget(
            name: "TensorFlowLite",
            url: "https://github.com/Seis-Inc/VouchedSPM/releases/download/v1.9.9/TensorFlowLite.xcframework.zip",
            checksum: "7254a6fdbacb336e9c8f7db26ae08d447ed681952185ab1765781e1e05504edc"
        ),
    ]
)
