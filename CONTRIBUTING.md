# Contributing

Thank you for helping make ContinuityPanel easier to reproduce and extend.

## Principles

- Keep the base installation provider-neutral.
- Install every optional agent through `bin/add-agent` and keep its state inside the isolated `home/` or `tools/` directories.
- Pin versions so clean installations are reproducible.
- Never add credentials, session data, generated databases, or personal paths.
- Preserve the shared `AGENTS.md` and `PROJECT_STATE.md` handoff contract.

## Before submitting a change

1. Run `bash -n install.sh "Install ContinuityPanel.command" bin/*`.
2. Run `plutil -lint config/dev.continuitypanel.mission-control.plist.template`.
3. Test both a clean installation and a repeated installation when changing bootstrap code.
4. Document new commands and security implications in `README.md`.

Use a focused pull request and explain which macOS architecture and version you tested.
