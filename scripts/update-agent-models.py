#!/usr/bin/env python3
"""Refresh explicitly selected models.dev provider models."""

import argparse
import json
from pathlib import Path
import subprocess
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
SOURCE_URL = "https://models.dev/api.json"
FIELDS = (
    "name",
    "description",
    "reasoning",
    "reasoning_options",
    "tool_call",
    "modalities",
    "limit",
)


def select_models(source, providers):
    selected = {}
    for name, provider in sorted(providers.items()):
        provider_id = provider.get("modelsDevProvider")
        if provider_id is None:
            continue
        upstream = source.get(provider_id)
        models = {}
        for model_id in provider.get("models", []):
            if model_id.startswith("local/"):
                continue
            if upstream is None:
                raise ValueError(f"Provider absent from {SOURCE_URL}: {provider_id}")
            model = upstream.get("models", {}).get(model_id)
            if model is None:
                raise ValueError(
                    f"Model absent from {SOURCE_URL}: {provider_id}/{model_id}"
                )
            models[model_id] = {
                field: model[field] for field in FIELDS if field in model
            }
        if models:
            selected[name] = models
    return selected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", type=Path, help="Use a downloaded api.json offline")
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
    count = sum(len(models) for models in models.values())
    print(f"Updated {count} subscribed models in {destination.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
