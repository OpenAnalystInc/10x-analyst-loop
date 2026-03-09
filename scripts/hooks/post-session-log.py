#!/usr/bin/env python3
"""
Post-session logging hook for 10x-Analyst-Loop pipelines.
Appends an entry to output/.session-history.json after every command.

Usage: python post-session-log.py <project-name> <command>
"""
import sys
import os
import json
import glob
from datetime import datetime


def main():
    if len(sys.argv) < 3:
        sys.exit(0)

    project = sys.argv[1]
    command = sys.argv[2]

    # Ensure output directory exists
    os.makedirs("output", exist_ok=True)

    history_path = os.path.join("output", ".session-history.json")

    # Load existing history
    history = []
    if os.path.exists(history_path):
        try:
            with open(history_path) as f:
                history = json.load(f)
        except (json.JSONDecodeError, Exception):
            history = []

    # Count output artifacts
    output_dir = os.path.join("output", project)
    artifact_count = 0
    if os.path.isdir(output_dir):
        artifact_count = len(glob.glob(os.path.join(output_dir, "**", "*.*"), recursive=True))

    # Count input files
    input_dir = os.path.join("input", project)
    input_count = 0
    if os.path.isdir(input_dir):
        for ext in ("*.csv", "*.xlsx", "*.xls", "*.json"):
            input_count += len(glob.glob(os.path.join(input_dir, "**", ext), recursive=True))

    # Create entry
    entry = {
        "timestamp": datetime.now().isoformat(),
        "project": project,
        "command": command,
        "session_id": os.environ.get("CLAUDE_SESSION_ID", "unknown"),
        "input_files": input_count,
        "output_artifacts": artifact_count,
        "tool": "10x Analyst Loop v2.0.0"
    }

    history.append(entry)

    # Keep last 500 entries
    if len(history) > 500:
        history = history[-500:]

    # Write back
    try:
        with open(history_path, "w") as f:
            json.dump(history, f, indent=2)
        print(f"SESSION LOG: {command} on {project} at {entry['timestamp']}")
    except Exception as e:
        print(f"SESSION LOG WARN: {e}")


if __name__ == "__main__":
    main()
