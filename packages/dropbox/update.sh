#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NIX_FILE="$SCRIPT_DIR/default.nix"

echo "Fetching latest Dropbox version from Homebrew API..."
JSON=$(curl -sS 'https://formulae.brew.sh/api/cask/dropbox.json')

VERSION=$(echo "$JSON" | jq -r '.version')
ARM_SHA_HEX=$(echo "$JSON" | jq -r '.sha256')
# Intel build: every macOS variation shares the same intel url+sha256
INTEL_SHA_HEX=$(echo "$JSON" | jq -r '[.variations[].sha256][0]')

echo "Version: $VERSION"
echo "Computing SRI hashes..."

ARM_HASH=$(nix hash convert --hash-algo sha256 --to sri "$ARM_SHA_HEX" 2>/dev/null \
  || nix hash to-sri --type sha256 "$ARM_SHA_HEX")
INTEL_HASH=$(nix hash convert --hash-algo sha256 --to sri "$INTEL_SHA_HEX" 2>/dev/null \
  || nix hash to-sri --type sha256 "$INTEL_SHA_HEX")

echo "arm:   $ARM_HASH"
echo "intel: $INTEL_HASH"

echo "Updating $NIX_FILE..."
sed -i \
  -e "s|version = \".*\";|version = \"$VERSION\";|" \
  -e "s|armHash = \".*\";|armHash = \"$ARM_HASH\";|" \
  -e "s|intelHash = \".*\";|intelHash = \"$INTEL_HASH\";|" \
  "$NIX_FILE"

echo "Done. Dropbox updated to $VERSION"
