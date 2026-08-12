#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NIX_FILE="$SCRIPT_DIR/linux.nix"
BASE_URL="https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Fetching latest ChatGPT Linux packages..."
curl -L --fail --silent --show-error "$BASE_URL/chatgpt_amd64.deb" \
  -o "$TMP_DIR/chatgpt_amd64.deb"
curl -L --fail --silent --show-error "$BASE_URL/chatgpt_arm64.deb" \
  -o "$TMP_DIR/chatgpt_arm64.deb"

VERSION="$(dpkg-deb -f "$TMP_DIR/chatgpt_amd64.deb" Version)"
ARM_VERSION="$(dpkg-deb -f "$TMP_DIR/chatgpt_arm64.deb" Version)"
if [[ "$VERSION" != "$ARM_VERSION" ]]; then
  echo "amd64 version ($VERSION) differs from arm64 version ($ARM_VERSION)" >&2
  exit 1
fi

AMD64_HASH="$(nix hash file --type sha256 --sri "$TMP_DIR/chatgpt_amd64.deb")"
ARM64_HASH="$(nix hash file --type sha256 --sri "$TMP_DIR/chatgpt_arm64.deb")"

echo "Version: $VERSION"
echo "amd64:   $AMD64_HASH"
echo "arm64:   $ARM64_HASH"
echo "Updating $NIX_FILE..."

if sed --version >/dev/null 2>&1; then
  sed -i \
    -e "s|version = \".*\";|version = \"$VERSION\";|" \
    -e "s|amd64Hash = \".*\";|amd64Hash = \"$AMD64_HASH\";|" \
    -e "s|arm64Hash = \".*\";|arm64Hash = \"$ARM64_HASH\";|" \
    "$NIX_FILE"
else
  sed -i '' \
    -e "s|version = \".*\";|version = \"$VERSION\";|" \
    -e "s|amd64Hash = \".*\";|amd64Hash = \"$AMD64_HASH\";|" \
    -e "s|arm64Hash = \".*\";|arm64Hash = \"$ARM64_HASH\";|" \
    "$NIX_FILE"
fi

echo "Done. ChatGPT Linux updated to $VERSION"
