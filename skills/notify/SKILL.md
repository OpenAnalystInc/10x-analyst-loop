---
name: notify
description: "Configure webhook notifications for analysis completion — POST JSON to any URL when pipelines finish. Use when user says 'notify me when done', 'send webhook', 'set up notifications', or 'post results to URL'."
argument-hint: "[project-name] [webhook-url]"
disable-model-invocation: true
user-invocable: true
allowed-tools: Read, Write, Bash, Glob, Grep
model: claude-haiku-4-5-20251001
hooks:
  post: "python ${CLAUDE_SKILL_DIR}/../../scripts/hooks/post-session-log.py $0 notify"
---

# 10x Analyst Loop — Webhook Notifier

Configure webhook URLs to receive POST notifications when analysis pipelines complete.

## STEP-BY-STEP INSTRUCTIONS

### STEP 1 — Parse Arguments

```
PROJECT = $0 (project name or path)
WEBHOOK_URL = $1 (full URL like https://webhook.site/xxx or https://hooks.slack.com/xxx)
```

Apply Smart Input Resolution for PROJECT if needed.

### STEP 2 — Validate Webhook URL

```bash
python -c "
from urllib.parse import urlparse
url = '$1'
parsed = urlparse(url)
if parsed.scheme in ('http', 'https') and parsed.netloc:
    print(f'VALID: {url}')
else:
    print(f'INVALID: {url} — must be http:// or https://')
"
```

If INVALID: tell user and STOP.

### STEP 3 — Save Webhook Config

Write `output/$PROJECT/.webhook-config.json`:
```json
{
  "webhook_url": "{WEBHOOK_URL}",
  "project": "{PROJECT}",
  "configured_at": "{ISO timestamp}",
  "events": ["analyze_complete", "report_complete", "dashboard_complete", "watch_alert"],
  "payload_template": "default"
}
```

Create output directory if needed:
```bash
mkdir -p output/$PROJECT
```

### STEP 4 — Test Webhook (Optional)

Send a test POST:
```bash
python -c "
import urllib.request, json
data = json.dumps({
    'event': 'test',
    'project': '$0',
    'message': '10x Analyst Loop webhook configured successfully',
    'timestamp': __import__('datetime').datetime.now().isoformat()
}).encode()
req = urllib.request.Request('$1', data=data, headers={'Content-Type': 'application/json'})
try:
    resp = urllib.request.urlopen(req, timeout=10)
    print(f'SUCCESS: HTTP {resp.status}')
except Exception as e:
    print(f'FAILED: {e}')
"
```

### STEP 5 — Confirm to User

```
Webhook configured for project '{PROJECT}'

| Setting | Value |
|---------|-------|
| URL | {WEBHOOK_URL} |
| Events | analyze, report, dashboard, watch alerts |
| Config | output/{PROJECT}/.webhook-config.json |
| Test | {Success/Failed} |

All future pipeline runs for '{PROJECT}' will POST results to this URL.
To remove: delete output/{PROJECT}/.webhook-config.json
```

## Webhook Payload Format

See `${CLAUDE_SKILL_DIR}/webhook-payload-template.json` for the full schema.

## Examples
```
/10x-analyst-loop:notify my-sales https://webhook.site/abc123
/10x-analyst-loop:notify inventory https://hooks.slack.com/services/xxx
```

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
