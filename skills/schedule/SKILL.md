---
name: schedule
description: "Schedule future or recurring analysis tasks via CronCreate — one-shot reminders or recurring reports. Use when user says 'schedule an analysis', 'run this tomorrow', 'every Monday analyze', or 'remind me to check data'."
argument-hint: "[project-name] [command: analyze|profile|report|dashboard] [when: 'in 30 minutes', 'tomorrow 9am', 'every Monday']"
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Write, Bash, Glob, Grep, CronCreate, CronList, CronDelete
model: claude-haiku-4-5-20251001
hooks:
  post: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/post-session-log.py $0 schedule"
---

# 10x Analyst Loop — Task Scheduler

Schedule future or recurring analysis tasks using CronCreate. Supports natural language time expressions.

## STEP-BY-STEP INSTRUCTIONS

### STEP 0 — Load Deferred Tools

**CRITICAL:** Before anything else, run:
```
ToolSearch with query "select:CronCreate,CronList,CronDelete"
```
This loads the cron tools which are deferred and not available until loaded.

### STEP 1 — Parse Arguments

Extract from `$ARGUMENTS`:
```
PROJECT = first argument (project name or path)
COMMAND = second argument (analyze, profile, report, dashboard, clean, watch)
WHEN = everything after second argument (time expression)
```

If PROJECT is a path, apply Smart Input Resolution:
1. Extract basename as PROJECT
2. Copy files: `mkdir -p input/PROJECT && cp "$0"/*.csv "$0"/*.xlsx "$0"/*.json input/PROJECT/ 2>/dev/null`

If COMMAND is missing: default to `analyze`.
If WHEN is missing: ask user when they want to schedule it.

### STEP 2 — Convert Time Expression to Cron

Read `${CLAUDE_SKILL_DIR}/cron-patterns.md` for the translation table.

Common conversions:
| User Says | Cron Expression | Recurring? |
|-----------|----------------|-----------|
| "in 5 minutes" | Now + 5min | No (one-shot) |
| "in 30 minutes" | Now + 30min | No |
| "tomorrow 9am" | `0 9 {tomorrow_date} * *` | No |
| "every hour" | `0 * * * *` | Yes |
| "every 6 hours" | `0 */6 * * *` | Yes |
| "every day at 9am" | `0 9 * * *` | Yes |
| "every Monday" | `0 9 * * 1` | Yes |
| "every Monday 9am" | `0 9 * * 1` | Yes |
| "every weekday" | `0 9 * * 1-5` | Yes |
| "every first of month" | `0 9 1 * *` | Yes |

For one-shot tasks: use `recurring: false`
For recurring tasks: use `recurring: true`

### STEP 3 — Build the Cron Prompt

The prompt passed to CronCreate should run the 10x-Analyst-Loop skill:

```
prompt: "/10x-analyst-loop:{COMMAND} {PROJECT}"
```

### STEP 4 — Create the Scheduled Task

Call CronCreate:
```
CronCreate(
  schedule: "{cron_expression}",
  prompt: "/10x-analyst-loop:{COMMAND} {PROJECT}",
  recurring: {true|false}
)
```

### STEP 5 — Confirm to User

```
Scheduled! ✓

| Detail | Value |
|--------|-------|
| Project | {PROJECT} |
| Command | :{COMMAND} |
| Schedule | {human-readable time} |
| Cron | {cron_expression} |
| Recurring | {Yes/No} |
| Auto-expires | 3 days (Claude Code limit) |

To view scheduled tasks: "list my schedules"
To cancel: "cancel the {COMMAND} schedule for {PROJECT}"
```

### STEP 6 — List or Cancel (if requested)

If user says "list" or "show schedules":
- Call CronList to show all active cron jobs

If user says "cancel" or "stop":
- Call CronList to find the job
- Call CronDelete with the job ID

## Examples
```
/10x-analyst-loop:schedule my-sales analyze "every day at 9am"
/10x-analyst-loop:schedule q1-data report "tomorrow 9am"
/10x-analyst-loop:schedule inventory profile "every 6 hours"
/10x-analyst-loop:schedule C:/data/live-feed watch "every hour"
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
