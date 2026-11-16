#!/usr/bin/env python3
"""Refresh referenced model facts from models.dev, never its provider catalog."""

import argparse
import json
from pathlib import Path
import subprocess
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
SOURCE_URL = "https://models.dev/models.json"
FIELDS = ("name", "description", "reasoning", "tool_call", "modalities", "limit")


def select_models(source, providers):
    references = {
        model["model"]
        for provider in providers.values()
        for model in provider["models"].values()
        if not model["model"].startswith("local/")
    }
    missing = references - source.keys()
    if missing:
        raise ValueError(f"Models absent from {SOURCE_URL}: {', '.join(sorted(missing))}")
    return {
        reference: {
            field: source[reference][field]
            for field in FIELDS
            if field in source[reference]
        }
        for reference in sorted(references)
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, help="Use a downloaded models.json offline")
    args = parser.parse_args()
    providers = json.loads(
        subprocess.check_output(
            [
                "nix", "eval", "--impure", "--json", "--file",
                str(ROOT / "modules/agents/_providers.nix"),
            ],
            text=True,
        )
    )
    if args.source:
        source = json.loads(args.source.read_text())
    else:
        with urllib.request.urlopen(SOURCE_URL, timeout=60) as response:
            source = json.load(response)
    try:
        models = select_models(source, providers)
    except ValueError as error:
        parser.error(str(error))
    destination = ROOT / "modules/agents/_models/models-dev.json"
    destination.write_text(json.dumps(models, ensure_ascii=False, indent=2, sort_keys=True) + "\n")
    print(f"Updated {len(models)} models in {destination.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
