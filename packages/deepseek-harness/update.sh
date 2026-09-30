#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../update-lib.sh"
NIX_FILE="$SCRIPT_DIR/default.nix"

# Upstream publishes no version manifest, only the unversioned "latest" DMG.
# The Homebrew cask pins the versioned .zip and bumps it on each release, so
# take version + sha256 from there.
echo "Fetching latest DeepSeek Harness version from Homebrew API..."
JSON=$(curl -sS 'https://formulae.brew.sh/api/cask/deepseek-harness.json')

VERSION=$(echo "$JSON" | jq -r '.version')
URL=$(echo "$JSON" | jq -r '.url')
SHA_HEX=$(echo "$JSON" | jq -r '.sha256')

# The derivation derives the URL from ${version}, so a changed CDN path has to
# be applied by hand instead of silently dropping out of the update.
EXPECTED_URL="https://download.deepseek.com/dsh-desk/bin/mac-arm64/deepseek-harness-${VERSION}-mac-arm64.zip"
if [ "$URL" != "$EXPECTED_URL" ]; then
  echo "error: unexpected download URL: $URL" >&2
  exit 1
fi

echo "Version: $VERSION"

HASH=$(to_sri "$SHA_HEX")

echo "Hash: $HASH"

echo "Updating $NIX_FILE..."
sed_inplace "$NIX_FILE" \
  -e "s|version = \".*\";|version = \"$VERSION\";|" \
  -e "s|hash = \"sha256-[A-Za-z0-9+/=]*\";|hash = \"$HASH\";|"

echo "Done. DeepSeek Harness updated to $VERSION"
