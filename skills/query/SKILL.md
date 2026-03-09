---
name: query
description: "Ask natural language questions about your data and get answers with evidence. Use when user asks 'what are the top products', 'average order value', 'which customers churned', or any specific data question."
argument-hint: "[project-name-or-path] [your question]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Bash, Glob, Grep
model: claude-sonnet-4-6
context: fork
agent: general-purpose
---

# 10x Analyst Loop — Data Query

Ask any question about your data in plain English. Get a precise answer backed by numbers.

## STEP-BY-STEP INSTRUCTIONS

### STEP 0 — Smart Input Resolution

The first argument `$0` can be:
- A **project name** already in `input/` (e.g., `my-sales`)
- An **absolute or relative path** to a folder anywhere on disk (e.g., `C:/Users/data/sales` or `~/exports/q1`)

**Resolution logic (do this FIRST before anything else):**

1. Check if `input/$0/` exists and has data files.
2. If YES: use `input/$0/` as INPUT. Set PROJECT = `$0`.
3. If NO: treat `$0` as a filesystem path.
   a. Check if that path exists and contains CSV/Excel/JSON files.
   b. If YES: extract the folder name as PROJECT. Copy all data files into `input/PROJECT/`:
      ```bash
      mkdir -p input/PROJECT
      cp "$0"/*.csv "$0"/*.xlsx "$0"/*.xls "$0"/*.json input/PROJECT/ 2>/dev/null
      ```
   c. If NO files found anywhere: tell user and STOP.
4. From here on, always read from `input/PROJECT/`.

### STEP 1 — Parse Question + Dynamic Context Injection
```
PROJECT = resolved project name from STEP 0
QUESTION = everything after the first argument
INPUT = input/PROJECT/
```

Inject data shape context before answering:
```bash
python -c "
import glob, pandas as pd
files = glob.glob('input/$0/**/*.*', recursive=True)
data_files = [f for f in files if f.endswith(('.csv','.xlsx','.xls','.json'))]
for f in data_files:
    try:
        df = pd.read_csv(f) if f.endswith('.csv') else pd.read_excel(f) if f.endswith(('.xlsx','.xls')) else pd.read_json(f)
        print(f'{f}: {len(df)} rows x {len(df.columns)} cols | Columns: {list(df.columns)}')
    except: print(f'{f}: could not read')
"
```
Use this schema context to write accurate queries without guessing column names.

### STEP 2 — Load Data with Python
Write and execute a Python script that:
1. Loads all data files from `input/PROJECT/`
2. Cleans column names: `df.columns = df.columns.str.strip().str.lower().str.replace(r'[^a-z0-9]+', '_', regex=True).str.strip('_')`
3. If multiple files: join on common keys (columns ending in `_id` or named `id`)

### STEP 3 — Answer the Question
Based on the QUESTION, write and run pandas operations (groupby, filter, aggregate, sort, etc.).

### STEP 4 — Present Answer
```
## Answer
{Direct answer with specific numbers}

### Supporting Data
{Table or list with evidence}

### How This Was Computed
{1-2 sentences on the pandas operations}

### Follow-Up Questions You Might Ask
- {Suggestion 1}
- {Suggestion 2}

---
*Powered by [10x Analyst Loop](https://10x.in) v2.0.0*
```

## Examples
```
/10x-analyst-loop:query my-sales "What is the average order value?"
/10x-analyst-loop:query C:/Users/data/exports "Top 10 products by revenue?"
/10x-analyst-loop:query ~/Desktop/q1-data "Is revenue growing month over month?"
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
