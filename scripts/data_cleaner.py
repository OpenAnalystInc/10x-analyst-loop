"""
10x-Analyst Data Cleaner
Cleans CSV, Excel, and JSON files — standardizes names, fixes types, handles missing data.

Usage:
    python data_cleaner.py input/<dataset> [output_directory]

Works with any model size (Haiku → Opus). Outputs cleaned files and a cleaning log.
"""

import pandas as pd
import os
import sys
import re
import glob


def load_file(filepath):
    """Load a data file into a pandas DataFrame."""
    ext = os.path.splitext(filepath)[1].lower()
    if ext == '.csv':
        return pd.read_csv(filepath)
    elif ext in ['.xlsx', '.xls']:
        return pd.read_excel(filepath)
    elif ext == '.json':
        return pd.read_json(filepath)
    return None


def clean_dataframe(df, filename):
    """Clean a DataFrame and return it with a log of actions taken."""
    actions = []
    original_rows = len(df)
    original_cols = len(df.columns)

    # 1. Standardize column names
    old_cols = list(df.columns)
    df.columns = (
        df.columns.str.strip()
        .str.lower()
        .str.replace(r'[^a-z0-9]+', '_', regex=True)
        .str.strip('_')
    )
    renamed = sum(1 for a, b in zip(old_cols, df.columns) if a != b)
    if renamed:
        actions.append(f"Renamed {renamed} columns to snake_case")

    # 2. Drop exact duplicates
    dup_count = int(df.duplicated().sum())
    if dup_count > 0:
        df.drop_duplicates(inplace=True)
        actions.append(f"Removed {dup_count} duplicate rows")

    # 3. Parse date columns
    date_keywords = ['date', 'time', 'created', 'updated', 'timestamp', '_at', '_on']
    date_cols = [c for c in df.columns if any(kw in c for kw in date_keywords)]
    for col in date_cols:
        if df[col].dtype == 'object':
            parsed = pd.to_datetime(df[col], errors='coerce')
            success_rate = parsed.notna().mean()
            if success_rate > 0.5:
                df[col] = parsed
                actions.append(f"Parsed '{col}' as datetime ({success_rate*100:.0f}% success)")

    # 4. Convert currency strings to float
    for col in df.select_dtypes(include='object').columns:
        sample = df[col].dropna().head(20).astype(str)
        if len(sample) > 0 and sample.str.match(r'^\$?[\d,]+\.?\d*$').mean() > 0.5:
            df[col] = df[col].astype(str).str.replace(r'[$,]', '', regex=True)
            df[col] = pd.to_numeric(df[col], errors='coerce')
            actions.append(f"Converted '{col}' from currency string to numeric")

    # 5. Handle missing values
    for col in df.columns:
        missing_pct = df[col].isna().mean()
        if missing_pct > 0.5:
            df.drop(columns=[col], inplace=True)
            actions.append(f"Dropped column '{col}' ({missing_pct*100:.0f}% missing)")
        elif missing_pct > 0.05:
            if df[col].dtype in ['float64', 'int64']:
                median_val = df[col].median()
                df[col].fillna(median_val, inplace=True)
                actions.append(f"Filled '{col}' missing with median ({median_val:.2f}), {missing_pct*100:.1f}% were missing")
            elif df[col].dtype == 'object':
                df[col].fillna('Unknown', inplace=True)
                actions.append(f"Filled '{col}' missing with 'Unknown', {missing_pct*100:.1f}% were missing")
        elif missing_pct > 0:
            if df[col].dtype in ['float64', 'int64']:
                df[col].fillna(df[col].median(), inplace=True)
                actions.append(f"Filled '{col}' missing with median ({missing_pct*100:.1f}% were missing)")
            elif df[col].dtype == 'object':
                mode_val = df[col].mode()
                if len(mode_val) > 0:
                    df[col].fillna(mode_val.iloc[0], inplace=True)
                    actions.append(f"Filled '{col}' missing with mode '{mode_val.iloc[0]}'")

    # 6. Strip whitespace from string columns
    for col in df.select_dtypes(include='object').columns:
        df[col] = df[col].str.strip()
        actions.append(f"Stripped whitespace from '{col}'")

    cleaned_rows = len(df)
    cleaned_cols = len(df.columns)

    log = {
        'file': filename,
        'original_rows': original_rows,
        'cleaned_rows': cleaned_rows,
        'rows_removed': original_rows - cleaned_rows,
        'original_cols': original_cols,
        'cleaned_cols': cleaned_cols,
        'cols_removed': original_cols - cleaned_cols,
        'actions': actions
    }

    return df, log


def find_data_files(path):
    """Find all supported data files at a path."""
    if os.path.isfile(path):
        return [path]
    files = []
    for pattern in ['**/*.csv', '**/*.xlsx', '**/*.xls', '**/*.json']:
        files.extend(glob.glob(os.path.join(path, pattern), recursive=True))
    return sorted(files)


def main():
    if len(sys.argv) < 2:
        print("Usage: python data_cleaner.py <file_or_directory> [output_directory]")
        sys.exit(1)

    target = sys.argv[1]
    dataset_name = os.path.basename(target.rstrip('/\\'))
    output_dir = sys.argv[2] if len(sys.argv) > 2 else f'output/{dataset_name}/cleaned-data'

    os.makedirs(output_dir, exist_ok=True)

    files = find_data_files(target)
    if not files:
        print(f"No data files found at: {target}")
        sys.exit(1)

    print(f"Found {len(files)} data file(s) to clean\n")

    logs = []
    for filepath in files:
        basename = os.path.basename(filepath)
        ext = os.path.splitext(basename)[1].lower()
        print(f"Cleaning: {basename}")

        df = load_file(filepath)
        if df is None:
            print(f"  Skipped (unsupported format)")
            continue

        df_cleaned, log = clean_dataframe(df, basename)
        logs.append(log)

        # Save cleaned file
        output_path = os.path.join(output_dir, basename)
        if ext == '.json':
            df_cleaned.to_json(output_path, orient='records', indent=2, default_handler=str)
        else:
            df_cleaned.to_csv(output_path, index=False)

        print(f"  {log['original_rows']} → {log['cleaned_rows']} rows | {len(log['actions'])} actions")
        for action in log['actions']:
            print(f"    - {action}")
        print()

    # Write cleaning log
    log_path = os.path.join(f'output/{dataset_name}', 'cleaning-log.md')
    with open(log_path, 'w', encoding='utf-8') as f:
        f.write("# Data Cleaning Log\n")
        f.write(f"> Generated by 10x-Analyst Data Cleaner | Files: {len(logs)}\n\n")

        f.write("## Summary\n")
        f.write("| File | Original Rows | Cleaned Rows | Removed | Actions |\n")
        f.write("|------|--------------|-------------|---------|--------|\n")
        for log in logs:
            f.write(f"| {log['file']} | {log['original_rows']:,} | {log['cleaned_rows']:,} | {log['rows_removed']:,} | {len(log['actions'])} |\n")
        f.write("\n")

        f.write("## Detailed Actions\n\n")
        for log in logs:
            f.write(f"### {log['file']}\n")
            for action in log['actions']:
                f.write(f"- {action}\n")
            f.write("\n")

        f.write("---\n")
        f.write("*Generated by [10x-Analyst](https://10x.in) Data Cleaner*\n")

    print(f"Cleaning log: {log_path}")
    print(f"Cleaned files: {output_dir}/")


if __name__ == '__main__':
    main()
