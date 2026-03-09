---
name: dashboard
description: "Build a standalone interactive HTML dashboard with Chart.js from any data project. Use when user says 'build a dashboard', 'interactive view', 'HTML report', or 'visual summary I can open in browser'."
argument-hint: "[project-name-or-path]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Write, Bash, Glob, Grep
model: claude-sonnet-4-6
context: fork
agent: general-purpose
hooks:
  post: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/post-session-log.py $0 dashboard"
---

# 10x Analyst Loop — Dashboard Builder

Build a standalone interactive HTML dashboard from any data project.

## STEP-BY-STEP INSTRUCTIONS

### STEP 0 — Smart Input Resolution

1. If `input/$0/` exists with data files: use it. PROJECT = `$0`.
2. Otherwise treat `$0` as a path. Extract folder name as PROJECT. Copy files:
   ```bash
   mkdir -p input/PROJECT
   cp "$0"/*.csv "$0"/*.xlsx "$0"/*.xls "$0"/*.json input/PROJECT/ 2>/dev/null
   ```
3. If no data files anywhere: tell user and STOP.

### STEP 1 — Create Output
```bash
mkdir -p output/$PROJECT
```

### STEP 2 — Generate Dashboard
```bash
python ${CLAUDE_SKILL_DIR}/../../scripts/dashboard_template.py input/$PROJECT output/$PROJECT/dashboard.html
```

### STEP 3 — Present
Tell user:
```
Dashboard ready! Open in browser:
  start output/$PROJECT/dashboard.html
```

Features: KPI cards, interactive Chart.js charts, data table, 10x.in branding, responsive, works offline.

## Examples
```
/10x-analyst-loop:dashboard my-sales
/10x-analyst-loop:dashboard C:/data/q1-export
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
