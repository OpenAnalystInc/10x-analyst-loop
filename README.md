<p align="center">
  <img src="https://10x.in/logo.png" alt="10x.in" width="120" />
</p>

<h1 align="center">10x-Analyst-Loop</h1>

<p align="center">
  <strong>Supercharged Agentic Analysis Swarm v2.1.1</strong><br/>
  A multi-agent Claude Code plugin for end-to-end data analysis automation<br/>
  Built by the <a href="https://10x.in">10x Team</a>
</p>

<p align="center">
  <a href="https://10x.in">Website</a> &middot;
  <a href="https://github.com/OpenAnalystInc/10x-analyst-loop">GitHub</a> &middot;
  <a href="https://openanalystinc.github.io/10x-analyst-loop/">Landing Page</a> &middot;
  <a href="#quick-start">Quick Start</a> &middot;
  <a href="#user-flow">User Flow</a> &middot;
  <a href="#use-cases">Use Cases</a> &middot;
  <a href="#commands">All Commands</a> &middot;
  <a href="#mcp-integration">MCP Integration</a> &middot;
  <a href="#architecture">Architecture</a> &middot;
  <a href="#statusline">Statusline</a>
</p>

---

> **Proprietary Software** — This plugin is the intellectual property of [10x.in](https://10x.in) and is developed, maintained, and owned by the **10x Team**. All rights reserved. Unauthorized reproduction, distribution, or commercial use without explicit written permission from 10x.in is strictly prohibited.

---

## What is 10x-Analyst-Loop?

**10x-Analyst-Loop** is a production-grade Claude Code plugin that transforms raw data into actionable insights, comprehensive reports, and interactive dashboards — fully automated through a coordinated swarm of five specialist AI agents.

Drop any CSV, Excel, or JSON files into a folder. Point the plugin at it. Walk away. Come back to a complete analysis: cleaned data, statistical insights, publication-ready charts, an interactive HTML dashboard, a Markdown report with business recommendations, and optional live notifications to Slack, Gmail, or Discord.

### Why 10x-Analyst-Loop?

- **Zero-config analysis** — No setup, no config files, no boilerplate. One command does everything.
- **Multi-agent swarm** — 5 specialist agents (Data Engineer, Statistician, Visualizer, Reporter, Strategist) work in parallel for maximum throughput.
- **Works on ALL models** — Every instruction is explicit step-by-step so Haiku, Sonnet, and Opus all produce full-quality output.
- **MCP-powered integrations** — Auto-discover and connect Shopify, databases, Google Sheets, Slack, Gmail, Discord, and more.
- **Voice-friendly** — All 18 commands work with Claude Code voice mode. Just speak naturally.
- **Self-healing pipeline** — 3-attempt auto-recovery with dependency installation, path fixing, and web search for unknown errors.

### v2.1.1 Highlights

- Agent swarms with parallel subagents and worktree isolation
- MCP integration for external data sources and live messaging
- Webhook notifications for pipeline events
- Scheduled/recurring tasks via CronCreate
- Deep pipeline debugging with auto-diagnosis
- 3-agent code review swarm for generated code quality
- API export with optional local HTTP server
- Bundled statusline with agent/cron monitoring and 5 themes

---

## Quick Start

```bash
# Option 1: Point at any folder on your system
/10x-analyst-loop:analyze C:/Users/you/Desktop/sales-data

# Option 2: Place files in the project registry manually
mkdir -p input/my-project
cp ~/data/*.csv input/my-project/
/10x-analyst-loop:analyze my-project

# Open the generated dashboard
start output/my-project/dashboard.html    # Windows
open output/my-project/dashboard.html     # macOS
xdg-open output/my-project/dashboard.html # Linux
```

That's it. The plugin auto-copies data into the project registry, runs the full 5-agent pipeline, and outputs everything to `output/my-project/`.

---

## User Flow

Here's exactly what happens when you run a command, step by step:

### Flow 1: First-Time Analysis (`/10x-analyst-loop:analyze`)

```
YOU                                    10x-ANALYST-LOOP
 |                                            |
 |  "/analyze C:/Users/me/sales-data"         |
 |  ----------------------------------------> |
 |                                            |
 |                              [1] Detect OS (Windows/Mac/Linux)
 |                              [2] Resolve input path
 |                                  -> Found: C:/Users/me/sales-data/
 |                                  -> Copy files to input/sales-data/
 |                              [3] Create output/sales-data/charts/
 |                                            |
 |  "Registered project 'sales-data'"         |
 |  <---------------------------------------- |
 |                                            |
 |                              [4] PHASE 1: Data Engineering
 |                                  -> Run profiler.py (structure, quality, types)
 |                                  -> Run data_cleaner.py (normalize, dedupe, parse dates)
 |                                            |
 |  "3 files profiled, 95.2% quality"         |
 |  <---------------------------------------- |
 |                                            |
 |                              [5] PHASE 2+3: PARALLEL SWARM FORK
 |                                  -> Agent A: Statistician (EDA, insights, RFM)
 |                                  -> Agent B: Dashboard Builder (HTML + Chart.js)
 |                                  -> Both run SIMULTANEOUSLY
 |                                            |
 |                              [6] PHASE 3.5: Generate Charts
 |                                  -> Read insights.json from Statistician
 |                                  -> Create PNG charts with 10x.in style
 |                                            |
 |                              [7] PHASE 4: Reporter
 |                                  -> Write report.md with executive summary
 |                                  -> Embed chart references
 |                                            |
 |                              [8] PHASE 5: Strategist
 |                                  -> Prioritize findings P0-P3
 |                                  -> Generate actionable recommendations
 |                                            |
 |  "Analysis complete! 12 insights found"    |
 |  "Top: Revenue grew 23% MoM"              |
 |  "Open: start output/sales-data/dashboard" |
 |  <---------------------------------------- |
 |                                            |
```

### Flow 2: Returning User (project already registered)

```
/10x-analyst-loop:query sales-data "What is the average order value by month?"

-> Loads data from input/sales-data/ (already registered)
-> Cleans column names, joins tables if needed
-> Writes + runs Python to compute AOV by month
-> Presents: Answer, Supporting Data, How Computed, Follow-Up Questions
```

### Flow 3: MCP-Connected Workflow

```
Step 1: /10x-analyst-loop:connect my-store shopify
        -> Auto-discovers Shopify MCP tools
        -> Saves config to output/my-store/.mcp-config.json

Step 2: /10x-analyst-loop:connect my-store slack #analytics
        -> Discovers Slack MCP tools
        -> Adds messaging target to config

Step 3: /10x-analyst-loop:analyze my-store
        -> STEP 0.5: Auto-pulls fresh data from Shopify MCP
        -> Runs full 5-agent pipeline
        -> STEP 8: Sends top insights + dashboard link to Slack #analytics
```

### Flow 4: Continuous Monitoring

```
/10x-analyst-loop:watch inventory 5m --dashboard

-> Runs baseline profile
-> Creates CronCreate job: re-profile every 5 minutes
-> On each run: compare quality vs baseline
-> If quality drops >5%: send alert via MCP (Slack/Discord/email)
-> Logs all changes to output/inventory/watch-log.md
```

### Flow 5: Multi-Project Batch

```
/10x-analyst-loop:batch-analyze q1-sales q2-sales q3-sales

-> Resolves all 3 projects
-> Spawns 3 parallel agents in isolated worktrees
-> Each agent runs the full :analyze pipeline independently
-> Waits for all agents to complete
-> Presents combined summary + cross-project insights
```

---

## Use Cases

### Use Case 1: E-Commerce Store Owner — "Where is my revenue going?"

**Scenario:** You run a Shopify store with 50,000+ orders. You export your data monthly but never have time to analyze it properly.

**Solution:**

```bash
# Connect Shopify for live data pulls
/10x-analyst-loop:connect my-store shopify

# Run full analysis
/10x-analyst-loop:analyze my-store
```

**What you get:**

| Output | What It Contains |
|--------|-----------------|
| `data-profile.md` | 50,234 orders across 3 files, 97.1% quality score, 8 columns profiled |
| `insights.json` | Revenue trend (+23% MoM), Top 10 products (3 drive 60% of revenue), AOV = $67.40, RFM segmentation (Champions: 12%, At Risk: 8%), Cohort retention (Month 3 drop-off: 45%) |
| `dashboard.html` | Interactive HTML with KPI cards, trend lines, product breakdown, RFM scatter |
| `report.md` | Executive summary, 12 findings with charts, prioritized recommendations |
| `charts/` | 8 PNG charts: revenue trend, top products, AOV over time, RFM distribution, cohort heatmap |

**Follow-up commands:**
```bash
/10x-analyst-loop:query my-store "Which customer segments have the highest CLV?"
/10x-analyst-loop:watch my-store 1h --full     # Re-analyze hourly
/10x-analyst-loop:live-update my-store slack    # Send insights to #analytics
```

**MCP integrations used:** Shopify (data source), Slack (messaging)

---

### Use Case 2: Marketing Team — "Which campaigns actually work?"

**Scenario:** Your team runs campaigns across Google Ads, Meta, and email. You have CSVs from each platform but no unified view.

**Solution:**

```bash
# Drop all platform exports into one folder
/10x-analyst-loop:analyze C:/Marketing/Q1-campaigns
```

**What you get:**

- **Domain auto-detected:** MARKETING (columns contain `campaign`, `clicks`, `impressions`, `ctr`, `conversion`)
- **Cross-platform analysis:** Campaign performance comparison, channel ROAS, funnel analysis, budget allocation efficiency
- **Unified dashboard:** All platforms in one interactive view with filters
- **Report:** "Google Ads drives 3.2x ROAS vs Meta's 1.8x. Email has highest conversion rate (4.2%) but lowest reach."

**Follow-up commands:**
```bash
/10x-analyst-loop:compare q1-campaigns q2-campaigns  # Quarter-over-quarter
/10x-analyst-loop:visualize q1-campaigns "ROAS by channel stacked bar"
/10x-analyst-loop:schedule q1-campaigns report "every monday 9am"
```

---

### Use Case 3: Data Analyst — "I need to analyze 15 datasets by Friday"

**Scenario:** You received 15 project datasets from different departments. Each needs profiling, cleaning, and a basic report.

**Solution:**

```bash
# Place all datasets in input/
# Each subfolder = one project
/10x-analyst-loop:batch-analyze input/*
```

**What happens:**

1. Plugin expands `input/*` to all 15 projects
2. Spawns **15 parallel agents** in isolated worktrees (capped at 10 concurrent)
3. Each agent independently: profiles, cleans, analyzes, generates dashboard + report
4. Waits for all agents to complete
5. Presents combined summary table:

```
| # | Project       | Files | Rows    | Quality | Top Insight                    |
|---|---------------|-------|---------|---------|-------------------------------|
| 1 | hr-data       | 3     | 12,450  | 94.2%   | Attrition spikes in Q3        |
| 2 | finance-q1    | 2     | 8,320   | 98.1%   | OpEx grew 15% above budget    |
| 3 | support-tickets| 1    | 45,000  | 87.3%   | Resolution time up 22%        |
| ...               |       |         |         |                               |
```

**Why this is powerful:** Without batch-analyze, you'd run 15 separate analyses. With it, they all run in parallel — total time is roughly the same as one analysis.

---

### Use Case 4: Ops Manager — "Alert me when data quality drops"

**Scenario:** You have an automated data pipeline that dumps CSVs into a folder. Sometimes the export breaks and produces garbage data. You need to know immediately.

**Solution:**

```bash
# Set up continuous monitoring with Slack alerts
/10x-analyst-loop:connect pipeline-data slack #data-alerts
/10x-analyst-loop:watch pipeline-data 10m --profile

# Optionally, set up a webhook for PagerDuty
/10x-analyst-loop:notify pipeline-data https://events.pagerduty.com/v2/enqueue
```

**What happens:**

- Every 10 minutes, the plugin re-profiles `input/pipeline-data/`
- Compares quality score against the baseline
- If quality drops >5%: sends alert to Slack `#data-alerts` with details
- If webhook configured: POSTs structured JSON payload to PagerDuty
- Logs all changes to `output/pipeline-data/watch-log.md`

**Alert format (Slack):**
```
⚠️ Data Quality Alert — pipeline-data
Quality dropped from 96.4% to 82.1%
3 new issues detected:
- orders.csv: 14% missing values in 'customer_id'
- orders.csv: 230 duplicate rows detected
- products.csv: encoding error in 'description' column
Check: output/pipeline-data/watch-log.md
```

**MCP integrations used:** Slack (alerts), Webhook (PagerDuty)

---

### Use Case 5: Startup Founder — "Research the market and analyze our data"

**Scenario:** You're building a SaaS product. You need to (a) research competitor pricing trends and (b) analyze your own user engagement data — all from Claude Code.

**Solution:**

```bash
# Part 1: Market research (no data files needed)
/10x-analyst-loop:research "SaaS pricing trends 2026"

# Part 2: Analyze your own data
/10x-analyst-loop:analyze user-engagement

# Part 3: Send findings to your team
/10x-analyst-loop:connect user-engagement slack #product
/10x-analyst-loop:connect user-engagement gmail
/10x-analyst-loop:live-update user-engagement slack "Weekly engagement report"
/10x-analyst-loop:live-update user-engagement gmail "Engagement analysis attached"
```

**`:research` output** (`output/research/saas-pricing-trends-2026.md`):
- 6 parallel WebSearches across Reddit, Hacker News, X/Twitter, YouTube, general web
- Cross-platform convergence detection (what appears on multiple sources)
- Ranked by engagement signals (upvotes, shares, comments)
- Key findings: pricing benchmarks, competitor moves, community sentiment

**`:analyze` output:**
- Full pipeline on your user data
- Domain auto-detected: GENERAL TABULAR (or E-COMMERCE if applicable)
- Engagement metrics, cohort retention, feature usage, churn indicators

**MCP integrations used:** Slack (team updates), Gmail (stakeholder reports)

---

## All Commands (18 total)

### Core Analysis Commands (7)

| Command | Description | Model | Agents |
|---------|-------------|-------|--------|
| `:analyze <project> [--safe]` | Full 5-agent swarm pipeline — ingest, clean, analyze, visualize, report, dashboard | Sonnet | Data Engineer → [Statistician + Dashboard **PARALLEL**] → Visualizer → Reporter → Strategist |
| `:profile <project>` | Data profiling and quality assessment | Haiku | Data Engineer |
| `:clean <project>` | Data cleaning and transformation (swarm mode for 10+ files) | Haiku | Data Engineer (chunk swarm if 10+ files) |
| `:query <project> <question>` | Ask natural language questions about your data | Sonnet | Data Engineer → Statistician → Strategist |
| `:visualize <project> <desc>` | Generate charts and visualizations | Haiku | Data Engineer → Visualizer |
| `:report <project>` | Generate a comprehensive Markdown analysis report | Sonnet | Data Engineer → Statistician → Reporter → Strategist |
| `:dashboard <project>` | Build a standalone interactive HTML dashboard | Sonnet | Data Engineer → Statistician → Visualizer |

### Power Commands (4)

| Command | Description | Model | Swarm Pattern |
|---------|-------------|-------|---------------|
| `:watch <project> [interval] [--mode]` | Live-monitor with CronCreate — profile, dashboard, or full re-analysis on a schedule | Haiku | Loop Swarm (CronCreate) |
| `:batch-analyze <p1> <p2> ... \| input/*` | Parallel agents per project, each in isolated worktree | Sonnet | Worktree Swarm (up to 10 parallel) |
| `:compare <project-a> <project-b>` | Parallel worktree profiling + side-by-side diff report | Sonnet | Worktree Pair |
| `:research <topic>` | Multi-source research across Reddit, X, HN, YouTube, web | Sonnet | Search Swarm (6 parallel WebSearches) |

### System & DevOps Commands (5)

| Command | Description | Model |
|---------|-------------|-------|
| `:debug <project> [error]` | Auto-diagnose pipeline failures — check deps, validate data, search fixes | Sonnet |
| `:schedule <project> <cmd> <when>` | Schedule future/recurring tasks via CronCreate | Haiku |
| `:notify <project> <webhook-url>` | Configure webhook notifications for pipeline events | Haiku |
| `:simplify <project>` | 3-agent code review swarm (Reuse + Quality + Efficiency) | Sonnet |
| `:api <project> [--serve]` | Export all artifacts as structured JSON, optionally serve on port 8080 | Haiku |

### Integration Commands (2)

| Command | Description | Model |
|---------|-------------|-------|
| `:connect <project> [mcp-name\|list]` | Auto-discover & configure MCP data sources and messaging apps | Haiku |
| `:live-update <project> [target] [message]` | Send results to connected apps (Slack, Gmail, Discord, Telegram) | Haiku |

---

## MCP Integration

MCP (Model Context Protocol) servers extend the plugin with external data sources and messaging. The plugin **auto-discovers** available MCPs — you never hardcode tool names.

### How MCP Works with 10x-Analyst-Loop

```
                          ┌─────────────────────┐
                          │   10x-Analyst-Loop   │
                          │     Orchestrator     │
                          └──────────┬──────────┘
                                     │
              ┌──────────────────────┼──────────────────────┐
              │                      │                      │
     ┌────────▼────────┐   ┌────────▼────────┐   ┌────────▼────────┐
     │   DATA SOURCES  │   │    MESSAGING    │   │     ACTIONS     │
     │                  │   │                  │   │                  │
     │  Shopify         │   │  Slack           │   │  Composio        │
     │  PostgreSQL      │   │  Gmail           │   │  Zapier          │
     │  Google Sheets   │   │  Discord         │   │                  │
     │  Notion          │   │  Telegram        │   │                  │
     │  Airtable        │   │  Teams           │   │                  │
     │  Stripe          │   │                  │   │                  │
     │  Supabase        │   │                  │   │                  │
     └─────────────────┘   └─────────────────┘   └─────────────────┘
```

### MCP Discovery Protocol

The plugin uses `ToolSearch` to discover available MCP tools at runtime. It runs **9+ parallel searches** simultaneously:

```
ToolSearch("slack message")        -> Slack MCP
ToolSearch("gmail email send")     -> Gmail MCP
ToolSearch("shopify")              -> Shopify MCP
ToolSearch("discord message")      -> Discord MCP
ToolSearch("database query sql")   -> Database MCP
ToolSearch("notion")               -> Notion MCP
ToolSearch("sheets spreadsheet")   -> Google Sheets MCP
ToolSearch("composio")             -> Composio MCP
ToolSearch("telegram send")        -> Telegram MCP
```

Each discovered tool is classified as `data_source`, `messaging`, or `action` and saved to `output/<project>/.mcp-config.json`.

### MCP Data Source Flows

| Source | Pull Method | Saved As |
|--------|-----------|----------|
| Shopify | `get_orders`, `get_products`, `get_customers` | `shopify_orders.csv`, `shopify_products.csv` |
| PostgreSQL/Supabase | `query` with SQL | `table_name.csv` per query |
| Google Sheets | `read` with sheet ID | `sheet_name.csv` |
| Notion | `query_database` | `notion_db_name.csv` |
| Airtable | `list_records` with base/table | `airtable_table.csv` |
| Stripe | `list_charges`, `get_customers` | `stripe_charges.csv`, `stripe_customers.csv` |

### MCP Messaging Flows

When analysis completes, the plugin can **automatically send results** to your team:

**Slack:**
```
*10x Analyst Loop — my-store Complete*
*Top Insights:*
1. Revenue grew 23% MoM driven by Product X
2. Customer churn spiked to 8.4% in March
3. Top 3 products drive 62% of total revenue
*Quality Score:* 96.4%
_Powered by 10x.in_
```

**Gmail:**
```
Subject: 10x Analyst Loop — my-store Analysis Complete
Body: Analysis results with top insights, quality score, and attached report
```

**Discord:**
```
**10x Analyst Loop — my-store**
**Insights:** Top findings with quality score
```

### MCP in the Pipeline

MCP tools are invoked at specific pipeline stages:

| Pipeline Stage | MCP Usage |
|---------------|-----------|
| `:analyze` STEP 0.5 | Pull fresh data from data source MCPs (Shopify, DB, Sheets) |
| `:analyze` STEP 8 | Send results via messaging MCPs (Slack, Gmail, Discord) |
| `:watch` alerts | Send quality drop alerts via messaging MCPs |
| `:report` distribution | Distribute finished reports via messaging MCPs |
| `:live-update` | On-demand message dispatch to any connected target |
| `:connect` | Discovery and configuration of all available MCPs |

### Webhook Integration

For services without MCP support, the plugin supports standard webhooks:

```bash
/10x-analyst-loop:notify my-project https://hooks.slack.com/services/...
/10x-analyst-loop:notify my-project https://events.pagerduty.com/v2/enqueue
```

**Webhook payload:**
```json
{
  "event": "analyze_complete",
  "project": "my-project",
  "session_id": "sess_abc123",
  "timestamp": "2026-03-08T14:30:00Z",
  "status": "success",
  "artifacts": {
    "report": "output/my-project/report.md",
    "dashboard": "output/my-project/dashboard.html",
    "insights_count": 12
  },
  "summary": {
    "files_analyzed": 3,
    "total_rows": 50234,
    "quality_score": 96.4,
    "top_insight": "Revenue grew 23% MoM"
  }
}
```

---

## Architecture

### 5-Agent Swarm

10x-Analyst-Loop coordinates **5 specialist agents** through an orchestrator pipeline:

```
                        User Request (text or voice)
                                    |
                                    v
                          +-------------------+
                          |   ORCHESTRATOR    |
                          |  (INDEX.md rules) |
                          +--------+----------+
                                   |
            +------+---------------+---------------+----------+
            v      v               v               v          v
       +---------+----------+----------+--------+----------+
       |  Data   |  Stats   |Visualizer|Reporter|Strategist|
       | Engineer|  ician   |          |        |          |
       +----+----+----+-----+----+-----+---+----+----+-----+
            |         |          |         |         |
            v         v          v         v         v
         Clean &    EDA &     Charts &  Markdown   Business
         Profile    Stats     Dashboard  Report    Actions
```

### Swarm Patterns (8 total)

| Pattern | Used By | Description |
|---------|---------|-------------|
| **Parallel Fork** | `:analyze` | Stats + Dashboard agents run simultaneously after data engineering |
| **Worktree Swarm** | `:batch-analyze` | One isolated agent per project, up to 10 parallel |
| **Worktree Pair** | `:compare` | 2 parallel worktree agents profile both projects simultaneously |
| **Chunk Swarm** | `:clean` (10+ files) | Split files into chunks of 10, one agent per chunk |
| **Review Swarm** | `:simplify` | 3 parallel code review agents (Reuse, Quality, Efficiency) |
| **Search Swarm** | `:research` | 6 parallel WebSearch calls across platforms |
| **Loop Swarm** | `:watch` | CronCreate for scheduled recurring execution |
| **MCP Discovery** | `:connect` | 9+ parallel ToolSearch calls for MCP detection |

### Domain Auto-Detection

The plugin automatically detects your data domain from column names:

| Domain | Trigger Columns | Analysis Run |
|--------|----------------|-------------|
| **E-Commerce** | order, revenue, price, product, customer, cart, sku | Revenue trends, Top products, AOV, RFM segmentation, Cohort retention, CLV |
| **Healthcare** | patient, diagnosis, treatment, medication | Outcome distributions, Treatment comparisons, Time-to-event |
| **Marketing** | campaign, clicks, impressions, ctr, conversion | Campaign performance, Channel comparison, Funnel analysis, ROAS |
| **General** | _(anything else)_ | Correlations, Distributions, Group-by aggregations, Anomaly detection, Pareto |

### Data Quality Pipeline

The Data Engineer agent applies a standardized quality pipeline:

| Step | Action | Details |
|------|--------|---------|
| 1 | **Profile** | Row/column counts, missing values, duplicates, data types, outliers (IQR), quality score |
| 2 | **Standardize** | Column names to snake_case, strip whitespace |
| 3 | **Deduplicate** | Drop exact duplicates, flag near-duplicates |
| 4 | **Parse dates** | Auto-detect date columns by keyword (`date`, `time`, `created`, `_at`, `_on`) |
| 5 | **Convert currency** | Detect `$1,234.56` patterns, convert to float |
| 6 | **Handle missing** | <5%: median/mode impute, 5-20%: fill + flag, 20-50%: flag only, >50%: drop column |
| 7 | **Detect relationships** | Match `_id` columns across files, check cardinality, verify referential integrity |

**Quality Score Formula:** `(1 - missing_cells / total_cells) * 100`

| Score | Grade | Action |
|-------|-------|--------|
| 95-100% | Excellent | Proceed with analysis |
| 85-94% | Good | Minor cleaning needed |
| 70-84% | Fair | Significant cleaning, flag issues |
| <70% | Poor | Warn user, cleaning may alter results |

### Error Handling & Auto-Recovery

Every step has a 3-attempt recovery protocol:

```
ATTEMPT 1: Run the command as specified
  |
  v (fails)
ATTEMPT 2: Auto-fix the most likely cause
  - Missing module → pip install
  - File not found → check paths, recreate dirs
  - Permission error → identify locked file
  - Empty data → skip file, continue
  - Encoding error → try latin-1, then cp1252
  |
  v (still fails)
ATTEMPT 3: WebSearch for the exact error message
  - Search: "{error} python pandas fix 2026"
  - Apply top solution, retry
  |
  v (still fails)
STOP: Show user what was tried, suggest :debug
```

### Output Artifacts

Every `:analyze` run produces:

```
output/<project>/
├── data-profile.md          # Data structure & quality report
├── data-profile.json        # Machine-readable profile
├── cleaning-log.md          # Actions taken during cleaning
├── insights.json            # Structured findings [{id, headline, category, value, priority}]
├── report.md                # Full Markdown report with executive summary
├── dashboard.html           # Interactive HTML dashboard (Chart.js, works offline)
├── api-export.json          # API-ready JSON bundle (if :api used)
├── watch-log.md             # Monitoring log (if :watch used)
├── .webhook-config.json     # Webhook config (if :notify used)
├── .mcp-config.json         # MCP connections (if :connect used)
├── cleaned-data/            # Cleaned versions of all input files
│   ├── orders_cleaned.csv
│   └── customers_cleaned.csv
└── charts/                  # Generated PNG visualizations
    ├── revenue_trend.png
    ├── top_products.png
    └── rfm_distribution.png
```

---

## Smart Input Resolution

Every command accepts EITHER:
- A **project name** already in `input/` (e.g., `my-sales`)
- A **full path** to any folder on disk (e.g., `C:/Users/data/q1-export`)

If you pass a path, the plugin auto-copies data files into `input/<folder-name>/` and registers it. The `input/` directory is your permanent project registry — every project ever analyzed stays there.

### Supported Data Formats

| Format | Extensions | Engine |
|--------|-----------|--------|
| CSV | `.csv` | pandas `read_csv` |
| Excel | `.xlsx`, `.xls` | pandas `read_excel` (openpyxl/xlrd) |
| JSON | `.json` | pandas `read_json` / `json_normalize` |

---

## Voice Mode

All 18 commands work with Claude Code voice mode. Just hold spacebar, speak, release:

| You Say | Routes To |
|---------|-----------|
| "analyze my sales project" | `:analyze my-sales` |
| "profile this data" | `:profile <project>` |
| "clean the dataset" | `:clean <project>` |
| "what's the average order value" | `:query <project> "average order value"` |
| "show me a chart of revenue" | `:visualize <project> "revenue chart"` |
| "write a report" | `:report <project>` |
| "build a dashboard" | `:dashboard <project>` |
| "watch my data every five minutes" | `:watch <project> 5m` |
| "analyze all my projects" | `:batch-analyze input/*` |
| "compare Q1 with Q2" | `:compare q1 q2` |
| "research e-commerce trends" | `:research "e-commerce trends"` |
| "debug the analysis" | `:debug <project>` |
| "schedule daily report" | `:schedule <project> report "every day 9am"` |
| "send results to Slack" | `:live-update <project> slack` |
| "connect my Shopify" | `:connect <project> shopify` |
| "export as JSON" | `:api <project>` |
| "simplify the code" | `:simplify <project>` |
| "set up webhook" | `:notify <project> <URL>` |

---

## Claude Code v2 Features Used

| Feature | How This Plugin Uses It |
|---------|----------------------|
| **Skills v2 frontmatter** | All 18 commands use full SKILL.md with model, context, agent, allowed-tools, hooks |
| **Agent swarms** | Parallel subagents for throughput and token efficiency |
| **`/loop` scheduling** | `:watch` and `:schedule` use CronCreate for recurring tasks |
| **Worktree isolation** | `:batch-analyze`, `:compare` spawn agents in isolated worktrees |
| **Pre/post hooks** | `pre-validate.py` blocks bad input, `post-session-log.py` tracks history, `post-notify.py` fires webhooks |
| **MCP integration** | Auto-discover and use external data sources and messaging |
| **Dynamic context injection** | `!`command`` injects live file lists, schemas, state into prompts |
| **`$ARGUMENTS` substitutions** | `$0`, `$1`, `$ARGUMENTS[N]` for flexible argument parsing |
| **`${CLAUDE_SKILL_DIR}`** | All skills reference scripts with portable relative paths |
| **`${CLAUDE_SESSION_ID}`** | All outputs tagged with session ID for tracking |
| **`context: fork`** | Complex skills run in forked subagent contexts |
| **Voice-friendly** | Natural speech routing for all 18 commands |
| **Model-agnostic** | Explicit numbered steps — Haiku works as reliably as Opus |

---

## Model Strategy

| Model | Best For | Why |
|-------|----------|-----|
| **Opus** | `:analyze`, complex `:query`, `:compare` | Maximum reasoning for deep analysis |
| **Sonnet** | `:report`, `:dashboard`, `:batch-analyze`, `:research`, `:simplify` | Balanced quality/speed |
| **Haiku** | `:profile`, `:clean`, `:visualize`, `:watch`, `:schedule`, `:notify`, `:api`, `:connect` | Fast, token-efficient |

---

## Statusline (Bundled)

10x-Analyst-Loop includes a production-grade Claude Code statusline with real-time session tracking, agent swarm monitoring, and multi-level context warnings.

### Install

```bash
bash statusline/install.sh
```

### Features

| Feature | Description |
|---------|-------------|
| **Session Tracking** | Real-time token counts (input/output/total), cost per API call |
| **Agent Monitoring** | Active agent count with visual `●` indicators |
| **Cron Monitoring** | Active scheduled job count with `◆` indicators |
| **Session Warnings** | 4-level warnings at 75%, 85%, 90%, 95% context usage |
| **Safe Stop** | At 95% context, warns to finish safely before hitting the limit |
| **5 Themes** | default, nord, tokyo-night, catppuccin, gruvbox |
| **4 Layouts** | compact (2 rows), standard (4), full (7), 10x-swarm (8) |

### 10x-Swarm Layout (Default)

```
 Skill: Agent          │  GitHub: user/repo/main
 Model: Claude Opus    │  Dir: projects/my-data
 Tokens: 45k in + 12k out  │  Cost: $0.32 ($0.04/m)
 Session: 57k total (8 calls)  │  $0.0400/call  +120/-15  2m30s
 Cache: W:12k R:33k    │  @main
 Agents: ●●● (3)  │  Cron: ◆ (1)
 ▰▰▰▰▰▱▱▱ HIGH 15% remaining
 Context: ████████████████████████████████░░░░░░░░ 85%
```

---

## Project Structure

```
10x-analyst-loop/
├── CLAUDE.md                      # Orchestrator instructions
├── INDEX.md                       # Master routing table (16 rules)
├── README.md                      # This file
├── input/                         # PROJECT REGISTRY
│   ├── project-a/
│   │   ├── data1.csv
│   │   └── data2.xlsx
│   └── project-b/
│       └── export.json
├── output/                        # All results (auto-created per project)
│   └── project-a/
│       ├── data-profile.md
│       ├── data-profile.json
│       ├── cleaning-log.md
│       ├── insights.json
│       ├── report.md
│       ├── dashboard.html
│       ├── cleaned-data/
│       └── charts/
├── agents/                        # 5 specialist agent definitions
│   ├── data-engineer.md
│   ├── statistician.md
│   ├── visualizer.md
│   ├── reporter.md
│   └── strategist.md
├── skills/                        # 18 slash commands
│   ├── analyze/SKILL.md
│   ├── profile/SKILL.md
│   ├── clean/SKILL.md
│   ├── query/SKILL.md
│   ├── visualize/SKILL.md
│   ├── report/SKILL.md
│   ├── dashboard/SKILL.md
│   ├── watch/SKILL.md
│   ├── batch-analyze/SKILL.md
│   ├── compare/SKILL.md
│   ├── research/SKILL.md
│   ├── debug/SKILL.md
│   ├── schedule/SKILL.md
│   ├── notify/SKILL.md
│   ├── simplify/SKILL.md
│   ├── api/SKILL.md
│   ├── connect/SKILL.md
│   └── live-update/SKILL.md
├── references/                    # Shared knowledge base
│   ├── analysis-patterns.md       # Python code snippets (RFM, cohort, correlation)
│   ├── chart-styles.md            # 10x.in color palette, matplotlib/Chart.js config
│   ├── data-quality.md            # Quality score formula, cleaning rules
│   ├── context-injections.md      # Dynamic context injection patterns
│   └── mcp-patterns.md            # MCP auto-discovery patterns
├── scripts/                       # Python utilities
│   ├── profiler.py                # Data profiling
│   ├── data_cleaner.py            # Data cleaning
│   ├── chart_generator.py         # PNG chart generation
│   ├── dashboard_template.py      # HTML dashboard generation
│   └── hooks/                     # Pre/post execution hooks
│       ├── pre-validate.py        # Validate input data
│       ├── post-notify.py         # Webhook notifications
│       └── post-session-log.py    # Session history tracking
└── statusline/                    # Claude Code statusline (bundled)
    ├── install.sh
    ├── core.sh
    ├── helpers.sh
    ├── json-parser.sh
    ├── statusline-node.js
    ├── statusline-command.sh
    ├── statusline-config.json
    ├── themes/                    # 5 color themes
    └── layouts/                   # 4 layouts
```

---

## Requirements

- Python 3.8+
- pandas, matplotlib, seaborn (auto-installed if missing)
- openpyxl (for `.xlsx`), xlrd (for `.xls`)
- Chart.js CDN (for dashboard interactivity)
- Claude Code v2.1.63+ (for Skills v2, /loop, worktree features)

## License

**Proprietary Software** — Copyright (c) 2024-2026 [10x.in](https://10x.in). All rights reserved.

This software and its associated documentation are the exclusive property of 10x.in. No part of this software may be reproduced, distributed, modified, or transmitted in any form or by any means without the prior written permission of 10x.in.

For licensing inquiries, contact the 10x Team at [10x.in](https://10x.in).

---

<p align="center">
  <sub>Built with precision by the <strong>10x Team</strong> at <a href="https://10x.in">10x.in</a></sub><br/>
  <sub>10x-Analyst-Loop v2.1.1 | <a href="https://github.com/OpenAnalystInc/10x-analyst-loop">GitHub</a> | <a href="https://openanalystinc.github.io/10x-analyst-loop/">Live Site</a></sub>
</p>
