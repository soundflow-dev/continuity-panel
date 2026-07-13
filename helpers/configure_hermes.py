#!/usr/bin/env python3
"""Apply Hermes model configuration received over stdin without exposing secrets."""

import json
import sys

from hermes_cli.config import read_raw_config, save_config, save_env_value_secure


def main() -> None:
    payload = json.load(sys.stdin)
    provider = str(payload["provider"]).strip()
    model = str(payload["model"]).strip()
    key_environment = str(payload["keyEnvironment"]).strip()
    api_key = str(payload["apiKey"]).strip()

    if not provider or not model or not key_environment or not api_key:
        raise ValueError("Provider, model, and API key are required")

    config = read_raw_config()
    current_model = config.get("model")
    model_config = dict(current_model) if isinstance(current_model, dict) else {}
    model_config["provider"] = provider
    model_config["default"] = model
    model_config.pop("base_url", None)
    model_config.pop("api_key", None)
    config["model"] = model_config

    save_config(config, strip_defaults=False)
    save_env_value_secure(key_environment, api_key)
    print(f"Hermes configured for {provider} with model {model}")


if __name__ == "__main__":
    main()
