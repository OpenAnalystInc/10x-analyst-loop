# 10x-Analyst-Loop v2.1.1 — Supercharged Agentic Analysis Swarm

A Claude Code plugin by **[10x.in](https://10x.in)** — multi-agent swarm for end-to-end data analysis automation, powered by Skills v2, `/loop` scheduling, agent swarms with worktree isolation, MCP integration, webhook notifications, cron tasks, dynamic context injection, multi-source research, bundled statusline with session tracking, and voice-friendly commands.

**Works on ALL models:** Every instruction is explicit step-by-step so Haiku, Sonnet, and Opus all produce full-quality output.

## How It Works

1. Give any command a **project name** or **folder path** (from anywhere on your system)
2. Plugin auto-copies data files into `input/<project-name>/` (the project registry)
3. All results appear in `output/<project-name>/`
4. Agent swarms run in parallel for maximum throughput

## Plugin Commands (18 total)

### Core Analysis Commands (7)
- `/10x-analyst-loop:analyze <project> [--safe]` — Full 5-agent swarm pipeline with parallel fork (Stats + Dashboard simultaneously)
- `/10x-analyst-loop:profile <project>` — Data profiling and quality assessment
- `/10x-analyst-loop:clean <project>` — Data cleaning (swarm mode for 10+ files)
- `/10x-analyst-loop:query <project> <question>` — Ask natural language questions about your data
- `/10x-analyst-loop:visualize <project> <description>` — Generate charts and visualizations
- `/10x-analyst-loop:report <project>` — Generate a comprehensive Markdown analysis report
- `/10x-analyst-loop:dashboard <project>` — Build a standalone interactive HTML dashboard

### Power Commands (4)
- `/10x-analyst-loop:watch <project> [interval] [--profile|--dashboard|--full]` — Live-monitor with `/loop` + CronCreate
- `/10x-analyst-loop:batch-analyze <p1> <p2> ... | input/*` — Swarm: parallel agents per project (worktree isolated)
- `/10x-analyst-loop:compare <project-a> <project-b>` — Parallel worktree profiling + diff report
- `/10x-analyst-loop:research <topic>` — Multi-source research across Reddit, X, YouTube, HN, web

### System & DevOps Commands (5)
- `/10x-analyst-loop:debug <project> [error]` — Auto-diagnose pipeline failures, check deps, search fixes
- `/10x-analyst-loop:schedule <project> <command> <when>` — Schedule future/recurring tasks via CronCreate
- `/10x-analyst-loop:notify <project> <webhook-url>` — Configure webhook notifications
- `/10x-analyst-loop:simplify <project>` — 3-agent swarm code review (Reuse + Quality + Efficiency)
- `/10x-analyst-loop:api <project> [--serve]` — Export all artifacts as structured JSON

### Integration Commands (2)
- `/10x-analyst-loop:connect <project> [mcp-name|list]` — Discover & configure MCP data sources and messaging
- `/10x-analyst-loop:live-update <project> [target] [message]` — Send results to connected apps (Slack, Gmail, Discord)

## Path Convention

Every command accepts EITHER:
- A **project name** already in `input/` (e.g., `my-sales`)
- A **full path** to any folder on disk (e.g., `C:/Users/data/q1-export`)

If you pass a path, the plugin auto-copies data files into `input/<folder-name>/` and registers it. The `input/` directory is your permanent project registry.

### Output Structure (per project)
```
output/<project-name>/
|-- data-profile.md          # Data structure & quality report
|-- data-profile.json        # Machine-readable profile
|-- cleaning-log.md          # Actions taken during cleaning
|-- insights.json            # Structured findings
|-- report.md                # Full Markdown analysis report
|-- dashboard.html           # Interactive HTML dashboard
|-- api-export.json          # API-ready JSON bundle (if :api used)
|-- watch-log.md             # /loop monitoring log (if :watch used)
|-- .webhook-config.json     # Webhook config (if :notify used)
|-- .mcp-config.json         # MCP connections (if :connect used)
|-- cleaned-data/            # Cleaned versions of input files
+-- charts/                  # Generated PNG visualizations
```

## Agent Swarm Architecture

```
User Request (text or voice)
     |
     v
+-----------------------+
|     ORCHESTRATOR      |  <-- INDEX.md routes everything
|   (Skill Router)      |
+-----------+-----------+
            |
   +--------+--------+----------+-----------+
   v        v        v          v           v
+------+ +------+ +----------+ +--------+ +----------+
| Data | | Stats| |Visualizer| |Reporter| |Strategist|
|Engine| | ician| |          | |        | |          |
+--+---+ +--+---+ +----+-----+ +---+----+ +----+-----+
   |        |          |            |           |
   v        v          v            v           v
 Clean    EDA &     Charts &    Markdown    Business
 Data     Stats     Dashboard    Report     Actions
```

### Swarm Patterns

| Pattern | Used By | Description |
|---------|---------|-------------|
| **Parallel Fork** | `:analyze` | Stats + Dashboard run simultaneously |
| **Worktree Swarm** | `:batch-analyze` | One isolated agent per project |
| **Worktree Pair** | `:compare` | 2 parallel profiling agents |
| **Chunk Swarm** | `:clean` (10+ files) | Split files, one agent per chunk |
| **Review Swarm** | `:simplify` | 3 parallel code review agents |
| **Search Swarm** | `:research` | 6 parallel WebSearch calls |
| **Loop Swarm** | `:watch` | CronCreate for recurring execution |
| **MCP Discovery** | `:connect` | 9+ parallel ToolSearch calls |

### Pipeline by Command

| Command | Agents / Pattern |
|---------|-----------------|
| `:analyze` | Data Engineer -> [Stats + Dashboard PARALLEL] -> Charts -> Reporter -> Strategist |
| `:profile` | Data Engineer |
| `:clean` | Data Engineer (swarm if 10+ files) |
| `:query` | Data Engineer -> Statistician -> Strategist |
| `:visualize` | Data Engineer -> Visualizer |
| `:report` | Data Engineer -> Statistician -> Reporter -> Strategist |
| `:dashboard` | Data Engineer -> Visualizer |
| `:watch` | Data Engineer (CronCreate loop) |
| `:batch-analyze` | N parallel worktree agents |
| `:compare` | 2 parallel worktree profilers -> Statistician |
| `:research` | 6 parallel WebSearches -> Synthesis |
| `:debug` | Self-contained diagnostician |
| `:schedule` | CronCreate scheduler |
| `:notify` | Webhook configurator |
| `:simplify` | 3 parallel review agents |
| `:api` | JSON exporter |
| `:connect` | MCP auto-discovery |
| `:live-update` | MCP message dispatcher |

## Claude Code v2 Features Used

| Feature | How This Plugin Uses It |
|---------|----------------------|
| **Skills v2 frontmatter** | All 18 commands use full SKILL.md with model, context, agent, allowed-tools, hooks |
| **`/loop` scheduling** | `:watch` and `:schedule` use CronCreate for recurring tasks |
| **Worktree isolation** | `:batch-analyze` and `:compare` spawn agents in isolated worktrees |
| **Agent swarms** | `:analyze`, `:clean`, `:simplify`, `:batch-analyze` use parallel subagents |
| **Dynamic context injection** | `!`command`` injects live file lists, schemas, state into prompts |
| **`$ARGUMENTS` substitutions** | `$0`, `$1`, `$ARGUMENTS[N]` for flexible argument parsing |
| **`${CLAUDE_SKILL_DIR}`** | All skills reference scripts with portable relative paths |
| **`${CLAUDE_SESSION_ID}`** | All outputs tagged with session ID for tracking |
| **`context: fork`** | Complex skills run in forked subagent contexts |
| **Pre/post hooks** | pre-validate.py blocks on bad input, post-session-log.py tracks history |
| **Webhook hooks** | post-notify.py POSTs results to configured URLs |
| **MCP integration** | `:connect` discovers MCPs, `:live-update` dispatches via MCPs |
| **Voice-friendly** | Descriptions match natural speech patterns for voice mode |
| **Model-agnostic** | Explicit numbered steps with exact code — Haiku runs as reliably as Opus |

## Model Strategy

| Model | Best For | Why |
|-------|----------|-----|
| **Opus** | `:analyze`, complex `:query`, `:compare` | Maximum reasoning for deep analysis |
| **Sonnet** | `:report`, `:dashboard`, `:batch-analyze`, `:research`, `:simplify` | Balanced quality/speed |
| **Haiku** | `:profile`, `:clean`, `:visualize`, `:watch`, `:schedule`, `:notify`, `:api`, `:connect` | Fast, token-efficient |

## Voice Examples

These work with Claude Code voice mode (hold spacebar, speak, release):
- "analyze my sales project"
- "watch inventory data every five minutes with dashboard mode"
- "compare q1 with q2"
- "research e-commerce trends"
- "debug my analysis"
- "schedule a daily report for my-sales"
- "connect my Shopify store"
- "send the results to Slack"
- "analyze all my projects" (batch-analyze with glob)
- "simplify the generated code"

## Bundled Statusline

The plugin includes a production-grade Claude Code statusline at `statusline/`. Install with `bash statusline/install.sh`.

- **Session tracking**: Real-time token counts (in/out/total), API call count, cost per call
- **Agent monitoring**: Active agent count with visual `●` indicators
- **Cron monitoring**: Active scheduled job count with `◆` indicators
- **4-level warnings**: At 75%, 85%, 90%, 95% context usage (safe stop at 95%)
- **5 themes**: default, nord, tokyo-night, catppuccin, gruvbox
- **4 layouts**: compact (2 rows), standard (4), full (7), 10x-swarm (8)

---
*10x-Analyst-Loop v2.1.1 | Built by [10x.in](https://10x.in) | [GitHub](https://github.com/OpenAnalystInc/10x-analyst-loop) | All rights reserved.*
