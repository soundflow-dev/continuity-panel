# Shared agent instructions

All coding agents working in this repository share the same files and Git history.

At the start of every session:

1. Read `PROJECT_STATE.md` completely.
2. Inspect `git status`, recent commits, and the relevant code before editing.
3. Verify that the stated next action is still valid.

During work:

- Preserve unrelated changes and never discard another agent's work.
- Record durable architecture and product decisions in `PROJECT_STATE.md`.
- Prefer small, verifiable changes and run the narrowest relevant tests.
- Never store secrets or authentication material in repository files.

Before handoff:

- Update `PROJECT_STATE.md` with completed work, remaining work, exact next action, changed files, and verification results.
- Leave the working tree in a comprehensible state and explicitly describe any uncommitted changes.

