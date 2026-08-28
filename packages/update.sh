#!/usr/bin/env bash

# Update one package (`packages/update.sh <name>`) or all packages
# (`packages/update.sh`). Each package keeps its own update.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$#" -gt 0 ]; then
  scripts=()
  for name in "$@"; do
    script="$ROOT/$name/update.sh"
    if [ ! -x "$script" ]; then
      echo "error: no executable update script found for package: $name" >&2
      exit 1
    fi
    scripts+=("$script")
  done
else
  shopt -s nullglob
  scripts=("$ROOT"/*/update.sh)
fi

failures=0
for script in "${scripts[@]}"; do
  package="$(basename "$(dirname "$script")")"
  echo
  echo "===== updating package: $package ====="
  if ! bash "$script"; then
    status=$?
    echo "error: package update failed: $package (exit $status)" >&2
    failures=$((failures + 1))
  fi
done

if [ "$failures" -ne 0 ]; then
  echo "error: $failures package update(s) failed" >&2
  exit 1
fi

echo
echo "All requested package updates finished."
