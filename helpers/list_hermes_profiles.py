#!/usr/bin/env python3
"""List non-secret Hermes profile metadata for the native app."""

import json
import os
from pathlib import Path

import yaml


def profile_from(home: Path, profile_id: str, display_name: str, is_default: bool):
    manifest_path = home / ".continuitypanel-profile.json"
    if manifest_path.is_file():
        try:
            data = json.loads(manifest_path.read_text(encoding="utf-8"))
            return {
                "id": profile_id,
                "displayName": str(data.get("displayName") or display_name),
                "provider": str(data.get("provider") or ""),
                "model": str(data.get("model") or ""),
                "isDefault": is_default,
            }
        except (OSError, ValueError, TypeError):
            pass

    config_path = home / "config.yaml"
    if not config_path.is_file():
        return None
    try:
        config = yaml.safe_load(config_path.read_text(encoding="utf-8")) or {}
        model_config = config.get("model", {})
        if isinstance(model_config, str):
            provider, model = "", model_config
        elif isinstance(model_config, dict):
            provider = str(model_config.get("provider") or "")
            model = str(model_config.get("default") or "")
        else:
            provider, model = "", ""
        return {
            "id": profile_id,
            "displayName": display_name,
            "provider": provider,
            "model": model,
            "isDefault": is_default,
        }
    except (OSError, yaml.YAMLError, TypeError):
        return None


def main() -> None:
    root = Path(os.environ.get("HERMES_HOME", str(Path.home() / ".hermes")))
    profiles = []
    default = profile_from(root, "__default__", "Default Hermes", True)
    if default:
        profiles.append(default)

    profiles_root = root / "profiles"
    if profiles_root.is_dir():
        for home in sorted(profiles_root.iterdir(), key=lambda path: path.name.lower()):
            if not home.is_dir() or home.name.startswith("."):
                continue
            profile = profile_from(home, home.name, home.name, False)
            if profile:
                profiles.append(profile)

    print(json.dumps(profiles))


if __name__ == "__main__":
    main()
