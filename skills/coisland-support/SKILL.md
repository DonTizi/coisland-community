---
name: coisland-support
description: Report a CoIsland problem. Gathers CoIsland's own diagnostic report (versions, connectors, monitors and their errors, recent failed checks), shows it to the owner, and files a GitHub issue on DonTizi/coisland-community only after the owner says yes; or drafts an email to hello@coisland.app for anything private. Use when the owner says "CoIsland is broken", "report this CoIsland bug", "my monitor keeps failing, tell the developer", "open an issue for CoIsland" or "why is my CoIsland connector failing".
license: MIT
metadata:
  coisland-version: "0.4.6"
---

# CoIsland support

CoIsland is a macOS notch app whose monitors raise alerts from the owner's work tools. Its public
issue tracker is https://github.com/DonTizi/coisland-community/issues. This skill turns a problem
into a report the developer can act on, with CoIsland's own diagnostics, and never sends anything
the owner has not read.

The command line: `/Applications/CoIsland.app/Contents/MacOS/CoIsland`. Call it by that full path.

## 0. Check the CoIsland version first

```sh
defaults read /Applications/CoIsland.app/Contents/Info CFBundleShortVersionString
```

`--report` needs **0.4.6 or later**. On an older version, or an error (CoIsland is not in
/Applications), do not run the binary: ask the owner to update (menu bar icon › Check for Updates,
or https://coisland.app/download), or to use Settings › General › Help › Report on GitHub in the app.

## Rules

1. **Nothing leaves without a yes.** An issue is public. Show the owner the whole issue, title and
   body, and file it only after an explicit yes to that text. Anything they want kept private goes
   by email instead, which they send themselves.
2. **Never a secret.** The report already replaces anything shaped like a token with `<redacted>`.
   Do not add one back: never paste a token, password, API key, licence key or the contents of a
   `.env`, and replace any you notice with `<token>`. Watch files can hold company names and query
   text: quote them only if the owner agrees.
3. **Run each command as one plain line:** the full path and its arguments, no variables, no `;`,
   `&&` or pipes.
4. **Never read or edit CoIsland's files** under `~/Library/Application Support/CoIsland/`, nor its
   code or bundle. The report is the source.

## 1. Gather

```
/Applications/CoIsland.app/Contents/MacOS/CoIsland --report
```

It prints the report as text (`--json` gives the same as one JSON document):

```
CoIsland 0.4.6 (46) (stable) · macOS 15.7.4 · Apple M2 Pro · licence: shown in the app's report

Connectors (2):
  github "work"
  reminders "mac" · problem: CoIsland has not asked macOS for your reminders yet: …

Monitors (1):
  Failed tasks · snowflake.custom-sql · Every 5 minutes · error: Warehouse suspended

Failed checks (1), newest first:
  2026-09-25 18:02 · Failed tasks · snowflake · timeout
```

A connector's `problem` or a monitor's `error` is often the whole answer: a permission to grant, a
token that expired, a query to fix. Tell the owner what it says and how to fix it first; many
reports end there, with no issue needed.

## 2. Ask what happened

If it is still a bug, ask for what the report cannot know, in a few words each: what they did, what
they expected, what happened instead, and since when. Do not invent steps.

## 3. Draft the issue and show it

Title: `[Bug]: ` and one line saying what goes wrong (`[Bug]: Jira monitor fails with 401 after
reconnecting`). Body, in this order:

```markdown
### macOS version
<from the report's first line>

### CoIsland version
<from the report's first line>

### Connector
<the provider involved, or "None, or the app itself">

### Exact error
<the problem or error line, word for word>

### Steps to reproduce
1. …

### What you expected
…

### Anything else
<details><summary>Diagnostic report</summary>

```
<the report, as printed>
```
</details>
```

Show the owner the title and the whole body, and ask: "File this as a public issue on
DonTizi/coisland-community?"

## 4. File it, once they say yes

With the GitHub CLI signed in (`gh auth status` succeeds):

```
gh issue create --repo DonTizi/coisland-community --title "<title>" --label bug --body-file <file>
```

Write the body to a temporary file first and pass its path; print the issue URL `gh` returns.

Without `gh`, give the owner this link to open, then paste the body in:
https://github.com/DonTizi/coisland-community/issues/new?template=bug_report.yml

For a private problem (a security issue, or data they will not make public), draft an email to
**hello@coisland.app** with the same text for the owner to send; never send it yourself.
