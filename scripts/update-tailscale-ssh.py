#!/usr/bin/env python3
"""Update modules/core/ssh.nix with current tailscale status.

Usage:
    tailscale status | python3 scripts/update-tailscale-ssh.py
    python3 scripts/update-tailscale-ssh.py
"""

import re
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SSH_NIX = REPO / "modules" / "core" / "ssh.nix"
HOSTS_DIR = REPO / "modules" / "hosts"


def run_tailscale_status() -> str:
    result = subprocess.run(["tailscale", "status"], capture_output=True, text=True)
    if result.returncode != 0:
        print("error: tailscale status failed", file=sys.stderr)
        sys.exit(1)
    return result.stdout


def parse_status(output: str) -> list[dict]:
    devices = []
    for line in output.strip().splitlines():
        if not line.strip():
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        devices.append({
            "ip": parts[0],
            "hostname": parts[1].rstrip("."),
            "offline": "offline" in line.lower(),
        })
    return devices


def get_host_user(hostname: str) -> str:
    for name in (hostname, hostname.split(".")[0]):
        host_dir = HOSTS_DIR / name
        if host_dir.is_dir():
            default_nix = host_dir / "default.nix"
            if default_nix.exists():
                m = re.search(r'name\s*=\s*"([^"]+)"', default_nix.read_text())
                if m:
                    return m.group(1)
    return "tendo"


def generate_block(devices: list[dict]) -> str:
    lines = ["          # Tailscale devices"]
    for d in sorted(devices, key=lambda d: d["hostname"]):
        user = get_host_user(d["hostname"])
        indent = "          " if not d["offline"] else "          # "
        lines.extend([
            f'{indent}"{d["hostname"]}.tailscale" = {{',
            f'{indent}  Hostname = "{d["ip"]}";',
            f'{indent}  User = "{user}";',
            f'{indent}  IdentityFile = "~/.ssh/id_ed25519";',
            f'{indent}}};',
        ])
    return "\n".join(lines)


def main() -> None:
    status_output = sys.stdin.read() if not sys.stdin.isatty() else run_tailscale_status()
    devices = parse_status(status_output)
    if not devices:
        print("error: no tailscale devices found", file=sys.stderr)
        sys.exit(1)

    new_block = generate_block(devices)
    content = SSH_NIX.read_text()

    marker = "          # Tailscale devices"
    if marker not in content:
        print(f"error: '{marker}' not found in {SSH_NIX}", file=sys.stderr)
        sys.exit(1)

    before = content[: content.index(marker)]
    # Find settings closing: "        };" at 8-space indent, after the marker
    rest = content[content.index(marker):]
    close = "\n        };"
    if close not in rest:
        print("error: cannot find settings closing brace", file=sys.stderr)
        sys.exit(1)

    end_idx = rest.index(close)
    new_content = before + new_block + rest[end_idx:]
    SSH_NIX.write_text(new_content)

    active = sum(1 for d in devices if not d["offline"])
    offline = sum(1 for d in devices if d["offline"])
    print(f"Updated {SSH_NIX}: {active} active, {offline} offline ({len(devices)} total)")


if __name__ == "__main__":
    main()
