---
name: api
description: "Export all analysis artifacts as structured JSON for app consumption — bundles profile, insights, charts, report into a single API-ready package. Use when user says 'export as JSON', 'API export', 'make this consumable', or 'package the results'."
argument-hint: "[project-name] [optional: --serve]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Write, Bash, Glob, Grep
model: claude-haiku-4-5-20251001
context: fork
agent: general-purpose
hooks:
  post: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/post-session-log.py $0 api"
---

# 10x Analyst Loop — API Exporter

Bundle all analysis outputs into a structured JSON file ready for app consumption.

## STEP-BY-STEP INSTRUCTIONS

### STEP 0 — Smart Input Resolution

1. If `input/$0/` exists: PROJECT = `$0`.
2. Otherwise apply path resolution as per standard Smart Input Resolution.
3. Verify `output/$0/` exists with analysis results. If not: tell user to run `:analyze $0` first.

### STEP 1 — Collect All Artifacts

```bash
python -c "
import os, glob, json

project = '$0'
output_dir = f'output/{project}'
artifacts = {}

# Profile
profile_path = f'{output_dir}/data-profile.md'
if os.path.exists(profile_path):
    with open(profile_path) as f: artifacts['profile'] = f.read()

# Insights
insights_path = f'{output_dir}/insights.json'
if os.path.exists(insights_path):
    with open(insights_path) as f: artifacts['insights'] = json.load(f)

# Report
report_path = f'{output_dir}/report.md'
if os.path.exists(report_path):
    with open(report_path) as f: artifacts['report'] = f.read()

# Charts
charts = glob.glob(f'{output_dir}/charts/*.png')
artifacts['chart_paths'] = [os.path.basename(c) for c in charts]

# Dashboard
dash_path = f'{output_dir}/dashboard.html'
artifacts['has_dashboard'] = os.path.exists(dash_path)

# Cleaned data info
cleaned = glob.glob(f'{output_dir}/cleaned-data/*')
artifacts['cleaned_files'] = [os.path.basename(c) for c in cleaned]

print(json.dumps({'artifacts_found': list(artifacts.keys()), 'counts': {
    'insights': len(artifacts.get('insights', [])),
    'charts': len(artifacts.get('chart_paths', [])),
    'cleaned_files': len(artifacts.get('cleaned_files', []))
}}))
"
```

### STEP 2 — Build API Export

Write `output/$PROJECT/api-export.json`:

```python
import os, glob, json
from datetime import datetime

project = '$0'
output_dir = f'output/{project}'

export = {
    'meta': {
        'project': project,
        'generated_at': datetime.now().isoformat(),
        'session_id': '${CLAUDE_SESSION_ID}',
        'version': '2.0.0',
        'tool': '10x Analyst Loop',
        'url': 'https://10x.in'
    },
    'profile': None,
    'insights': [],
    'kpis': [],
    'charts': [],
    'report_text': None,
    'dashboard_path': None,
    'cleaned_files': [],
    'input_files': []
}

# Load profile
profile_path = f'{output_dir}/data-profile.md'
if os.path.exists(profile_path):
    with open(profile_path) as f:
        export['profile'] = f.read()

# Load insights
insights_path = f'{output_dir}/insights.json'
if os.path.exists(insights_path):
    with open(insights_path) as f:
        export['insights'] = json.load(f)

# Load report
report_path = f'{output_dir}/report.md'
if os.path.exists(report_path):
    with open(report_path) as f:
        export['report_text'] = f.read()

# Chart paths
charts = glob.glob(f'{output_dir}/charts/*.png')
export['charts'] = [{'name': os.path.basename(c), 'path': c} for c in charts]

# Dashboard
if os.path.exists(f'{output_dir}/dashboard.html'):
    export['dashboard_path'] = f'{output_dir}/dashboard.html'

# Cleaned files
cleaned = glob.glob(f'{output_dir}/cleaned-data/*')
export['cleaned_files'] = [os.path.basename(c) for c in cleaned]

# Input files
inputs = glob.glob(f'input/{project}/**/*.*', recursive=True)
export['input_files'] = [os.path.basename(f) for f in inputs if f.endswith(('.csv','.xlsx','.xls','.json'))]

with open(f'{output_dir}/api-export.json', 'w') as f:
    json.dump(export, f, indent=2, default=str)

print(f'Exported to {output_dir}/api-export.json ({os.path.getsize(f"{output_dir}/api-export.json")} bytes)')
```

### STEP 3 — Optional: Serve Locally

If user passed `--serve` or asked to serve:
```bash
python -m http.server 8080 --directory output/$PROJECT/
```
Tell user: "API available at http://localhost:8080/api-export.json"

### STEP 4 — Present Summary

```
API Export Complete!

| Detail | Value |
|--------|-------|
| File | output/{PROJECT}/api-export.json |
| Size | {file_size} |
| Insights | {count} |
| Charts | {count} |
| Profile | {Yes/No} |
| Report | {Yes/No} |
| Dashboard | {Yes/No} |

To serve locally: /10x-analyst-loop:api {PROJECT} --serve
```

## API Schema

See `${CLAUDE_SKILL_DIR}/api-schema.json` for the full JSON schema.

## Examples
```
/10x-analyst-loop:api my-sales
/10x-analyst-loop:api inventory --serve
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
