---
name: profile
description: "Profile data files — row counts, column types, missing values, duplicates, statistics, quality score. Use when user says 'what is in this data', 'describe this dataset', 'how clean is this data', or 'profile this'."
argument-hint: "[project-name]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Bash, Glob, Grep
model: claude-haiku-4-5-20251001
context: fork
agent: general-purpose
---

# 10x Analyst Loop — Data Profiler

Profile any data project to understand structure, quality, and statistics.

Reads from `input/<project>/`, writes profile to `output/<project>/`.

## STEP-BY-STEP INSTRUCTIONS

### STEP 0 — Smart Input Resolution (Auto-Copy + Project Tracking)

The first argument `$0` can be a project name OR a path to any folder on disk.

1. If `input/$0/` exists with data files: PROJECT = `$0`.
2. Otherwise treat `$0` as a path. Extract basename as PROJECT. Copy files:
   ```bash
   mkdir -p input/PROJECT
   cp "$0"/*.csv "$0"/*.xlsx "$0"/*.xls "$0"/*.json input/PROJECT/ 2>/dev/null
   ```
   Tell user: "Registered project 'PROJECT' — data copied to input/PROJECT/"
3. If no data files anywhere: tell user and STOP.
4. `input/` is the project registry — every project ever worked on stays here.

### STEP 1 — Set Paths
```
PROJECT = resolved name
INPUT = input/PROJECT/
OUTPUT = output/PROJECT/
```

### STEP 2 — Find Data Files
Glob: `input/PROJECT/**/*.csv`, `*.xlsx`, `*.xls`, `*.json`
If ZERO files: tell user and STOP.

### STEP 3 — Create Output
```bash
mkdir -p output/$0
```

### STEP 4 — Run Profiler
```bash
python ${CLAUDE_SKILL_DIR}/../../scripts/profiler.py input/$0 output/$0/data-profile.md
```

### STEP 5 — Present Results
Read `output/$0/data-profile.md`. Show summary:
```
| File | Rows | Columns | Quality | Issues |
|------|------|---------|---------|--------|
```
Suggest: `:clean $0` to fix issues, `:analyze $0` for full pipeline.

## Examples
```
/10x-analyst-loop:profile my-sales
/10x-analyst-loop:profile customer-export
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
