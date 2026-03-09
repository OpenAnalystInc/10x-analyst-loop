#!/usr/bin/env python3
"""
Post-notification hook for 10x-Analyst-Loop pipelines.
Reads .webhook-config.json and POSTs results to configured webhook URL.

Usage: python post-notify.py <project-name> <command> [status]
"""
import sys
import os
import json
import urllib.request
from datetime import datetime


def main():
    if len(sys.argv) < 3:
        print("SKIP: No project/command specified")
        sys.exit(0)

    project = sys.argv[1]
    command = sys.argv[2]
    status = sys.argv[3] if len(sys.argv) > 3 else "success"

    # Check for webhook config
    config_path = os.path.join("output", project, ".webhook-config.json")
    if not os.path.exists(config_path):
        # No webhook configured — silent skip
        sys.exit(0)

    try:
        with open(config_path) as f:
            config = json.load(f)
    except Exception as e:
        print(f"WARN: Could not read webhook config: {e}")
        sys.exit(0)

    webhook_url = config.get("webhook_url")
    if not webhook_url:
        sys.exit(0)

    # Build payload
    output_dir = os.path.join("output", project)
    artifacts = {}
    for artifact in ["report.md", "dashboard.html", "data-profile.md", "insights.json"]:
        path = os.path.join(output_dir, artifact)
        artifacts[artifact.replace(".", "_").replace("-", "_")] = os.path.exists(path)

    # Load insights summary if available
    summary = {}
    insights_path = os.path.join(output_dir, "insights.json")
    if os.path.exists(insights_path):
        try:
            with open(insights_path) as f:
                insights = json.load(f)
            summary["insights_count"] = len(insights)
            if insights:
                summary["top_insight"] = insights[0].get("headline", "N/A")
        except Exception:
            pass

    payload = {
        "event": f"{command}_complete",
        "project": project,
        "command": command,
        "status": status,
        "timestamp": datetime.now().isoformat(),
        "session_id": os.environ.get("CLAUDE_SESSION_ID", "unknown"),
        "artifacts": artifacts,
        "summary": summary,
        "branding": {
            "tool": "10x Analyst Loop",
            "version": "2.0.0",
            "url": "https://10x.in"
        }
    }

    # POST to webhook
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        webhook_url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST"
    )

    try:
        resp = urllib.request.urlopen(req, timeout=10)
        print(f"WEBHOOK OK: HTTP {resp.status} -> {webhook_url}")
    except Exception as e:
        print(f"WEBHOOK FAILED: {e}")
        # Don't block pipeline on webhook failure
        sys.exit(0)


if __name__ == "__main__":
    main()
