<p align="center">
  <img src="assets/continuity-panel-logo.svg" alt="ContinuityPanel" width="760">
</p>

A reproducible, local-first macOS workspace for orchestrating cloud-powered coding agents without coupling project continuity to one provider or chat session.

ContinuityPanel installs [Builderz Labs Mission Control](https://github.com/builderz-labs/mission-control), keeps agent installations isolated inside one folder, and gives every application a durable Git-based handoff file. It is an orchestration environment, not an operating-system distribution.

> Status: early-stage community project. Mission Control itself is alpha software; back up important projects and review changes before production use.

## What it provides

- One-click macOS bootstrap through `Install ContinuityPanel.command`.
- Pinned, reproducible versions of Mission Control and local runtimes.
- Optional agent modules; currently Codex and Hermes Agent.
- Local Mission Control service managed by `launchd`.
- Shared `AGENTS.md` and `PROJECT_STATE.md` protocol for agent handoff.
- No bundled models and no credentials committed to Git.

## Requirements

- macOS on Apple Silicon or Intel.
- Internet access.
- Git. On a clean Mac, run `xcode-select --install` if Git requests the Command Line Tools.
- Cloud subscriptions or API credentials for whichever agents/models you choose.

## Install

The recommended location is `~/continuity-panel`:

```bash
cd ~
git clone https://github.com/soundflow-dev/continuity-panel.git
cd continuity-panel
open "Install ContinuityPanel.command"
```

Alternatively, run the same installer in Terminal:

```bash
./install.sh
```

The installer downloads Node.js, installs pnpm, checks out Mission Control v2.1.0, builds it, and registers a user-level macOS service. Mission Control starts immediately and is started automatically whenever you log in to macOS. It does not require Docker or administrator access.

## Add agents

Agents are deliberately separate from the base installation:

```bash
./bin/add-agent codex
./bin/add-agent hermes
```

Then authenticate or select cloud providers:

```bash
./bin/codex login
./bin/hermes model
```

Credentials and sessions live under the ignored `home/` directory. They are never part of the installer repository. Adding a future agent should be implemented as another isolated case in `bin/add-agent` plus a small launcher in `bin/`.

## Mission Control service

After installation, Mission Control runs automatically at login. You do not need to run a start command after restarting the Mac.

```bash
./bin/start
./bin/status
./bin/stop
```

Use `start` to restart it manually, `status` to check it, and `stop` to stop it for the current login session. Because automatic startup remains enabled, a service stopped manually will run again the next time you log in. Keep the ContinuityPanel folder in the same location after installation because the registered service uses its absolute path.

Open <http://127.0.0.1:3000/setup> on first use and create the local administrator account.

## Create an application

```bash
./bin/new-project my-app
cd projects/my-app
```

The command initializes Git and adds:

- `AGENTS.md`: durable rules shared by all coding agents.
- `PROJECT_STATE.md`: objective, decisions, completed work, verification, risks, and the exact next action.

Commit both files with the application and give each application its own GitHub repository. This is what allows Codex, Hermes, or another agent to resume work without depending on another provider's conversation history.

## Reinstall after formatting a Mac

1. Install Git/Command Line Tools.
2. Clone this repository again into `~/continuity-panel`.
3. Run `Install ContinuityPanel.command`.
4. Add the desired agents using `bin/add-agent`.
5. Authenticate cloud accounts again.
6. Clone each application repository into `projects/`.

Downloaded dependencies do not need to be backed up. Mission Control history and local agent sessions are runtime data; if you need them, back them up separately to encrypted storage. Never commit them to this repository.

## Directory layout

```text
continuity-panel/
├── bin/                 # start, stop, agent and project commands
├── config/              # launchd service template
├── templates/           # Codex, Hermes and project handoff defaults
├── install.sh           # reproducible base installer
├── mission-control/     # downloaded upstream source; ignored
├── runtime/             # downloaded Node, Python and uv; ignored
├── home/                # credentials, sessions and agent state; ignored
├── tools/               # optional installed agents; ignored
└── projects/            # independent application repositories; ignored here
```

## Security

- Do not commit `.env`, API keys, OAuth tokens, session databases, Mission Control `.data`, or the isolated `home/` directory.
- The dashboard binds to `127.0.0.1` by default. Do not expose it publicly without TLS, host restrictions, and a security review.
- Review upstream release notes before changing pinned versions.
- See [SECURITY.md](SECURITY.md) before reporting a vulnerability.

## Upstream projects

This repository automates installation and interoperability; it does not redistribute or replace the upstream projects:

- [Builderz Labs Mission Control](https://github.com/builderz-labs/mission-control)
- [Nous Research Hermes Agent](https://github.com/NousResearch/hermes-agent)
- [OpenAI Codex](https://developers.openai.com/codex/cli/)

Each upstream project retains its own trademarks, copyright, license, release process, and support policy.

## Contributing

Community contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md). The most useful next modules are additional CLI agents, encrypted state backup, upgrade/rollback commands, and automated end-to-end handoff tests.

## License

The original files in this repository are available under the [MIT License](LICENSE). Installed upstream components remain under their respective licenses.
