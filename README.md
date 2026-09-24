# CoIsland community

[CoIsland](https://coisland.app) is a macOS app that watches your tools through connectors and turns
what changed into alerts in the notch. Work with AI. Stay in control.

This repository holds CoIsland's agent skills and its public issue tracker. The app's source is not
here.

## Use CoIsland from your AI

Two skills, in the open `SKILL.md` format, let the AI you already use set CoIsland up and triage what
it raises:

- **`coisland-monitors`** creates, checks, edits, pauses and deletes monitors: the plain `.sql` watch
  files in `~/.coisland/watches`, for all 11 connectors (Snowflake, GitHub, Jira, Vercel, Linear,
  Sentry, PagerDuty, Gmail, Confluence, Calendar, Databricks).
- **`coisland-alerts`** reads your open alerts, summarises them by monitor, and acknowledges,
  resolves, reopens or notes them.

Ask it things like:

- "Watch my failed GitHub Actions runs on acme/api."
- "Alert me when the orders table gets rows with no customer."
- "Add a CoIsland monitor for Jira requests about to breach their SLA."
- "List my CoIsland monitors, and pause the big orders one."
- "What fired overnight?"
- "Resolve the alert about the checkout deploy, it's noise."

The skills need CoIsland 0.3.0 or later, installed in `/Applications`.

### Install

One line, for every agent it finds on your Mac:

```sh
curl -fsSL https://raw.githubusercontent.com/DonTizi/coisland-community/main/install.sh | sh
```

It copies `skills/*` into the folders below, prints what it did, and can be run again to update.
`sh install.sh --dry-run` shows what it would do; `--uninstall` removes the skills
(`curl ... | sh -s -- --uninstall` when piped).

Or by hand, per agent:

| Agent | Skills folder | By hand |
|---|---|---|
| Claude Code | `~/.claude/skills` | `cp -R skills/* ~/.claude/skills/` |
| Codex | `~/.agents/skills` (`~/.codex/skills` also works) | `cp -R skills/* ~/.agents/skills/` |
| Cortex Code | `~/.snowflake/cortex/skills` | `cortex skill add https://github.com/DonTizi/coisland-community.git` |
| Any agent that reads `SKILL.md` | Its skills folder | Copy `skills/coisland-monitors` and `skills/coisland-alerts` there |

Cortex Code also reads `~/.claude/skills`, so with Claude Code installed it already has the skills;
`install.sh` does not add a second copy. Start a new agent session after installing.

## Report a bug or ask for a connector

Open an [issue](https://github.com/DonTizi/coisland-community/issues/new/choose): a bug report, a
connector request or an idea. Never paste a token, password or API key in an issue. Security and
licence questions go to [hello@coisland.app](mailto:hello@coisland.app).

## Security

- **The skills never handle tokens.** When a connector is missing, they open CoIsland's own form
  (`coisland://connectors/add?provider=...`), where you add it. Tokens stay in your login Keychain.
- **They use only the local command line** (`/Applications/CoIsland.app/Contents/MacOS/CoIsland`) and
  the watches folder. They never read CoIsland's app data or code, and never edit `alerts.json`.
- **Monitors only read.** The skills refuse SQL that writes, as the app does.
- Everything stays on your Mac. What your agent sends to its own model is up to that agent.

## Licence

The skills and this repository are under the [MIT licence](LICENSE). CoIsland itself is a paid app
with its own licence.
