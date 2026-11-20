#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../update-lib.sh"
NIX_FILE="$SCRIPT_DIR/default.nix"

echo "Fetching latest FlClash release from GitHub..."
RELEASE_JSON=$(curl -sS https://api.github.com/repos/chen08209/FlClash/releases/latest)
VERSION=$(echo "$RELEASE_JSON" | jq -r '.tag_name | sub("^v"; "")')

if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
  echo "Could not find the FlClash release version" >&2
  exit 1
fi

echo "Version: $VERSION"
ARM_SHA_HEX=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | endswith("-macos-arm64.dmg")) | .digest | sub("^sha256:"; "")')
INTEL_SHA_HEX=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name | endswith("-macos-amd64.dmg")) | .digest | sub("^sha256:"; "")')

if [ -z "$ARM_SHA_HEX" ] || [ -z "$INTEL_SHA_HEX" ]; then
  echo "Could not find macOS asset hashes in the FlClash release" >&2
  exit 1
fi

echo "Computing SRI hashes..."
ARM_HASH=$(to_sri "$ARM_SHA_HEX")
INTEL_HASH=$(to_sri "$INTEL_SHA_HEX")

echo "arm:   $ARM_HASH"
echo "intel: $INTEL_HASH"

echo "Updating $NIX_FILE..."
sed_inplace "$NIX_FILE" \
  -e "s|version = \".*\";|version = \"$VERSION\";|" \
  -e "s|armHash = \".*\";|armHash = \"$ARM_HASH\";|" \
  -e "s|intelHash = \".*\";|intelHash = \"$INTEL_HASH\";|"

echo "Done. FlClash updated to $VERSION"
