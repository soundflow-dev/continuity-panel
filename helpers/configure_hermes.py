#!/usr/bin/env python3
"""Apply Hermes model configuration received over stdin without exposing secrets."""

import json
import os
import sys
from pathlib import Path

from hermes_cli.config import read_raw_config, save_config, save_env_value_secure


def main() -> None:
    payload = json.load(sys.stdin)
    provider = str(payload["provider"]).strip()
    model = str(payload["model"]).strip()
    environment = payload.get("environment", {})
    profile_id = str(payload.get("profileID", "__default__")).strip()
    display_name = str(payload.get("displayName", "Default Hermes")).strip()

    if not provider or not model:
        raise ValueError("Provider and model are required")
    if not isinstance(environment, dict):
        raise ValueError("Environment must be an object")

    config = read_raw_config()
    current_model = config.get("model")
    model_config = dict(current_model) if isinstance(current_model, dict) else {}
    model_config["provider"] = provider
    model_config["default"] = model
    model_config.pop("api_key", None)
    config["model"] = model_config

    save_config(config, strip_defaults=False)
    for name, value in environment.items():
        name = str(name).strip()
        value = str(value).strip()
        if name and value:
            save_env_value_secure(name, value)

    hermes_home = Path(os.environ.get("HERMES_HOME", str(Path.home() / ".hermes")))
    hermes_home.mkdir(parents=True, exist_ok=True)
    manifest = {
        "id": profile_id,
        "displayName": display_name,
        "provider": provider,
        "model": model,
        "isDefault": profile_id == "__default__",
    }
    manifest_path = hermes_home / ".continuitypanel-profile.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    manifest_path.chmod(0o600)
    print(f"Hermes configured for {provider} with model {model}")


if __name__ == "__main__":
    main()
