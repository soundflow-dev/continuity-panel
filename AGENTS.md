# Agentic OS operating rules

This directory is a local agent orchestration environment. Application work belongs under `projects/`.

For every application project:

1. Read the nearest `AGENTS.md` and `PROJECT_STATE.md` before changing files.
2. Inspect `git status` and preserve changes made by other agents or the user.
3. Keep `PROJECT_STATE.md` current after material decisions, completed work, test results, and newly discovered risks.
4. Before ending a session or changing agent, record the exact next action and the last verified command in `PROJECT_STATE.md`.
5. Never place credentials, API keys, OAuth tokens, or private user data in project memory files.

Mission Control tracks tasks and sessions; the repository and its state files remain the source of truth for handoff.

