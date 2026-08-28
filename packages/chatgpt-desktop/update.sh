#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../update-lib.sh"
NIX_FILE="$SCRIPT_DIR/default.nix"
CASK_URL="https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/c/chatgpt.rb"

echo "Fetching latest ChatGPT cask..."
CASK=$(curl -sS "$CASK_URL")

VERSION=$(echo "$CASK" | sed -nE 's/^[[:space:]]*version "([^"]+)".*/\1/p')
ARM_SHA_HEX=$(echo "$CASK" | sed -nE 's/.*sha256[[:space:]]+arm:[[:space:]]*"([0-9a-f]+)".*/\1/p')
INTEL_SHA_HEX=$(echo "$CASK" | sed -nE 's/.*intel:[[:space:]]*"([0-9a-f]+)".*/\1/p')

echo "Version: $VERSION"
echo "Computing SRI hashes..."

ARM_HASH=$(to_sri "$ARM_SHA_HEX")
INTEL_HASH=$(to_sri "$INTEL_SHA_HEX")

echo "arm64:  $ARM_HASH"
echo "x86_64: $INTEL_HASH"

echo "Updating $NIX_FILE..."
sed_inplace "$NIX_FILE" \
  -e "s|version = \".*\";|version = \"$VERSION\";|" \
  -e "s|armHash = \".*\";|armHash = \"$ARM_HASH\";|" \
  -e "s|intelHash = \".*\";|intelHash = \"$INTEL_HASH\";|"

echo "Done. ChatGPT/Codex Desktop updated to $VERSION"
