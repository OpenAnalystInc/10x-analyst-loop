# Common Error Patterns

Error database used by the `:debug` skill to auto-diagnose pipeline failures.

---

## Python Dependency Errors

| Error Pattern | Package | Fix |
|--------------|---------|-----|
| `ModuleNotFoundError: No module named 'pandas'` | pandas | `pip install pandas` |
| `ModuleNotFoundError: No module named 'matplotlib'` | matplotlib | `pip install matplotlib` |
| `ModuleNotFoundError: No module named 'seaborn'` | seaborn | `pip install seaborn` |
| `ModuleNotFoundError: No module named 'openpyxl'` | openpyxl | `pip install openpyxl` |
| `ModuleNotFoundError: No module named 'xlrd'` | xlrd | `pip install xlrd` |

## File System Errors

| Error Pattern | Cause | Fix |
|--------------|-------|-----|
| `FileNotFoundError: input/` | Project not found | Check project name, run Smart Input Resolution |
| `PermissionError` | File locked by another process | Close Excel/other apps, retry |
| `IsADirectoryError` | Path points to directory not file | Check glob patterns |

## Data Parsing Errors

| Error Pattern | Cause | Fix |
|--------------|-------|-----|
| `UnicodeDecodeError` | Non-UTF-8 encoding | Read with `encoding='latin-1'` or `encoding='cp1252'` |
| `ParserError: Error tokenizing data` | Malformed CSV | Try `read_csv(f, on_bad_lines='skip')` |
| `EmptyDataError: No columns to parse` | Empty file | Remove empty files from input |
| `ValueError: Excel file format cannot be determined` | Wrong extension or corrupt | Verify file is valid Excel |
| `JSONDecodeError` | Malformed JSON | Validate JSON structure |

## Analysis Errors

| Error Pattern | Cause | Fix |
|--------------|-------|-----|
| `KeyError: 'column_name'` | Column doesn't exist after cleaning | Check cleaned data schema |
| `ValueError: Cannot convert` | Type mismatch | Check column types, apply proper casting |
| `MemoryError` | Dataset too large | Use chunked reading or sampling |
| `ZeroDivisionError` | Empty group or zero denominator | Add zero-check guards |

## Dashboard Errors

| Error Pattern | Cause | Fix |
|--------------|-------|-----|
| `No insights found` | insights.json missing or empty | Re-run analysis step first |
| `Chart.js CDN unreachable` | No internet | Dashboard still works with inline data |

## Expected Output Artifacts

After a full `:analyze` pipeline, these files should exist:

| File | Created By | Stage |
|------|-----------|-------|
| `data-profile.md` | profiler.py | Data Engineering |
| `cleaning-log.md` | data_cleaner.py | Data Engineering |
| `cleaned-data/*.csv` | data_cleaner.py | Data Engineering |
| `insights.json` | Statistician agent | Analysis |
| `charts/*.png` | Visualizer agent | Visualization |
| `dashboard.html` | dashboard_template.py | Visualization |
| `report.md` | Reporter agent | Reporting |

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
