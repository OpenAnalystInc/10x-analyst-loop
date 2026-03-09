---
name: live-update
description: "Send analysis results, alerts, or reports to connected messaging apps (Slack, Gmail, Discord). Use when user says 'send this to Slack', 'email the report', 'notify the team', 'post updates to Discord'."
argument-hint: "[project-name] [target: slack|gmail|discord|all] [optional: message]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Write, Bash, Glob, Grep
model: claude-haiku-4-5-20251001
context: fork
agent: general-purpose
hooks:
  post: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/post-session-log.py $0 live-update"
---

# 10x Analyst Loop — Live Update Sender

Send analysis results to connected messaging apps. Reads MCP config from `:connect` and dispatches messages.

## STEP-BY-STEP INSTRUCTIONS

### STEP 1 — Parse Arguments

```
PROJECT = $0
TARGET = $1 (slack, gmail, discord, telegram, all — or omit for all configured)
MESSAGE = $2+ (optional custom message, otherwise auto-generates from results)
```

### STEP 2 — Read MCP Config

Read `output/$PROJECT/.mcp-config.json`.

If file doesn't exist:
```
No MCP connections configured for '{PROJECT}'.
Run: /10x-analyst-loop:connect {PROJECT} list
to discover and configure available integrations.
```
STOP.

### STEP 3 — Compose Message

If MESSAGE was provided: use it directly.
If not: auto-compose from project results:

```bash
python -c "
import json, os

project = '$0'
msg_parts = ['**10x Analyst Loop — {project} Results**\n']

# Load insights
try:
    with open(f'output/{project}/insights.json') as f:
        insights = json.load(f)
    msg_parts.append('**Top Insights:**')
    for i, ins in enumerate(insights[:3], 1):
        msg_parts.append(f'{i}. {ins.get(\"headline\", \"N/A\")}')
except: pass

# Quality score
try:
    with open(f'output/{project}/data-profile.md') as f:
        content = f.read()
    # Extract quality score from profile
    msg_parts.append(f'\n**Files analyzed:** see data-profile.md')
except: pass

msg_parts.append(f'\n**Dashboard:** output/{project}/dashboard.html')
msg_parts.append(f'**Report:** output/{project}/report.md')
msg_parts.append(f'\n— Powered by 10x.in')

print('\n'.join(msg_parts))
"
```

### STEP 4 — Dispatch to Targets

For each configured messaging target (filtered by TARGET if specified):

**Slack:**
1. Use ToolSearch to find Slack MCP tool: `ToolSearch("slack message send")`
2. Call the discovered tool with the composed message
3. Include channel from `.mcp-config.json`

**Gmail:**
1. Use ToolSearch to find Gmail MCP tool: `ToolSearch("gmail email send")`
2. Call the discovered tool with:
   - To: email from `.mcp-config.json`
   - Subject: "10x Analyst Loop — {PROJECT} Analysis Complete"
   - Body: composed message + report.md content

**Discord:**
1. Use ToolSearch to find Discord MCP tool: `ToolSearch("discord message send")`
2. Call the discovered tool with the composed message

**Telegram:**
1. Use ToolSearch to find Telegram MCP tool: `ToolSearch("telegram send")`
2. Call the discovered tool with the composed message

### STEP 5 — Confirm Delivery

```
Live updates sent!

| Target | Status | Destination |
|--------|--------|-------------|
| Slack | ✅ Sent | #analytics |
| Gmail | ✅ Sent | user@company.com |
| Discord | ❌ Not configured | — |

Message included: Top 3 insights, dashboard link, report link.
```

## Examples
```
/10x-analyst-loop:live-update my-sales all
/10x-analyst-loop:live-update inventory slack "Weekly inventory report ready"
/10x-analyst-loop:live-update q1-data gmail
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
