#!/usr/bin/env bash
set -euo pipefail

# MacSweep Distribution Packaging Script
# Usage:
#   ./scripts/package-release.sh                  build + versioned DMG into build/
#   ./scripts/package-release.sh --create-release  also create git tag + GitHub release (requires gh CLI)
#
# The version is read from MARKETING_VERSION in the Xcode project.
# Override with VERSION=x.y.z if needed.
#
# Optional environment variables:
#   DEVELOPER_ID_APPLICATION : "Developer ID Application: Your Name (TEAMID)"
#   APPLE_ID                 : "developer@example.com"
#   TEAM_ID                  : "ABCDE12345"
#   APP_SPECIFIC_PASSWORD    : "xxxx-xxxx-xxxx-xxxx" (or use keychain item with notarytool)
#   RELEASE_NOTES            : body text for the GitHub release (optional)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
DMG_STAGING="${BUILD_DIR}/dmg_staging"

CREATE_RELEASE=0
for arg in "$@"; do
    case "${arg}" in
        --create-release) CREATE_RELEASE=1 ;;
        *) echo "Unknown argument: ${arg}" >&2; exit 1 ;;
    esac
done

VERSION="${VERSION:-$(grep -m1 'MARKETING_VERSION = ' "${ROOT_DIR}/MacSweep.xcodeproj/project.pbxproj" | sed -E 's/.*MARKETING_VERSION = ([^;]+);.*/\1/')}"
if [[ -z "${VERSION}" || "${VERSION}" == "MARKETING_VERSION = " ]]; then
    echo "Error: could not determine version. Set VERSION=x.y.z or fix MARKETING_VERSION in the project." >&2
    exit 1
fi
echo "==> Packaging MacSweep v${VERSION}"
OUTPUT_DMG="${BUILD_DIR}/MacSweep-${VERSION}.dmg"

echo "==> Building MacSweep (Release configuration)..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}" "${DMG_STAGING}"

xcodebuild -project "${ROOT_DIR}/MacSweep.xcodeproj" \
    -scheme MacSweep \
    -configuration Release \
    -derivedDataPath "${BUILD_DIR}/DerivedData" \
    clean build

APP_PATH="${BUILD_DIR}/DerivedData/Build/Products/Release/MacSweep.app"

if [[ ! -d "${APP_PATH}" ]]; then
    echo "Error: MacSweep.app not found at ${APP_PATH}" >&2
    exit 1
fi

echo "==> Verifying binary..."
codesign -v --strict "${APP_PATH}"

# Developer ID signing if configured
if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
    echo "==> Signing with Developer ID: ${DEVELOPER_ID_APPLICATION}..."
    codesign --force --deep --options runtime \
        --sign "${DEVELOPER_ID_APPLICATION}" \
        "${APP_PATH}"
    codesign -v --strict "${APP_PATH}"
else
    echo "==> No DEVELOPER_ID_APPLICATION specified; keeping ad-hoc signature for local testing."
fi

# Notarization if credentials provided
if [[ -n "${APPLE_ID:-}" && -n "${TEAM_ID:-}" && -n "${APP_SPECIFIC_PASSWORD:-}" ]]; then
    echo "==> Submitting for Apple notarization..."
    ZIP_PATH="${BUILD_DIR}/MacSweep.zip"
    ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"
    xcrun notarytool submit "${ZIP_PATH}" \
        --apple-id "${APPLE_ID}" \
        --team-id "${TEAM_ID}" \
        --password "${APP_SPECIFIC_PASSWORD}" \
        --wait
    echo "==> Stapling notarization ticket..."
    xcrun stapler staple "${APP_PATH}"
    rm -f "${ZIP_PATH}"
else
    echo "==> Notarization credentials not provided; skipping notarization."
fi

echo "==> Preparing DMG staging..."
cp -R "${APP_PATH}" "${DMG_STAGING}/"
ln -s /Applications "${DMG_STAGING}/Applications"

echo "==> Creating DMG: ${OUTPUT_DMG}..."
hdiutil create \
    -volname "MacSweep" \
    -srcfolder "${DMG_STAGING}" \
    -ov \
    -format UDZO \
    "${OUTPUT_DMG}"

if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
    echo "==> Signing DMG..."
    codesign --sign "${DEVELOPER_ID_APPLICATION}" "${OUTPUT_DMG}"
    if [[ -n "${APPLE_ID:-}" && -n "${TEAM_ID:-}" && -n "${APP_SPECIFIC_PASSWORD:-}" ]]; then
        echo "==> Stapling DMG..."
        xcrun stapler staple "${OUTPUT_DMG}"
    fi
fi

echo "==> Verifying DMG..."
hdiutil verify "${OUTPUT_DMG}"

rm -rf "${DMG_STAGING}"
echo "==> Packaging complete! Distribution artifact: ${OUTPUT_DMG}"

if [[ "${CREATE_RELEASE}" -eq 1 ]]; then
    if ! command -v gh >/dev/null 2>&1; then
        echo "Error: --create-release requires the GitHub CLI (gh)." >&2
        echo "Install with: brew install gh" >&2
        exit 1
    fi
    if ! git -C "${ROOT_DIR}" rev-parse --git-dir >/dev/null 2>&1; then
        echo "Error: ${ROOT_DIR} is not a git repository." >&2
        exit 1
    fi

    TAG="v${VERSION}"
    if ! git -C "${ROOT_DIR}" rev-parse -q --verify "refs/tags/${TAG}" >/dev/null; then
        git -C "${ROOT_DIR}" tag -a "${TAG}" -m "MacSweep v${VERSION}"
        echo "==> Created tag ${TAG}"
    else
        echo "==> Tag ${TAG} already exists"
    fi
    git -C "${ROOT_DIR}" push origin "main" "${TAG}"

    NOTES="${RELEASE_NOTES:-MacSweep v${VERSION}}"
    gh release create "${TAG}" "${OUTPUT_DMG}" \
        --repo "${GH_REPO:-arintsohaib/MacSweep}" \
        --title "MacSweep v${VERSION}" \
        --notes "${NOTES}"
    echo "==> GitHub release created: https://github.com/${GH_REPO:-arintsohaib/MacSweep}/releases/tag/${TAG}"
fi
