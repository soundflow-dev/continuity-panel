#!/usr/bin/env python3
"""Emit Hermes' canonical provider catalog as JSON for the native app."""

import json

from hermes_cli.provider_catalog import provider_catalog


def provider_runtime_metadata(slug: str):
    default_base_url = ""
    models = []

    try:
        from hermes_cli.auth import PROVIDER_REGISTRY

        config = PROVIDER_REGISTRY.get(slug)
        default_base_url = str(getattr(config, "inference_base_url", "") or "")
    except Exception:
        pass

    try:
        from hermes_cli.models import OPENROUTER_MODELS, _PROVIDER_MODELS

        raw_models = OPENROUTER_MODELS if slug == "openrouter" else _PROVIDER_MODELS.get(slug, [])
        for item in raw_models:
            model = item[0] if isinstance(item, (list, tuple)) else item
            model = str(model).strip()
            if model and model not in models:
                models.append(model)
    except Exception:
        pass

    return default_base_url, models


def field(name: str, label: str, *, secret: bool = False, required: bool = False):
    return {"name": name, "label": label, "secret": secret, "required": required}


def fields_for(provider):
    if provider.slug == "custom":
        return [
            field("OPENAI_API_KEY", "API key", secret=True),
            field("OPENAI_BASE_URL", "OpenAI-compatible base URL", required=True),
        ]
    if provider.auth_type == "aws_sdk":
        return [
            field("AWS_PROFILE", "AWS profile"),
            field("AWS_REGION", "AWS region"),
        ]
    if provider.auth_type == "vertex":
        return [
            field("VERTEX_CREDENTIALS_PATH", "Service-account JSON path"),
            field("GOOGLE_CLOUD_PROJECT", "Google Cloud project"),
            field("GOOGLE_CLOUD_LOCATION", "Google Cloud location"),
        ]

    result = []
    if provider.api_key_env_vars:
        primary = provider.api_key_env_vars[0]
        result.append(
            field(
                primary,
                f"API key ({primary})",
                secret=True,
                required=provider.slug != "lmstudio",
            )
        )
    if provider.base_url_env_var:
        result.append(field(provider.base_url_env_var, "Base URL override"))
    return result


def main():
    providers = list(provider_catalog())
    rows = []
    for provider in providers:
        default_base_url, models = provider_runtime_metadata(provider.slug)
        rows.append({
            "slug": provider.slug,
            "label": provider.label,
            "description": provider.description,
            "authType": provider.auth_type,
            "tab": provider.tab,
            "signupURL": provider.signup_url,
            "fields": fields_for(provider),
            "defaultBaseURL": default_base_url,
            "models": models,
        })
    if not any(row["slug"] == "custom" for row in rows):
        custom = type(
            "CustomProvider",
            (),
            {
                "slug": "custom",
                "label": "Custom endpoint",
                "description": "Any OpenAI-compatible endpoint, including a private or self-hosted service.",
                "auth_type": "api_key",
                "tab": "keys",
                "signup_url": "",
            },
        )()
        rows.append(
            {
                "slug": custom.slug,
                "label": custom.label,
                "description": custom.description,
                "authType": custom.auth_type,
                "tab": custom.tab,
                "signupURL": custom.signup_url,
                "fields": fields_for(custom),
                "defaultBaseURL": "",
                "models": [],
            }
        )
    print(json.dumps(rows))


if __name__ == "__main__":
    main()
