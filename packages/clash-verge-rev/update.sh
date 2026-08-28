#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../update-lib.sh"
NIX_FILE="$SCRIPT_DIR/default.nix"

echo "Fetching latest Clash Verge Rev version from Homebrew API..."
JSON=$(curl -sS 'https://formulae.brew.sh/api/cask/clash-verge-rev.json')

VERSION=$(echo "$JSON" | jq -r '.version')
ARM_SHA_HEX=$(echo "$JSON" | jq -r '.sha256')
# Intel build: every macOS variation shares the same intel url+sha256
INTEL_SHA_HEX=$(echo "$JSON" | jq -r '[.variations[].sha256][0]')

echo "Version: $VERSION"
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

echo "Done. Clash Verge Rev updated to $VERSION"
