# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

This repository repackages the [Vouched iOS SDK](https://github.com/vouched/vouched-ios) (CocoaPods-only) as Swift Package Manager binary xcframeworks. It bundles TensorFlowLite to avoid version conflicts with other SPM packages.

## Key Commands

### Sync with upstream vouched-ios release
```bash
./update.sh
```

This script:
1. Checks for new versions from vouched-ios
2. Downloads VouchedCore/VouchedBarcode xcframeworks from upstream release
3. Clones vouched-ios, runs `pod install`, builds TensorFlowLite.xcframework
4. Uploads all 4 xcframeworks to a GitHub release
5. Regenerates `Package.swift` with new checksums
6. Commits and pushes

**Requirements:** `gh` CLI (authenticated), `pod`, `xcodebuild`

## Architecture

This is a **binary-only SPM package** - no Swift source files to compile.

**Package.swift** exposes two products:
- `VouchedCore` → links VouchedCoreFramework + TensorFlowLite + TensorFlowLiteC
- `VouchedBarcode` → links VouchedBarcodeFramework + VouchedCore dependencies

**GitHub releases** contain 4 xcframeworks:
- `VouchedCore.xcframework` - from upstream release
- `VouchedBarcode.xcframework` - from upstream release
- `TensorFlowLiteC.xcframework` - from CocoaPods
- `TensorFlowLite.xcframework` - built from CocoaPods TensorFlowLiteSwift sources

## Why Binary-Only

TensorFlowLite must be pre-built because:
1. SPM uses the lowest iOS deployment target across all packages in the dependency graph
2. Many popular packages specify iOS 13, but VouchedCore requires iOS 15+
3. Source targets would fail with "compiling for iOS 13.0, but module has minimum deployment target of iOS 15.0"
4. Binary xcframeworks bypass SPM compilation entirely

## Version Tracking

- `version.txt` contains the current synced version
- Versions match upstream vouched-ios tags (e.g., `1.9.9`)
