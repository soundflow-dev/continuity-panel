#!/usr/bin/env python3
"""Apply Hermes model configuration received over stdin without exposing secrets."""

import json
import sys

from hermes_cli.config import read_raw_config, save_config, save_env_value_secure


def main() -> None:
    payload = json.load(sys.stdin)
    provider = str(payload["provider"]).strip()
    model = str(payload["model"]).strip()
    environment = payload.get("environment", {})

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
    print(f"Hermes configured for {provider} with model {model}")


if __name__ == "__main__":
    main()
