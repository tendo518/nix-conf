#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../update-lib.sh"
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
HASH=$(hash_file "$TMP_DMG")

rm -f "$TMP_DMG"

echo "Hash: $HASH"

echo "Updating $NIX_FILE..."
sed_inplace "$NIX_FILE" \
  -e "s/version = \".*\";/version = \"$VERSION\";/" \
  -e "s|hash = \".*\";|hash = \"$HASH\";|"

echo "Done. Skim updated to $VERSION"
