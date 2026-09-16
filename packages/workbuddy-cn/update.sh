#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../update-lib.sh"
NIX_FILE="$SCRIPT_DIR/default.nix"
TMP_DMG="/tmp/workbuddy-cn_update.dmg"

# WorkBuddy has no Homebrew cask, so read Tencent's own update API. It reports
# the newest macOS build and hands out a .zip URL; the DMG is the same artifact
# with the extension swapped.
echo "Fetching latest WorkBuddy version from codebuddy.cn..."
JSON=$(curl -sS 'https://www.codebuddy.cn/v2/update?platform=workbuddy-darwin-arm64')

VERSION=$(echo "$JSON" | jq -r '.version')
URL=$(echo "$JSON" | jq -r '.url' | sed -e 's/\.zip$/.dmg/')

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
  -e "s|version = \".*\";|version = \"$VERSION\";|" \
  -e "s|url = \".*\";|url = \"$URL\";|" \
  -e "s|hash = \".*\";|hash = \"$HASH\";|"

echo "Done. WorkBuddy updated to $VERSION"
