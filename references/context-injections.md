# Dynamic Context Injection Patterns

All `!`command`` patterns used across 10x-Analyst-Loop skills. These inject live data into prompts before execution.

**IMPORTANT:** All commands use Python one-liners for cross-platform compatibility (Windows + Mac + Linux).

---

## File Count & Size (used by :analyze STEP 2.5)

```bash
python -c "import glob, os; files=glob.glob('input/$0/**/*.*', recursive=True); exts=[f for f in files if f.endswith(('.csv','.xlsx','.xls','.json'))]; total=sum(os.path.getsize(f) for f in exts); print(f'FILES={len(exts)} TOTAL_SIZE={total} bytes')"
```

**Output:** `FILES=5 TOTAL_SIZE=234567 bytes`
**Used to:** Calibrate analysis depth — <10 files standard, 10-50 chunked, 50+ sampling.

---

## Data Schema Context (used by :query STEP 1)

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

**Output:** `input/my-sales/orders.csv: 1000 rows x 8 cols | Columns: ['order_id', 'date', ...]`
**Used to:** Write accurate pandas queries without guessing column names.

---

## Watch State Snapshot (used by :watch STEP 3.5)

```bash
python -c "import glob, os, json; files=glob.glob('input/$PROJECT/**/*.*', recursive=True); exts=[f for f in files if f.endswith(('.csv','.xlsx','.xls','.json'))]; stats=[{'file':f,'size':os.path.getsize(f),'mtime':os.path.getmtime(f)} for f in exts]; print(json.dumps(stats))"
```

**Output:** JSON array of file stats for change detection.
**Used to:** Compare current state vs baseline to detect file changes.

---

## Last Modified Time (general utility)

```bash
python -c "import os, time; print(time.ctime(os.path.getmtime('input/$0')))"
```

---

## Directory Size (general utility)

```bash
python -c "import os; print(sum(os.path.getsize(os.path.join(dp,f)) for dp,_,fns in os.walk('input/$0') for f in fns))"
```

---

## Line Count (replaces `wc -l`)

```bash
python -c "import glob; print(len(glob.glob('input/$0/*')))"
```

---

## Webhook Config Check (used by :analyze STEP 8, :report STEP 6)

```bash
python -c "import os, json; path='output/$0/.webhook-config.json'; print(json.load(open(path)) if os.path.exists(path) else 'NO_WEBHOOK')"
```

---

## MCP Config Check (used by :analyze STEP 0.5 and STEP 8)

```bash
python -c "import os, json; path='output/$0/.mcp-config.json'; print(json.load(open(path)) if os.path.exists(path) else 'NO_MCP')"
```

---

## Cross-Platform Notes

| Unix Command | Python Equivalent | Used By |
|-------------|-------------------|---------|
| `wc -l` | `python -c "..."` (line count) | General |
| `du -sh` | `python -c "..."` (dir size) | :analyze |
| `stat` | `python -c "..."` (mtime) | :watch |
| `curl` | `python -c "import urllib.request; ..."` | :notify |
| `find` | `python -c "import glob; ..."` | All skills |

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
