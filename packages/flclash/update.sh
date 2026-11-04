#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../update-lib.sh"
NIX_FILE="$SCRIPT_DIR/default.nix"

echo "Fetching latest FlClash release from GitHub..."
RELEASE_JSON=$(curl -sS https://api.github.com/repos/chen08209/FlClash/releases/latest)
VERSION=$(echo "$RELEASE_JSON" | jq -r '.tag_name | sub("^v"; "")')
SUMS_URL=$(echo "$RELEASE_JSON" | jq -r '.assets[] | select(.name == "SHA256SUMS") | .browser_download_url')

if [ -z "$VERSION" ] || [ "$VERSION" = "null" ] || [ -z "$SUMS_URL" ] || [ "$SUMS_URL" = "null" ]; then
  echo "Could not find the FlClash release version or SHA256SUMS asset" >&2
  exit 1
fi

echo "Version: $VERSION"
SUMS=$(curl -sS -L "$SUMS_URL")
ARM_SHA_HEX=$(echo "$SUMS" | awk '/macos-arm64\.dmg$/ { print $1 }')
INTEL_SHA_HEX=$(echo "$SUMS" | awk '/macos-amd64\.dmg$/ { print $1 }')

if [ -z "$ARM_SHA_HEX" ] || [ -z "$INTEL_SHA_HEX" ]; then
  echo "Could not find macOS hashes in SHA256SUMS" >&2
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
