---
name: connect
description: "Connect external data sources (Shopify, databases, APIs) and messaging apps (Slack, Gmail, Discord) via MCP servers. Use when user says 'connect my Shopify', 'send updates to Slack', 'pull data from my database', or 'integrate with Gmail'."
argument-hint: "[project-name] [mcp-name or 'list']"
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Write, Bash, Glob, Grep
model: claude-haiku-4-5-20251001
hooks:
  post: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/post-session-log.py $0 connect"
---

# 10x Analyst Loop — MCP Connector

Connect external data sources and messaging apps via user-installed MCP servers. This skill does NOT hardcode any MCP server — it discovers what's available and configures routing.

## STEP-BY-STEP INSTRUCTIONS

### STEP 1 — Parse Arguments

```
PROJECT = $0 (project name)
TARGET = $1 (MCP name like "shopify", "slack", "gmail", or "list")
EXTRA = $2+ (optional: channel name, email address, etc.)
```

If TARGET is "list" or missing: skip to STEP 2 (discovery only).

### STEP 2 — Discover Available MCP Tools

Use ToolSearch to scan for installed MCP servers:

```
ToolSearch("slack message")          -> finds Slack MCP tools
ToolSearch("gmail email send")       -> finds Gmail MCP tools
ToolSearch("shopify")                -> finds Shopify MCP tools
ToolSearch("discord message")        -> finds Discord MCP tools
ToolSearch("database query sql")     -> finds DB MCP tools
ToolSearch("notion")                 -> finds Notion MCP tools
ToolSearch("sheets spreadsheet")     -> finds Google Sheets MCP tools
ToolSearch("composio")               -> finds Composio MCP tools
ToolSearch("airtable")               -> finds Airtable MCP tools
ToolSearch("telegram")               -> finds Telegram MCP tools
```

Run ALL ToolSearch calls in parallel. For each result, record:
- Tool name (e.g., `mcp__slack__send_message`)
- Tool description
- Whether it's a data source or messaging target

### STEP 3 — Classify Discovered Tools

Categorize into:

**Data Sources** (pull data INTO the project):
- shopify, database, postgres, mysql, sheets, notion, airtable, supabase

**Messaging Targets** (send results OUT):
- slack, gmail, discord, teams, telegram

**Action Platforms** (trigger workflows):
- composio, zapier, make

### STEP 4 — Save MCP Config

Write `output/$PROJECT/.mcp-config.json`:
```json
{
  "project": "{PROJECT}",
  "configured_at": "{ISO timestamp}",
  "data_sources": [
    {
      "name": "shopify",
      "tool_prefix": "mcp__shopify__",
      "detected": true,
      "tools": ["mcp__shopify__get_orders", "mcp__shopify__get_products"]
    }
  ],
  "messaging": [
    {
      "name": "slack",
      "tool_prefix": "mcp__slack__",
      "detected": true,
      "tools": ["mcp__slack__send_message"],
      "config": {
        "channel": "#analytics"
      }
    }
  ],
  "actions": []
}
```

If EXTRA was provided (e.g., channel name, email address), include it in the config.

### STEP 5 — Present Connected Integrations

```markdown
## MCP Connections for {PROJECT}

### Data Sources (pull data in)
| Source | Status | Tools Found |
|--------|--------|-------------|
| Shopify | ✅ Connected | get_orders, get_products, get_customers |
| Database | ❌ Not found | Install a database MCP server |

### Messaging (send results out)
| Target | Status | Config |
|--------|--------|--------|
| Slack | ✅ Connected | Channel: #analytics |
| Gmail | ❌ Not found | Install Gmail MCP server |

### Actions
| Platform | Status |
|----------|--------|
| Composio | ❌ Not found |

To use: Run `:analyze {PROJECT}` — data will be pulled from connected sources and results sent to connected targets automatically.

To add more: Install MCP servers in your Claude Code config, then run `:connect {PROJECT} list` to detect them.
```

## How Other Skills Use MCP Config

When `:analyze`, `:report`, or `:watch` run, they check for `output/$PROJECT/.mcp-config.json`:

- **Data sources**: Pull fresh data before analysis (STEP 0.5 in :analyze)
- **Messaging targets**: Send results after completion (STEP 8 in :analyze)
- **Watch alerts**: Send quality alerts to messaging targets

## Examples
```
/10x-analyst-loop:connect my-store list
/10x-analyst-loop:connect my-store slack #analytics
/10x-analyst-loop:connect my-store shopify
/10x-analyst-loop:connect inventory gmail alerts@company.com
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
