# 10x-Analyst-Loop — Master Index & Execution Rules

> **PURPOSE:** This file is the SINGLE SOURCE OF TRUTH for Claude when executing any 10x-Analyst-Loop skill.
> Read THIS FILE FIRST before doing anything. Do NOT explore files, do NOT guess, do NOT assume.
> Every path, every command, every error handler is defined here.

---

## RULE 1: Detect User's Operating System FIRST

Before running ANY command, detect the OS and set platform-specific variables.

```
DETECT OS:
  Run: python -c "import platform; print(platform.system())"

  IF output is "Windows":
    OPEN_CMD = "start"
    COPY_CMD = "copy"
    SLASH = "/"           (use forward slashes — Git Bash/MINGW compatible)
    PYTHON = "python"
    NULL = "/dev/null"    (Git Bash) or "NUL" (cmd.exe — avoid)
    MKDIR = "mkdir -p"

  IF output is "Darwin":
    OPEN_CMD = "open"
    COPY_CMD = "cp"
    SLASH = "/"
    PYTHON = "python3"
    NULL = "/dev/null"
    MKDIR = "mkdir -p"

  IF output is "Linux":
    OPEN_CMD = "xdg-open"
    COPY_CMD = "cp"
    SLASH = "/"
    PYTHON = "python3"
    NULL = "/dev/null"
    MKDIR = "mkdir -p"
```

**ALWAYS use forward slashes in paths.** Git Bash on Windows handles them correctly.

---

## RULE 2: Smart Input Resolution (EVERY command does this)

```
GIVEN: first argument ARG from user

STEP A: Check if input/ARG/ exists
  Glob: input/ARG/**/*.csv, *.xlsx, *.xls, *.json
  IF files found:
    PROJECT = ARG
    INPUT_DIR = input/PROJECT/
    GOTO RULE 3

STEP B: Treat ARG as filesystem path
  Check if ARG is a valid directory with data files
  IF YES:
    PROJECT = basename of ARG (last folder name)
    Run: mkdir -p input/PROJECT
    Run: cp ARG/*.csv ARG/*.xlsx ARG/*.xls ARG/*.json input/PROJECT/ 2>/dev/null
    Run: cp ARG/**/*.csv ARG/**/*.xlsx ARG/**/*.json input/PROJECT/ 2>/dev/null
    Tell user: "Registered project 'PROJECT' — data copied to input/PROJECT/"
    INPUT_DIR = input/PROJECT/
    GOTO RULE 3

STEP C: No data found
  Tell user: "No data files found. Place CSV, Excel, or JSON files in input/<project-name>/ and try again."
  STOP. Do not proceed.
```

**input/ is the project registry. NEVER delete projects from it.**

---

## RULE 3: Set Output Paths

```
OUTPUT_DIR = output/PROJECT/
Run: mkdir -p output/PROJECT/charts output/PROJECT/cleaned-data
```

All output goes INSIDE `output/PROJECT/`. Never write outside this directory.

---

## RULE 4: Skill Routing Table

When a command is invoked, follow EXACTLY this routing. Do NOT add steps. Do NOT skip steps.

### `:analyze <project> [question] [--safe]`
```
AGENTS: Data Engineer -> [Statistician + Dashboard PARALLEL] -> Visualizer -> Reporter -> Strategist
SWARM: YES — parallel fork at STEP 6-7 (Statistician + Dashboard run simultaneously)
STEPS:
  1. RULE 1 (detect OS)
  2. RULE 2 (resolve input)
  3. RULE 3 (set output)
  4. IF .mcp-config.json has data_sources: pull fresh data via MCP (STEP 0.5)
  5. Run: $PYTHON scripts/profiler.py input/$PROJECT output/$PROJECT/data-profile.md
  6. Run: $PYTHON scripts/data_cleaner.py input/$PROJECT output/$PROJECT/cleaned-data
  7. PARALLEL FORK — spawn 2 subagents simultaneously:
     Agent A (Statistician): Load cleaned data, detect domain, run EDA, save insights.json
     Agent B (Dashboard): Run dashboard_template.py
  8. WAIT for both agents — then generate charts from insights
  9. Write output/$PROJECT/report.md (template in agents/reporter.md)
  10. Add strategy layer (priority P0-P3, recommendations)
  11. IF .mcp-config.json has messaging: send live updates via MCP (STEP 8)
  12. IF .webhook-config.json exists: POST results via webhook
  13. Present summary + suggest :simplify, :watch, :query
  14. Tell user: "$OPEN_CMD output/$PROJECT/dashboard.html"
IF --safe flag: wrap entire pipeline in Agent(isolation: "worktree")
MODEL: claude-sonnet-4-6
CONTEXT: fork
```

### `:profile <project>`
```
AGENTS: Data Engineer
STEPS:
  1. RULE 1 -> RULE 2 -> RULE 3
  2. Run: $PYTHON scripts/profiler.py input/$PROJECT output/$PROJECT/data-profile.md
  3. Read output, present summary table
  4. Suggest: ":clean $PROJECT" or ":analyze $PROJECT"
MODEL: claude-haiku-4-5-20251001
CONTEXT: fork
```

### `:clean <project>`
```
AGENTS: Data Engineer (swarm mode for 10+ files)
SWARM: CONDITIONAL — if >10 files, split into chunks, spawn parallel subagents
STEPS:
  1. RULE 1 -> RULE 2 -> RULE 3
  2. Count data files. IF <= 10: run cleaner directly
     IF > 10: split into chunks of 10, spawn parallel Agent per chunk
  3. Run: $PYTHON scripts/data_cleaner.py input/$PROJECT output/$PROJECT/cleaned-data
  4. Read output, present cleaning summary
  5. Suggest: ":analyze $PROJECT" or ":visualize $PROJECT"
MODEL: claude-haiku-4-5-20251001
CONTEXT: fork
```

### `:query <project> <question>`
```
AGENTS: Data Engineer -> Statistician -> Strategist
STEPS:
  1. RULE 1 -> RULE 2
  2. Load data from input/$PROJECT/ with pandas
  3. Clean column names (snake_case)
  4. Join tables on _id columns if multiple files
  5. Write + run Python to answer the question
  6. Present: Answer, Supporting Data, How Computed, Follow-Ups
MODEL: claude-sonnet-4-6
CONTEXT: fork
```

### `:visualize <project> <description>`
```
AGENTS: Data Engineer -> Visualizer
STEPS:
  1. RULE 1 -> RULE 2 -> RULE 3
  2. Load data, determine chart type from description
  3. Generate chart with 10x.in style (see RULE 7)
  4. Save to output/$PROJECT/charts/
  5. Tell user file path
MODEL: claude-haiku-4-5-20251001
CONTEXT: fork
```

### `:report <project> [focus]`
```
AGENTS: Data Engineer -> Statistician -> Reporter -> Strategist
STEPS:
  1. RULE 1 -> RULE 2 -> RULE 3
  2. Run profiler + cleaner scripts
  3. Run EDA, save insights.json
  4. Generate charts
  5. Write output/$PROJECT/report.md (template in agents/reporter.md)
  6. Add strategy layer
  7. Present location + top insights
MODEL: claude-sonnet-4-6
CONTEXT: fork
```

### `:dashboard <project>`
```
AGENTS: Data Engineer -> Statistician -> Visualizer
STEPS:
  1. RULE 1 -> RULE 2 -> RULE 3
  2. Run: $PYTHON scripts/dashboard_template.py input/$PROJECT output/$PROJECT/dashboard.html
  3. Tell user: "$OPEN_CMD output/$PROJECT/dashboard.html"
MODEL: claude-sonnet-4-6
CONTEXT: fork
```

### `:watch <project> [interval] [--profile|--dashboard|--full]`
```
AGENTS: Data Engineer (recurring via CronCreate)
SWARM: LOOP — uses CronCreate for scheduled recurring execution
STEPS:
  1. RULE 1 -> RULE 2 -> RULE 3
  2. Run baseline profile: $PYTHON scripts/profiler.py input/$PROJECT output/$PROJECT/data-profile.md
  3. Write initial output/$PROJECT/watch-log.md with session ID
  4. Parse interval ($1 or default "10m") and mode (--profile default, --dashboard, --full)
  5. ToolSearch "select:CronCreate,CronList,CronDelete" to load deferred tools
  6. Use CronCreate to schedule recurring task based on mode
  7. IF quality drops >5% AND .mcp-config.json has messaging: send MCP alert
  8. Confirm to user: watching PROJECT every INTERVAL in MODE
MODEL: claude-haiku-4-5-20251001
DISABLE-MODEL-INVOCATION: true
```

### `:batch-analyze <p1> <p2> ... | input/*`
```
AGENTS: Swarm — one isolated agent per project (up to 10 parallel)
SWARM: YES — full swarm with worktree isolation per project
STEPS:
  1. RULE 1
  2. IF argument contains *: expand glob (e.g., input/* -> all projects)
  3. For EACH argument: run RULE 2 to resolve
  4. Present plan table to user
  5. Spawn one Agent per project with isolation: worktree, run_in_background: true
  6. Each agent runs the full :analyze pipeline independently
  7. Wait for ALL agents to complete
  8. Collect results, present combined summary + cross-project insights
MODEL: claude-sonnet-4-6
DISABLE-MODEL-INVOCATION: true
```

### `:compare <project-a> <project-b>`
```
AGENTS: Data Engineer x2 (parallel worktree) -> Statistician -> Reporter
SWARM: YES — 2 parallel worktree agents profile both projects simultaneously
STEPS:
  1. RULE 1
  2. RULE 2 for $0 (PROJECT_A) and $1 (PROJECT_B)
  3. PARALLEL: Spawn 2 worktree agents to profile both projects simultaneously
  4. WAIT for both agents
  5. Compare: row counts, columns, quality, numeric stats
  6. Write output/$PROJECT_A/comparison-vs-$PROJECT_B.md
  7. Present diff summary
MODEL: claude-sonnet-4-6
CONTEXT: fork
```

### `:research <topic>`
```
AGENTS: None (WebSearch-driven)
STEPS:
  1. RULE 1
  2. Parse topic from $ARGUMENTS
  3. Detect query type: RECOMMENDATIONS / NEWS / PROMPTING / GENERAL
  4. Run 4-6 WebSearch calls in PARALLEL (Reddit, HN, YouTube, X, web)
  5. Rank by engagement signals
  6. Detect cross-platform convergence
  7. Write output/research/<topic-slug>.md
  8. Present key findings inline + file path
MODEL: claude-sonnet-4-6
CONTEXT: fork
```

### `:debug <project> [error-message]`
```
AGENTS: Diagnostician (self-contained)
STEPS:
  1. Check Python deps: pandas, matplotlib, seaborn, openpyxl
  2. Validate input data: empty files, encoding issues, permissions
  3. Check expected output artifacts vs what exists
  4. Match error against common-errors.md pattern database
  5. IF no match: WebSearch for the error
  6. Present diagnosis table + fix + offer to re-run failed step
MODEL: claude-sonnet-4-6
CONTEXT: fork
```

### `:schedule <project> <command> <when>`
```
AGENTS: None (CronCreate-driven)
STEPS:
  1. Parse project, command, time expression
  2. ToolSearch "select:CronCreate,CronList,CronDelete" to load deferred tools
  3. Convert time expression to cron using cron-patterns.md
  4. CronCreate with prompt "/10x-analyst-loop:{command} {project}"
  5. Confirm schedule to user
MODEL: claude-haiku-4-5-20251001
DISABLE-MODEL-INVOCATION: true
```

### `:notify <project> <webhook-url>`
```
AGENTS: None
STEPS:
  1. Validate webhook URL
  2. Write output/$PROJECT/.webhook-config.json
  3. Send test POST
  4. Confirm to user
MODEL: claude-haiku-4-5-20251001
DISABLE-MODEL-INVOCATION: true
```

### `:simplify <project>`
```
AGENTS: 3 parallel review agents (Reuse, Quality, Efficiency)
SWARM: YES — 3 parallel subagents review code simultaneously
STEPS:
  1. Find all .py files in scripts/ and output/$PROJECT/
  2. Spawn 3 parallel review agents: Reuse, Quality, Efficiency
  3. Collect and deduplicate findings, prioritize P0-P3
  4. Auto-apply P0 and P1 fixes
  5. Present P2 and P3 as suggestions
MODEL: claude-sonnet-4-6
CONTEXT: fork
```

### `:api <project> [--serve]`
```
AGENTS: None
STEPS:
  1. Verify output/$PROJECT/ has analysis results
  2. Bundle all artifacts into output/$PROJECT/api-export.json
  3. IF --serve: start local HTTP server on port 8080
  4. Present export summary
MODEL: claude-haiku-4-5-20251001
CONTEXT: fork
```

### `:connect <project> [mcp-name|list]`
```
AGENTS: None (ToolSearch-driven MCP discovery)
STEPS:
  1. Run ToolSearch for all common MCP patterns (parallel)
  2. Classify discovered tools: data_source / messaging / action
  3. Write output/$PROJECT/.mcp-config.json
  4. Present connected integrations table
MODEL: claude-haiku-4-5-20251001
DISABLE-MODEL-INVOCATION: true
```

### `:live-update <project> [target] [message]`
```
AGENTS: None (MCP-driven messaging)
STEPS:
  1. Read output/$PROJECT/.mcp-config.json (if missing: suggest :connect)
  2. Compose message from insights + quality score
  3. For each messaging target: ToolSearch, call MCP tool
  4. Confirm delivery
MODEL: claude-haiku-4-5-20251001
CONTEXT: fork
```

---

## RULE 5: Error Handling & Auto-Recovery

### Retry Protocol

When ANY step fails:

```
ATTEMPT 1: Run the command as specified.
  IF FAIL: Read the error message carefully.

ATTEMPT 2: Fix the most likely cause:
  - "ModuleNotFoundError: No module named 'X'"
    -> Run: $PYTHON -m pip install X
    -> Retry the command

  - "FileNotFoundError" or "No such file or directory"
    -> Check if the path exists with Glob
    -> Check if PROJECT was resolved correctly (RULE 2)
    -> Check if output dirs were created (RULE 3)
    -> Fix path and retry

  - "PermissionError"
    -> On Windows: check if file is open in another program
    -> Tell user which file is locked

  - "pd.errors.EmptyDataError" or "No columns to parse"
    -> File is empty or corrupted
    -> Skip this file, warn user, continue with remaining files

  - "UnicodeDecodeError"
    -> Retry with: pd.read_csv(file, encoding='latin-1')
    -> If still fails: try encoding='cp1252'

  - Script not found
    -> Check relative path: scripts/ from plugin root
    -> Try absolute path using ${CLAUDE_SKILL_DIR}/../../scripts/

  IF STILL FAILS after fix: go to ATTEMPT 3.

ATTEMPT 3: WebSearch for the EXACT error message.
  - Search: "{error message} python pandas fix 2026"
  - Read top 2-3 results
  - Apply the solution
  - Retry the command

  IF STILL FAILS after WebSearch fix:
  - Tell user the exact error
  - Show what was tried
  - Suggest: "/10x-analyst-loop:debug $PROJECT" for deep diagnostics
  - Do NOT loop — STOP after 3 attempts
```

### Common Auto-Fixes Table

| Error | Platform | Auto-Fix |
|-------|----------|----------|
| `No module named 'pandas'` | All | `$PYTHON -m pip install pandas` |
| `No module named 'matplotlib'` | All | `$PYTHON -m pip install matplotlib seaborn` |
| `No module named 'openpyxl'` | All | `$PYTHON -m pip install openpyxl` |
| `No module named 'xlrd'` | All | `$PYTHON -m pip install xlrd` |
| `python3: command not found` | Windows | Use `python` instead |
| `python: command not found` | Mac/Linux | Use `python3` instead |
| `start: command not found` | Mac | Use `open` instead |
| `start: command not found` | Linux | Use `xdg-open` instead |
| `charmap codec can't decode` | Windows | Add `encoding='utf-8'` to read_csv |
| `yt-dlp not found` | All | Skip YouTube in :research, note to user |

---

## RULE 6: File Reference Map

**DO NOT explore files to find things. Use this map.**

### Scripts (run with $PYTHON)
| Script | Purpose | Usage |
|--------|---------|-------|
| `scripts/profiler.py` | Profile data files | `$PYTHON scripts/profiler.py <input-dir> <output-file>` |
| `scripts/data_cleaner.py` | Clean data files | `$PYTHON scripts/data_cleaner.py <input-dir> <output-dir>` |
| `scripts/chart_generator.py` | Generate PNG charts | `$PYTHON scripts/chart_generator.py <data-file> <type> <x-col> [y-col] [output] [title]` |
| `scripts/dashboard_template.py` | Generate HTML dashboard | `$PYTHON scripts/dashboard_template.py <input-dir> <output-file>` |

### Hook Scripts (auto-run via skill hooks)
| Script | Purpose | Trigger |
|--------|---------|---------|
| `scripts/hooks/pre-validate.py` | Validate input data exists | Before :analyze, :batch-analyze |
| `scripts/hooks/post-notify.py` | POST to webhook if configured | After any pipeline |
| `scripts/hooks/post-session-log.py` | Append to session history | After every command |

### Chart Types (for chart_generator.py)
`line`, `bar`, `hbar`, `donut`, `heatmap`, `scatter`, `boxplot`, `histogram`

### Agents (reference only — do NOT run these as scripts)
| Agent | File | When Used |
|-------|------|-----------|
| Data Engineer | `agents/data-engineer.md` | Phase 1 of every pipeline |
| Statistician | `agents/statistician.md` | Phase 2 (EDA, stats) |
| Visualizer | `agents/visualizer.md` | Phase 3 (charts, dashboard) |
| Reporter | `agents/reporter.md` | Phase 4 (report writing) |
| Strategist | `agents/strategist.md` | Phase 5 (recommendations) |

### References (read when needed for patterns/standards)
| File | Contains |
|------|----------|
| `references/analysis-patterns.md` | Python code snippets for common analyses (RFM, cohort, correlation) |
| `references/chart-styles.md` | 10x.in color palette, matplotlib config, Chart.js config |
| `references/data-quality.md` | Quality score formula, cleaning rules, missing value strategy |
| `references/context-injections.md` | All dynamic context injection patterns (Python one-liners) |
| `references/mcp-patterns.md` | MCP auto-discovery patterns, message templates, data ingestion |

### Skills (18 slash commands — invoked by user, not by you)

**Core Analysis (7):**
| Skill | File |
|-------|------|
| `:analyze` | `skills/analyze/SKILL.md` |
| `:profile` | `skills/profile/SKILL.md` |
| `:clean` | `skills/clean/SKILL.md` |
| `:query` | `skills/query/SKILL.md` |
| `:visualize` | `skills/visualize/SKILL.md` |
| `:report` | `skills/report/SKILL.md` |
| `:dashboard` | `skills/dashboard/SKILL.md` |

**Power Commands (4):**
| Skill | File |
|-------|------|
| `:watch` | `skills/watch/SKILL.md` |
| `:batch-analyze` | `skills/batch-analyze/SKILL.md` |
| `:compare` | `skills/compare/SKILL.md` |
| `:research` | `skills/research/SKILL.md` |

**System & DevOps (5):**
| Skill | File |
|-------|------|
| `:debug` | `skills/debug/SKILL.md` |
| `:schedule` | `skills/schedule/SKILL.md` |
| `:notify` | `skills/notify/SKILL.md` |
| `:simplify` | `skills/simplify/SKILL.md` |
| `:api` | `skills/api/SKILL.md` |

**Integration (2):**
| Skill | File |
|-------|------|
| `:connect` | `skills/connect/SKILL.md` |
| `:live-update` | `skills/live-update/SKILL.md` |

### Statusline (bundled — install with `bash statusline/install.sh`)
| File | Purpose |
|------|---------|
| `statusline/core.sh` | v2 engine — themes, layouts, session tracking, agent/cron detection |
| `statusline/helpers.sh` | Utility functions (caching, formatting, rpad) |
| `statusline/json-parser.sh` | Single-pass AWK JSON extractor (no jq dependency) |
| `statusline/statusline-node.js` | Node.js fallback renderer (zero bash dependency) |
| `statusline/statusline-command.sh` | Entry point (delegates to core.sh) |
| `statusline/statusline-config.json` | Default config (10x-swarm layout, burn rate enabled) |
| `statusline/install.sh` | Auto-installer for ~/.claude/ integration |
| `statusline/themes/*.sh` | 5 color themes (default, nord, tokyo-night, catppuccin, gruvbox) |
| `statusline/layouts/*.sh` | 4 layouts (compact, standard, full, 10x-swarm) |

---

## RULE 7: 10x.in Visual Style (memorize, do NOT look up)

```python
COLORS = ['#FF6B35', '#004E89', '#00A878', '#FFD166', '#EF476F', '#118AB2', '#073B4C']
POSITIVE = '#00A878'   # green — growth
NEGATIVE = '#EF476F'   # red — decline
NEUTRAL  = '#004E89'   # blue — info
HIGHLIGHT = '#FF6B35'  # orange — primary
BACKGROUND = '#F5EDE0' # cream — dashboard bg

# Matplotlib setup
import matplotlib.pyplot as plt, seaborn as sns
plt.style.use('seaborn-v0_8-whitegrid')
sns.set_palette(COLORS)
plt.rcParams.update({
    'figure.figsize': (12, 6), 'figure.dpi': 150, 'font.size': 11,
    'axes.titlesize': 14, 'axes.titleweight': 'bold',
    'figure.facecolor': 'white', 'axes.facecolor': 'white',
    'grid.color': '#eeeeee'
})
```

**Chart title rule:** ALWAYS include the key takeaway in the title.
- GOOD: "Revenue Grew 23% MoM Driven by Product X"
- BAD: "Revenue Over Time"

---

## RULE 8: Domain Detection (memorize)

```
IF any column name contains: order, revenue, price, product, customer, cart, checkout, sku
  -> DOMAIN = E-COMMERCE
  -> Run: revenue trends, top products, AOV, RFM, cohort retention, CLV

IF any column name contains: patient, diagnosis, treatment, medication
  -> DOMAIN = HEALTHCARE
  -> Run: outcome distributions, treatment comparisons, time-to-event

IF any column name contains: campaign, clicks, impressions, ctr, conversion
  -> DOMAIN = MARKETING
  -> Run: campaign performance, channel comparison, funnel analysis, ROAS

OTHERWISE:
  -> DOMAIN = GENERAL TABULAR
  -> Run: correlations, distributions, group-by aggregations, anomaly detection, Pareto
```

---

## RULE 9: Output Artifacts Checklist

After ANY pipeline command (`:analyze`, `:report`, `:dashboard`), verify these files exist:

| File | Created By | Required For |
|------|-----------|-------------|
| `output/$PROJECT/data-profile.md` | profiler.py | :analyze, :report |
| `output/$PROJECT/data-profile.json` | profiler.py | :compare, :watch |
| `output/$PROJECT/cleaning-log.md` | data_cleaner.py | :analyze, :report |
| `output/$PROJECT/cleaned-data/*.csv` | data_cleaner.py | Phase 2+ |
| `output/$PROJECT/insights.json` | Statistician | Phase 3+ |
| `output/$PROJECT/charts/*.png` | chart_generator.py | :report |
| `output/$PROJECT/dashboard.html` | dashboard_template.py | user opens in browser |
| `output/$PROJECT/report.md` | Reporter | user reads |
| `output/$PROJECT/watch-log.md` | :watch only | monitoring log |
| `output/$PROJECT/comparison-*.md` | :compare only | diff report |
| `output/research/*.md` | :research only | briefing |

If any expected file is MISSING after a step, re-run that step. If it fails, follow RULE 5 (error handling).

---

## RULE 10: Autonomous Execution Protocol

When running any skill:

1. **Do NOT ask the user for confirmation** on intermediate steps. Just execute.
2. **Do NOT explore the codebase.** Everything you need is in THIS file.
3. **Do NOT read SKILL.md files** during execution — this INDEX has the routing.
4. **Read agent .md files ONLY IF** you need the detailed report template or analysis patterns.
5. **Read reference .md files ONLY IF** you need specific Python code snippets.
6. **Always run steps sequentially** within a pipeline (each step depends on the previous).
7. **Run independent tasks in parallel** (e.g., multiple WebSearches in :research).
8. **Present progress** at natural milestones (after profiling, after analysis, after report).
9. **Always end with** the full list of output files and how to open/use them.
10. **If the user gives a path** that doesn't exist, tell them immediately. Do NOT guess or create fake data.

### Dependency Install (run ONCE per session if needed)
```bash
$PYTHON -m pip install pandas matplotlib seaborn openpyxl xlrd 2>/dev/null
```

---

## RULE 11: Project Registry

The `input/` directory is the permanent project registry.

- `ls input/` shows ALL projects ever analyzed
- Each subfolder is one project
- NEVER delete projects from `input/`
- To list projects, tell user:
  ```
  Registered Projects:
  | # | Project | Files | Last Modified |
  |---|---------|-------|---------------|
  ```
- If user asks "what projects do I have" or "list my data", scan `input/` and show this table.

---

## RULE 12: Branding

Every output file MUST include:
- Header: `Generated by **10x Analyst Loop** | {date} | Session: ${CLAUDE_SESSION_ID} | Powered by 10x.in`
- Footer: `*Generated by [10x Analyst Loop](https://10x.in) v2.0.0*`
- Dashboard footer: `Powered by <a href="https://10x.in">10x.in</a> | 10x-Analyst-Loop v2.0.0`

---

## RULE 13: Voice Routing Table

When invoked via Claude Code voice mode, map natural speech to skills:

| User Says (voice) | Routes To | Notes |
|-------------------|-----------|-------|
| "analyze my sales project" | `:analyze my-sales` | Extract project name |
| "profile this data" | `:profile $0` | |
| "clean the dataset" | `:clean $0` | |
| "what's the average order value" | `:query $0 "average order value"` | |
| "show me a chart of revenue" | `:visualize $0 "revenue chart"` | |
| "write a report" | `:report $0` | |
| "build a dashboard" | `:dashboard $0` | |
| "watch my data every five minutes" | `:watch $0 5m` | Parse time words |
| "analyze all my projects" | `:batch-analyze input/*` | Glob expansion |
| "compare Q1 with Q2" | `:compare q1 q2` | |
| "research e-commerce trends" | `:research "e-commerce trends"` | |
| "debug the analysis" | `:debug $0` | |
| "schedule daily report" | `:schedule $0 report "every day 9am"` | |
| "send results to Slack" | `:live-update $0 slack` | |
| "connect my Shopify" | `:connect $0 shopify` | |
| "export as JSON" | `:api $0` | |
| "simplify the code" | `:simplify $0` | |
| "set up webhook" | `:notify $0 $URL` | Needs URL |

---

## RULE 14: Webhook & Hooks Protocol

### Pre-Hooks (run BEFORE skill execution)
- `pre-validate.py`: Validates input data exists and is readable
- IF exit code 1: **block** the pipeline, show validation errors

### Post-Hooks (run AFTER skill execution)
- `post-session-log.py`: Appends entry to `output/.session-history.json`
- `post-notify.py`: POSTs to webhook if `output/$PROJECT/.webhook-config.json` exists

### Webhook Payload
When a webhook is configured, the post-notify hook sends:
```json
{
  "event": "{command}_complete",
  "project": "{PROJECT}",
  "session_id": "${CLAUDE_SESSION_ID}",
  "timestamp": "ISO-8601",
  "status": "success|partial|failed",
  "artifacts": {...},
  "summary": {...}
}
```

---

## RULE 15: MCP Integration Discovery

When `:connect` or `:live-update` is invoked:

```
STEP 1: Use ToolSearch to scan for available MCP tools (run ALL in parallel):
  ToolSearch("slack message")       -> Slack MCP
  ToolSearch("gmail email send")    -> Gmail MCP
  ToolSearch("shopify")             -> Shopify MCP
  ToolSearch("discord message")     -> Discord MCP
  ToolSearch("database query")      -> DB MCP
  ToolSearch("notion")              -> Notion MCP
  ToolSearch("sheets")              -> Google Sheets MCP
  ToolSearch("composio")            -> Composio MCP
  ToolSearch("telegram")            -> Telegram MCP

STEP 2: For each discovered tool, record:
  - Tool name (e.g., mcp__slack__send_message)
  - Category: data_source | messaging | action
  - Required parameters

STEP 3: Save to output/$PROJECT/.mcp-config.json

STEP 4: When other skills check for MCP:
  - :analyze STEP 0.5 → pull data from data_source MCPs
  - :analyze STEP 8 → send results via messaging MCPs
  - :watch → send quality alerts via messaging MCPs
  - :report STEP 6 → distribute report via messaging MCPs
```

**IMPORTANT:** Do NOT hardcode tool names. ALWAYS discover via ToolSearch first, then call.

---

## RULE 16: Agent Swarm Coordination Protocol

The 10x-Analyst-Loop uses **agent swarms** to maximize throughput and minimize token usage.

### Swarm Patterns Used

| Pattern | Used By | How |
|---------|---------|-----|
| **Parallel Fork** | `:analyze` | Statistician + Dashboard run simultaneously after data engineering |
| **Worktree Swarm** | `:batch-analyze` | One isolated agent per project, up to 10 parallel |
| **Worktree Pair** | `:compare` | 2 worktree agents profile both projects simultaneously |
| **Chunk Swarm** | `:clean` (10+ files) | Split files into chunks, one agent per chunk |
| **Review Swarm** | `:simplify` | 3 parallel review agents (Reuse, Quality, Efficiency) |
| **Search Swarm** | `:research` | 6 parallel WebSearch calls across platforms |
| **Loop Swarm** | `:watch` | CronCreate for scheduled recurring execution |
| **MCP Discovery** | `:connect` | 9+ parallel ToolSearch calls for MCP detection |

### Swarm Rules

1. **Always spawn subagents with `run_in_background: true`** for parallel execution
2. **Use `isolation: "worktree"`** when agents write to the same directories
3. **Wait for ALL agents** before merging results or proceeding
4. **Each agent should be self-contained** — include all context in the prompt, not references
5. **Keep agent prompts explicit** — include exact commands, paths, and expected outputs
6. **Limit parallel agents to 10** to avoid resource contention
7. **Use Agent description field** for clear identification (e.g., "Statistician for my-sales")
8. **Never spawn agents for trivial tasks** — only when parallelism provides real benefit
9. **Log agent completion** in the session history for auditability
10. **Subagents inherit the project context** but NOT the parent's conversation history

### Token Efficiency

Agent swarms are MORE token-efficient than doing everything in one context because:
- Each subagent only loads the context it needs (not the full conversation)
- Parallel execution means total wall-clock time is reduced
- Failed agents can be retried independently without re-running the whole pipeline
- The orchestrator (main agent) only processes summaries, not raw data

---

*10x-Analyst-Loop v2.1.1 | Master Index | [10x.in](https://10x.in) | [GitHub](https://github.com/OpenAnalystInc/10x-analyst-loop)*
