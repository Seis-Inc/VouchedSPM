# VouchedSPM

Swift Package Manager distribution of [Vouched](https://github.com/vouched/vouched-ios) iOS SDK.

The official Vouched SDK is distributed via CocoaPods only. This repository repackages it as SPM-compatible binary xcframeworks, enabling use in projects that don't use CocoaPods.

## Installation

Add the package dependency to your Xcode project:

```
https://github.com/Seis-Inc/VouchedSPM.git
```

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Seis-Inc/VouchedSPM.git", from: "1.9.9"),
]
```

## Usage

Import the framework in your Swift code:

```swift
import VouchedCore

// For barcode scanning support
import VouchedBarcode
```

## Available Products

| Product | Description |
|---------|-------------|
| `VouchedCore` | Core ID verification and selfie capture |
| `VouchedBarcode` | Barcode scanning support (includes VouchedCore) |

## What's Included

Each release bundles these xcframeworks:

- **VouchedCore.xcframework** - Core verification SDK
- **VouchedBarcode.xcframework** - Barcode scanning extension
- **TensorFlowLiteC.xcframework** - TensorFlow Lite C library
- **TensorFlowLite.xcframework** - TensorFlow Lite Swift wrapper

All frameworks are pre-built binaries. No source compilation is required, which avoids iOS deployment target conflicts with other SPM packages.

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## Updating

This repository tracks the upstream [vouched-ios](https://github.com/vouched/vouched-ios) releases.

To sync with a new upstream version, run:

```bash
./update.sh
```

The script will:
1. Check for new versions from vouched-ios
2. Download VouchedCore and VouchedBarcode xcframeworks
3. Clone vouched-ios and run `pod install` to get TensorFlow dependencies
4. Build TensorFlowLite.xcframework from CocoaPods sources
5. Package and upload all xcframeworks to a GitHub release
6. Update `Package.swift` with new checksums
7. Commit and push changes

### Script Requirements

- `gh` CLI (authenticated with repo write access)
- `pod` (CocoaPods)
- `xcodebuild` (Xcode Command Line Tools)

## Version Mapping

| VouchedSPM | vouched-ios | TensorFlowLite |
|------------|-------------|----------------|
| 1.9.9      | 1.9.9       | 2.17.0         |

## License

The Vouched SDK is proprietary software. See the [upstream repository](https://github.com/vouched/vouched-ios) for licensing information.

TensorFlow Lite is licensed under the Apache 2.0 License.

## Links

- [Vouched iOS SDK](https://github.com/vouched/vouched-ios)
- [Vouched Documentation](https://docs.vouched.id/)
