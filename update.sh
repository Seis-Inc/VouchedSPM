#!/bin/bash
set -e

# VouchedSPM Update Script
# Syncs Vouched xcframeworks from vouched-ios CocoaPods repo to this SPM repo
# Builds TensorFlowLite.xcframework from CocoaPods to avoid version conflicts

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM_REPO="vouched/vouched-ios"
THIS_REPO="Seis-Inc/VouchedSPM"
TEMP_DIR="${REPO_ROOT}/.tmp"
VERSION_FILE="${REPO_ROOT}/version.txt"
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--force|-f]"
            exit 1
            ;;
    esac
done

cleanup() {
    rm -rf "${TEMP_DIR}"
}
trap cleanup EXIT

echo "==> Checking for updates from ${UPSTREAM_REPO}..."

# Get latest version from upstream
UPSTREAM_VERSION=$(gh api "repos/${UPSTREAM_REPO}/releases/latest" --jq '.tag_name' | sed 's/^v//')
echo "    Upstream version: ${UPSTREAM_VERSION}"

# Get current local version
if [[ -f "${VERSION_FILE}" ]]; then
    LOCAL_VERSION=$(cat "${VERSION_FILE}")
    echo "    Local version: ${LOCAL_VERSION}"
else
    LOCAL_VERSION=""
    echo "    Local version: (none)"
fi

# Compare versions
if [[ "${UPSTREAM_VERSION}" == "${LOCAL_VERSION}" ]] && [[ "${FORCE}" != "true" ]]; then
    echo "==> Already up to date (v${LOCAL_VERSION})"
    echo "    Use --force to re-release anyway"
    exit 0
fi

if [[ "${FORCE}" == "true" ]] && [[ "${UPSTREAM_VERSION}" == "${LOCAL_VERSION}" ]]; then
    echo "==> Force re-release of v${UPSTREAM_VERSION}"
else
    echo "==> New version available: ${UPSTREAM_VERSION}"
fi
mkdir -p "${TEMP_DIR}"

# =============================================================================
# Download Vouched frameworks from upstream release
# =============================================================================
echo "==> Downloading VouchedMobileSDK.zip..."
VOUCHED_URL="https://github.com/${UPSTREAM_REPO}/releases/download/v${UPSTREAM_VERSION}/VouchedMobileSDK.zip"
curl -sL "${VOUCHED_URL}" -o "${TEMP_DIR}/VouchedMobileSDK.zip"

echo "==> Extracting Vouched xcframeworks..."
unzip -q "${TEMP_DIR}/VouchedMobileSDK.zip" -d "${TEMP_DIR}"

if [[ ! -d "${TEMP_DIR}/VouchedMobileSDK/VouchedCore.xcframework" ]]; then
    echo "ERROR: VouchedCore.xcframework not found in archive"
    exit 1
fi
if [[ ! -d "${TEMP_DIR}/VouchedMobileSDK/VouchedBarcode.xcframework" ]]; then
    echo "ERROR: VouchedBarcode.xcframework not found in archive"
    exit 1
fi

# =============================================================================
# Clone vouched-ios and run pod install to get TensorFlow frameworks
# =============================================================================
echo "==> Cloning vouched-ios for CocoaPods build..."
git clone --depth 1 "https://github.com/${UPSTREAM_REPO}.git" "${TEMP_DIR}/vouched-ios"

echo "==> Running pod install..."
cd "${TEMP_DIR}/vouched-ios/Example"
pod install --repo-update 2>&1 | tail -5

# Verify TensorFlowLiteC was installed
if [[ ! -d "Pods/TensorFlowLiteC/Frameworks/TensorFlowLiteC.xcframework" ]]; then
    echo "ERROR: TensorFlowLiteC.xcframework not found after pod install"
    exit 1
fi

# =============================================================================
# Build TensorFlowLite.xcframework from CocoaPods sources
# =============================================================================
echo "==> Building TensorFlowLiteSwift for simulator..."
xcodebuild -workspace Vouched.xcworkspace \
    -scheme TensorFlowLiteSwift \
    -destination 'generic/platform=iOS Simulator' \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    build 2>&1 | tail -5

echo "==> Building TensorFlowLiteSwift for device..."
xcodebuild -workspace Vouched.xcworkspace \
    -scheme TensorFlowLiteSwift \
    -destination 'generic/platform=iOS' \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    build 2>&1 | tail -5

# Find the DerivedData path
DERIVED_DATA=$(ls -d ~/Library/Developer/Xcode/DerivedData/Vouched-* 2>/dev/null | head -1)
if [[ -z "${DERIVED_DATA}" ]]; then
    echo "ERROR: Could not find Vouched DerivedData"
    exit 1
fi

echo "==> Creating TensorFlowLite.xcframework..."
xcodebuild -create-xcframework \
    -framework "${DERIVED_DATA}/Build/Products/Release-iphoneos/TensorFlowLiteSwift/TensorFlowLite.framework" \
    -framework "${DERIVED_DATA}/Build/Products/Release-iphonesimulator/TensorFlowLiteSwift/TensorFlowLite.framework" \
    -output "${TEMP_DIR}/TensorFlowLite.xcframework"

cd "${REPO_ROOT}"

# =============================================================================
# Package all xcframeworks for SPM
# =============================================================================
echo "==> Packaging xcframeworks for SPM..."

# Vouched frameworks
cd "${TEMP_DIR}/VouchedMobileSDK"
zip -rq "${TEMP_DIR}/VouchedCore.xcframework.zip" VouchedCore.xcframework
zip -rq "${TEMP_DIR}/VouchedBarcode.xcframework.zip" VouchedBarcode.xcframework

# TensorFlowLiteC from Pods - add missing Info.plist to each framework slice
TFLITE_C_XCF="${TEMP_DIR}/vouched-ios/Example/Pods/TensorFlowLiteC/Frameworks/TensorFlowLiteC.xcframework"
for FRAMEWORK_DIR in "${TFLITE_C_XCF}"/*/TensorFlowLiteC.framework; do
    if [[ -d "${FRAMEWORK_DIR}" ]] && [[ ! -f "${FRAMEWORK_DIR}/Info.plist" ]]; then
        cat > "${FRAMEWORK_DIR}/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>TensorFlowLiteC</string>
    <key>CFBundleIdentifier</key>
    <string>org.tensorflow.TensorFlowLiteC</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>TensorFlowLiteC</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>100.0</string>
    <key>NSPrincipalClass</key>
    <string></string>
</dict>
</plist>
PLIST
    fi
done

cd "${TEMP_DIR}/vouched-ios/Example/Pods/TensorFlowLiteC/Frameworks"
zip -rq "${TEMP_DIR}/TensorFlowLiteC.xcframework.zip" TensorFlowLiteC.xcframework

# TensorFlowLite (built)
cd "${TEMP_DIR}"
zip -rq "${TEMP_DIR}/TensorFlowLite.xcframework.zip" TensorFlowLite.xcframework

cd "${REPO_ROOT}"

# Compute checksums
CORE_CHECKSUM=$(shasum -a 256 "${TEMP_DIR}/VouchedCore.xcframework.zip" | awk '{print $1}')
BARCODE_CHECKSUM=$(shasum -a 256 "${TEMP_DIR}/VouchedBarcode.xcframework.zip" | awk '{print $1}')
TFLITE_C_CHECKSUM=$(shasum -a 256 "${TEMP_DIR}/TensorFlowLiteC.xcframework.zip" | awk '{print $1}')
TFLITE_CHECKSUM=$(shasum -a 256 "${TEMP_DIR}/TensorFlowLite.xcframework.zip" | awk '{print $1}')

echo "    VouchedCore checksum: ${CORE_CHECKSUM}"
echo "    VouchedBarcode checksum: ${BARCODE_CHECKSUM}"
echo "    TensorFlowLiteC checksum: ${TFLITE_C_CHECKSUM}"
echo "    TensorFlowLite checksum: ${TFLITE_CHECKSUM}"

# =============================================================================
# Generate Package.swift
# =============================================================================
echo "==> Generating Package.swift..."

cat > "${REPO_ROOT}/Package.swift" << EOF
// swift-tools-version:5.7
// Synced from vouched-ios v${UPSTREAM_VERSION}
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
            url: "https://github.com/${THIS_REPO}/releases/download/v${UPSTREAM_VERSION}/VouchedCore.xcframework.zip",
            checksum: "${CORE_CHECKSUM}"
        ),
        .binaryTarget(
            name: "VouchedBarcodeFramework",
            url: "https://github.com/${THIS_REPO}/releases/download/v${UPSTREAM_VERSION}/VouchedBarcode.xcframework.zip",
            checksum: "${BARCODE_CHECKSUM}"
        ),
        .binaryTarget(
            name: "TensorFlowLiteC",
            url: "https://github.com/${THIS_REPO}/releases/download/v${UPSTREAM_VERSION}/TensorFlowLiteC.xcframework.zip",
            checksum: "${TFLITE_C_CHECKSUM}"
        ),
        .binaryTarget(
            name: "TensorFlowLite",
            url: "https://github.com/${THIS_REPO}/releases/download/v${UPSTREAM_VERSION}/TensorFlowLite.xcframework.zip",
            checksum: "${TFLITE_CHECKSUM}"
        ),
    ]
)
EOF

# =============================================================================
# Commit and push (BEFORE creating release so tag points to correct commit)
# =============================================================================
echo "==> Updating version file..."
echo "${UPSTREAM_VERSION}" > "${VERSION_FILE}"

echo "==> Committing changes..."
cd "${REPO_ROOT}"
git add Package.swift version.txt update.sh
git commit -m "Sync with vouched-ios v${UPSTREAM_VERSION}

All binary xcframeworks (no source compilation):
- VouchedCore.xcframework: ${CORE_CHECKSUM}
- VouchedBarcode.xcframework: ${BARCODE_CHECKSUM}
- TensorFlowLiteC.xcframework: ${TFLITE_C_CHECKSUM}
- TensorFlowLite.xcframework: ${TFLITE_CHECKSUM}"

echo "==> Pushing to remote..."
git push origin main

# =============================================================================
# Create GitHub release (AFTER commit so tag points to commit with correct checksums)
# =============================================================================
echo "==> Creating GitHub release v${UPSTREAM_VERSION}..."

if gh release view "v${UPSTREAM_VERSION}" --repo "${THIS_REPO}" &>/dev/null; then
    echo "    Release v${UPSTREAM_VERSION} already exists, deleting..."
    gh release delete "v${UPSTREAM_VERSION}" --repo "${THIS_REPO}" --yes
    git push origin :refs/tags/v${UPSTREAM_VERSION} 2>/dev/null || true
fi

gh release create "v${UPSTREAM_VERSION}" \
    --repo "${THIS_REPO}" \
    --title "v${UPSTREAM_VERSION}" \
    --notes "Synced from vouched-ios v${UPSTREAM_VERSION}

Includes:
- VouchedCore.xcframework
- VouchedBarcode.xcframework
- TensorFlowLiteC.xcframework
- TensorFlowLite.xcframework (built from CocoaPods)" \
    "${TEMP_DIR}/VouchedCore.xcframework.zip" \
    "${TEMP_DIR}/VouchedBarcode.xcframework.zip" \
    "${TEMP_DIR}/TensorFlowLiteC.xcframework.zip" \
    "${TEMP_DIR}/TensorFlowLite.xcframework.zip"

# Clean up Vouched DerivedData
rm -rf "${DERIVED_DATA}"

echo "==> Done! Updated to v${UPSTREAM_VERSION}"
echo ""
echo "To use in your project, add this SPM dependency:"
echo "  https://github.com/${THIS_REPO}.git"
