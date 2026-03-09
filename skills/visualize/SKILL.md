---
name: visualize
description: "Generate charts and plots from data — line, bar, pie, heatmap, scatter, histogram. Use when user says 'plot this', 'show me a chart', 'visualize revenue', or 'graph the data'."
argument-hint: "[project-name-or-path] [chart-type or description]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Write, Bash, Glob, Grep
model: claude-haiku-4-5-20251001
context: fork
agent: general-purpose
hooks:
  post: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/post-session-log.py $0 visualize"
---

# 10x Analyst Loop — Visualizer

Generate publication-ready charts with the 10x.in visual style.

## STEP-BY-STEP INSTRUCTIONS

### STEP 0 — Smart Input Resolution

The first argument `$0` can be a project name in `input/` OR a path to any folder.

1. If `input/$0/` exists with data files: use it. PROJECT = `$0`.
2. Otherwise treat `$0` as a path. Extract folder name as PROJECT. Copy files:
   ```bash
   mkdir -p input/PROJECT
   cp "$0"/*.csv "$0"/*.xlsx "$0"/*.xls "$0"/*.json input/PROJECT/ 2>/dev/null
   ```
3. If no data files anywhere: tell user and STOP.

### STEP 1 — Parse Arguments
```
PROJECT = resolved project name
CHART_DESC = everything after $0 (e.g., "line chart of revenue by month")
INPUT = input/PROJECT/
OUTPUT = output/PROJECT/charts/
```

### STEP 2 — Create Output
```bash
mkdir -p output/$PROJECT/charts
```

### STEP 3 — Determine Chart Type

| User Says | Chart Type |
|-----------|-----------|
| "trend", "over time", "line" | Line chart |
| "top", "ranking", "bar" | Bar chart |
| "breakdown", "proportion", "pie" | Donut chart |
| "correlation", "heatmap" | Heatmap |
| "distribution", "histogram" | Histogram |
| "scatter", "compare two" | Scatter plot |
| "box", "spread" | Box plot |

### STEP 4 — Generate Chart
```python
import matplotlib.pyplot as plt, seaborn as sns, pandas as pd
COLORS = ['#FF6B35', '#004E89', '#00A878', '#FFD166', '#EF476F', '#118AB2', '#073B4C']
plt.style.use('seaborn-v0_8-whitegrid')
sns.set_palette(COLORS)
plt.rcParams.update({'figure.figsize': (12, 6), 'figure.dpi': 150, 'font.size': 11})
# Load, plot, save to output/PROJECT/charts/
```

### STEP 5 — Tell User
Show file path. Suggest `:dashboard` for interactive version.

## Examples
```
/10x-analyst-loop:visualize my-sales "revenue trend line chart"
/10x-analyst-loop:visualize C:/data/exports "top 10 bar chart"
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
