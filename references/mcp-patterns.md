# MCP Integration Patterns

Reference for auto-discovering and using MCP servers with 10x-Analyst-Loop.

---

## Discovery Protocol

MCP tools are **deferred** — they must be discovered via ToolSearch before use. Never hardcode tool names.

### Step 1: Search for Available Tools

```
ToolSearch("slack message")           -> Slack MCP
ToolSearch("gmail email send")        -> Gmail MCP
ToolSearch("shopify")                 -> Shopify MCP
ToolSearch("discord message")         -> Discord MCP
ToolSearch("database query sql")      -> Database MCP
ToolSearch("notion")                  -> Notion MCP
ToolSearch("sheets spreadsheet")      -> Google Sheets MCP
ToolSearch("composio")                -> Composio MCP
ToolSearch("airtable")                -> Airtable MCP
ToolSearch("telegram send")           -> Telegram MCP
ToolSearch("stripe")                  -> Stripe MCP
ToolSearch("supabase")                -> Supabase MCP
```

### Step 2: Record Discovered Tools

For each result, save:
- `tool_name`: e.g., `mcp__slack__send_message`
- `description`: what the tool does
- `category`: `data_source` | `messaging` | `action`

### Step 3: Store in Project Config

Write to `output/<project>/.mcp-config.json`

---

## Tool Naming Conventions

MCP tools follow this pattern: `mcp__<server>__<action>`

| Server | Common Actions |
|--------|---------------|
| slack | `send_message`, `read_channel`, `list_channels` |
| gmail | `send_email`, `create_draft`, `read_inbox` |
| discord | `send_message`, `read_channel` |
| shopify | `get_orders`, `get_products`, `get_customers` |
| postgres | `query`, `execute` |
| notion | `query_database`, `get_page`, `create_page` |
| sheets | `read`, `write`, `append` |
| composio | `execute_action`, `list_actions` |

---

## Data Ingestion Pattern

When pulling data from MCP data sources into a project:

```python
import pandas as pd
import json

# 1. Call MCP tool (returns JSON data)
# result = mcp__shopify__get_orders(...)

# 2. Normalize nested JSON to flat DataFrame
df = pd.json_normalize(result)

# 3. Save as CSV to input directory
df.to_csv(f'input/{project}/{source}_{table}.csv', index=False)
print(f'Pulled {len(df)} rows from {source}')
```

### Supported Data Source Flows

| Source | Pull Method | Output |
|--------|-----------|--------|
| Shopify | `get_orders`, `get_products`, `get_customers` | `shopify_orders.csv`, `shopify_products.csv`, `shopify_customers.csv` |
| Database | `query` with SQL | `table_name.csv` per query |
| Google Sheets | `read` with sheet ID | `sheet_name.csv` |
| Notion | `query_database` | `notion_db_name.csv` |
| Airtable | `list_records` with base/table | `airtable_table.csv` |
| Stripe | `list_charges`, `get_customers` | `stripe_charges.csv`, `stripe_customers.csv` |

---

## Message Composition Pattern

When sending results via MCP messaging tools:

### Slack Message Format
```
*10x Analyst Loop — {PROJECT} Complete*

*Top Insights:*
1. {insight_1}
2. {insight_2}
3. {insight_3}

*Quality Score:* {score}%
*Dashboard:* `output/{project}/dashboard.html`
*Report:* `output/{project}/report.md`

_Powered by 10x.in_
```

### Gmail Email Format
```
Subject: 10x Analyst Loop — {PROJECT} Analysis Complete

Body:
Analysis results for {PROJECT}:

Top Insights:
1. {insight_1}
2. {insight_2}
3. {insight_3}

Quality Score: {score}%
Files analyzed: {count}

Attachments:
- report.md
- dashboard.html (open in browser)

— 10x Analyst Loop v2.0.0 | https://10x.in
```

### Discord Message Format
```
**10x Analyst Loop — {PROJECT}**

**Insights:**
1. {insight_1}
2. {insight_2}
3. {insight_3}

Quality: {score}% | Files: {count}
*Powered by 10x.in*
```

---

## Alert Message Pattern (for :watch)

```
⚠️ **Data Quality Alert — {PROJECT}**

Quality dropped from {old_score}% to {new_score}%
{N} new issues detected:
- {issue_1}
- {issue_2}

Check: output/{project}/watch-log.md
— 10x Analyst Loop
```

---

## Config File Schema

`output/<project>/.mcp-config.json`:
```json
{
  "project": "project-name",
  "configured_at": "ISO timestamp",
  "data_sources": [
    {
      "name": "shopify",
      "tool_prefix": "mcp__shopify__",
      "detected": true,
      "tools": ["mcp__shopify__get_orders"],
      "config": {}
    }
  ],
  "messaging": [
    {
      "name": "slack",
      "tool_prefix": "mcp__slack__",
      "detected": true,
      "tools": ["mcp__slack__send_message"],
      "config": { "channel": "#analytics" }
    }
  ],
  "actions": []
}
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
