---
name: watch
description: "Live-monitor a data project with /loop — re-profiles on interval, alerts on quality changes. Use when user says 'watch my data', 'monitor this dataset', 'keep checking', or 'alert me if data changes'."
argument-hint: "[project-name-or-path] [interval like 5m, 1h, 30s]"
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Write, Bash, Glob, Grep, CronCreate, CronList, CronDelete
model: claude-haiku-4-5-20251001
hooks:
  post: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/post-session-log.py $0 watch"
---

# 10x Analyst Loop — Data Watcher (uses /loop + CronCreate)

Live-monitor a data project by scheduling recurring profiling. Detects file changes, quality degradation, new files, and row count shifts. Logs everything to `output/<project>/watch-log.md`.

## STEP-BY-STEP INSTRUCTIONS

### STEP 0 — Smart Input Resolution (Auto-Copy + Project Tracking)

The first argument `$0` can be a project name OR a path to any folder on disk.

1. Check if `input/$0/` already exists and contains data files (*.csv, *.xlsx, *.xls, *.json).
2. If YES: PROJECT = `$0`. Input is `input/$0/`.
3. If NO: treat `$0` as a filesystem path.
   a. Verify that path exists.
   b. Extract the folder basename as PROJECT.
   c. Copy ALL data files into `input/PROJECT/` to register this project:
      ```bash
      mkdir -p input/PROJECT
      cp "$0"/*.csv "$0"/*.xlsx "$0"/*.xls "$0"/*.json input/PROJECT/ 2>/dev/null
      cp "$0"/**/*.csv "$0"/**/*.xlsx "$0"/**/*.json input/PROJECT/ 2>/dev/null
      ```
   d. Tell user: "Registered project 'PROJECT' — data copied to input/PROJECT/"
4. If NO data files found anywhere: tell user and STOP.
5. `input/` is the project registry — every project ever worked on stays here.

### STEP 1 — Parse Arguments
```
PROJECT = resolved project name from STEP 0
INTERVAL = first time-like argument ($1 or $2) or default "10m"
MODE = --profile (default) | --dashboard | --full
```
Supported intervals: `30s`, `1m`, `5m`, `10m`, `30m`, `1h`, `2h`, `1d`

**Modes:**
- `--profile` (default): Re-profile only, detect changes, log them
- `--dashboard`: Re-profile + regenerate dashboard on each check
- `--full`: Re-run entire `:analyze` pipeline on each interval (heavy, use with care)

Parse `--mode` from `$ARGUMENTS` if present. Examples:
- `watch my-sales 5m` → profile mode, 5m interval
- `watch my-sales 5m --dashboard` → dashboard mode, 5m interval
- `watch my-sales 1h --full` → full re-analysis every hour

### STEP 2 — Create Initial Baseline Profile
```bash
mkdir -p output/$PROJECT
python ${CLAUDE_SKILL_DIR}/../../scripts/profiler.py input/$PROJECT output/$PROJECT/data-profile.md
```
Read and store the baseline metrics: file count, total rows, quality scores.

### STEP 3 — Initialize Watch Log
Write `output/$PROJECT/watch-log.md`:
```markdown
# Watch Log — {PROJECT}
> Monitoring started by **10x Analyst Loop** | Session: ${CLAUDE_SESSION_ID}
> Interval: {INTERVAL} | Started: {timestamp}

## Baseline
| File | Rows | Quality |
|------|------|---------|
{baseline data}

## Change Log
```

### STEP 3.5 — Dynamic Context Injection (Current State)

Before scheduling, capture current state for comparison:
```bash
python -c "import glob, os, json; files=glob.glob('input/$PROJECT/**/*.*', recursive=True); exts=[f for f in files if f.endswith(('.csv','.xlsx','.xls','.json'))]; stats=[{'file':f,'size':os.path.getsize(f),'mtime':os.path.getmtime(f)} for f in exts]; print(json.dumps(stats))"
```
Store this as the baseline state snapshot for change detection.

### STEP 4 — Schedule Recurring Check with CronCreate

**IMPORTANT:** Before calling CronCreate, run ToolSearch with query `"select:CronCreate,CronList,CronDelete"` to load the deferred tools.

Use the CronCreate tool to schedule a recurring task:
- **Prompt (based on MODE):**

  **--profile mode:**
  "Re-profile input/{PROJECT}/ by running: python ${CLAUDE_SKILL_DIR}/../../scripts/profiler.py input/{PROJECT} output/{PROJECT}/data-profile.md. Compare against baseline. If any file changed (row count, columns, quality >2%), append timestamped entry to output/{PROJECT}/watch-log.md. Note new/removed files. If output/{PROJECT}/.mcp-config.json exists with messaging targets and quality dropped >5%, send alert via MCP."

  **--dashboard mode:**
  "Re-profile input/{PROJECT}/ then regenerate dashboard: python ${CLAUDE_SKILL_DIR}/../../scripts/profiler.py input/{PROJECT} output/{PROJECT}/data-profile.md && python ${CLAUDE_SKILL_DIR}/../../scripts/dashboard_template.py input/{PROJECT} output/{PROJECT}/dashboard.html. Log changes to watch-log.md."

  **--full mode:**
  "Run full 10x Analyst Loop pipeline: /10x-analyst-loop:analyze {PROJECT}. This is a complete re-analysis including profiling, cleaning, EDA, charts, dashboard, and report. Log completion to watch-log.md."

- **Interval:** Convert INTERVAL to cron expression (e.g., `5m` -> `*/5 * * * *`)
- **Recurring:** true

### STEP 5 — Confirm to User
Tell user:
```
Watching project '{PROJECT}' every {INTERVAL}.
- Baseline: {file_count} files, {total_rows} rows, {avg_quality}% quality
- Log: output/{PROJECT}/watch-log.md
- To stop: "cancel the watch job" or "stop watching"
- Note: Watch stops when you close Claude Code or after 3 days.
```

## What Gets Detected
- New files added to `input/PROJECT/`
- Files removed from `input/PROJECT/`
- Row count changes (data appended or deleted)
- Quality score changes (missing values appeared)
- New columns added
- Schema changes (column type changed)

## Examples
```
/10x-analyst-loop:watch my-sales 5m
/10x-analyst-loop:watch my-sales 5m --dashboard
/10x-analyst-loop:watch my-sales 1h --full
/10x-analyst-loop:watch C:/data/live-feed 1m
/10x-analyst-loop:watch inventory-data 30m
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
