---
name: analyze
description: "Full agentic analysis pipeline — ingest, clean, analyze, visualize, report, and dashboard from any data project. Use when user says 'analyze this data', 'give me insights', 'full analysis', or 'what does this data tell us'."
argument-hint: "[project-name] [optional-question]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch
model: claude-sonnet-4-6
context: fork
agent: general-purpose
hooks:
  pre: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/pre-validate.py $0"
  post: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/post-session-log.py $0 analyze"
---

# 10x Analyst Loop — Full Analysis Pipeline (Agent Swarm)

Run the complete 5-agent swarm pipeline on any CSV, Excel, or JSON data project.
Uses **parallel subagents** to maximize throughput and minimize token usage.

Reads from `input/<project>/`, writes everything to `output/<project>/`.

**Swarm Architecture:**
```
STEP 0-3: Sequential (data must exist before analysis)
STEP 4+5: PARALLEL FORK (Statistician + Visualizer run simultaneously)
STEP 6: Sequential (needs insights from STEP 4)
STEP 7: Sequential (needs report from STEP 6)
STEP 8: Conditional (MCP updates)
```

**Flags:**
- `--safe` → Run entire pipeline in an isolated worktree, copy results back on success

## STEP-BY-STEP INSTRUCTIONS

Follow these steps EXACTLY in order. Each step produces files the next step needs.
If `--safe` flag is present in `$ARGUMENTS`: run entire pipeline inside `Agent(isolation: "worktree")`.

### STEP 0 — Smart Input Resolution (Auto-Copy + Project Tracking)

The first argument `$0` can be a project name OR a path to any folder on disk.

1. Check if `input/$0/` already exists and contains data files (*.csv, *.xlsx, *.xls, *.json).
2. If YES: PROJECT = `$0`. Input is `input/$0/`.
3. If NO: treat `$0` as a filesystem path.
   a. Verify that path exists and contains data files.
   b. Extract the folder basename as PROJECT.
   c. Copy ALL data files into `input/PROJECT/` to register this project:
      ```bash
      mkdir -p input/PROJECT
      cp "$0"/*.csv "$0"/*.xlsx "$0"/*.xls "$0"/*.json input/PROJECT/ 2>/dev/null
      cp "$0"/**/*.csv "$0"/**/*.xlsx "$0"/**/*.json input/PROJECT/ 2>/dev/null
      ```
   d. Tell user: "Registered project 'PROJECT' — data copied to input/PROJECT/"
4. If NO data files found at either location: tell user and STOP.
5. The `input/` folder is the project registry — every project ever worked on stays here.

```
PROJECT = resolved project name
QUESTION = everything after first argument (optional focus question)
INPUT_DIR = input/PROJECT/
OUTPUT_DIR = output/PROJECT/
```

### STEP 1 — Verify Input Data Exists

1. Use Glob to find files in `input/PROJECT/`:
   - `input/PROJECT/**/*.csv`, `*.xlsx`, `*.xls`, `*.json`
2. If ZERO files found: tell user and STOP.
3. If files found: list them with file sizes and continue.

### STEP 0.5 — MCP Data Pull (if configured)

IF `output/$0/.mcp-config.json` exists AND has `data_sources`:
1. Read the MCP config
2. For each data source:
   - Use ToolSearch to find the MCP tool (e.g., `ToolSearch("shopify orders")`)
   - Call the discovered tool to pull fresh data
   - Save results as CSV to `input/$0/{source}_{table}.csv`
3. Tell user: "Pulled fresh data from {sources} into input/$0/"

IF no `.mcp-config.json` or no data sources: skip silently.

### STEP 2 — Create Output Directories

```bash
mkdir -p output/$0/charts output/$0/cleaned-data
```

### STEP 2.5 — Dynamic Context Injection

Gather live context about the project before analysis begins:
```bash
python -c "import glob, os; files=glob.glob('input/$0/**/*.*', recursive=True); exts=[f for f in files if f.endswith(('.csv','.xlsx','.xls','.json'))]; total=sum(os.path.getsize(f) for f in exts); print(f'FILES={len(exts)} TOTAL_SIZE={total} bytes')"
```
Use this context to calibrate analysis depth: <10 files = standard, 10-50 = chunked, 50+ = sampling.

### STEP 3 — PHASE 1: Data Engineering (Profile + Clean)

Run profiler:
```bash
python ${CLAUDE_SKILL_DIR}/../../scripts/profiler.py input/$0 output/$0/data-profile.md
```

Run cleaner:
```bash
python ${CLAUDE_SKILL_DIR}/../../scripts/data_cleaner.py input/$0 output/$0/cleaned-data
```

Read output of both scripts. Present data inventory:
```
| File | Rows | Columns | Quality | Issues |
|------|------|---------|---------|--------|
```

### STEP 4+5 — PARALLEL SWARM FORK: Statistics + Visualization

**This is the core swarm optimization.** After data engineering completes, the Statistician and Visualizer/Dashboard agents can run **in parallel** because they both read from cleaned data independently.

Spawn **2 parallel subagents** using the Agent tool. Send BOTH in the same message:

**SUBAGENT A — Statistician (EDA + Insights):**
```
Agent(
  description: "Statistician for $0",
  prompt: "You are the 10x Analyst Loop Statistician agent.

    Load ALL cleaned data from output/$0/cleaned-data/.

    1. Detect domain:
       - Columns contain order, revenue, price, product, customer -> E-COMMERCE
       - Otherwise -> GENERAL TABULAR

    2. E-COMMERCE analysis:
       - Revenue by month: df.groupby(pd.Grouper(key='date_col', freq='M'))['revenue_col'].sum()
       - Top 10 products by revenue
       - AOV: df.groupby('order_id_col')['revenue_col'].sum().mean()
       - RFM segmentation with quartile scores
       - Cohort retention analysis

    3. GENERAL analysis:
       - Correlation matrix, flag |r| > 0.7
       - Full describe(include='all')
       - Top-N value counts for categoricals
       - Pareto analysis (80/20 rule)
       - Anomaly detection (IQR method)

    4. Save insights to output/$0/insights.json:
       [{\"id\": \"insight-001\", \"headline\": \"...\", \"category\": \"...\", \"value\": 0, \"change_pct\": 0, \"implication\": \"...\", \"priority\": \"P0\"}]

    Return: number of insights found + top 3 headlines.",
  run_in_background: true
)
```

**SUBAGENT B — Dashboard Builder:**
```
Agent(
  description: "Dashboard for $0",
  prompt: "You are the 10x Analyst Loop Dashboard agent.

    Run the dashboard generator:
    python ${CLAUDE_SKILL_DIR}/../../scripts/dashboard_template.py input/$0 output/$0/dashboard.html

    If the script fails, build a standalone HTML dashboard manually:
    - Read cleaned data from output/$0/cleaned-data/
    - Create KPI cards with delta indicators using Chart.js CDN
    - Use 10x.in color palette: ['#FF6B35', '#004E89', '#00A878', '#FFD166', '#EF476F', '#118AB2', '#073B4C']
    - Background: #F5EDE0, cards: white with 12px radius
    - Include responsive layout, works offline after first load

    Return: dashboard file path and KPI count.",
  run_in_background: true
)
```

**Wait for BOTH subagents to complete.** Then continue to STEP 5.5.

### STEP 5.5 — Post-Fork: Generate Charts from Insights

After the Statistician subagent completes:
1. Read `output/$0/insights.json`
2. Generate PNG charts with 10x.in style:
```python
import matplotlib.pyplot as plt, seaborn as sns
COLORS = ['#FF6B35', '#004E89', '#00A878', '#FFD166', '#EF476F', '#118AB2', '#073B4C']
plt.style.use('seaborn-v0_8-whitegrid')
sns.set_palette(COLORS)
plt.rcParams.update({'figure.figsize': (12, 6), 'figure.dpi': 150, 'font.size': 11})
```
3. Chart by insight type: Trend->line, Top-N->hbar, Proportion->donut, Correlation->heatmap, Distribution->histogram
4. Save to `output/$0/charts/`

**Why not in the parallel fork?** Charts need insights.json which the Statistician produces. The dashboard uses the script (no insights needed). So: Stats + Dashboard in parallel, then charts after stats.

### STEP 6 — PHASE 4: Report

Write `output/$0/report.md`:
```markdown
# Data Analysis Report
> Generated by **10x Analyst Loop** | {date} | Source: input/{project} | Session: ${CLAUDE_SESSION_ID} | Powered by 10x.in

## Executive Summary
- {3-5 bullets: metric + direction + magnitude + implication}

## Data Overview
| Metric | Value |
|--------|-------|

## Key Findings
### 1. {Headline}
{Numbers + context}
![Chart](charts/chart_name.png)
**Implication:** {Business meaning}

## Recommendations
1. **{Action}** -- Finding #X -> Expected impact: {outcome}

## Methodology
## Appendix
---
*Generated by [10x Analyst Loop](https://10x.in) v2.0.0*
```

### STEP 7 — PHASE 5: Strategy

1. Prioritize insights: P0 (critical) -> P3 (low)
2. Generate actionable recommendations with expected impact
3. Append executive brief to report
4. Present final summary:
   - All files created in `output/$0/`
   - Top 3 insights
   - Open dashboard: `start output/$0/dashboard.html`
   - Suggest: `:watch $0 5m` for monitoring, `:query $0 <question>` for follow-ups
   - Suggest: `:simplify $0` to optimize generated code

### STEP 8 — MCP Live Updates (if configured)

IF `output/$0/.mcp-config.json` exists:
1. Read the config for messaging targets (Slack, Gmail, Discord, etc.)
2. For each messaging target:
   - Compose summary: top 3 insights + dashboard link + quality score
   - Use ToolSearch to find the MCP tool (e.g., `ToolSearch("slack message")`)
   - Call the discovered MCP tool to send the message
3. Tell user: "Live updates sent to: {list of targets}"

IF no `.mcp-config.json`: skip silently.

## Examples
```
/10x-analyst-loop:analyze my-sales
/10x-analyst-loop:analyze q1-data "Which segments are most profitable?"
/10x-analyst-loop:analyze customer-export
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
