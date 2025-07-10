#!/usr/bin/env python3
"""Sync modules/network/tailnet.nix with current `tailscale status`.

Usage:
    tailscale status | python3 scripts/update-tailnet-hosts.py [--dry-run]
    python3 scripts/update-tailnet-hosts.py [--dry-run]

Only machines that already live in this repo (a directory under
modules/hosts/<name>, or already listed in tailnet.nix) are kept. Unrelated
tailnet devices are skipped so they never end up in every machine's
/etc/hosts.
"""

import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
TAILNET_NIX = REPO / "modules" / "network" / "tailnet.nix"
HOSTS_DIR = REPO / "modules" / "hosts"

LIST_START = "  tailnetHosts = ["
LIST_END = "  ];"

# One list entry: { name = "x"; ip = "1.2.3.4"; sshUser = "u"; }
ENTRY_RE = re.compile(
    r'name\s*=\s*"([^"]+)"\s*;\s*ip\s*=\s*"([^"]+)"\s*;\s*sshUser\s*=\s*"([^"]+)"',
    re.S,
)


def run_tailscale_status() -> str:
    result = subprocess.run(["tailscale", "status"], capture_output=True, text=True)
    if result.returncode != 0:
        print("error: `tailscale status` failed:", file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        sys.exit(1)
    return result.stdout


def parse_status(output: str) -> dict[str, str]:
    """hostname -> tailscale IP, ignoring status headers and non-100.x lines."""
    devices = {}
    for line in output.strip().splitlines():
        if not line.strip():
            continue
        parts = line.split()
        if len(parts) < 2 or not parts[0].startswith("100."):
            continue
        devices[parts[1].rstrip(".")] = parts[0]
    return devices


def read_existing() -> dict[str, dict]:
    """name -> { ip, sshUser } from the current tailnet.nix list."""
    text = TAILNET_NIX.read_text()
    entries = {}
    for match in ENTRY_RE.finditer(text):
        entries[match.group(1)] = {
            "ip": match.group(2),
            "sshUser": match.group(3),
        }
    return entries


def host_user(name: str, existing: dict[str, dict]) -> str:
    if name in existing:
        return existing[name]["sshUser"]
    default_nix = HOSTS_DIR / name / "default.nix"
    if default_nix.exists():
        match = re.search(r'user\s*=\s*\{\s*name\s*=\s*"([^"]+)"', default_nix.read_text(), re.S)
        if match:
            return match.group(1)
    return "tendo"


def render_list(entries: list[dict]) -> str:
    lines = [LIST_START]
    for entry in sorted(entries, key=lambda e: e["name"]):
        lines.extend(
            [
                "    {",
                f'      name = "{entry["name"]}";',
                f'      ip = "{entry["ip"]}";',
                f'      sshUser = "{entry["sshUser"]}";',
                "    }",
            ]
        )
    lines.append(LIST_END)
    return "\n".join(lines)


def main() -> None:
    dry_run = "--dry-run" in sys.argv
    status = sys.stdin.read() if not sys.stdin.isatty() else run_tailscale_status()
    live = parse_status(status)
    existing = read_existing()

    names = set(existing) | {p.name for p in HOSTS_DIR.iterdir() if p.is_dir()}
    relevant = sorted(names & set(live))
    skipped = sorted(set(live) - set(relevant))

    entries = [
        {
            "name": name,
            "ip": live[name],
            "sshUser": host_user(name, existing),
        }
        for name in relevant
    ]

    text = TAILNET_NIX.read_text()
    start = text.index(LIST_START)
    end = text.index(LIST_END, start) + len(LIST_END)
    new_text = text[:start] + render_list(entries) + text[end:]

    if new_text == text:
        print(f"unchanged {TAILNET_NIX}: {len(entries)} hosts ({len(skipped)} skipped)")
    elif dry_run:
        print(f"would update {TAILNET_NIX}: {len(entries)} hosts ({len(skipped)} skipped)")
        print(new_text)
    else:
        TAILNET_NIX.write_text(new_text)
        print(f"updated {TAILNET_NIX}: {len(entries)} hosts ({len(skipped)} skipped)")

    if skipped:
        print("skipped (not in repo): " + ", ".join(skipped))


if __name__ == "__main__":
    main()
