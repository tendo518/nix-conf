#!/usr/bin/env python3
"""Generate nvfetcher entries for vendor APIs that do not expose stable URL schemas."""

from __future__ import annotations

import json
import sys
import time
import tomllib
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def fetch_json(url: str) -> dict:
    request = urllib.request.Request(url, headers={"User-Agent": "nix-conf-updater"})
    last_error: Exception | None = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                return json.load(response)
        except Exception as error:  # network and upstream JSON failures are retryable
            last_error = error
            if attempt < 2:
                time.sleep(attempt + 1)
    raise RuntimeError(f"failed to fetch {url}: {last_error}")


def toml_value(value: str | bool) -> str:
    if isinstance(value, bool):
        return str(value).lower()
    return json.dumps(value, ensure_ascii=False)


def dynamic_entry(version: str, url: str) -> dict:
    return {
        "src": {"manual": version},
        "fetch": {"url": url, "force": True},
    }


def render_config(entries: dict[str, dict]) -> str:
    lines: list[str] = []
    for name, fields in entries.items():
        lines.append(f"[{name}]")
        for section, values in fields.items():
            for key, value in values.items():
                lines.append(f"{section}.{key} = {toml_value(value)}")
        lines.append("")
    return "\n".join(lines)


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {Path(sys.argv[0]).name} OUTPUT", file=sys.stderr)
        return 2

    output = Path(sys.argv[1])
    dynamic_entries: dict[str, dict] = {}

    ticktick = fetch_json("https://formulae.brew.sh/api/cask/ticktick.json")
    dynamic_entries["ticktick"] = dynamic_entry(
        ticktick["version"].split(",", 1)[0],
        ticktick["url"],
    )

    tencent = fetch_json("https://formulae.brew.sh/api/cask/tencent-meeting.json")
    tencent_version = tencent["version"].split(",", 1)[0]
    tencent_x86 = next(
        value["url"]
        for value in tencent["variations"].values()
        if "x86_64" in value.get("url", "")
    )
    dynamic_entries["tencent-meeting-arm64"] = dynamic_entry(
        tencent_version, tencent["url"]
    )
    dynamic_entries["tencent-meeting-amd64"] = dynamic_entry(
        tencent_version, tencent_x86
    )

    workbuddy = fetch_json(
        "https://www.codebuddy.cn/v2/update?platform=workbuddy-darwin-arm64"
    )
    workbuddy_url = workbuddy["url"]
    if not workbuddy_url.endswith(".zip"):
        raise RuntimeError(f"unexpected WorkBuddy URL: {workbuddy_url}")
    dynamic_entries["workbuddy-cn"] = dynamic_entry(
        workbuddy["version"],
        workbuddy_url.removesuffix(".zip") + ".dmg",
    )

    entries = tomllib.loads((ROOT / "packages/nvfetcher/base.toml").read_text())
    entries.update(dynamic_entries)

    output.write_text(render_config(entries))
    print(f"Wrote {output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
