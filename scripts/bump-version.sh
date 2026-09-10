#!/usr/bin/env bash
set -euo pipefail

# MacSweep Version Bump Script
# Usage: ./scripts/bump-version.sh <new-version>
# Example: ./scripts/bump-version.sh 0.2.0
#
# Updates MARKETING_VERSION in the Xcode project for all build configurations.
# Remember to commit the change and tag the release (see README, "Releasing a new version").

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
PBX="${ROOT_DIR}/MacSweep.xcodeproj/project.pbxproj"

NEW_VERSION="${1:-}"
if [[ -z "${NEW_VERSION}" ]]; then
    echo "Usage: $0 <new-version> (e.g. 0.2.0)" >&2
    exit 1
fi

if [[ ! "${NEW_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: version must be in X.Y.Z form (e.g. 0.2.0), got '${NEW_VERSION}'" >&2
    exit 1
fi

if [[ ! -f "${PBX}" ]]; then
    echo "Error: project file not found at ${PBX}" >&2
    exit 1
fi

OLD_VERSION="$(grep -m1 'MARKETING_VERSION = ' "${PBX}" | sed -E 's/.*MARKETING_VERSION = ([^;]+);.*/\1/')"

if [[ "${OLD_VERSION}" == "${NEW_VERSION}" ]]; then
    echo "MARKETING_VERSION is already ${NEW_VERSION}; nothing to do."
    exit 0
fi

LC_ALL=C sed -i '' -E "s/MARKETING_VERSION = [0-9]+\.[0-9]+\.[0-9]+/MARKETING_VERSION = ${NEW_VERSION}/g" "${PBX}"

COUNT="$(grep -c "MARKETING_VERSION = ${NEW_VERSION};" "${PBX}")"
echo "==> Bumped MARKETING_VERSION: ${OLD_VERSION} -> ${NEW_VERSION} (${COUNT} build configurations updated)"
echo "==> Next steps:"
echo "    git add -A && git commit -m \"Release ${NEW_VERSION}\""
echo "    ./scripts/package-release.sh"
echo "    git tag -a v${NEW_VERSION} -m \"MacSweep v${NEW_VERSION}\""
echo "    git push origin main v${NEW_VERSION}"
