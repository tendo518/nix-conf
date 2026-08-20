#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NIX_FILE="$SCRIPT_DIR/default.nix"
CASK_URL="https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/c/chatgpt.rb"

echo "Fetching latest ChatGPT cask..."
CASK=$(curl -sS "$CASK_URL")

VERSION=$(echo "$CASK" | sed -nE 's/^[[:space:]]*version "([^"]+)".*/\1/p')
ARM_SHA_HEX=$(echo "$CASK" | sed -nE 's/.*sha256[[:space:]]+arm:[[:space:]]*"([0-9a-f]+)".*/\1/p')
INTEL_SHA_HEX=$(echo "$CASK" | sed -nE 's/.*intel:[[:space:]]*"([0-9a-f]+)".*/\1/p')

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
    -e "s|armHash = \".*\";|armHash = \"$ARM_HASH\";|" \
    -e "s|intelHash = \".*\";|intelHash = \"$INTEL_HASH\";|" \
    "$NIX_FILE"
else
  sed -i '' \
    -e "s|version = \".*\";|version = \"$VERSION\";|" \
    -e "s|armHash = \".*\";|armHash = \"$ARM_HASH\";|" \
    -e "s|intelHash = \".*\";|intelHash = \"$INTEL_HASH\";|" \
    "$NIX_FILE"
fi

echo "Done. ChatGPT/Codex Desktop updated to $VERSION"
