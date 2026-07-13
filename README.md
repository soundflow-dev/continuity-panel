<p align="center">
  <img src="assets/continuity-panel-logo.svg" alt="ContinuityPanel" width="760">
</p>

A native, local-first macOS control panel for orchestrating cloud-powered coding agents without coupling project continuity to one provider or chat session.

ContinuityPanel.app installs [Builderz Labs Mission Control](https://github.com/builderz-labs/mission-control), keeps agent installations isolated under the current user's Application Support folder, and gives every project a durable Git-based handoff file. It is an orchestration environment, not an operating-system distribution.

> Status: early-stage community project. Mission Control itself is alpha software; back up important projects and review changes before production use.

## What it provides

- Native SwiftUI app for installation, status, agents, cloud providers, and projects.
- Mission Control dashboard and first-time setup embedded directly in the native app.
- One-click graphical installation with no Docker, Homebrew, or remote server.
- Pinned, reproducible versions of Mission Control and local runtimes.
- Built-in catalog for Codex, Hermes, Claude Code, Gemini CLI, GitHub Copilot CLI, OpenCode, goose, Aider, Qwen Code, and Kimi Code.
- Separate cloud-provider catalog for OpenAI, Anthropic, OpenRouter, Google, Z.AI/GLM, Mistral, Groq, xAI, DeepSeek, and Moonshot.
- Local Mission Control service managed by `launchd`.
- Shared `AGENTS.md` and `PROJECT_STATE.md` protocol for agent handoff.
- Cloud-provider secrets stored in the current user's macOS Keychain.
- No bundled models and no credentials committed to Git.

## Requirements

- macOS on Apple Silicon or Intel.
- Internet access.
- Apple Command Line Tools. ContinuityPanel detects them and Git; macOS can install them on demand.
- Cloud subscriptions or API credentials for whichever agents/models you choose.

## Install the app

Download `ContinuityPanel-0.2.0-macos.zip` from the GitHub Releases page, move `ContinuityPanel.app` to Applications, and open it. On first use:

1. Select **Install Environment** in the app.
2. Create the local Mission Control administrator when the embedded setup appears.
3. Add the agents you want under **Agents & Models**.
4. Sign in or connect cloud providers through the graphical interface.
5. Create a local project or restore one from its own GitHub repository.

The app never sends a project to the ContinuityPanel maintainer's GitHub account. New projects remain local until their owner explicitly chooses a GitHub account, repository, organization, and visibility.

> The current community build is ad-hoc signed. Until a notarized Developer ID build is available, macOS may require **Control-click → Open** on first launch.

## Build from source

Contributors can clone the source anywhere, then build and run the native app:

```bash
cd ~
git clone https://github.com/soundflow-dev/continuity-panel.git
cd continuity-panel
./script/build_and_run.sh
```

Create the distributable zip with:

```bash
./script/build_and_run.sh --package
```

The app copies its bundled installation engine to `~/Library/Application Support/ContinuityPanel`, downloads Node.js, installs pnpm, checks out Mission Control v2.1.0, builds it, and registers a user-level macOS service. Mission Control starts immediately and is started automatically whenever you log in. It does not require administrator access.

## Add agents

Agents are added from the **Agents & Models** screen. The command-line engine remains available for diagnostics and contributors:

```bash
./bin/add-agent codex
./bin/add-agent hermes
```

The graphical interface handles agent installation, Codex browser login, Hermes provider/model configuration, and reusable provider credentials. Equivalent diagnostic commands include:

```bash
./bin/codex login
./bin/hermes model
```

Agent credentials and sessions live in the isolated Application Support environment. Reusable cloud API keys are stored in the macOS Keychain. They are never part of this repository. Adding a future agent means extending the declarative app catalog and its isolated installer adapter.

## Mission Control service

After installation, Mission Control runs automatically at login. You do not need to run a start command after restarting the Mac. These commands are optional diagnostics from the installed engine directory.

```bash
./bin/start
./bin/status
./bin/stop
```

Use `start` to restart it manually, `status` to check it, and `stop` to stop it for the current login session. Because automatic startup remains enabled, a service stopped manually will run again the next time you log in. Keep the ContinuityPanel folder in the same location after installation because the registered service uses its absolute path.

Open **Mission Control** in the ContinuityPanel sidebar. Its first-time setup and dashboard are displayed inside the app; opening a localhost URL manually is not required.

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

1. Download and install ContinuityPanel.app again.
2. Allow macOS to install Command Line Tools if requested.
3. Select **Install Environment** and add the desired agents in the GUI.
4. Authenticate cloud accounts again.
5. Clone each application from its owner's GitHub account or organization.

Downloaded dependencies do not need to be backed up. Mission Control history and local agent sessions are runtime data; if you need them, back them up separately to encrypted storage. Never commit them to this repository.

## Directory layout

```text
continuity-panel/
├── Sources/             # native SwiftUI application
├── Tests/               # native application tests
├── Packaging/           # bundle metadata and app icon
├── script/              # build, run, and package entrypoint
├── bin/                 # isolated service, agent, and project engine
├── config/              # launchd service template
├── helpers/             # non-interactive configuration adapters
├── templates/           # agent and project handoff defaults
├── install.sh           # reproducible engine installer
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
