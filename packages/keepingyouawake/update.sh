#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../update-lib.sh"
NIX_FILE="$SCRIPT_DIR/default.nix"

echo "Fetching latest KeepingYouAwake version from Homebrew API..."
JSON=$(curl -sS 'https://formulae.brew.sh/api/cask/keepingyouawake.json')

VERSION=$(echo "$JSON" | jq -r '.version')
SHA_HEX=$(echo "$JSON" | jq -r '.sha256')

echo "Version: $VERSION"
echo "Computing SRI hash..."

HASH=$(to_sri "$SHA_HEX")

echo "Hash: $HASH"

echo "Updating $NIX_FILE..."
sed_inplace "$NIX_FILE" \
  -e "s|version = \".*\";|version = \"$VERSION\";|" \
  -e "s|hash = \".*\";|hash = \"$HASH\";|"

echo "Done. KeepingYouAwake updated to $VERSION"
