#!/usr/bin/env bash
# Print the Syncthing device ID(s) of the machine(s) you point it at.
#
# The device ID is NOT generated here — it's the (immutable) fingerprint of the
# long-lived certificate each Syncthing node already has. This script just
# reports that existing ID so it can be declared in tailnet.nix.
#
# Needs sudo (reads the syncthing service log / config dir on NixOS hosts).
#
# Usage (run from this repo):
#   scripts/get-syncthing-id.sh                  # local machine only
#   scripts/get-syncthing-id.sh <user>@<host>... # over ssh (TTY so sudo can prompt)
#
# Examples:
#   scripts/get-syncthing-id.sh
#   scripts/get-syncthing-id.sh tendo@100.124.50.41 pengwy@100.66.176.74
set -uo pipefail

CONFIG_DIR=/var/lib/syncthing/.config/syncthing

# --- method 1: syncthing CLI run as the syncthing service user ---
# The CLI reads the GUI API key from its own config and prints myID from the
# running daemon. Most reliable (no journal retention concerns).
id_from_cli() {
  command -v runuser >/dev/null 2>&1 || return 1
  local j
  j="$(runuser -u syncthing -- syncthing --home="$CONFIG_DIR" cli show system 2>/dev/null)"
  local raw; raw="$(printf '%s' "$j" | grep -oE '"myID":"[A-Z2-7-]+"' | head -1 | sed -E 's/.*:"([^"]+)"/\1/')"
  [ -n "$raw" ] && { echo "$raw"; return 0; }
  return 1
}

# --- method 2: "My ID" line in the syncthing service log ---
id_from_journal() {
  command -v journalctl >/dev/null 2>&1 || return 1
  local raw
  raw="$(journalctl -u syncthing --no-pager 2>/dev/null \
    | grep -ioE 'My ?ID:[[:space:]]*[A-Z0-9]{7}(-[A-Z0-9]{7}){7}' | tail -1 \
    | grep -oE '[A-Z0-9]{7}(-[A-Z0-9]{7}){7}')"
  [ -n "$raw" ] && { echo "$raw"; return 0; }
  return 1
}

print_local_id() {
  local got=""
  got="$(id_from_cli)" && { echo "$got"; return 0; }
  got="$(id_from_journal)" && { echo "$got"; return 0; }
  echo "UNKNOWN: no syncthing CLI access and no 'My ID' in the syncthing log"
  return 1
}

# --- remote mode: re-run this whole script through sudo on each host ---
if [ "$#" -gt 0 ]; then
  for host in "$@"; do
    echo "== $host =="
    ssh -t "$host" 'sudo bash -s' < "$0"
  done
  exit 0
fi

# --- local mode (also reached at the end of the remote heredoc) ---
print_local_id