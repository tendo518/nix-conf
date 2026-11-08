#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../update-lib.sh"
NIX_FILE="$SCRIPT_DIR/default.nix"

echo "Fetching latest gwfox commit..."
GH_API_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
AUTH_HEADER=()
if [ -n "$GH_API_TOKEN" ]; then
  AUTH_HEADER=(-H "Authorization: Bearer $GH_API_TOKEN")
fi
JSON=$(curl -fsSL --retry 3 "${AUTH_HEADER[@]}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/akkva/gwfox/commits/main)

REV=$(echo "$JSON" | jq -r '.sha')
DATE=$(echo "$JSON" | jq -r '.commit.committer.date' | cut -dT -f1)
HASH=$(nix flake prefetch --json "github:akkva/gwfox/$REV" | jq -r '.hash')

echo "Revision: $REV"
echo "Date: $DATE"
echo "Hash: $HASH"

sed_inplace "$NIX_FILE" \
  -e "s|version = \".*\";|version = \"unstable-$DATE\";|" \
  -e "s|rev = \".*\";|rev = \"$REV\";|" \
  -e "s|hash = \".*\";|hash = \"$HASH\";|"

echo "Done. gwfox updated to $REV"
