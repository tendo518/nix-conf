#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../update-lib.sh"
NIX_FILE="$SCRIPT_DIR/default.nix"

echo "Fetching latest GWfox-T commit..."
JSON=$(curl -sS https://api.github.com/repos/akkva/GWfox-T/commits/main)

REV=$(echo "$JSON" | jq -r '.sha')
DATE=$(echo "$JSON" | jq -r '.commit.committer.date' | cut -dT -f1)
HASH=$(nix flake prefetch --json "github:akkva/GWfox-T/$REV" | jq -r '.hash')

echo "Revision: $REV"
echo "Date: $DATE"
echo "Hash: $HASH"

sed_inplace "$NIX_FILE" \
  -e "s|version = \".*\";|version = \"unstable-$DATE\";|" \
  -e "s|rev = \".*\";|rev = \"$REV\";|" \
  -e "s|hash = \".*\";|hash = \"$HASH\";|"

echo "Done. GWfox-T updated to $REV"
