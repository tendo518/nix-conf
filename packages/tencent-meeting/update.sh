#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NIX_FILE="$SCRIPT_DIR/default.nix"

echo "Fetching latest Tencent Meeting version from Homebrew API..."
JSON=$(curl -sS 'https://formulae.brew.sh/api/cask/tencent-meeting.json')

# top-level entries describe the arm64 build; the x86_64 build lives in variations
ARM_VERSION_FULL=$(echo "$JSON" | jq -r '.version')                    # "3.45.2.404,5bd79d..."
INTEL_VERSION_FULL=$(echo "$JSON" | jq -r '[.variations[].version][0]')
ARM_SHA_HEX=$(echo "$JSON" | jq -r '.sha256')
INTEL_SHA_HEX=$(echo "$JSON" | jq -r '[.variations[].sha256][0]')

VERSION="${ARM_VERSION_FULL%,*}"
ARM_TOKEN="${ARM_VERSION_FULL#*,}"
INTEL_TOKEN="${INTEL_VERSION_FULL#*,}"

echo "Version: $VERSION"
echo "Computing SRI hashes..."

ARM_HASH=$(nix hash convert --hash-algo sha256 --to sri "$ARM_SHA_HEX" 2>/dev/null \
  || nix hash to-sri --type sha256 "$ARM_SHA_HEX")
INTEL_HASH=$(nix hash convert --hash-algo sha256 --to sri "$INTEL_SHA_HEX" 2>/dev/null \
  || nix hash to-sri --type sha256 "$INTEL_SHA_HEX")

echo "arm64:  $ARM_HASH"
echo "x86_64: $INTEL_HASH"

echo "Updating $NIX_FILE..."
if sed --version >/dev/null 2>&1; then
  sed -i \
    -e "s|version = \".*\";|version = \"$VERSION\";|" \
    -e "s|armToken = \".*\";|armToken = \"$ARM_TOKEN\";|" \
    -e "s|intelToken = \".*\";|intelToken = \"$INTEL_TOKEN\";|" \
    -e "s|armHash = \".*\";|armHash = \"$ARM_HASH\";|" \
    -e "s|intelHash = \".*\";|intelHash = \"$INTEL_HASH\";|" \
    "$NIX_FILE"
else
  sed -i '' \
    -e "s|version = \".*\";|version = \"$VERSION\";|" \
    -e "s|armToken = \".*\";|armToken = \"$ARM_TOKEN\";|" \
    -e "s|intelToken = \".*\";|intelToken = \"$INTEL_TOKEN\";|" \
    -e "s|armHash = \".*\";|armHash = \"$ARM_HASH\";|" \
    -e "s|intelHash = \".*\";|intelHash = \"$INTEL_HASH\";|" \
    "$NIX_FILE"
fi

echo "Done. Tencent Meeting updated to $VERSION"
