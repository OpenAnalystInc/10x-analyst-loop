#!/usr/bin/env python3
"""
Pre-validation hook for 10x-Analyst-Loop pipelines.
Checks that input data exists and is readable before any pipeline runs.

Usage: python pre-validate.py <project-name-or-path> [project2] [project3] ...
Exit 0 = valid, Exit 1 = invalid (blocks pipeline)
"""
import sys
import os
import glob


def validate_project(project_arg):
    """Validate a single project argument."""
    errors = []

    # Check if it's a project name in input/
    input_dir = os.path.join("input", project_arg)
    if not os.path.isdir(input_dir):
        # Maybe it's a direct path
        if os.path.isdir(project_arg):
            input_dir = project_arg
        else:
            errors.append(f"Project directory not found: input/{project_arg} or {project_arg}")
            return errors

    # Find data files
    extensions = ("*.csv", "*.xlsx", "*.xls", "*.json")
    data_files = []
    for ext in extensions:
        data_files.extend(glob.glob(os.path.join(input_dir, "**", ext), recursive=True))

    if not data_files:
        errors.append(f"No data files (.csv, .xlsx, .xls, .json) found in {input_dir}")
        return errors

    # Check each file is readable and non-empty
    for f in data_files:
        if os.path.getsize(f) == 0:
            errors.append(f"Empty file: {f}")
        try:
            with open(f, "rb") as fh:
                fh.read(1)
        except PermissionError:
            errors.append(f"Permission denied: {f}")
        except Exception as e:
            errors.append(f"Cannot read {f}: {e}")

    return errors


def main():
    if len(sys.argv) < 2:
        print("ERROR: No project specified")
        sys.exit(1)

    all_errors = []
    for arg in sys.argv[1:]:
        if not arg.strip():
            continue
        errors = validate_project(arg.strip())
        all_errors.extend(errors)

    if all_errors:
        print("PRE-VALIDATION FAILED:")
        for err in all_errors:
            print(f"  - {err}")
        sys.exit(1)
    else:
        print(f"PRE-VALIDATION OK: {len(sys.argv) - 1} project(s) validated")
        sys.exit(0)


if __name__ == "__main__":
    main()
