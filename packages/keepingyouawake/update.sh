#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NIX_FILE="$SCRIPT_DIR/default.nix"

echo "Fetching latest KeepingYouAwake version from Homebrew API..."
JSON=$(curl -sS 'https://formulae.brew.sh/api/cask/keepingyouawake.json')

VERSION=$(echo "$JSON" | jq -r '.version')
SHA_HEX=$(echo "$JSON" | jq -r '.sha256')

echo "Version: $VERSION"
echo "Computing SRI hash..."

HASH=$(nix hash convert --hash-algo sha256 --to sri "$SHA_HEX" 2>/dev/null \
  || nix hash to-sri --type sha256 "$SHA_HEX")

echo "Hash: $HASH"

echo "Updating $NIX_FILE..."
if sed --version >/dev/null 2>&1; then
  sed -i \
    -e "s|version = \".*\";|version = \"$VERSION\";|" \
    -e "s|hash = \".*\";|hash = \"$HASH\";|" \
    "$NIX_FILE"
else
  sed -i '' \
    -e "s|version = \".*\";|version = \"$VERSION\";|" \
    -e "s|hash = \".*\";|hash = \"$HASH\";|" \
    "$NIX_FILE"
fi

echo "Done. KeepingYouAwake updated to $VERSION"
