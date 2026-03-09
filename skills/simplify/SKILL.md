---
name: simplify
description: "Review and optimize generated Python code after any pipeline completes — removes dead code, consolidates duplicates, improves naming. Use when user says 'simplify the code', 'optimize scripts', 'clean up generated code', or 'review the output code'."
argument-hint: "[project-name]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent
model: claude-sonnet-4-6
context: fork
agent: general-purpose
hooks:
  post: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/post-session-log.py $0 simplify"
---

# 10x Analyst Loop — Code Simplifier

Review and optimize all generated Python scripts in a project's output. Runs 3 parallel review passes: reuse, quality, and efficiency.

## STEP-BY-STEP INSTRUCTIONS

### STEP 1 — Find Generated Code

Scan for Python files in the project:
```bash
python -c "
import glob
scripts = glob.glob('${CLAUDE_SKILL_DIR}/../../scripts/*.py')
output_py = glob.glob('output/$0/**/*.py', recursive=True)
print('Core scripts:', scripts)
print('Output scripts:', output_py)
"
```

### STEP 2 — Launch 3 Parallel Review Agents

Spawn 3 Agent calls in parallel:

**Agent 1 — Reuse Review:**
```
"Review these Python files for code reuse opportunities:
{list of files}
Look for: duplicated logic across files, copy-pasted code blocks, functions that should be shared utilities.
Return a list of specific reuse opportunities with file:line references."
```

**Agent 2 — Quality Review:**
```
"Review these Python files for code quality:
{list of files}
Look for: unclear variable names, missing error handling at system boundaries, overly complex functions (>30 lines), unused imports, dead code.
Return a list of specific issues with file:line references and suggested fixes."
```

**Agent 3 — Efficiency Review:**
```
"Review these Python files for performance:
{list of files}
Look for: unnecessary loops over DataFrames (use vectorized ops), repeated file reads, inefficient string concatenation, missing dtype specifications in read_csv.
Return a list of specific optimizations with file:line references."
```

### STEP 3 — Collect and Deduplicate Findings

Merge results from all 3 agents. Remove duplicate findings. Prioritize by impact:
- P0: Bugs or correctness issues
- P1: Significant performance improvements
- P2: Code clarity improvements
- P3: Style/naming suggestions

### STEP 4 — Apply Fixes (with confirmation)

For each P0 and P1 finding:
1. Show the current code and proposed fix
2. Apply the fix using Edit tool

For P2 and P3: present as suggestions, do not auto-apply.

### STEP 5 — Present Summary

```markdown
## Code Simplification Report for {PROJECT}

### Applied Fixes
| # | File | Issue | Fix |
|---|------|-------|-----|
| 1 | scripts/profiler.py:42 | Duplicated null check | Extracted to helper |

### Suggestions (not applied)
| # | File | Suggestion | Impact |
|---|------|-----------|--------|
| 1 | scripts/chart_generator.py:88 | Use vectorized string ops | Minor speedup |

### Metrics
- Files reviewed: {N}
- Issues found: {N}
- Fixes applied: {N}
- Suggestions: {N}
```

## Examples
```
/10x-analyst-loop:simplify my-sales
/10x-analyst-loop:simplify customer-data
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
