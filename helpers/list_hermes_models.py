#!/usr/bin/env python3
"""Discover a provider's live model catalog without exposing credentials."""

import json
import sys

from hermes_cli.models import _PROVIDER_MODELS
from providers import get_provider_profile


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

    fallback = unique(_PROVIDER_MODELS.get(provider_id, []))
    profile = get_provider_profile(provider_id)
    if profile is None:
        print(json.dumps(fallback))
        return

    api_key = ""
    for name in profile.env_vars:
        candidate = str(environment.get(name) or "").strip()
        if candidate:
            api_key = candidate
            break

    base_url = str(environment.get("baseURL") or "").strip() or profile.base_url
    live = profile.fetch_models(api_key=api_key, base_url=base_url or None)
    print(json.dumps(unique(live) if live else fallback))


if __name__ == "__main__":
    main()
