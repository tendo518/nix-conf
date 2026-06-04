#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NIX_FILE="$SCRIPT_DIR/default.nix"
TMP_DMG="/tmp/skimpdf_update.dmg"

echo "Fetching latest Skim version from Homebrew API..."
JSON=$(curl -sS 'https://formulae.brew.sh/api/cask/skim.json')

VERSION=$(echo "$JSON" | jq -r '.version')   # e.g. "1.7.15"
URL=$(echo "$JSON" | jq -r '.url')

echo "Version: $VERSION"
echo "URL: $URL"

echo "Downloading DMG..."
curl -sS -L -o "$TMP_DMG" "$URL"

echo "Computing SRI hash..."
HASH=$(nix hash file "$TMP_DMG" 2>/dev/null || nix --extra-experimental-features nix-command hash file "$TMP_DMG")

rm -f "$TMP_DMG"

echo "Hash: $HASH"

echo "Updating $NIX_FILE..."
if sed --version >/dev/null 2>&1; then
  sed -i \
    -e "s/version = \".*\";/version = \"$VERSION\";/" \
    -e "s|hash = \".*\";|hash = \"$HASH\";|" \
    "$NIX_FILE"
else
  sed -i '' \
    -e "s/version = \".*\";/version = \"$VERSION\";/" \
    -e "s|hash = \".*\";|hash = \"$HASH\";|" \
    "$NIX_FILE"
fi

echo "Done. Skim updated to $VERSION"
