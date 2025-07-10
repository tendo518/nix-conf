#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../update-lib.sh"
NIX_FILE="$SCRIPT_DIR/default.nix"
TMP_DMG="/tmp/ticktick_update.dmg"

echo "Fetching latest TickTick version from Homebrew API..."
JSON=$(curl -sS 'https://formulae.brew.sh/api/cask/ticktick.json')

VERSION_FULL=$(echo "$JSON" | jq -r '.version')   # e.g. "8.0.60,468"
URL=$(echo "$JSON" | jq -r '.url')

VERSION="${VERSION_FULL%,*}"   # "8.0.60"
BUILD="${VERSION_FULL#*,}"    # "468"

echo "Version: $VERSION (build $BUILD)"
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
  -e "s|url = \".*\";|url = \"$URL\";|" \
  -e "s|hash = \".*\";|hash = \"$HASH\";|"

echo "Done. TickTick updated to $VERSION (build $BUILD)"
