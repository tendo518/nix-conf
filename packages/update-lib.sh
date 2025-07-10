#!/usr/bin/env bash

# Shared helpers for the per-package update scripts under packages/.
set -euo pipefail

# Portable in-place sed. GNU sed accepts `sed -i ...`, while BSD sed
# requires an explicit empty backup suffix: `sed -i '' ...`.
sed_inplace() {
  local file="$1"
  shift

  if sed --version >/dev/null 2>&1; then
    sed -i "$@" "$file"
  else
    sed -i '' "$@" "$file"
  fi
}

# Convert a hexadecimal sha256 (as used by Homebrew) into the SRI form
# accepted by Nix fetchurl. Works with both the modern and legacy CLI.
to_sri() {
  local hex="$1"

  if [ -z "$hex" ]; then
    echo "error: empty sha256" >&2
    return 1
  fi

  if nix hash convert --hash-algo sha256 --to sri "$hex" 2>/dev/null; then
    return 0
  fi

  nix hash to-sri --type sha256 "$hex" 2>/dev/null
}

# Hash a downloaded file with the active Nix CLI.
hash_file() {
  local file="$1"

  if nix hash file "$file" 2>/dev/null; then
    return 0
  fi

  nix --extra-experimental-features nix-command hash file "$file"
}
