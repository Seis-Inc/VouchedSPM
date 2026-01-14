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
            checksum: "8a2c190607bf8db1c07bd5efea7eb4e00510045facfc9031b29bd7020fd0cb9e"
        ),
        .binaryTarget(
            name: "TensorFlowLite",
            url: "https://github.com/Seis-Inc/VouchedSPM/releases/download/v1.9.9/TensorFlowLite.xcframework.zip",
            checksum: "4717e153003d809a19c80b3e01f3244e5ab640e1f221f0b7a6b297d589074c7d"
        ),
    ]
)
