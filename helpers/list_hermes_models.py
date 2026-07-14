#!/usr/bin/env python3
"""Discover a provider's live model catalog without exposing credentials."""

import json
import os
import re
import sys

from hermes_cli.models import cached_provider_model_ids


def unique(values):
    seen = set()
    result = []
    for value in values:
        model = str(value or "").strip()
        key = model.lower()
        if model and key not in seen:
            seen.add(key)
            result.append(model)
    return result


def main():
    payload = json.load(sys.stdin)
    provider_id = str(payload.get("provider") or "").strip()
    environment = payload.get("environment") or {}
    if not provider_id or not isinstance(environment, dict):
        raise ValueError("Provider and environment are required")

    for name, value in environment.items():
        name = str(name).strip()
        if name == "baseURL" or not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name):
            continue
        value = str(value or "").strip()
        if value:
            os.environ[name] = value

    models = cached_provider_model_ids(provider_id, force_refresh=True)
    print(json.dumps(unique(models)))


if __name__ == "__main__":
    main()
