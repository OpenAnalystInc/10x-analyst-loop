---
name: batch-analyze
description: "Analyze multiple data projects in parallel using worktree isolation. Use when user says 'analyze all my projects', 'batch process these datasets', or 'run analysis on multiple folders'."
argument-hint: "[project1] [project2] [project3] ..."
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch
model: claude-sonnet-4-6
hooks:
  pre: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/pre-validate.py $ARGUMENTS"
  post: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/post-session-log.py batch batch-analyze"
---

# 10x Analyst Loop — Batch Analyzer (Agent Swarm + Worktree Isolation)

Analyze multiple data projects simultaneously using a **swarm of isolated agents**. Each project runs in its own worktree agent to prevent file conflicts. Supports glob patterns like `input/*` to analyze ALL registered projects.

**Swarm Pattern:**
```
Orchestrator (this skill)
    ├── Agent 1 (worktree) → analyze project-a
    ├── Agent 2 (worktree) → analyze project-b
    ├── Agent 3 (worktree) → analyze project-c
    └── ... (up to 10 parallel agents)
```

## STEP-BY-STEP INSTRUCTIONS

### STEP 0 — Smart Input Resolution for EACH Argument (+ Glob Expansion)

**Glob expansion:** If any argument is `input/*` or contains `*`:
```bash
python -c "import glob, os; dirs=[d for d in glob.glob('$ARGUMENTS') if os.path.isdir(d)]; print(' '.join([os.path.basename(d) for d in dirs]))"
```
This expands `input/*` to all project directories in the registry.

For EACH argument in `$ARGUMENTS` (space-separated project names or paths):

1. If `input/ARG/` exists with data files: PROJECT = ARG.
2. Otherwise treat ARG as a filesystem path:
   - Extract folder basename as PROJECT
   - Copy data files: `mkdir -p input/PROJECT && cp ARG/*.csv ARG/*.xlsx ARG/*.json input/PROJECT/ 2>/dev/null`
   - Tell user: "Registered project 'PROJECT'"
3. Collect all resolved PROJECT names into a list.

If ZERO valid projects: tell user and STOP.

### STEP 1 — List All Projects to Analyze

Present the plan:
```
Batch Analysis Plan:
| # | Project | Files | Est. Rows |
|---|---------|-------|-----------|
| 1 | project-a | 5 files | ~10,000 |
| 2 | project-b | 3 files | ~5,000 |
| 3 | project-c | 8 files | ~25,000 |

Proceed? (Each runs in an isolated parallel agent)
```

### STEP 2 — Spawn Parallel Agents

For EACH project, spawn a background Agent with `isolation: worktree`:

```
Agent(
  description: "Analyze {PROJECT}",
  prompt: "Run the full 10x Analyst Loop pipeline on input/{PROJECT}/:
    1. mkdir -p output/{PROJECT}/charts output/{PROJECT}/cleaned-data
    2. python ${CLAUDE_SKILL_DIR}/../../scripts/profiler.py input/{PROJECT} output/{PROJECT}/data-profile.md
    3. python ${CLAUDE_SKILL_DIR}/../../scripts/data_cleaner.py input/{PROJECT} output/{PROJECT}/cleaned-data
    4. Load cleaned data, detect domain, run EDA, save output/{PROJECT}/insights.json
    5. Generate charts to output/{PROJECT}/charts/
    6. python ${CLAUDE_SKILL_DIR}/../../scripts/dashboard_template.py input/{PROJECT} output/{PROJECT}/dashboard.html
    7. Write output/{PROJECT}/report.md with executive summary, findings, recommendations
    Present completion summary when done.",
  isolation: "worktree",
  run_in_background: true
)
```

### STEP 3 — Wait for All Agents

As each agent completes, collect its results. Present a combined summary:

```
Batch Analysis Complete!

| Project | Files | Rows | Quality | Top Insight | Report |
|---------|-------|------|---------|-------------|--------|
| project-a | 5 | 10,234 | 94% | Revenue up 23% | output/project-a/report.md |
| project-b | 3 | 5,102 | 88% | Churn at 15% | output/project-b/report.md |
| project-c | 8 | 24,891 | 96% | Top product: X | output/project-c/report.md |

Dashboards:
  start output/project-a/dashboard.html
  start output/project-b/dashboard.html
  start output/project-c/dashboard.html
```

### STEP 4 — Cross-Project Insights (if 2+ projects)
If multiple projects share similar schemas (e.g., both have revenue columns), note cross-project patterns:
- Which project has higher quality data?
- Which project shows stronger growth?
- Common data issues across projects

## Examples
```
/10x-analyst-loop:batch-analyze q1-sales q2-sales q3-sales
/10x-analyst-loop:batch-analyze input/*
/10x-analyst-loop:batch-analyze C:/data/store-a C:/data/store-b
/10x-analyst-loop:batch-analyze marketing-data finance-data hr-data
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
