#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
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

HASH=$(nix hash convert --hash-algo sha256 --to sri "$SHA_HEX" 2>/dev/null \
  || nix hash to-sri --type sha256 "$SHA_HEX")
[ -n "$HASH" ] || HASH="sha256-$(printf '%s' "$SHA_HEX" | xxd -r -p | base64)"

echo "Hash: $HASH"

echo "Updating $NIX_FILE..."
if sed --version >/dev/null 2>&1; then
  sed -i \
    -e "s|version = \".*\";|version = \"$VERSION\";|" \
    -e "s|hash = \"sha256-[A-Za-z0-9+/=]*\";|hash = \"$HASH\";|" \
    "$NIX_FILE"
else
  sed -i '' \
    -e "s|version = \".*\";|version = \"$VERSION\";|" \
    -e "s|hash = \"sha256-[A-Za-z0-9+/=]*\";|hash = \"$HASH\";|" \
    "$NIX_FILE"
fi

echo "Done. Zotero updated to $VERSION"