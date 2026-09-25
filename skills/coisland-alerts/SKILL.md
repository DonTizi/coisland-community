---
name: coisland-alerts
description: Read, summarise and triage CoIsland alerts, the things CoIsland's monitors raised in the Mac's notch, and acknowledge, resolve, reopen or add a note to them. Use when the owner asks "what fired overnight", "summarise my open CoIsland alerts", "what's new in the notch", "resolve the alert about X, it's noise", "acknowledge the PagerDuty alert", "note on that alert that the runner was flaky" or "look into the failed deploy alert".
license: MIT
metadata:
  coisland-version: "0.3.0"
---

# CoIsland alerts

CoIsland is a macOS notch app whose monitors raise alerts when something changes in the owner's tools.
Each alert belongs to one monitor, holds the rows or items that fired, and has a status: **new**,
**acknowledged** or **resolved**, plus a history of notes. The running app owns them; this skill reads
and changes them only through the app's command line, which hands each change to the app. It was
written for CoIsland 0.3.0, the first version with `--alerts`.

The command line: `/Applications/CoIsland.app/Contents/MacOS/CoIsland`. Call it by that full path.

## 0. Check the CoIsland version first

Before any CoIsland command, run this once:

```sh
defaults read /Applications/CoIsland.app/Contents/Info CFBundleShortVersionString
```

It prints a version such as `0.3.0`. The commands below need **0.3.0 or later**. On an older
version, or when it prints an error (CoIsland is not in /Applications), stop and tell the owner to
update CoIsland (menu bar icon › Check for Updates, or https://coisland.app/download) and to
install it in Applications, not run it from the disk image. Never run the CoIsland binary on an
older version: before 0.3.0 it does not know these commands and starts a second copy of the app
that never answers.

## Rules

1. **Only the command line.** Never read or edit `alerts.json` or anything else under
   `~/Library/Application Support/CoIsland/`: the app keeps alerts in memory and would overwrite an
   outside edit. Never read the app's code or bundle.
2. **Run each command as one plain line:** the full path and its arguments, no variables, no `;`,
   `&&` or pipes.
3. **Confirm before resolving more than one alert.** List what you will resolve (monitor, what fired,
   alert id) and wait for a yes. One alert the owner named can be resolved directly.
4. **Never ask for or handle a token.** Investigating uses the owner's own tools and sign-ins.

## Read

```
/Applications/CoIsland.app/Contents/MacOS/CoIsland --alerts --open --json
```

`--open` keeps the alerts still open (new or acknowledged); without it, resolved ones come too. It
prints `{"alerts": [...]}`, newest first, each with:

- `id`; `status`: `new`, `acknowledged` or `resolved`; `raised`: when it fired (ISO 8601, UTC);
- `monitor` (its name), `monitorFile`, `kind` and `connector`;
- `title` (`1 new run in Failed deploys`), `summary` (the rule) and `observed` (`1 new run`);
- `rows`: what fired, each a `title` and its `fields` (column to value; a URL, when there is one, is
  a field);
- `notes`: each a `date` and its `text`.

Summarise **by monitor**, newest first:

- the monitor's name, how many alerts are open, and how many are new versus acknowledged;
- for each alert: when it fired and what fired, in a line a person reads (the row's title, such as
  `deploy.yml failed on main`, the issue key and summary, the incident number), with a link when the
  row has a URL;
- the notes already on it.

For "what fired overnight", keep the alerts detected since the evening before (say which cut-off you
used). Say plainly when nothing is open. Keep the alert ids out of the prose unless asked, but keep
them at hand to act.

## Act

```
/Applications/CoIsland.app/Contents/MacOS/CoIsland --alert <id> ack
/Applications/CoIsland.app/Contents/MacOS/CoIsland --alert <id> resolve
/Applications/CoIsland.app/Contents/MacOS/CoIsland --alert <id> reopen
/Applications/CoIsland.app/Contents/MacOS/CoIsland --alert <id> note "flaky runner, retried and passed"
```

- `ack` marks it acknowledged: seen, being handled. `resolve` closes it. `reopen` makes a resolved or
  acknowledged alert new again. `note` adds a line to its history without changing its status.
- Find the id by matching the owner's words ("the alert about the checkout deploy") against the
  monitor names and fired rows from `--alerts --open --json`. When two alerts match, ask which.
- For "it's noise", resolve it and add a short note saying why, in the owner's words.
- Add `--json` to read the result: `{"ok": true, "appliedBy": ..., "alert": {...}}`, the alert as
  `--alerts` shows it after the change, or `{"ok": false, "error": "..."}`. `appliedBy` is `app` (the
  running app applied it) or `file` (no app runs on this home, so the command wrote it safely, and the
  app shows it at its next launch). Both are done; neither needs a retry.

Exit codes, and what to tell the owner:

- **0:** done. Say what changed, in the command's words.
- **1:** nothing changed: an unknown id (often an alert that was already removed, or another CoIsland
  home) or an error. Report its message.
- **2:** the running app got the request but did not confirm in time. It may still apply it. Do not
  retry blindly: run `--alerts --json` after a few seconds and check the alert's status.
- **64:** the command was wrong (a malformed id, a note with no text), or CoIsland is older than this
  skill: ask the owner to update it.

Setting the status an alert already has changes nothing.

## Investigate, then note

When the owner asks to look into an alert:

1. Read it with `--alerts --open --json`: the monitor, the rows, their URLs.
2. Look with the owner's own tools and their own sign-ins, read-only: `gh run view` for a failed
   GitHub run, the Jira or Linear issue, the Sentry issue, the query against the table, the Vercel
   deployment's logs. Ask before running anything that changes something in those tools.
3. Tell the owner what you found and what you suggest.
4. Offer to record it: `--alert <id> note "<one or two lines: cause, and what was done>"`, then `ack`
   while it is being handled, or `resolve` once it is fixed or confirmed as noise.

A monitor that alerts on noise again and again is better fixed at the monitor (narrower query, a
`key`, a count rule): the `coisland-monitors` skill edits monitors.
