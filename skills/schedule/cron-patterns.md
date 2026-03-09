# Cron Pattern Translation Table

Reference for converting natural language time expressions to cron expressions.

---

## Cron Expression Format

```
┌──────── minute (0-59)
│ ┌────── hour (0-23)
│ │ ┌──── day of month (1-31)
│ │ │ ┌── month (1-12)
│ │ │ │ ┌ day of week (0-7, 0=Sun, 1=Mon, ..., 7=Sun)
│ │ │ │ │
* * * * *
```

## Common Patterns

### Recurring Intervals

| Natural Language | Cron | Notes |
|-----------------|------|-------|
| every minute | `* * * * *` | Not recommended |
| every 5 minutes | `*/5 * * * *` | Useful for `:watch` |
| every 10 minutes | `*/10 * * * *` | Default for `:watch` |
| every 15 minutes | `*/15 * * * *` | |
| every 30 minutes | `*/30 * * * *` | |
| every hour | `0 * * * *` | Top of hour |
| every 2 hours | `0 */2 * * *` | |
| every 6 hours | `0 */6 * * *` | |
| every 12 hours | `0 */12 * * *` | |

### Daily Patterns

| Natural Language | Cron | Notes |
|-----------------|------|-------|
| every day at midnight | `0 0 * * *` | |
| every day at 9am | `0 9 * * *` | Business hours |
| every day at 6pm | `0 18 * * *` | End of day |
| every morning | `0 8 * * *` | 8 AM |
| every evening | `0 18 * * *` | 6 PM |

### Weekly Patterns

| Natural Language | Cron | Notes |
|-----------------|------|-------|
| every Monday | `0 9 * * 1` | 9 AM Monday |
| every Friday | `0 9 * * 5` | 9 AM Friday |
| every weekday | `0 9 * * 1-5` | Mon-Fri 9 AM |
| every weekend | `0 10 * * 0,6` | Sat+Sun 10 AM |
| every Sunday night | `0 20 * * 0` | 8 PM Sunday |

### Monthly Patterns

| Natural Language | Cron | Notes |
|-----------------|------|-------|
| first of every month | `0 9 1 * *` | 1st at 9 AM |
| 15th of every month | `0 9 15 * *` | 15th at 9 AM |
| last weekday | `0 9 28 * *` | Approximate (use 28th) |

## One-Shot Tasks

For one-shot tasks ("in 30 minutes", "tomorrow 9am"), calculate the exact time:

```python
from datetime import datetime, timedelta

# "in N minutes"
target = datetime.now() + timedelta(minutes=N)
cron = f"{target.minute} {target.hour} {target.day} {target.month} *"

# "tomorrow at 9am"
target = datetime.now() + timedelta(days=1)
cron = f"0 9 {target.day} {target.month} *"
```

Set `recurring: false` for one-shot tasks.

## Important Notes

- All times are in the user's **local timezone**
- Cron jobs **auto-expire after 3 days** (Claude Code session limit)
- For long-term scheduling, suggest the user set up external cron/Task Scheduler
- Add **jitter** for recurring tasks to avoid exact synchronization issues

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
