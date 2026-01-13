#!/bin/bash
set -e

# VouchedSPM Update Script
# Syncs Vouched xcframeworks from vouched-ios CocoaPods repo to this SPM repo

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UPSTREAM_REPO="vouched/vouched-ios"
THIS_REPO="Seis-Inc/VouchedSPM"
TEMP_DIR="${REPO_ROOT}/.tmp"
VERSION_FILE="${REPO_ROOT}/version.txt"

# TensorFlowLiteSwift version (must match upstream podspec dependency)
TFLITE_VERSION="2.17.0"

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
echo "==> Downloading VouchedMobileSDK.zip..."

mkdir -p "${TEMP_DIR}"
DOWNLOAD_URL="https://github.com/${UPSTREAM_REPO}/releases/download/v${UPSTREAM_VERSION}/VouchedMobileSDK.zip"
curl -sL "${DOWNLOAD_URL}" -o "${TEMP_DIR}/VouchedMobileSDK.zip"

echo "==> Extracting xcframeworks..."
unzip -q "${TEMP_DIR}/VouchedMobileSDK.zip" -d "${TEMP_DIR}"

# Verify extraction
if [[ ! -d "${TEMP_DIR}/VouchedMobileSDK/VouchedCore.xcframework" ]]; then
    echo "ERROR: VouchedCore.xcframework not found in archive"
    exit 1
fi
if [[ ! -d "${TEMP_DIR}/VouchedMobileSDK/VouchedBarcode.xcframework" ]]; then
    echo "ERROR: VouchedBarcode.xcframework not found in archive"
    exit 1
fi

echo "==> Packaging xcframeworks for SPM..."

# Create individual zips for SPM binary targets
cd "${TEMP_DIR}/VouchedMobileSDK"
zip -rq "${TEMP_DIR}/VouchedCore.xcframework.zip" VouchedCore.xcframework
zip -rq "${TEMP_DIR}/VouchedBarcode.xcframework.zip" VouchedBarcode.xcframework
cd "${REPO_ROOT}"

# Compute checksums
CORE_CHECKSUM=$(shasum -a 256 "${TEMP_DIR}/VouchedCore.xcframework.zip" | awk '{print $1}')
BARCODE_CHECKSUM=$(shasum -a 256 "${TEMP_DIR}/VouchedBarcode.xcframework.zip" | awk '{print $1}')

echo "    VouchedCore checksum: ${CORE_CHECKSUM}"
echo "    VouchedBarcode checksum: ${BARCODE_CHECKSUM}"

echo "==> Creating GitHub release v${UPSTREAM_VERSION}..."

# Check if release already exists
if gh release view "v${UPSTREAM_VERSION}" --repo "${THIS_REPO}" &>/dev/null; then
    echo "    Release v${UPSTREAM_VERSION} already exists, deleting..."
    gh release delete "v${UPSTREAM_VERSION}" --repo "${THIS_REPO}" --yes
fi

# Create release and upload assets
gh release create "v${UPSTREAM_VERSION}" \
    --repo "${THIS_REPO}" \
    --title "v${UPSTREAM_VERSION}" \
    --notes "Synced from vouched-ios v${UPSTREAM_VERSION}" \
    "${TEMP_DIR}/VouchedCore.xcframework.zip" \
    "${TEMP_DIR}/VouchedBarcode.xcframework.zip"

echo "==> Generating Package.swift..."

cat > "${REPO_ROOT}/Package.swift" << EOF
// swift-tools-version:5.7
// Synced from vouched-ios v${UPSTREAM_VERSION}

import PackageDescription

let package = Package(
    name: "VouchedSPM",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "VouchedCore", targets: ["VouchedCoreWrapper"]),
        .library(name: "VouchedBarcode", targets: ["VouchedBarcodeWrapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kewlbear/TensorFlowLiteSwift.git", exact: "${TFLITE_VERSION}"),
    ],
    targets: [
        // Binary targets from upstream
        .binaryTarget(
            name: "VouchedCore",
            url: "https://github.com/${THIS_REPO}/releases/download/v${UPSTREAM_VERSION}/VouchedCore.xcframework.zip",
            checksum: "${CORE_CHECKSUM}"
        ),
        .binaryTarget(
            name: "VouchedBarcode",
            url: "https://github.com/${THIS_REPO}/releases/download/v${UPSTREAM_VERSION}/VouchedBarcode.xcframework.zip",
            checksum: "${BARCODE_CHECKSUM}"
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
EOF

echo "==> Updating version file..."
echo "${UPSTREAM_VERSION}" > "${VERSION_FILE}"

echo "==> Committing changes..."
cd "${REPO_ROOT}"
git add Package.swift version.txt
git commit -m "Sync with vouched-ios v${UPSTREAM_VERSION}

- VouchedCore.xcframework checksum: ${CORE_CHECKSUM}
- VouchedBarcode.xcframework checksum: ${BARCODE_CHECKSUM}
- TensorFlowLiteSwift: ${TFLITE_VERSION}"

echo "==> Pushing to remote..."
git push origin main

echo "==> Done! Updated to v${UPSTREAM_VERSION}"
echo ""
echo "To use in your project, add this SPM dependency:"
echo "  https://github.com/${THIS_REPO}.git"
