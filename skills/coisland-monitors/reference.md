# CoIsland watch file reference

Every monitor kind of the 11 connectors, with a complete watch file for each. The keys, values, limits
and messages come from the app's own parser and monitors (CoIsland 0.3). Read the section for the
connector you need; the common rules come first.

- [Header keys](#header-keys)
- [Schedules](#schedules-every-active-at-once-paused)
- [Keys, titles and what alerts](#keys-titles-and-what-alerts)
- Connectors: [Snowflake](#snowflake) · [GitHub](#github) · [Jira](#jira) · [Vercel](#vercel) ·
  [Linear](#linear) · [Sentry](#sentry) · [PagerDuty](#pagerduty) · [Gmail](#gmail) ·
  [Confluence](#confluence) · [Calendar](#calendar) · [Databricks](#databricks)

## Header keys

The header is every line at the top that is blank or starts with `--`. The body starts at the first
line that is neither. A setting is `-- key: value`: a key of letters and underscores, the rest of the
line as its value, never on two lines.

| Key | What it sets | Default | Example |
|---|---|---|---|
| `name` | Name in the notch, Settings and alerts | The file name, less `.sql` | `-- name: Failed deploys` |
| `kind` | Connector type and body language | `snowflake.custom-sql` | `-- kind: jira.sla` |
| `connector` | The connector, by name (`connection` is the older spelling) | That type's default connector | `-- connector: acme_github` |
| `every` | A number and `s`, `m` or `h`, from `30s` to `720h` | `15m` | `-- every: 5m` |
| `alert` | `new-rows`, or `count` with `>`, `>=`, `<`, `<=`, `=` or `!=` and a whole number | `new-rows` | `-- alert: count > 0` |
| `key` | Columns that identify a row, comma-separated | Whole row (SQL), the kind's identity columns (others) | `-- key: ORDER_ID` |
| `title` | A row's line, with `{COLUMN}` placeholders | First three columns | `-- title: {WORKFLOW} failed on {BRANCH}` |
| `sound` | A macOS sound name, or `none` | `Glass` | `-- sound: Basso` |
| `icon` | An SF Symbol name: lower-case words and digits joined by dots | The kind's symbol | `-- icon: xmark.octagon` |
| `warehouse`, `role`, `database`, `schema` | SQL session overrides (Snowflake; Databricks takes `warehouse`, `database` as the catalog, `schema`) | The connector's | `-- role: COISLAND_READER` |
| `timezone` | An IANA zone: Snowflake's session `TIMEZONE`, and how dates read | Account (query), Mac (display) | `-- timezone: America/Toronto` |
| `paused` | `yes` or `no` (`true`, `false`) | `no` | `-- paused: yes` |
| `active`, `at`, `once` | When it runs (below) | Every `every` | `-- active: weekdays 09:00-18:00` |

- Write keys in this order: `name`, `kind`, `connector`, `warehouse`, `database`, `schema`, `every`,
  `alert`, `key`, `title`, `sound`, `icon`, `role`, `timezone`, then prose notes, a blank line, then the
  body. The app writes that order; the parser accepts any.
- No `d` unit in `every`: a day is `24h`. `alert` also reads `new rows`, and `==` as `=`.
- A prose comment in the header is kept as a note. A note shaped like a setting (`-- todo: x`) reads as
  an unknown key and shows a warning, so write notes without a colon after the first word.
- A key given twice: the last one wins, with a warning.
- Errors that stop a monitor, exactly as CoIsland prints them:

| In the file | CoIsland says |
|---|---|
| `-- every: 5` | `Invalid every "5": use a number followed by s, m or h, e.g. 5m` |
| `-- every: 10s` | `Invalid every "10s": the minimum is 30s` |
| `-- alert: count above 5` | `Invalid alert "count above 5": use new-rows, or count followed by >, >=, <, <=, = or != and a number, e.g. count > 0` |
| `-- timezone: Toronto` | `Invalid timezone "Toronto": not an IANA time zone such as America/Toronto` |
| `-- paused: maybe` | `Invalid paused "maybe": use yes or no` |
| `-- key: ,` | `Invalid key ",": name at least one column` |
| A header and no body | `The file has no SQL after its header.` |
| A SQL body starting with `DELETE` | `Watches only run SELECT, WITH or SHOW; this one starts with DELETE.` |

## Schedules: every, active, at, once, paused

- `every: 5m` runs every five minutes (default `15m`).
- `active:` limits `every` to days and hours: `weekdays`, `weekends`, `daily`, day names or ranges
  (`mon-fri`, `mon,wed,fri`), and one time range `09:00-18:00`. A range that ends before it starts runs
  past midnight (`22:00-06:00`). Example: `-- active: mon-fri 09:00-18:00`.
- `at:` runs at set times instead: a five-field cron expression in the Mac's local time
  (`0 9 * * mon-fri`), several separated by `;`, or `@hourly`, `@daily`, `@weekly`, `@monthly`,
  `@yearly`. Example: `-- at: 0 9 * * wed`.
- `once:` runs one time: `-- once: 2026-10-01 09:00`.
- `at` and `once` together are refused. `active` is ignored, with a warning, next to `at` or `once`.
- `paused: yes` keeps the monitor, its alerts and history, and never checks it. Remove the line (or
  write `no`) to resume.

## Keys, titles and what alerts

- `alert: new-rows`: each check hashes each row's `key` columns and keeps only the hashes. A row alerts
  when its key was not in the previous complete check, and again if it leaves and comes back. **The
  first check is a silent baseline.**
- `alert: count > N` (and the other comparisons) has no baseline: it fires on the first check if
  already true, then each time it becomes true again after clearing.
- A column that changes between checks (a timestamp, a running total) makes every row new unless the
  file names a `key` without it. Non-SQL kinds already have a key (their identity columns, listed per
  kind below); leave `key` out for them unless the owner asks otherwise.
- `title` placeholders name a column of the result, in any case; one that matches no column stays as
  typed.
- **What starts a new baseline:** changing the body, `key`, `connector`, `role`, `database`, `schema`,
  `timezone`, `alert` or `kind`. `name`, `title`, `sound`, `icon`, `every` and `warehouse` keep it.
- **Only complete results count.** Past a kind's limit (10,000 SQL rows, 100 GitHub search matches,
  and so on) nothing is compared: `More than the 100 rows fetched match, so nothing is compared. Narrow
  the query.` A count rule still works when the lower bound is enough to tell.

---

## Snowflake

Provider id `snowflake`. Add form: `coisland://connectors/add?provider=snowflake`.

| Kind | Body | Default key |
|---|---|---|
| `snowflake.custom-sql` (the default: no `kind` line) | One SQL statement starting with `SELECT`, `WITH` or `SHOW` | The whole row |

- CoIsland reads the first word, past comments and parentheses, and refuses anything else before it
  reaches Snowflake. One statement only: Snowflake's SQL API rejects a second.
- The whole file runs, header included (comments are valid SQL), with the query tag `coisland:` plus
  the monitor's name. A check has two minutes and reads up to 10,000 rows.
- The columns are the query's, upper-cased by Snowflake unless quoted. Always set `key` when a column
  changes between checks.
- "Validation" (rows of a table that break a rule) is plain Custom SQL: a `SELECT` of the rows that
  break the rule, with no `kind` line.
- `warehouse`, `role`, `database`, `schema` and `timezone` override the connector's session.

Custom SQL, new rows with a key, `big-orders.sql`:

```sql
-- name: Big orders
-- connector: acme
-- warehouse: COISLAND_WH
-- every: 15m
-- alert: new-rows
-- key: ORDER_ID
-- title: #{ORDER_ID} {CUSTOMER} ${AMOUNT} ({REGION})
-- sound: Glass
-- icon: cart
-- timezone: America/Toronto

SELECT order_id, customer, amount, region, placed_at
FROM analytics.sales.orders
WHERE amount > 10000
  AND placed_at > DATEADD('hour', -24, CURRENT_TIMESTAMP())
```

Validation (bad rows in a table), `orders-with-no-customer.sql`:

```sql
-- name: Orders with no customer
-- connector: acme
-- every: 1h
-- alert: new-rows
-- key: ORDER_ID
-- title: Order {ORDER_ID} has no customer

SELECT order_id, placed_at
FROM analytics.sales.orders
WHERE customer_id IS NULL
  AND placed_at > DATEADD('day', -7, CURRENT_TIMESTAMP())
```

Failed tasks, `failed-tasks.sql` (the role must own the tasks, hold MONITOR or OPERATE on them, or
hold MONITOR EXECUTION; `INFORMATION_SCHEMA` belongs to the current database, hence `database`):

```sql
-- name: Failed tasks
-- connector: acme
-- database: ANALYTICS
-- every: 5m
-- alert: new-rows
-- key: QUERY_ID
-- title: {NAME} failed: {ERROR_MESSAGE}
-- sound: Basso
-- icon: exclamationmark.triangle

SELECT query_id, name, schema_name, error_code, error_message, scheduled_time
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    SCHEDULED_TIME_RANGE_START => DATEADD('hour', -1, CURRENT_TIMESTAMP()),
    RESULT_LIMIT => 1000))
WHERE state IN ('FAILED', 'FAILED_AND_AUTO_SUSPENDED')
```

Count rule, `stale-orders-table.sql` (fires when no order arrived in the last hour):

```sql
-- name: No new orders in an hour
-- connector: acme
-- every: 15m
-- alert: count = 0

SELECT order_id
FROM analytics.sales.orders
WHERE placed_at > DATEADD('hour', -1, CURRENT_TIMESTAMP())
```

---

## GitHub

Provider id `github`. Add form: `coisland://connectors/add?provider=github`.

| Kind | Body | Default key |
|---|---|---|
| `github.issues` | A GitHub issue search, as typed on github.com | `ID` |
| `github.review-requests` | A GitHub search; `is:pr` is added unless the search has `is:pr`, `is:pull-request`, `type:pr` or `type:pull-request` | `ID` |
| `github.workflow-runs` | `repo:owner/name` (repeatable), optional `branch:`, `event:`, `workflow:`, `actor:`, `status:` | `ID`, `ATTEMPT` |
| `github.releases` | `repo:owner/name` (repeatable), optional `-is:prerelease` | `ID` |
| `github.security-alerts` | `repo:owner/name` and/or `org:name` (both repeatable), optional `tool:` and `severity:` | `SOURCE`, `REPO`, `NUMBER` |

- **Searches** (`github.issues`, `github.review-requests`): the body on one line is the search, with
  GitHub's advanced search on, so a space between two `repo:` means AND: join repositories with `OR`,
  `(repo:acme/api OR repo:acme/web)`. One request for the 100 newest; over 100 matches compares
  nothing.
- **Filters** (runs, releases, security): CoIsland's own `key:value` words, not GitHub search.
  An unknown key is refused: `Unknown filter "label:". Use repo:, branch:, event:, workflow:, actor: or
  status:.` A key other than `repo:`/`org:` given twice is refused.
- `workflow-runs`: `status:` is one of `failure` (default), `timed_out`, `cancelled`,
  `action_required`, `success`, `neutral`, `skipped`, `stale`, `completed`, `in_progress`, `queued`,
  `requested`, `waiting`, `pending`. `workflow:` is a file name like `deploy.yml`, or its ID. Runs of
  the last 7 days, up to 100 per repository. A re-run that fails again is a new attempt and alerts
  again.
- `releases`: published in the last 30 days, never drafts. `-is:prerelease` leaves pre-releases out.
- `security-alerts`: open alerts only. `tool:` takes `dependabot`, `code-scanning`, `secret-scanning`,
  comma-separated (default `dependabot,code-scanning`: secret scanning needs an admin, so it is asked
  for only by name). `severity:` takes `critical`, `high`, `medium`, `low`, comma-separated.
- The token needs read-only Issues and Pull requests for searches, Actions for runs, Contents for
  releases, and the matching alerts permission for security alerts.

Columns:

- `github.issues`: REPO, NUMBER, TITLE, TYPE, STATE, AUTHOR, LABELS, ASSIGNEES, CREATED, UPDATED, URL, ID.
- `github.review-requests`: REPO, NUMBER, TITLE, AUTHOR, DRAFT, CREATED, UPDATED, URL, ID.
- `github.workflow-runs`: REPO, WORKFLOW, TITLE, BRANCH, EVENT, CONCLUSION, RUN, ATTEMPT, ACTOR, SHA,
  CREATED, URL, ID.
- `github.releases`: REPO, TAG, NAME, PRERELEASE, AUTHOR, PUBLISHED, URL, ID.
- `github.security-alerts`: REPO, SEVERITY, SUMMARY, SOURCE, NUMBER, STATE, SUBJECT, IDENTIFIER,
  CREATED, URL.

Issues and pull requests, `open-bugs-in-the-api.sql`:

```sql
-- name: Open bugs in the API
-- kind: github.issues
-- connector: acme_github
-- every: 5m
-- alert: new-rows
-- title: {REPO}#{NUMBER} {TITLE}

repo:acme/api is:issue is:open label:bug
```

Review requests, `reviews-waiting-on-me.sql`:

```sql
-- name: Reviews waiting on me
-- kind: github.review-requests
-- connector: acme_github
-- every: 5m
-- alert: new-rows
-- title: {REPO}#{NUMBER} {TITLE}

user-review-requested:@me is:open draft:false
```

Failed workflow runs, `failed-deploys.sql`:

```sql
-- name: Failed deploys
-- kind: github.workflow-runs
-- connector: acme_github
-- every: 5m
-- alert: new-rows
-- title: {WORKFLOW} failed on {BRANCH}: {TITLE}
-- sound: Basso
-- icon: xmark.octagon

repo:acme/api branch:main workflow:deploy.yml
```

New releases, `swift-nio-releases.sql`:

```sql
-- name: swift-nio releases
-- kind: github.releases
-- connector: acme_github
-- every: 1h
-- alert: new-rows
-- title: {REPO} {TAG}

repo:apple/swift-nio -is:prerelease
```

Security alerts, `critical-security-alerts.sql`:

```sql
-- name: Critical security alerts
-- kind: github.security-alerts
-- connector: acme_github
-- every: 30m
-- alert: new-rows
-- title: {SEVERITY}: {SUMMARY} ({REPO})

org:acme tool:dependabot,code-scanning severity:critical,high
```

---

## Jira

Provider id `jira`. Add form: `coisland://connectors/add?provider=jira`.

| Kind | Body | Default key |
|---|---|---|
| `jira.issues` | Any JQL | `ID` |
| `jira.status` | JQL; an issue alerts each time it is in a status it was not in at the last check | `ID`, `STATUS` |
| `jira.comments` | JQL for the issues whose new comments alert | `COMMENT_ID` |
| `jira.sla` | Jira Service Management JQL with `breached()` or `remaining("30m")` | `ID` |
| `jira.sprint` | Jira Software JQL, such as `sprint in openSprints()` | `ID` |

- The body is sent to Jira as written; every line of it is the query, so keep notes in the header.
  Jira itself judges the JQL; a refusal shows as `Jira refused the query: ...`.
- Issues are keyed on their id, which survives a move to another project.
- A status change or comment dated over an hour before the previous check came back into the JQL, so it
  does not alert. Keep a JQL window (`-1d`, `-2d`) longer than the check interval.
- Jira Cloud sends each issue's 20 newest comments, so over 20 new comments on one issue between two
  checks alert only the newest 20.
- A check reads up to 1,000 issues (10,000 for issues, SLAs and sprints on Data Center).
- `remaining()` also returns requests already breached: add `AND "<SLA name>" != breached()`. Use the
  SLA's name as the service project shows it.

Columns:

- `jira.issues`, `jira.sla`: KEY, SUMMARY, STATUS, STATUS_CATEGORY, TYPE, PRIORITY, ASSIGNEE, REPORTER,
  PROJECT, CREATED, UPDATED, DUE, URL, ID.
- `jira.status`: the same, plus FROM_STATUS, CHANGED_AT.
- `jira.sprint`: the same as issues, plus SPRINT.
- `jira.comments`: KEY, AUTHOR, BODY, SUMMARY, CREATED, COMMENT_ID, ID, URL.

Issues, `high-priority-ops-bugs.sql`:

```sql
-- name: High-priority OPS bugs
-- kind: jira.issues
-- connector: acme
-- every: 5m
-- alert: new-rows
-- title: {KEY} {SUMMARY} ({PRIORITY})

project = OPS AND issuetype = Bug AND priority in (Highest, High) AND statusCategory != Done
```

Status changes, `ops-issues-done.sql`:

```sql
-- name: OPS issues done
-- kind: jira.status
-- connector: acme
-- every: 15m
-- alert: new-rows
-- title: {KEY} {FROM_STATUS} to {STATUS}

project = OPS AND status CHANGED TO Done AFTER "-1d"
```

Comments, `comments-on-watched-issues.sql`:

```sql
-- name: Comments on issues I watch
-- kind: jira.comments
-- connector: acme
-- every: 5m
-- alert: new-rows
-- title: {KEY} {AUTHOR}: {BODY}

watcher = currentUser() AND updated >= "-2d"
```

SLAs, `sla-at-risk.sql`:

```sql
-- name: SLA at risk
-- kind: jira.sla
-- connector: acme
-- every: 5m
-- alert: new-rows
-- title: {KEY} {SUMMARY} ({PRIORITY})
-- sound: Sosumi
-- icon: timer

project = HELP AND "Time to resolution" < remaining("30m") AND "Time to resolution" != breached()
```

Sprint scope, `added-to-the-app-sprint.sql`:

```sql
-- name: Added to the APP sprint
-- kind: jira.sprint
-- connector: acme
-- every: 15m
-- alert: new-rows
-- title: {KEY} {SUMMARY} joined {SPRINT}

project = APP AND sprint in openSprints()
```

---

## Vercel

Provider id `vercel`. Add form: `coisland://connectors/add?provider=vercel`.

| Kind | Body | Default key |
|---|---|---|
| `vercel.deployments` | Optional `team:`, `project:` (repeatable), `target:`, `state:`, `branch:`, `checks:failed` | `ID` |
| `vercel.stuck` | Optional `team:`, `project:` (repeatable), `target:`, `for:` | `ID` |
| `vercel.domains` | `project:` (one or more, required), optional `team:`, `problem:`, `cert:` | `DOMAIN`, `PROBLEM` |

- All three are `key:value` words; an unknown key is refused with the list of valid ones.
- `team:` is a team slug or ID (`team_...`); without it, the token's default team. `project:` is a
  project name or ID (`prj_...`); none is every project of the team (not for domains).
- `target:` is `production` or `preview`.
- `state:` (deployments) is comma-separated among `error` (default), `canceled`, `ready`, `building`,
  `queued`, `initializing`, `blocked`. Deployments of the last 7 days.
- `checks:failed` keeps deployments whose checks concluded failed; no other value is known.
- `for:` (stuck) is how long a build may queue or build: `20m` default, from `5m` to `12h`, written
  with `m` or `h`. Deployments of the last day.
- `problem:` (domains) is `misconfigured`, `unverified` or both (default both). `cert:14d` adds
  certificates expiring within that many days, from `1d` to `60d`.
- A redeploy is a new deployment, so a build that fails again alerts again. Over 10 pages of 100
  deployments compares nothing.

Columns:

- `vercel.deployments`: TEAM, PROJECT, TARGET, STATE, SUBSTATE, BRANCH, COMMIT, MESSAGE, AUTHOR, ERROR,
  CHECKS, DEPLOYMENT, CREATED, READY, URL, ID.
- `vercel.stuck`: the same, plus STARTED, FOR.
- `vercel.domains`: TEAM, PROJECT, DOMAIN, PROBLEM, DETAIL, EXPIRES, URL.

Deployments, `failed-production-deploys.sql`:

```sql
-- name: Failed production deploys
-- kind: vercel.deployments
-- connector: vercel
-- every: 5m
-- alert: new-rows
-- title: {PROJECT} {STATE} on {BRANCH}: {ERROR}

team:acme project:web target:production state:error,canceled
```

Stuck builds, `stuck-builds.sql`:

```sql
-- name: Stuck builds
-- kind: vercel.stuck
-- connector: vercel
-- every: 5m
-- alert: new-rows
-- title: {PROJECT} {STATE} for {FOR}s

team:acme project:web for:20m
```

Domain problems, `web-domain-problems.sql`:

```sql
-- name: Web domain problems
-- kind: vercel.domains
-- connector: vercel
-- every: 1h
-- alert: new-rows
-- title: {DOMAIN} {PROBLEM}

project:web problem:misconfigured,unverified cert:14d
```

---

## Linear

Provider id `linear`. Add form: `coisland://connectors/add?provider=linear`.

| Kind | Body | Default key |
|---|---|---|
| `linear.issues` | A Linear `IssueFilter` as JSON; an issue alerts when it starts matching | `ID` |
| `linear.status` | An `IssueFilter`; an issue alerts each time it lands in a new workflow state | `ID`, `STATE_ID` |
| `linear.triage` | An `IssueFilter` naming the team; issues entering Triage alert | `ID` |
| `linear.sla` | An `IssueFilter` naming the team; SLAs turning high risk or breached (Business and Enterprise) | `ID`, `SLA_STATUS` |
| `linear.inbox` | `category:` one or more notification categories, or `category:all` | `NOTIFICATION_ID` |
| `linear.project-updates` | `health:` (default `atRisk,offTrack`), optional `team:KEY`, `project:slug` | `UPDATE_ID` |

- The issue kinds take the JSON object Linear's API takes as `IssueFilter`, on one or more lines. Not a
  JSON object: `The filter is a JSON object, like {"team":{"key":{"eq":"ENG"}}}.` Linear itself judges
  the fields.
- `linear.triage` and `linear.sla` must have a `"team"` key: `Pick a team: triage is watched team by
  team.` The SLA kind watches `HighRisk` and `Breached` unless the filter names `slaStatus` itself
  (`MediumRisk` is the third value).
- Priorities are numbers: 1 Urgent, 2 High, 3 Medium, 4 Low, 0 none. Relative dates are ISO 8601
  durations: `-P1D` a day ago, `P1D` a day from now. State types: `triage`, `backlog`, `unstarted`,
  `started`, `completed`, `canceled`.
- `linear.inbox` categories: `mentions`, `commentsAndReplies`, `assignments`, `statusChanges`,
  `reactions`, `reviews`, `triage`, `customers`, `postsAndUpdates`, `reminders`, `subscriptions`,
  `documentChanges`, `appsAndIntegrations`, `feed`, `loops`, `billing`, `system`, comma-separated, or
  `all`. Your 50 newest notifications are read.
- `linear.project-updates` health values: `atRisk`, `offTrack`, `onTrack`. Updates of the last 14 days.
- A check reads up to 250 issues. A state entered, or a notification or update created, over an hour
  before the previous check does not alert.

Columns:

- `linear.issues`, `linear.triage`, `linear.sla`: KEY, TITLE, STATE, STATE_TYPE, PRIORITY, ASSIGNEE,
  CREATOR, TEAM, PROJECT, CYCLE, LABELS, CREATED, UPDATED, DUE, SLA_STATUS, SLA_BREACHES_AT, CUSTOMERS,
  URL, ID.
- `linear.status`: the same, plus FROM_STATE, STATE_SINCE, STATE_ID.
- `linear.inbox`: KEY, ISSUE_TITLE, CATEGORY, TYPE, TITLE, SUBTITLE, ACTOR, BODY, CREATED, READ, URL,
  NOTIFICATION_ID.
- `linear.project-updates`: PROJECT, HEALTH, AUTHOR, BODY, CREATED, URL, UPDATE_ID.

Issues, `assigned-to-me.sql`:

```sql
-- name: Assigned to me
-- kind: linear.issues
-- connector: acme
-- every: 5m
-- alert: new-rows
-- title: {KEY} {TITLE}

{"assignee":{"isMe":{"eq":true}},"state":{"type":{"nin":["completed","canceled"]}}}
```

Status changes, `eng-status-changes.sql`:

```sql
-- name: ENG status changes
-- kind: linear.status
-- connector: acme
-- every: 5m
-- alert: new-rows
-- title: {KEY} {FROM_STATE} to {STATE}

{"team":{"key":{"eq":"ENG"}}}
```

New in triage, `eng-triage.sql`:

```sql
-- name: New in ENG triage
-- kind: linear.triage
-- connector: acme
-- every: 5m
-- alert: new-rows

{"team":{"key":{"eq":"ENG"}}}
```

SLA at risk, `eng-sla-at-risk.sql`:

```sql
-- name: ENG SLA at risk
-- kind: linear.sla
-- connector: acme
-- every: 5m
-- alert: new-rows
-- title: {KEY} {TITLE} ({SLA_STATUS})

{"slaStatus":{"in":["MediumRisk","HighRisk","Breached"]},"team":{"key":{"eq":"ENG"}}}
```

Inbox, `linear-mentions.sql`:

```sql
-- name: Linear mentions and replies
-- kind: linear.inbox
-- connector: acme
-- every: 2m
-- alert: new-rows
-- title: {KEY} {SUBTITLE}

category:mentions,commentsAndReplies
```

Project health, `eng-projects-at-risk.sql`:

```sql
-- name: ENG projects at risk
-- kind: linear.project-updates
-- connector: acme
-- every: 1h
-- alert: new-rows
-- title: {PROJECT}: {HEALTH}

health:atRisk,offTrack team:ENG
```

---

## Sentry

Provider id `sentry`. Add form: `coisland://connectors/add?provider=sentry`.

| Kind | Body | Default key |
|---|---|---|
| `sentry.issues` | Any Sentry issue search (empty is `is:unresolved`) | `ID` |
| `sentry.regressions` | `is:regressed` and/or `is:escalating` (both unless given), plus scope | `ID` |
| `sentry.assigned` | `assigned:me` or `assigned_or_suggested:me`, plus search and scope (empty is `assigned:me is:unresolved`) | `ID` |
| `sentry.outages` | `issue.type:` of the monitors to watch, plus search and scope | `ID` |
| `sentry.releases` | `project:slug` (one or more, required), optional `environment:name`, nothing else | `VERSION` |

- Every kind takes CoIsland's `project:slug` (lower-case letters, digits, `-`, `_`) and
  `environment:name`, each repeatable. No project is every project the token sees. The other words are
  Sentry's own search, as typed on Sentry's Issues page.
- Outage issue types: `monitor_check_in_failure` (crons), `uptime_domain_failure` (uptime),
  `metric_issue` (metric monitors), as `issue.type:[a,b]`.
- One request per 100 issues, up to 1,000. Check every minute or more; 5 minutes suits most.
- Releases: created in the last 30 days; a release alerts once.

Columns:

- Issue kinds: SHORT_ID, TITLE, CULPRIT, LEVEL, STATUS, SUBSTATUS, PRIORITY, CATEGORY, TYPE, PROJECT,
  ASSIGNEE, EVENTS, USERS, FIRST_SEEN, LAST_SEEN, URL, ID.
- `sentry.releases`: VERSION, PROJECTS, NEW_ISSUES, CREATED, RELEASED, URL, ID.

Issue search, `new-fatal-errors.sql`:

```sql
-- name: New fatal errors
-- kind: sentry.issues
-- connector: acme
-- every: 5m
-- alert: new-rows
-- title: {SHORT_ID} {TITLE}

environment:production is:unresolved level:fatal
```

Regressed and escalating, `regressions-in-production.sql`:

```sql
-- name: Regressions in production
-- kind: sentry.regressions
-- connector: acme
-- every: 5m
-- alert: new-rows
-- title: {SHORT_ID} {TITLE}

environment:production is:regressed is:escalating
```

Assigned to me, `sentry-assigned-to-me.sql`:

```sql
-- name: Sentry issues assigned to me
-- kind: sentry.assigned
-- connector: acme
-- every: 5m
-- alert: new-rows
-- title: {SHORT_ID} {TITLE}

assigned_or_suggested:me is:unresolved
```

Crons, uptime and metric monitors, `checkout-outages.sql`:

```sql
-- name: Checkout outages
-- kind: sentry.outages
-- connector: acme
-- every: 5m
-- alert: new-rows
-- title: {SHORT_ID} {TITLE}

project:checkout environment:production is:unresolved issue.type:[monitor_check_in_failure,uptime_domain_failure,metric_issue]
```

New releases, `checkout-releases.sql`:

```sql
-- name: Checkout releases
-- kind: sentry.releases
-- connector: acme
-- every: 15m
-- alert: new-rows
-- title: {VERSION} ({NEW_ISSUES} new issues)

project:checkout environment:production
```

---

## PagerDuty

Provider id `pagerduty`. Add form: `coisland://connectors/add?provider=pagerduty`.

| Kind | Body keys | Default key |
|---|---|---|
| `pagerduty.assigned` | `service:`, `status:` (`triggered,acknowledged` default), `urgency:` | `ID`, `ASSIGNED_AT` |
| `pagerduty.incidents` | `service:` or `team:` (or `scope:all`), `status:`, `urgency:` | `ID` |
| `pagerduty.status` | `service:` or `team:` (or `scope:all`), `status:`, `urgency:` | `ID`, `STATUS` |
| `pagerduty.stale-acks` | `older:` (default `30m`), `service:` or `team:` (or `scope:all`), `urgency:` | `ID`, `CHANGED_AT` |
| `pagerduty.oncall-now` | `user:me`, `policy:`, `schedule:` | `POLICY_ID`, `LEVEL`, `START` |
| `pagerduty.oncall-next` | `within:` (default `1h`), `user:me`, `policy:`, `schedule:` | `POLICY_ID`, `LEVEL`, `START` |

- `service:`, `team:`, `policy:` and `schedule:` take PagerDuty IDs (letters and digits, like
  `PABC123`) and repeat. `team:mine` is the connector user's teams, read at each check.
- `incidents`, `status` and `stale-acks` need a service, a team or `scope:all`: `Pick a service or a
  team, or choose all incidents: service:PABC123, team:mine or scope:all.` `scope:all` cannot be
  combined with `service:` or `team:`.
- `status:` is comma-separated among `triggered`, `acknowledged`, `resolved` (`assigned` allows only the
  first two; `status` watches all three unless given). Resolved incidents are those of the last 24 hours.
- `urgency:` takes one value, `high` or `low`; leave it out for both.
- `older:` is from `5m` to `24h`; `within:` from `5m` to `7d`, written with `m`, `h` or `d`.
  `within:` must be longer than the check interval: `within: must be longer than the check interval, or
  a shift can start unseen.`
- `user:` only accepts `me`.
- On call now with `alert: count = 0` tells you when you go off call instead.

Columns:

- Incident kinds: NUMBER, TITLE, STATUS, URGENCY, PRIORITY, SERVICE, SERVICE_ID, ESCALATION_POLICY,
  ASSIGNEES, (ASSIGNED_AT for `assigned`), ACKNOWLEDGERS, CREATED, CHANGED_AT, CHANGED_BY, CHANGED_BY_ID,
  ASSIGNEE_IDS, TEAMS, (ACKED_FOR for `stale-acks`), URL, ID, USER_ID.
- On-call kinds: POLICY, LEVEL, SCHEDULE, START, END, POLICY_ID, SCHEDULE_ID, URL, USER_ID.

Assigned to me, `pagerduty-assigned-to-me.sql`:

```sql
-- name: PagerDuty assigned to me
-- kind: pagerduty.assigned
-- connector: pagerduty
-- every: 1m
-- alert: new-rows
-- title: #{NUMBER} {TITLE}

status:triggered,acknowledged urgency:high
```

Incidents, `triggered-on-my-teams.sql`:

```sql
-- name: Triggered on my teams
-- kind: pagerduty.incidents
-- connector: pagerduty
-- every: 1m
-- alert: new-rows
-- title: #{NUMBER} {TITLE} ({SERVICE})

team:mine status:triggered
```

Status changes, `incident-status-changes.sql`:

```sql
-- name: Incident status changes
-- kind: pagerduty.status
-- connector: pagerduty
-- every: 1m
-- alert: new-rows
-- title: #{NUMBER} {TITLE} is {STATUS}

service:PABC123
```

Acknowledged too long, `acknowledged-too-long.sql`:

```sql
-- name: Acknowledged too long
-- kind: pagerduty.stale-acks
-- connector: pagerduty
-- every: 5m
-- alert: new-rows
-- title: #{NUMBER} {TITLE}

older:30m team:mine
```

On call now, `on-call-now.sql`:

```sql
-- name: On call now
-- kind: pagerduty.oncall-now
-- connector: pagerduty
-- every: 1m
-- alert: new-rows
-- title: {POLICY} level {LEVEL}

user:me
```

Shift starting soon, `shift-starting-soon.sql`:

```sql
-- name: Shift starting soon
-- kind: pagerduty.oncall-next
-- connector: pagerduty
-- every: 5m
-- alert: new-rows
-- title: {POLICY} level {LEVEL} at {START}

within:1h
```

---

## Gmail

Provider id `gmail`. Add form: `coisland://connectors/add?provider=gmail`.

| Kind | Body | Default key |
|---|---|---|
| `gmail.unread` | A Gmail search, as typed in Gmail's search box | `MSGID` |
| `gmail.senders` | One address (`ana@acme.com`) or `@domain` per line; other lines add more search | `MSGID` |
| `gmail.search` | Any Gmail search | `MSGID` |
| `gmail.count` | A Gmail search whose number of matches alerts; use a count rule | `UID` |

- Every kind searches All Mail, so Spam and Trash are left out unless the search asks for them. Lines
  of the body are joined into one search. An empty search is refused: `Write the Gmail search to run.`
- `gmail.senders` searches unread mail in the inbox from any of the senders:
  `from:(a OR b) is:unread in:inbox` plus the extra lines. It needs at least one address or domain.
- `gmail.count` is meant for `alert: count > N` (the editor proposes `count > 20`).
- The newest 100 matching emails are compared; up to 10,000 are counted.
- The editor proposes checking every 2 minutes; 1 minute or more is kind to Gmail.

Columns: SUBJECT, FROM, RECEIVED, LABELS, UNREAD, URL, FROM_ADDRESS, MSGID, THRID, UID.

Unread mail, `unread-inbox.sql`:

```sql
-- name: Unread in the inbox
-- kind: gmail.unread
-- connector: gmail_ana
-- every: 2m
-- alert: new-rows
-- title: {SUBJECT} from {FROM}

in:inbox is:unread
```

Mail from people, `mail-from-legal.sql`:

```sql
-- name: Mail from legal
-- kind: gmail.senders
-- connector: gmail_ana
-- every: 2m
-- alert: new-rows
-- title: {SUBJECT} from {FROM}

ana@acme.com
@acme-legal.com
has:attachment
```

Gmail search, `drive-comments.sql`:

```sql
-- name: Drive comments
-- kind: gmail.search
-- connector: gmail_ana
-- every: 2m
-- alert: new-rows
-- title: {SUBJECT} from {FROM}

from:comments-noreply@docs.google.com is:unread
```

Unread count, `inbox-piling-up.sql`:

```sql
-- name: Inbox piling up
-- kind: gmail.count
-- connector: gmail_ana
-- every: 5m
-- alert: count > 20

in:inbox is:unread
```

---

## Confluence

Provider id `confluence`. Add form: `coisland://connectors/add?provider=confluence`.

| Kind | Body | Default key |
|---|---|---|
| `confluence.search` | Any CQL | `ID` |
| `confluence.mentions` | `space:KEY` (repeatable, none is every space), `within:` | `ID` |
| `confluence.updates` | CQL for the pages to follow; each new version alerts | `ID`, `VERSION` |
| `confluence.comments` | CQL for the pages whose new comments alert (50 pages at most) | `COMMENT_ID` |
| `confluence.tasks` | `space:KEY` (repeatable), `status:`, `due-within:` | `TASK_ID`, `STATE` |

- CQL kinds refuse an empty body: `Write the CQL to run, like type = page AND space = ENG.` Confluence
  judges the CQL itself.
- `confluence.updates` adds `type in (page, blogpost)` and `lastmodified >= now("-2d")` unless the CQL
  says which types or since when.
- `confluence.comments` reads the comments of the last 7 days, of at most 50 pages.
- `within:` (mentions) is `1d`, `3d`, `7d` (default), `14d` or `30d`; keep it longer than the check
  interval.
- `space:` is a space key: letters, digits and `_`, with a leading `~` for a personal space.
- `status:` (tasks) is `open` (default) or `overdue`. `due-within:` is `1d`, `3d` or `7d`, for open
  tasks only.
- A search reads up to 500 items.

Columns:

- `search`, `mentions`, `updates`: TITLE, TYPE, SPACE, PARENT, AUTHOR, LAST_MODIFIED, CREATED, VERSION,
  EXCERPT, URL, ID.
- `comments`: PAGE, AUTHOR, BODY, CREATED, COMMENT_ID, KIND, SPACE, PAGE_ID, URL.
- `tasks`: TASK, PAGE, SPACE, DUE, STATE, AUTHOR, CREATED, TASK_ID, PAGE_ID, URL.

Search (CQL), `new-eng-pages.sql`:

```sql
-- name: New ENG pages
-- kind: confluence.search
-- connector: acme
-- every: 15m
-- alert: new-rows
-- title: {TITLE} by {AUTHOR}

type = page AND space = ENG AND created >= now("-7d")
```

Mentions, `mentions-of-me.sql`:

```sql
-- name: Mentions of me
-- kind: confluence.mentions
-- connector: acme
-- every: 5m
-- alert: new-rows
-- title: {TITLE}

space:ENG within:7d
```

Page updates, `pages-i-watch.sql`:

```sql
-- name: Pages I watch
-- kind: confluence.updates
-- connector: acme
-- every: 15m
-- alert: new-rows
-- title: {TITLE} v{VERSION} by {AUTHOR}

watcher = currentUser()
```

Comments, `comments-on-my-pages.sql`:

```sql
-- name: Comments on my pages
-- kind: confluence.comments
-- connector: acme
-- every: 15m
-- alert: new-rows
-- title: {PAGE}: {AUTHOR}

type = page AND creator = currentUser() AND lastmodified >= now("-30d")
```

Tasks, `overdue-tasks.sql`:

```sql
-- name: Overdue tasks
-- kind: confluence.tasks
-- connector: acme
-- every: 1h
-- alert: new-rows
-- title: {TASK} ({PAGE})

space:ENG status:overdue
```

---

## Calendar

Provider id `calendar`. Add form: `coisland://connectors/add?provider=calendar`. There is one Calendar
connector, this Mac's calendars (named `mac` unless the owner chose another), so leave `connector` out.

| Kind | Body | Default key |
|---|---|---|
| `calendar.meetings` | `lead:`, `horizon:`, `calendar:`, leave-out flags | `ID`, `PHASE` |
| `calendar.changes` | `horizon:`, `calendar:`, `status:pending`, leave-out flags | `ID`, `START`, `END`, `STATUS` |

- `lead:` (meetings only) is minutes of warning, `0` to `60`, like `lead:5m` (default 5).
- `horizon:` is hours or days ahead: `1h` to `24h` for meetings (default `12h`), `1d` to `14d` for
  changes (default `7d`).
- `calendar:` is a calendar id and repeats; none is every calendar.
- Flags that leave events out: `-allday`, `-declined`, `-free`, `-tentative`, `-nolink`, `-solo`.
- `status:pending` (changes only) keeps invitations not answered yet.
- **Alert when is fixed for both kinds:** leave `alert` and `key` out. A meeting alerts within a second
  of its warning time, whatever `every` is.
- The body must not be empty: write at least one word, such as the default `horizon:`.

Columns: TITLE, START, END, CALENDAR, JOIN_SERVICE, JOIN_URL, LOCATION, ORGANIZER, ATTENDEES,
ATTENDEE_COUNT, MY_STATUS, IS_ORGANIZER, STATUS, ALL_DAY, ACCOUNT, PHASE, ALERT, CHANGE, WAS_START,
EVENT_ID, ID.

Meetings, `meetings.sql`:

```sql
-- name: Meetings
-- kind: calendar.meetings
-- every: 1m
-- sound: Glass

lead:5m horizon:12h -allday -declined -free
```

Invitations and changes, `invitations-and-changes.sql`:

```sql
-- name: Invitations and changes
-- kind: calendar.changes
-- every: 5m

horizon:7d -declined
```

---

## Databricks

Provider id `databricks`. Add form: `coisland://connectors/add?provider=databricks`.

| Kind | Body | Default key |
|---|---|---|
| `databricks.custom-sql` | One SQL statement: `SELECT`, `WITH` or `SHOW` | The whole row |
| `databricks.job-runs` | Optional `job:` (repeatable), `status:`, `lookback:` | `RUN_ID`, `END_TIME` |
| `databricks.pipeline-updates` | `pipeline:` (repeatable) or `name:` (a LIKE pattern), optional `status:`, `health:unhealthy` | `PIPELINE_ID`, `UPDATE_ID` |
| `databricks.sql-alerts` | Optional `alert:` (repeatable), `state:` | `ID`, `STATE` |

- **Keep the `kind` line:** a file without one is Snowflake SQL.
- Custom SQL (and "Validation", which saves as Custom SQL) must start with `SELECT`, `WITH` or `SHOW`,
  and must not use a write word anywhere outside strings, quoted names and comments: `INSERT`,
  `UPDATE`, `DELETE`, `MERGE`, `CREATE`, `DROP`, `ALTER`, `TRUNCATE`, `COPY`, `OPTIMIZE`, `VACUUM`,
  `GRANT`, `REVOKE`, `RESTORE`, `MSCK`, `CALL`. `Monitors only read: this SQL uses DELETE. Quote a
  column of that name in backticks.` One statement: `Monitors run one statement; remove what follows
  the ;.`
- A SQL monitor takes `warehouse:` (a warehouse ID or HTTP path), `database:` (the catalog) and
  `schema:`. `role:` does not apply and is ignored with a warning. `timezone:` only changes how times
  display. Each SQL check wakes the warehouse: propose `every: 30m` or more.
- `job:` is a numeric job ID; none is every job the token can view. `status:` is comma-separated among
  `failed`, `timedout` (the default pair), `canceled`, `upstream_failed`, `upstream_canceled`,
  `maximum_concurrent_runs_reached`, `excluded`, `disabled`, `success_with_failures`, `success`.
  `lookback:` is `1h` to `7d` (default `24h`), written with `h` or `d`.
- Pipelines: `pipeline:` IDs or one `name:` pattern like `sales%`, not both; none is every pipeline.
  `status:` is `failed` (default) and/or `canceled`.
- SQL alerts: `alert:` IDs, none is every alert; `state:` is `triggered` (default) and/or `error`.
- Job, pipeline and alert kinds wake no warehouse: `every: 5m` is fine.

Columns:

- Custom SQL: the query's own.
- `databricks.job-runs`: JOB, JOB_ID, RUN_NAME, RUN_ID, RESULT, TERMINATION_CODE, MESSAGE, TRIGGER,
  CREATOR, START_TIME, END_TIME, DURATION, URL.
- `databricks.pipeline-updates`: PIPELINE, PIPELINE_ID, UPDATE_ID, STATE, HEALTH, CAUSE, CREATED,
  RUN_AS, URL.
- `databricks.sql-alerts`: ALERT, ID, STATE, CONDITION, OWNER, LAST_EVALUATED, QUERY, WAREHOUSE_ID, URL.

Custom SQL, `stale-sales-tables.sql`:

```sql
-- name: Stale sales tables
-- kind: databricks.custom-sql
-- connector: dbc-a1b2c3d4
-- warehouse: 1234567890abcdef
-- every: 1h
-- alert: new-rows
-- key: TABLE_NAME
-- title: {TABLE_NAME} not updated since {LAST_ALTERED}

SELECT table_catalog, table_schema, table_name, last_altered
FROM system.information_schema.tables
WHERE table_schema = 'sales' AND last_altered < current_timestamp() - INTERVAL 24 HOURS
```

Validation (bad rows), `orders-with-negative-amounts.sql`:

```sql
-- name: Orders with negative amounts
-- kind: databricks.custom-sql
-- connector: dbc-a1b2c3d4
-- database: main
-- schema: sales
-- every: 30m
-- alert: new-rows
-- key: ORDER_ID

SELECT order_id, amount, placed_at
FROM orders
WHERE amount < 0
```

Failed job runs, `failed-nightly-etl.sql`:

```sql
-- name: Failed nightly ETL
-- kind: databricks.job-runs
-- connector: dbc-a1b2c3d4
-- every: 5m
-- alert: new-rows
-- title: {JOB} {RESULT}: {MESSAGE}

job:123456 status:failed,timedout lookback:24h
```

Failed pipeline updates, `failed-sales-pipelines.sql`:

```sql
-- name: Failed sales pipelines
-- kind: databricks.pipeline-updates
-- connector: dbc-a1b2c3d4
-- every: 5m
-- alert: new-rows
-- title: {PIPELINE} {STATE}

name:sales% status:failed,canceled
```

Triggered SQL alerts, `triggered-sql-alerts.sql`:

```sql
-- name: Triggered SQL alerts
-- kind: databricks.sql-alerts
-- connector: dbc-a1b2c3d4
-- every: 5m
-- alert: new-rows
-- title: {ALERT} {STATE}

state:triggered,error
```
