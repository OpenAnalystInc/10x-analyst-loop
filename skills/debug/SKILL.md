---
name: debug
description: "Auto-diagnose pipeline failures — checks dependencies, validates files, searches for fixes. Use when user says 'debug my analysis', 'why did it fail', 'fix the error', or 'diagnose the problem'."
argument-hint: "[project-name] [optional: error-message]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch
model: claude-sonnet-4-6
context: fork
agent: general-purpose
hooks:
  post: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/post-session-log.py $0 debug"
---

# 10x Analyst Loop — Pipeline Debugger

Auto-diagnose and fix pipeline failures for any data project.

## STEP-BY-STEP INSTRUCTIONS

### STEP 0 — Smart Input Resolution

The first argument `$0` can be a project name OR a path to any folder on disk.

1. If `input/$0/` exists with data files: PROJECT = `$0`.
2. Otherwise treat `$0` as a path. Extract basename as PROJECT.
3. If no data files anywhere: this may BE the problem — note it.
4. `input/` is the project registry.

```
PROJECT = resolved project name
ERROR_MSG = everything after first argument (optional user-provided error)
OUTPUT = output/PROJECT/
```

### STEP 1 — Check Python Dependencies

Run this exact command:
```bash
python -c "
missing = []
for pkg in ['pandas', 'matplotlib', 'seaborn', 'openpyxl']:
    try: __import__(pkg)
    except ImportError: missing.append(pkg)
if missing: print(f'MISSING: {missing}')
else: print('ALL_OK')
"
```

If MISSING: auto-fix with `pip install {packages}` and report.

### STEP 2 — Validate Input Data

Check for common input problems:
```bash
python -c "
import glob, os
files = glob.glob('input/$0/**/*.*', recursive=True)
data = [f for f in files if f.endswith(('.csv','.xlsx','.xls','.json'))]
print(f'Data files: {len(data)}')
for f in data:
    size = os.path.getsize(f)
    if size == 0: print(f'EMPTY: {f}')
    elif size > 500_000_000: print(f'VERY_LARGE: {f} ({size/1e6:.0f}MB)')
    else: print(f'OK: {f} ({size} bytes)')
"
```

Check for encoding issues:
```bash
python -c "
import glob
for f in glob.glob('input/$0/**/*.csv', recursive=True):
    try:
        with open(f, 'r', encoding='utf-8') as fh: fh.read(1000)
        print(f'UTF8_OK: {f}')
    except UnicodeDecodeError:
        try:
            with open(f, 'r', encoding='latin-1') as fh: fh.read(1000)
            print(f'LATIN1: {f} (needs encoding fix)')
        except: print(f'ENCODING_ERROR: {f}')
"
```

### STEP 3 — Check Expected Output Artifacts

Read `${CLAUDE_SKILL_DIR}/common-errors.md` for the expected artifacts checklist.

Check which artifacts exist vs expected:
```bash
python -c "
import os
project = '$0'
expected = [
    f'output/{project}/data-profile.md',
    f'output/{project}/cleaning-log.md',
    f'output/{project}/insights.json',
    f'output/{project}/report.md',
    f'output/{project}/dashboard.html',
]
for f in expected:
    status = 'EXISTS' if os.path.exists(f) else 'MISSING'
    print(f'{status}: {f}')
"
```

### STEP 4 — Analyze Error (if provided)

If ERROR_MSG was provided:
1. Match against common error patterns in `${CLAUDE_SKILL_DIR}/common-errors.md`
2. If pattern found: apply the documented fix
3. If pattern NOT found: use WebSearch to search for the error:
   ```
   WebSearch("{ERROR_MSG} pandas python fix")
   ```
4. Present the fix to the user

### STEP 5 — Diagnose from Logs

Check for partial outputs that indicate where the pipeline broke:
- `data-profile.md` exists but no `cleaning-log.md` → Cleaner failed
- `cleaning-log.md` exists but no `insights.json` → Analysis failed
- `insights.json` exists but no `report.md` → Reporter failed
- `report.md` exists but no `dashboard.html` → Dashboard failed

### STEP 6 — Present Diagnosis

```markdown
## Diagnosis Report for {PROJECT}

### Status
| Check | Result |
|-------|--------|
| Python deps | ✅ All installed / ❌ Missing: X, Y |
| Input files | ✅ N files found / ❌ No data files |
| File encoding | ✅ All UTF-8 / ⚠️ Latin-1 detected in X |
| Empty files | ✅ None / ❌ Found N empty files |
| Pipeline stage | Failed at: {stage} |
| Error match | {matched pattern or "unknown"} |

### Fix
{Specific fix instructions}

### Next Step
{Offer to re-run the failed step}
```

## Examples
```
/10x-analyst-loop:debug my-sales
/10x-analyst-loop:debug my-project "ModuleNotFoundError: No module named 'openpyxl'"
/10x-analyst-loop:debug C:/data/exports "FileNotFoundError"
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
