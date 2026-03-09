---
name: clean
description: "Clean and transform data files — fix types, handle missing values, remove duplicates, standardize names. Use when user says 'clean this data', 'fix this dataset', 'prepare for analysis'."
argument-hint: "[project-name]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Write, Bash, Glob, Grep
model: claude-haiku-4-5-20251001
context: fork
agent: general-purpose
hooks:
  post: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/post-session-log.py $0 clean"
---

# 10x Analyst Loop — Data Cleaner (Swarm-Enabled)

Clean and transform raw data into analysis-ready datasets.
**For 10+ files:** Automatically spawns parallel subagents to clean files in chunks.

Reads from `input/<project>/`, writes cleaned files to `output/<project>/cleaned-data/`.

## STEP-BY-STEP INSTRUCTIONS

### STEP 0 — Smart Input Resolution (Auto-Copy + Project Tracking)

1. If `input/$0/` exists with data files: PROJECT = `$0`.
2. Otherwise treat `$0` as a path. Extract basename as PROJECT. Copy files:
   ```bash
   mkdir -p input/PROJECT
   cp "$0"/*.csv "$0"/*.xlsx "$0"/*.xls "$0"/*.json input/PROJECT/ 2>/dev/null
   ```
   Tell user: "Registered project 'PROJECT'"
3. If no data files anywhere: tell user and STOP.
4. `input/` is the project registry.

### STEP 1 — Set Paths
```
PROJECT = resolved name
INPUT = input/PROJECT/
OUTPUT = output/PROJECT/cleaned-data/
```

### STEP 2 — Find Data Files
Glob in `input/PROJECT/`. If ZERO: tell user and STOP.

### STEP 3 — Create Output
```bash
mkdir -p output/$0/cleaned-data
```

### STEP 4 — Run Cleaner (Standard or Swarm Mode)

**Count the data files first:**
```bash
python -c "import glob; files=glob.glob('input/$0/**/*.*', recursive=True); data=[f for f in files if f.endswith(('.csv','.xlsx','.xls','.json'))]; print(f'FILE_COUNT={len(data)}')"
```

**IF FILE_COUNT <= 10:** Run cleaner directly (standard mode):
```bash
python ${CLAUDE_SKILL_DIR}/../../scripts/data_cleaner.py input/$0 output/$0/cleaned-data
```

**IF FILE_COUNT > 10:** Swarm mode — split into chunks of 10 and spawn parallel subagents:

1. Split file list into chunks of 10
2. For EACH chunk, spawn a background Agent:
```
Agent(
  description: "Clean chunk N of $0",
  prompt: "Clean these specific files using the 10x data cleaning rules:
    Files: {chunk_file_list}

    For each file:
    1. Load with pandas
    2. Standardize column names: df.columns = df.columns.str.strip().str.lower().str.replace(r'[^a-z0-9]+', '_', regex=True).str.strip('_')
    3. Handle missing values per data-quality rules (median for numeric <5%, mode for categorical <5%)
    4. Remove exact duplicates
    5. Parse date columns (keywords: date, time, created, updated, timestamp, _at, _on)
    6. Detect and convert currency columns
    7. Save cleaned file to output/$0/cleaned-data/{filename}_cleaned.csv

    Return: summary table of files cleaned with row counts.",
  run_in_background: true
)
```
3. Wait for ALL chunk agents to complete
4. Merge cleaning logs from all chunks into a single `output/$0/cleaning-log.md`

### STEP 5 — Present Results
Show cleaning summary:
```
| File | Original Rows | Cleaned Rows | Removed | Actions |
|------|--------------|-------------|---------|---------|
```
Suggest: `:analyze $0` for full pipeline, `:visualize $0` for charts.

## Examples
```
/10x-analyst-loop:clean my-sales
/10x-analyst-loop:clean raw-export
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
