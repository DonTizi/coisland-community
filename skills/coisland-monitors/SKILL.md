---
name: coisland-monitors
description: Create, list, check, edit, pause and delete CoIsland monitors, the .sql watch files that alert in the Mac's notch. Use when the owner asks to watch, monitor or get alerted about something in Snowflake, GitHub, Jira, Vercel, Linear, Sentry, PagerDuty, Gmail, Confluence, Calendar or Databricks, for example "watch my failed GitHub Actions runs", "alert me when a Snowflake table gets bad rows", "add a CoIsland monitor for Jira SLAs", "notify me when a PagerDuty incident is assigned to me", "list my CoIsland monitors", "pause the big orders monitor" or "why does my CoIsland monitor fail its check".
license: MIT
metadata:
  coisland-version: "0.3.0"
---

# CoIsland monitors

CoIsland is a macOS notch app that watches the owner's tools through connectors and alerts when
something changes. Every monitor is one plain `.sql` watch file: a header of `-- key: value` lines,
then a body in that tool's language (SQL, a GitHub search, JQL, `key:value` filters...). The app picks
up a new, changed or deleted file within a second. This skill writes those files and checks them with
the app's command line. It was written for CoIsland 0.3.0, the first version with `--connectors`.

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

## Where things are

- The command line: `/Applications/CoIsland.app/Contents/MacOS/CoIsland`. Call it by that full path.
- The watches folder, below `<watches>`: run `printenv COISLAND_HOME` first. If it prints a folder,
  the watches are in its `watches` subfolder, directly (`$COISLAND_HOME/watches/`, no `.coisland`).
  Otherwise they are in `~/.coisland/watches/`. Only visible `.sql` files at the top of that folder
  count; a file anywhere else is never checked.
- Every kind, key, filter and limit, with a complete example per kind: [reference.md](reference.md).
  Read the section of the connector you need before writing a file.

## Rules

1. **Never ask for, accept, read or write a token, password or API key.** Connectors and their secrets
   are added by the owner in the app's own form. If the owner pastes a secret, do not repeat it or put
   it anywhere; tell them to use the form.
2. **Use only the command line and the watches folder.** Do not read or edit anything under
   `~/Library/Application Support/CoIsland/` (connectors, alerts, state), the Keychain, or the app's
   code or bundle. When a check fails, report its message; do not go looking for its cause in the app.
3. **Monitors only read.** A SQL body (Snowflake, Databricks) must be one `SELECT`, `WITH` or `SHOW`
   statement. Refuse to write SQL that inserts, updates, deletes, merges, creates, drops, alters,
   grants or calls anything, even when asked; offer a query that finds the same rows instead.
4. **Run each command as one plain line:** the full binary path and its arguments, no variables, no
   `;`, `&&` or pipes, so the owner can allow it with one rule.
5. **Never overwrite a file you did not mean to change.** Look before writing.

## 1. Check the connectors

```
/Applications/CoIsland.app/Contents/MacOS/CoIsland --connectors --json
```

It prints `{"connectors": [...]}`, each with `name`, `provider` and `default` (true for its
provider's default), never a secret.
A monitor names its connector with `-- connector: <name>`; without that line it runs on the default
connector of its provider.

- **The provider has no connector:** open the app's form for it, then stop and ask the owner to add
  it there and tell you when it is done:

  ```
  open "coisland://connectors/add?provider=github"
  ```

  Provider ids: `snowflake`, `github`, `jira`, `vercel`, `linear`, `sentry`, `pagerduty`, `gmail`,
  `confluence`, `calendar`, `databricks`. Then run `--connectors --json` again.
- **Several connectors of that provider:** ask which one, unless the request names it.
- **Exit code 64, or an unknown option:** the installed CoIsland is older than this skill. Ask the
  owner to update it (Settings › About).

## 2. Write the watch file

1. Pick the kind from [reference.md](reference.md). If the request is ambiguous (which repository,
   project, table, team), ask rather than guess.
2. **File name:** the monitor's name in lower case, with every run of other characters turned into
   one `-`, plus `.sql`: "Failed deploys" is `failed-deploys.sql`. If that file exists, use
   `failed-deploys-2.sql`, then `-3`, and so on. The file name is the monitor's id: renaming a file
   makes a new monitor.
3. **Header,** one `-- key: value` per line, in this order, only the lines needed. A value is the
   rest of its line, so never put a comment after it.
   - `-- name:` what the owner will read in the notch.
   - `-- kind:` the kind. Every kind needs it except Snowflake SQL, the default.
   - `-- connector:` the connector's name, when it is not the provider's default or several exist.
   - `-- every:` `30s` to `720h`, a number and `s`, `m` or `h` (`5m`).
   - `-- alert:` `new-rows`, or a count rule such as `count > 0`, `count >= 10`, `count = 0`.
   - `-- key:` SQL kinds only, the columns that identify a row when others change between checks.
   - `-- title:` how a row reads in the notch, with `{COLUMN}` placeholders from reference.md.

   Then optionally `sound`, `icon`, `warehouse`/`database`/`schema`/`role`/`timezone` (SQL), a blank
   line, and the body. Keep prose notes in the header, never in the body.
4. **Body:** exactly what that kind takes, per reference.md. It must not be empty, and must not start
   with a `--` line (that line would be read as header).
5. **Choose `every` for the kind:** a SQL check wakes a warehouse (15m on Snowflake, 30m or more on
   Databricks); API kinds are fine at 1m to 5m; Gmail 2m.
6. Tell the owner what the monitor will do. With `alert: new-rows`, **the first check only records
   what matches now and raises nothing**; later checks alert on what is new. A count rule fires on
   its first check if already true.

## 3. Check it: one command, then report

```
/Applications/CoIsland.app/Contents/MacOS/CoIsland --check <watches>/failed-deploys.sql
```

Use the file's absolute path (`<watches>` spelled out). With `--json` it prints `ok` (true only when
every file passed) and `results`, one per file, each with `file`, `name`, `kind`, `connector` and a
`result`:

- **`ok`:** the file parsed and the check ran. `matching` is how many rows or items match now;
  report any `warnings`.
- **`invalid`:** the file is wrong. `message` says why and `line` where (a bad value, an unknown
  filter such as `Unknown filter "label:"`, a refused query). Fix the file and check again, at most
  twice, then ask the owner.
- **`connector-missing`:** no connector for it. Open the `addConnector` link with `open`, and ask the
  owner to add the connector there (step 1).
- **`could-not-run`:** the file parsed, but the check could not run. `category` says why:
  `auth` (no token saved, or refused), `permission`, `not-found`, `rate-limited`, `timeout`,
  `network`, `configuration`, `server` or `other`. The file may be right: report `message`, tell the
  owner what to fix in the app or that service, and do not change the file.

Exit codes: **0** every file is `ok`; **1** at least one is not; **64** the command was wrong, or the
app is too old (see step 1).

A new or edited file is also checked by the running app within a second. Running every file:
`/Applications/CoIsland.app/Contents/MacOS/CoIsland --check` with no path.

## List, edit, pause, delete

- **List:** list the watches folder and read each file's header (`name`, `kind`, `connector`,
  `every`, `paused`). Summarise by connector. To know which ones work, run `--check` with no path,
  which checks them all.
- **Edit:** change only the lines asked for, keep the rest byte for byte, then run step 3. Changing
  the body, `key`, `connector`, `role`, `database`, `schema`, `timezone`, `alert` or `kind` starts a
  new silent baseline; `name`, `title`, `sound`, `icon`, `every` and `warehouse` keep it. Say which.
  Renaming the file makes a new monitor, so change `-- name:` instead.
- **Pause:** add `-- paused: yes` as the last header line. It keeps its alerts and history and is
  never checked. **Resume:** remove that line.
- **Delete:** confirm with the owner first (name the file), then move it to the Trash, as the app
  does, never `rm`:

  ```
  trash <watches>/failed-deploys.sql
  ```

## Examples

"Watch my failed GitHub Actions runs on acme/api": `--connectors --json` shows one GitHub connector,
`acme_github`. Write `<watches>/failed-github-actions-runs.sql`:

```sql
-- name: Failed GitHub Actions runs
-- kind: github.workflow-runs
-- connector: acme_github
-- every: 5m
-- alert: new-rows
-- title: {WORKFLOW} failed on {BRANCH}: {TITLE}

repo:acme/api
```

Then run `--check` on it and report. Failed runs of the last 7 days are the baseline; a new failure
(or a failed re-run) alerts.

"Alert me when the orders table gets rows with no customer" (Snowflake): a `SELECT` of the rows that
break the rule, `-- key:` on the table's id column, no `kind` line. See reference.md, Snowflake,
Validation.
