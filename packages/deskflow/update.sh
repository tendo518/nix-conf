#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../update-lib.sh"
NIX_FILE="$SCRIPT_DIR/default.nix"
# Deskflow ships its own tap (not in homebrew-cask), so read the cask directly.
CASK_URL="https://raw.githubusercontent.com/deskflow/homebrew-tap/main/Casks/d/deskflow.rb"

echo "Fetching latest Deskflow cask from homebrew-tap..."
CASK=$(curl -sS "$CASK_URL")

VERSION=$(echo "$CASK" | sed -nE 's/^[[:space:]]*version "([^"]+)".*/\1/p')
ARM_SHA_HEX=$(echo "$CASK" | sed -nE 's/.*sha256[[:space:]]+arm:[[:space:]]*"([0-9a-f]+)".*/\1/p')
INTEL_SHA_HEX=$(echo "$CASK" | sed -nE 's/.*intel:[[:space:]]*"([0-9a-f]+)".*/\1/p')

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

echo "Done. Deskflow updated to $VERSION"
