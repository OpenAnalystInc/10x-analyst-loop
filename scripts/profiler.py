"""
10x-Analyst Data Profiler
Profiles CSV, Excel, and JSON files — outputs a Markdown data profile.

Usage:
    python profiler.py input/<dataset> [output_path]

Works with any model size (Haiku → Opus). The model calls this script,
reads stdout, and uses the structured output directly.
"""

import pandas as pd
import os
import sys
import json
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
    else:
        return None


def profile_dataframe(df, filename):
    """Profile a single DataFrame and return structured results."""
    total_cells = df.shape[0] * df.shape[1]
    missing_cells = int(df.isna().sum().sum())
    quality_score = round((1 - missing_cells / total_cells) * 100, 1) if total_cells > 0 else 0

    profile = {
        'file': filename,
        'rows': len(df),
        'columns': len(df.columns),
        'duplicates': int(df.duplicated().sum()),
        'missing_cells': missing_cells,
        'quality_score': quality_score,
        'column_profiles': []
    }

    for col in df.columns:
        col_profile = {
            'name': col,
            'dtype': str(df[col].dtype),
            'missing': int(df[col].isna().sum()),
            'missing_pct': round(df[col].isna().mean() * 100, 1),
            'unique': int(df[col].nunique()),
        }

        if df[col].dtype in ['int64', 'float64'] and not df[col].isna().all():
            col_profile['min'] = round(float(df[col].min()), 2)
            col_profile['max'] = round(float(df[col].max()), 2)
            col_profile['mean'] = round(float(df[col].mean()), 2)
            col_profile['median'] = round(float(df[col].median()), 2)
            col_profile['std'] = round(float(df[col].std()), 2)

            # Outlier detection (IQR)
            q1 = df[col].quantile(0.25)
            q3 = df[col].quantile(0.75)
            iqr = q3 - q1
            outliers = int(((df[col] < q1 - 1.5 * iqr) | (df[col] > q3 + 1.5 * iqr)).sum())
            col_profile['outliers'] = outliers
        elif df[col].dtype == 'object':
            top_values = df[col].value_counts().head(5).to_dict()
            col_profile['top_values'] = {str(k): int(v) for k, v in top_values.items()}

        profile['column_profiles'].append(col_profile)

    return profile


def profile_to_markdown(profile):
    """Convert a profile dict to Markdown string."""
    lines = []
    lines.append(f"## {profile['file']}")
    lines.append(f"- **Rows:** {profile['rows']:,}")
    lines.append(f"- **Columns:** {profile['columns']}")
    lines.append(f"- **Duplicates:** {profile['duplicates']:,}")
    lines.append(f"- **Missing Cells:** {profile['missing_cells']:,}")
    lines.append(f"- **Quality Score:** {profile['quality_score']}%")
    lines.append("")

    # Column details table
    lines.append("| Column | Type | Missing | Missing % | Unique |")
    lines.append("|--------|------|---------|-----------|--------|")
    for cp in profile['column_profiles']:
        lines.append(f"| {cp['name']} | {cp['dtype']} | {cp['missing']:,} | {cp['missing_pct']}% | {cp['unique']:,} |")
    lines.append("")

    # Numeric statistics
    num_cols = [cp for cp in profile['column_profiles'] if 'mean' in cp]
    if num_cols:
        lines.append("### Numeric Statistics")
        lines.append("| Column | Min | Max | Mean | Median | Std | Outliers |")
        lines.append("|--------|-----|-----|------|--------|-----|----------|")
        for cp in num_cols:
            lines.append(f"| {cp['name']} | {cp['min']} | {cp['max']} | {cp['mean']} | {cp['median']} | {cp['std']} | {cp.get('outliers', 0)} |")
        lines.append("")

    # Top categorical values
    cat_cols = [cp for cp in profile['column_profiles'] if 'top_values' in cp]
    if cat_cols:
        lines.append("### Top Categorical Values")
        for cp in cat_cols:
            lines.append(f"**{cp['name']}:** {', '.join(f'{k} ({v})' for k, v in list(cp['top_values'].items())[:5])}")
        lines.append("")

    return '\n'.join(lines)


def find_data_files(path):
    """Find all supported data files at a path."""
    if os.path.isfile(path):
        return [path]

    files = []
    for pattern in ['**/*.csv', '**/*.xlsx', '**/*.xls', '**/*.json']:
        files.extend(glob.glob(os.path.join(path, pattern), recursive=True))
    return sorted(files)


def detect_relationships(profiles_data):
    """Detect potential join keys between files."""
    relationships = []
    file_columns = {}

    for filepath, df in profiles_data.items():
        basename = os.path.basename(filepath)
        id_cols = [c for c in df.columns if c == 'id' or c.endswith('_id')]
        file_columns[basename] = {'id_cols': id_cols, 'all_cols': list(df.columns), 'df': df}

    files = list(file_columns.keys())
    for i in range(len(files)):
        for j in range(i + 1, len(files)):
            f1, f2 = files[i], files[j]
            common = set(file_columns[f1]['id_cols']) & set(file_columns[f2]['id_cols'])
            for col in common:
                df1 = file_columns[f1]['df']
                df2 = file_columns[f2]['df']
                u1 = df1[col].nunique()
                u2 = df2[col].nunique()

                if u1 == len(df1):
                    cardinality = f"{f2}.{col} → {f1}.{col} (many-to-one)"
                elif u2 == len(df2):
                    cardinality = f"{f1}.{col} → {f2}.{col} (many-to-one)"
                else:
                    cardinality = f"{f1}.{col} ↔ {f2}.{col} (many-to-many)"

                # Referential integrity
                set1 = set(df1[col].dropna())
                set2 = set(df2[col].dropna())
                overlap = len(set1 & set2)
                total = max(len(set1), len(set2))
                match_rate = round(overlap / total * 100, 1) if total > 0 else 0

                relationships.append({
                    'column': col,
                    'cardinality': cardinality,
                    'match_rate': f"{match_rate}%"
                })

    return relationships


def main():
    if len(sys.argv) < 2:
        print("Usage: python profiler.py <file_or_directory> [output_path]")
        sys.exit(1)

    target = sys.argv[1]
    dataset_name = os.path.basename(target.rstrip('/\\'))
    output_path = sys.argv[2] if len(sys.argv) > 2 else f'output/{dataset_name}/data-profile.md'

    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    files = find_data_files(target)
    if not files:
        print(f"No data files found at: {target}")
        sys.exit(1)

    print(f"Found {len(files)} data file(s)")

    profiles = []
    dataframes = {}
    for filepath in files:
        print(f"Profiling: {os.path.basename(filepath)}")
        df = load_file(filepath)
        if df is not None:
            profile = profile_dataframe(df, os.path.basename(filepath))
            profiles.append(profile)
            dataframes[filepath] = df

    # Build Markdown report
    md_lines = ["# Data Profile Report", f"> Generated by 10x-Analyst Profiler | Files: {len(profiles)}", ""]

    # Summary table
    md_lines.append("## Summary")
    md_lines.append("| File | Rows | Columns | Quality | Duplicates |")
    md_lines.append("|------|------|---------|---------|------------|")
    for p in profiles:
        md_lines.append(f"| {p['file']} | {p['rows']:,} | {p['columns']} | {p['quality_score']}% | {p['duplicates']:,} |")
    md_lines.append("")

    # Relationships
    if len(dataframes) > 1:
        relationships = detect_relationships(dataframes)
        if relationships:
            md_lines.append("## Detected Relationships")
            md_lines.append("| Join Column | Cardinality | Match Rate |")
            md_lines.append("|-------------|-------------|------------|")
            for r in relationships:
                md_lines.append(f"| {r['column']} | {r['cardinality']} | {r['match_rate']} |")
            md_lines.append("")

    # Detailed profiles
    md_lines.append("## Detailed Profiles")
    md_lines.append("")
    for p in profiles:
        md_lines.append(profile_to_markdown(p))

    md_lines.append("---")
    md_lines.append("*Generated by [10x-Analyst](https://10x.in) Profiler*")

    # Write output
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(md_lines))

    # Also output JSON for downstream agents
    json_path = output_path.replace('.md', '.json')
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(profiles, f, indent=2, default=str)

    print(f"\nProfile written to: {output_path}")
    print(f"Profile JSON written to: {json_path}")

    # Print summary for the model to read
    print("\n--- SUMMARY ---")
    for p in profiles:
        print(f"{p['file']}: {p['rows']:,} rows, {p['columns']} cols, {p['quality_score']}% quality")


if __name__ == '__main__':
    main()
