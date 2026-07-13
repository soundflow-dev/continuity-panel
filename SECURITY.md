# Security policy

## Supported version

Only the latest commit on the default branch is supported while the project is in its early stage.

## Reporting a vulnerability

Use the repository's private GitHub Security Advisory reporting flow. Do not open a public issue containing credentials, exploit details, private paths, or session data.

## Sensitive local data

The following paths must remain ignored and must not be attached to issues without careful redaction:

- `home/`
- `mission-control/.env`
- `mission-control/.data/`
- agent session databases and transcripts
- any application `.env` files

Rotate affected credentials immediately if any of these files are exposed.

