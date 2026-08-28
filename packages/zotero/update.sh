#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../update-lib.sh"
NIX_FILE="$SCRIPT_DIR/default.nix"
CASK_URL="https://raw.githubusercontent.com/Homebrew/homebrew-cask/master/Casks/z/zotero.rb"

echo "Fetching latest Zotero cask..."
CASK=$(curl -sS "$CASK_URL")

VERSION=$(echo "$CASK" | sed -nE 's/^[[:space:]]*version "([^"]+)".*/\1/p')
SHA_HEX=$(echo "$CASK" | sed -nE 's:.*sha256[[:space:]]+"([0-9a-f]+)".*:\1:p')

if [ -z "$VERSION" ] || [ -z "$SHA_HEX" ]; then
  echo "Could not parse version/sha256 from cask" >&2
  exit 1
fi

echo "Version: $VERSION"
echo "Computing SRI hash..."

HASH=$(to_sri "$SHA_HEX")

echo "Hash: $HASH"

echo "Updating $NIX_FILE..."
sed_inplace "$NIX_FILE" \
  -e "s|version = \".*\";|version = \"$VERSION\";|" \
  -e "s|hash = \"sha256-[A-Za-z0-9+/=]*\";|hash = \"$HASH\";|"

echo "Done. Zotero updated to $VERSION"
