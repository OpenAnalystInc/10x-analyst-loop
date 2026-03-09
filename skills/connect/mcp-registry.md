# MCP Server Registry Patterns

Reference of common MCP server naming patterns for auto-discovery via ToolSearch.

---

## Data Source MCPs

| Service | ToolSearch Keywords | Common Tool Names | Data Format |
|---------|-------------------|-------------------|-------------|
| Shopify | `shopify` | `mcp__shopify__get_orders`, `get_products`, `get_customers` | JSON → CSV |
| PostgreSQL | `database query postgres` | `mcp__postgres__query`, `mcp__db__execute` | SQL → CSV |
| MySQL | `database mysql` | `mcp__mysql__query` | SQL → CSV |
| Supabase | `supabase` | `mcp__supabase__query` | JSON → CSV |
| Google Sheets | `sheets spreadsheet` | `mcp__sheets__read`, `mcp__google_sheets__get` | Rows → CSV |
| Notion | `notion` | `mcp__notion__query_database`, `mcp__notion__get_page` | JSON → CSV |
| Airtable | `airtable` | `mcp__airtable__list_records` | JSON → CSV |
| MongoDB | `mongodb mongo` | `mcp__mongodb__find`, `mcp__mongo__query` | JSON → CSV |
| Stripe | `stripe` | `mcp__stripe__list_charges`, `mcp__stripe__get_customers` | JSON → CSV |

## Messaging MCPs

| Service | ToolSearch Keywords | Common Tool Names | Message Format |
|---------|-------------------|-------------------|---------------|
| Slack | `slack message` | `mcp__slack__send_message`, `mcp__slack__post_message` | Markdown text |
| Gmail | `gmail email send` | `mcp__gmail__send_email`, `mcp__gmail__create_draft` | HTML/text email |
| Discord | `discord message` | `mcp__discord__send_message` | Markdown text |
| Microsoft Teams | `teams message` | `mcp__teams__send_message` | Adaptive card |
| Telegram | `telegram send` | `mcp__telegram__send_message` | Markdown text |

## Action MCPs

| Service | ToolSearch Keywords | Common Tool Names |
|---------|-------------------|-------------------|
| Composio | `composio` | `mcp__composio__execute_action` |
| Zapier | `zapier` | `mcp__zapier__trigger` |

## Data Ingestion Pattern

When pulling data from MCP data sources into the project:

```python
# Generic pattern for any MCP data source
import pandas as pd
import json

# 1. Call MCP tool to get data (returns JSON)
# 2. Normalize JSON to flat DataFrame
df = pd.json_normalize(mcp_result)
# 3. Save as CSV to input directory
df.to_csv(f'input/{project}/{source_name}_{table}.csv', index=False)
```

## Message Composition Pattern

When sending results via MCP messaging tools:

```
Subject: 10x Analyst Loop — {PROJECT} Analysis Complete

Top Insights:
1. {insight_1_headline}
2. {insight_2_headline}
3. {insight_3_headline}

Quality Score: {score}%
Dashboard: {dashboard_path}
Full Report: {report_path}

— Powered by 10x.in
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
