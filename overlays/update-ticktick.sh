#!/usr/bin/env bash
set -euo pipefail

# Update script for TickTick macOS overlay
# Usage: ./update-ticktick.sh <version> <build_num>
# Example: ./update-ticktick.sh 8.0.30 464

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERLAY_FILE="$SCRIPT_DIR/ticktick.nix"

if [ $# -lt 2 ]; then
    echo "Usage: $0 <version> <build_num>"
    echo "Example: $0 8.0.30 464"
    echo ""
    echo "Current version in overlay:"
    grep "version = " "$OVERLAY_FILE" | head -1
    exit 1
fi

version="$1"
build_num="$2"

dmg_url="https://download.ticktick.app/download/mac/TickTick_${version}_${build_num}.dmg"

echo "=== TickTick Overlay Updater ==="
echo ""
echo "Version: $version (build $build_num)"
echo "URL: $dmg_url"
echo ""
echo "Downloading DMG to calculate hash..."

# Get the hash using nix-prefetch-url
hash=$(nix-prefetch-url --type sha256 "$dmg_url" 2>&1 | tail -1)

# Convert to SRI format
sri_hash=$(nix hash to-sri --type sha256 "$hash" 2>/dev/null)

echo ""
echo "New hash: $sri_hash"
echo ""
echo "Updating $OVERLAY_FILE..."

# Update the overlay file
sed -i '' "s/version = \"[^\"]*\";/version = \"$version\";/" "$OVERLAY_FILE"
sed -i '' "s|TickTick_[^\"]*|TickTick_${version}_${build_num}|" "$OVERLAY_FILE"
sed -i '' "s/hash = \"[^\"]*\";/hash = \"$sri_hash\";/" "$OVERLAY_FILE"

echo ""
echo "Done! Changes:"
git diff "$OVERLAY_FILE"
echo ""
echo "To build and test: just build-darwin laptop-solar-modoka"
