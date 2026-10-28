# pi extensions

Copied from pi's examples at tag `v1.4.0`
(<https://github.com/earendil-works/pi/tree/v1.4.0/packages/coding-agent/examples/extensions>).
Re-copy them when a pi upgrade changes the extension API.

Local changes:

- `agents/`: dropped the Claude model pins so subagents inherit the session's
  model; `scout` uses `openai/gpt-6-luna`.
- `permission-gate.ts`: also confirms force pushes, `git reset --hard` and `git clean -f`.
- `protected-paths.ts`: also blocks writes under `.ssh/`.
