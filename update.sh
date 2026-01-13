#!/bin/bash
set -e

# VouchedSPM Update Script
# Syncs Vouched xcframeworks from vouched-ios CocoaPods repo to this SPM repo
# Bundles TensorFlowLite to avoid external dependency version conflicts

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM_REPO="vouched/vouched-ios"
THIS_REPO="Seis-Inc/VouchedSPM"
TEMP_DIR="${REPO_ROOT}/.tmp"
VERSION_FILE="${REPO_ROOT}/version.txt"
TFLITE_SOURCES_DIR="${REPO_ROOT}/Sources/TensorFlowLite"

# TensorFlowLite version (must match upstream podspec dependency)
TFLITE_VERSION="2.17.0"
TFLITE_C_REPO="kewlbear/TensorFlowLiteC"
TFLITE_SWIFT_REPO="kewlbear/TensorFlowLiteSwift"

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
if [[ "${UPSTREAM_VERSION}" == "${LOCAL_VERSION}" ]]; then
    echo "==> Already up to date (v${LOCAL_VERSION})"
    exit 0
fi

echo "==> New version available: ${UPSTREAM_VERSION}"
mkdir -p "${TEMP_DIR}"

# =============================================================================
# Download Vouched frameworks
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
# Download TensorFlowLiteC xcframework
# =============================================================================
echo "==> Downloading TensorFlowLiteC.xcframework (v${TFLITE_VERSION})..."
TFLITE_C_URL="https://github.com/${TFLITE_C_REPO}/releases/download/${TFLITE_VERSION}/TensorFlowLiteC.xcframework.zip"
curl -sL "${TFLITE_C_URL}" -o "${TEMP_DIR}/TensorFlowLiteC.xcframework.zip"

echo "==> Extracting TensorFlowLiteC..."
unzip -q "${TEMP_DIR}/TensorFlowLiteC.xcframework.zip" -d "${TEMP_DIR}"

if [[ ! -d "${TEMP_DIR}/TensorFlowLiteC.xcframework" ]]; then
    echo "ERROR: TensorFlowLiteC.xcframework not found"
    exit 1
fi

# =============================================================================
# Get TensorFlowLiteSwift sources
# =============================================================================
echo "==> Cloning TensorFlowLiteSwift sources..."
git clone --depth 1 --branch "${TFLITE_VERSION}" "https://github.com/${TFLITE_SWIFT_REPO}.git" "${TEMP_DIR}/TensorFlowLiteSwift" 2>/dev/null || \
git clone --depth 1 "https://github.com/${TFLITE_SWIFT_REPO}.git" "${TEMP_DIR}/TensorFlowLiteSwift"

# Copy TensorFlowLiteSwift sources to our repo
echo "==> Updating TensorFlowLiteSwift sources in repo..."
rm -rf "${TFLITE_SOURCES_DIR}"
mkdir -p "${TFLITE_SOURCES_DIR}"
cp -R "${TEMP_DIR}/TensorFlowLiteSwift/Sources/TensorFlowLite/"* "${TFLITE_SOURCES_DIR}/"

# =============================================================================
# Package xcframeworks for SPM
# =============================================================================
echo "==> Packaging xcframeworks for SPM..."

cd "${TEMP_DIR}/VouchedMobileSDK"
zip -rq "${TEMP_DIR}/VouchedCore.xcframework.zip" VouchedCore.xcframework
zip -rq "${TEMP_DIR}/VouchedBarcode.xcframework.zip" VouchedBarcode.xcframework
cd "${TEMP_DIR}"
zip -rq "${TEMP_DIR}/TensorFlowLiteC.xcframework.zip" TensorFlowLiteC.xcframework
cd "${REPO_ROOT}"

# Compute checksums
CORE_CHECKSUM=$(shasum -a 256 "${TEMP_DIR}/VouchedCore.xcframework.zip" | awk '{print $1}')
BARCODE_CHECKSUM=$(shasum -a 256 "${TEMP_DIR}/VouchedBarcode.xcframework.zip" | awk '{print $1}')
TFLITE_C_CHECKSUM=$(shasum -a 256 "${TEMP_DIR}/TensorFlowLiteC.xcframework.zip" | awk '{print $1}')

echo "    VouchedCore checksum: ${CORE_CHECKSUM}"
echo "    VouchedBarcode checksum: ${BARCODE_CHECKSUM}"
echo "    TensorFlowLiteC checksum: ${TFLITE_C_CHECKSUM}"

# =============================================================================
# Create GitHub release
# =============================================================================
echo "==> Creating GitHub release v${UPSTREAM_VERSION}..."

if gh release view "v${UPSTREAM_VERSION}" --repo "${THIS_REPO}" &>/dev/null; then
    echo "    Release v${UPSTREAM_VERSION} already exists, deleting..."
    gh release delete "v${UPSTREAM_VERSION}" --repo "${THIS_REPO}" --yes
fi

gh release create "v${UPSTREAM_VERSION}" \
    --repo "${THIS_REPO}" \
    --title "v${UPSTREAM_VERSION}" \
    --notes "Synced from vouched-ios v${UPSTREAM_VERSION}

Includes:
- VouchedCore.xcframework
- VouchedBarcode.xcframework
- TensorFlowLiteC.xcframework (v${TFLITE_VERSION})
- TensorFlowLiteSwift sources (v${TFLITE_VERSION})" \
    "${TEMP_DIR}/VouchedCore.xcframework.zip" \
    "${TEMP_DIR}/VouchedBarcode.xcframework.zip" \
    "${TEMP_DIR}/TensorFlowLiteC.xcframework.zip"

# =============================================================================
# Generate Package.swift
# =============================================================================
echo "==> Generating Package.swift..."

cat > "${REPO_ROOT}/Package.swift" << EOF
// swift-tools-version:5.7
// Synced from vouched-ios v${UPSTREAM_VERSION}
// TensorFlowLite v${TFLITE_VERSION} bundled (no external dependencies)

import PackageDescription

let package = Package(
    name: "VouchedSPM",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "VouchedCore", targets: ["VouchedCoreWrapper"]),
        .library(name: "VouchedBarcode", targets: ["VouchedBarcodeWrapper"]),
    ],
    targets: [
        // Binary targets
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
        // TensorFlowLite Swift wrapper (sources bundled in repo)
        .target(
            name: "TensorFlowLite",
            dependencies: ["TensorFlowLiteC"],
            path: "Sources/TensorFlowLite",
            exclude: ["LICENSE", "README.md"]
        ),
        // Vouched wrapper targets
        .target(
            name: "VouchedCoreWrapper",
            dependencies: ["VouchedCoreFramework", "TensorFlowLite"],
            path: "Sources/VouchedCoreWrapper"
        ),
        .target(
            name: "VouchedBarcodeWrapper",
            dependencies: ["VouchedBarcodeFramework", "VouchedCoreWrapper"],
            path: "Sources/VouchedBarcodeWrapper"
        ),
    ]
)
EOF

# =============================================================================
# Commit and push
# =============================================================================
echo "==> Updating version file..."
echo "${UPSTREAM_VERSION}" > "${VERSION_FILE}"

echo "==> Committing changes..."
cd "${REPO_ROOT}"
git add Package.swift version.txt Sources/TensorFlowLite
git commit -m "Sync with vouched-ios v${UPSTREAM_VERSION}

Bundled dependencies (no external SPM packages):
- VouchedCore.xcframework: ${CORE_CHECKSUM}
- VouchedBarcode.xcframework: ${BARCODE_CHECKSUM}
- TensorFlowLiteC.xcframework: ${TFLITE_C_CHECKSUM}
- TensorFlowLiteSwift sources: v${TFLITE_VERSION}"

echo "==> Pushing to remote..."
git push origin main

echo "==> Done! Updated to v${UPSTREAM_VERSION}"
echo ""
echo "To use in your project, add this SPM dependency:"
echo "  https://github.com/${THIS_REPO}.git"
