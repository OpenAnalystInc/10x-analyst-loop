"""
10x-Analyst Dashboard Generator
Generates a standalone interactive HTML dashboard with Chart.js.

Usage:
    python dashboard_template.py input/<dataset> [output-path]

Works with any model size — the model calls this with data path, script handles the rest.
"""

import pandas as pd
import os
import sys
import json
import glob


def load_all_data(path):
    """Load all data files from a path into a dict of DataFrames."""
    files = {}
    if os.path.isfile(path):
        targets = [path]
    else:
        targets = []
        for ext in ['*.csv', '*.xlsx', '*.xls', '*.json']:
            targets.extend(glob.glob(os.path.join(path, ext)))

    for filepath in sorted(targets):
        basename = os.path.basename(filepath)
        ext = os.path.splitext(filepath)[1].lower()
        try:
            if ext == '.csv':
                files[basename] = pd.read_csv(filepath)
            elif ext in ['.xlsx', '.xls']:
                files[basename] = pd.read_excel(filepath)
            elif ext == '.json':
                files[basename] = pd.read_json(filepath)
        except Exception as e:
            print(f"Warning: Could not load {basename}: {e}")

    return files


def compute_kpis(dataframes):
    """Compute KPI cards from available data."""
    kpis = []

    # Try to find revenue/sales data
    for name, df in dataframes.items():
        df.columns = df.columns.str.strip().str.lower().str.replace(r'[^a-z0-9]+', '_', regex=True).str.strip('_')

        # Row count KPI
        kpis.append({
            'label': f'{name.replace(".csv","").replace("_"," ").title()} Records',
            'value': f'{len(df):,}',
            'delta': 0
        })

        # Revenue KPI
        rev_cols = [c for c in df.columns if any(kw in c for kw in ['revenue', 'total', 'price', 'amount', 'sales'])]
        if rev_cols and df[rev_cols[0]].dtype in ['int64', 'float64']:
            total = df[rev_cols[0]].sum()
            kpis.append({
                'label': f'Total {rev_cols[0].replace("_", " ").title()}',
                'value': f'${total:,.2f}',
                'delta': 0
            })

        # Unique count KPIs
        id_cols = [c for c in df.columns if c.endswith('_id') or c == 'id']
        for col in id_cols[:2]:
            kpis.append({
                'label': f'Unique {col.replace("_", " ").title()}',
                'value': f'{df[col].nunique():,}',
                'delta': 0
            })

    return kpis[:8]  # Max 8 KPI cards


def compute_charts(dataframes):
    """Compute chart data from available DataFrames."""
    charts = []
    colors = ['#FF6B35', '#004E89', '#00A878', '#FFD166', '#EF476F', '#118AB2', '#073B4C']

    for name, df in dataframes.items():
        df.columns = df.columns.str.strip().str.lower().str.replace(r'[^a-z0-9]+', '_', regex=True).str.strip('_')

        # Detect date columns for trend charts
        date_cols = [c for c in df.columns if any(kw in c for kw in ['date', 'time', 'created'])]
        num_cols = [c for c in df.select_dtypes(include='number').columns]
        cat_cols = [c for c in df.select_dtypes(include='object').columns]

        # Trend chart (if date + numeric column available)
        if date_cols and num_cols:
            date_col = date_cols[0]
            val_col = num_cols[0]
            try:
                df[date_col] = pd.to_datetime(df[date_col], errors='coerce')
                monthly = df.dropna(subset=[date_col]).groupby(
                    df[date_col].dt.to_period('M')
                )[val_col].sum().reset_index()
                monthly[date_col] = monthly[date_col].astype(str)

                charts.append({
                    'title': f'{val_col.replace("_", " ").title()} Trend ({name})',
                    'type': 'line',
                    'data': {
                        'labels': monthly[date_col].tolist()[-24:],
                        'datasets': [{
                            'label': val_col.replace('_', ' ').title(),
                            'data': monthly[val_col].tolist()[-24:],
                            'borderColor': colors[0],
                            'backgroundColor': colors[0] + '20',
                            'fill': True,
                            'tension': 0.3
                        }]
                    },
                    'options': {}
                })
            except Exception:
                pass

        # Top-N bar chart (if categorical + numeric columns)
        if cat_cols and num_cols:
            cat_col = cat_cols[0]
            val_col = num_cols[0]
            top = df.groupby(cat_col)[val_col].sum().nlargest(10).reset_index()

            charts.append({
                'title': f'Top 10 {cat_col.replace("_", " ").title()} by {val_col.replace("_", " ").title()}',
                'type': 'bar',
                'data': {
                    'labels': top[cat_col].astype(str).tolist(),
                    'datasets': [{
                        'label': val_col.replace('_', ' ').title(),
                        'data': top[val_col].tolist(),
                        'backgroundColor': colors[:len(top)]
                    }]
                },
                'options': {}
            })

        # Distribution donut (first categorical with <20 unique values)
        for col in cat_cols:
            if 2 <= df[col].nunique() <= 15:
                vc = df[col].value_counts().head(8)
                charts.append({
                    'title': f'{col.replace("_", " ").title()} Distribution',
                    'type': 'doughnut',
                    'data': {
                        'labels': vc.index.astype(str).tolist(),
                        'datasets': [{
                            'data': vc.values.tolist(),
                            'backgroundColor': colors[:len(vc)]
                        }]
                    },
                    'options': {}
                })
                break

    return charts[:8]  # Max 8 charts


def compute_table(dataframes):
    """Compute a summary data table."""
    rows = []
    for name, df in dataframes.items():
        df.columns = df.columns.str.strip().str.lower().str.replace(r'[^a-z0-9]+', '_', regex=True).str.strip('_')
        num_cols = df.select_dtypes(include='number').columns

        for col in num_cols[:3]:
            rows.append({
                'file': name,
                'metric': col.replace('_', ' ').title(),
                'sum': f'{df[col].sum():,.2f}',
                'mean': f'{df[col].mean():,.2f}',
                'min': f'{df[col].min():,.2f}',
                'max': f'{df[col].max():,.2f}'
            })

    return rows[:20]


def generate_html(kpis, charts, table_rows, source_name, output_path):
    """Generate the complete dashboard HTML."""
    html = f'''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>10x Analysis Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * {{ margin: 0; padding: 0; box-sizing: border-box; }}
        body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #F5EDE0; color: #073B4C; padding: 24px; min-height: 100vh; }}
        .header {{ text-align: center; margin-bottom: 32px; padding: 24px 0; }}
        .header h1 {{ font-size: 32px; color: #004E89; margin-bottom: 4px; }}
        .header .subtitle {{ color: #666; font-size: 14px; }}
        .header .brand {{ color: #FF6B35; font-weight: 600; }}
        .kpi-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 32px; }}
        .kpi-card {{ background: white; border-radius: 12px; padding: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); transition: transform 0.2s; }}
        .kpi-card:hover {{ transform: translateY(-2px); box-shadow: 0 4px 16px rgba(0,0,0,0.1); }}
        .kpi-card .label {{ font-size: 12px; color: #888; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 8px; }}
        .kpi-card .value {{ font-size: 28px; font-weight: 700; color: #004E89; }}
        .kpi-card .delta {{ font-size: 13px; margin-top: 4px; }}
        .delta.up {{ color: #00A878; }}
        .delta.down {{ color: #EF476F; }}
        .delta.neutral {{ color: #888; }}
        .charts-grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(450px, 1fr)); gap: 24px; margin-bottom: 32px; }}
        .chart-card {{ background: white; border-radius: 12px; padding: 24px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }}
        .chart-card h3 {{ font-size: 15px; color: #004E89; margin-bottom: 16px; font-weight: 600; }}
        canvas {{ max-height: 350px; }}
        .data-table {{ background: white; border-radius: 12px; padding: 24px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); margin-bottom: 32px; overflow-x: auto; }}
        .data-table h3 {{ font-size: 15px; color: #004E89; margin-bottom: 16px; font-weight: 600; }}
        table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
        th {{ background: #004E89; color: white; padding: 10px 14px; text-align: left; font-weight: 600; white-space: nowrap; }}
        th:first-child {{ border-radius: 6px 0 0 0; }}
        th:last-child {{ border-radius: 0 6px 0 0; }}
        td {{ padding: 10px 14px; border-bottom: 1px solid #f0ece6; }}
        tr:hover td {{ background: #faf8f5; }}
        .footer {{ text-align: center; color: #999; font-size: 13px; padding: 24px 0; }}
        .footer a {{ color: #FF6B35; text-decoration: none; font-weight: 600; }}
        .footer a:hover {{ text-decoration: underline; }}
        @media (max-width: 768px) {{
            body {{ padding: 12px; }}
            .charts-grid {{ grid-template-columns: 1fr; }}
            .kpi-grid {{ grid-template-columns: repeat(2, 1fr); }}
            .kpi-card .value {{ font-size: 22px; }}
        }}
    </style>
</head>
<body>
    <div class="header">
        <h1>10x Analysis Dashboard</h1>
        <p class="subtitle">Source: {source_name} | Generated by <span class="brand">10x Analyst</span></p>
    </div>

    <div class="kpi-grid" id="kpis"></div>
    <div class="charts-grid" id="charts"></div>
    <div class="data-table" id="tableSection">
        <h3>Key Metrics Summary</h3>
        <table id="dataTable">
            <thead><tr><th>File</th><th>Metric</th><th>Sum</th><th>Mean</th><th>Min</th><th>Max</th></tr></thead>
            <tbody id="tableBody"></tbody>
        </table>
    </div>

    <div class="footer">
        <p>Powered by <a href="https://10x.in">10x.in</a> | 10x-Analyst v1.0.0</p>
    </div>

    <script>
        const COLORS = ['#FF6B35', '#004E89', '#00A878', '#FFD166', '#EF476F', '#118AB2', '#073B4C'];

        // KPI Data
        const kpis = {json.dumps(kpis)};

        // Render KPI cards
        const kpiGrid = document.getElementById('kpis');
        kpis.forEach(kpi => {{
            const deltaClass = kpi.delta > 0 ? 'up' : kpi.delta < 0 ? 'down' : 'neutral';
            const arrow = kpi.delta > 0 ? '&#9650;' : kpi.delta < 0 ? '&#9660;' : '&#9644;';
            const deltaText = kpi.delta !== 0 ? `${{arrow}} ${{Math.abs(kpi.delta)}}%` : 'No change';
            kpiGrid.innerHTML += `
                <div class="kpi-card">
                    <div class="label">${{kpi.label}}</div>
                    <div class="value">${{kpi.value}}</div>
                    <div class="delta ${{deltaClass}}">${{deltaText}}</div>
                </div>`;
        }});

        // Chart Data
        const chartsData = {json.dumps(charts)};

        // Render chart containers
        const chartsGrid = document.getElementById('charts');
        chartsData.forEach((chart, i) => {{
            const canvasId = `chart-${{i}}`;
            chartsGrid.innerHTML += `
                <div class="chart-card">
                    <h3>${{chart.title}}</h3>
                    <canvas id="${{canvasId}}"></canvas>
                </div>`;
        }});

        // Initialize Chart.js
        chartsData.forEach((chart, i) => {{
            const ctx = document.getElementById(`chart-${{i}}`);
            new Chart(ctx, {{
                type: chart.type,
                data: chart.data,
                options: {{
                    responsive: true,
                    maintainAspectRatio: true,
                    plugins: {{
                        legend: {{ position: 'bottom', labels: {{ padding: 12, usePointStyle: true }} }},
                        tooltip: {{ backgroundColor: '#073B4C', titleColor: '#fff', bodyColor: '#fff', padding: 12, cornerRadius: 8 }}
                    }},
                    ...chart.options
                }}
            }});
        }});

        // Table Data
        const tableRows = {json.dumps(table_rows)};
        const tbody = document.getElementById('tableBody');
        tableRows.forEach(row => {{
            tbody.innerHTML += `<tr><td>${{row.file}}</td><td>${{row.metric}}</td><td>${{row.sum}}</td><td>${{row.mean}}</td><td>${{row.min}}</td><td>${{row.max}}</td></tr>`;
        }});

        if (tableRows.length === 0) {{
            document.getElementById('tableSection').style.display = 'none';
        }}
    </script>
</body>
</html>'''

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(html)
    print(f"Dashboard saved: {output_path}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python dashboard_template.py <data-file-or-directory> [output-path]")
        sys.exit(1)

    data_path = sys.argv[1]
    dataset_name = os.path.basename(data_path.rstrip('/\\'))
    output_path = sys.argv[2] if len(sys.argv) > 2 else f'output/{dataset_name}/dashboard.html'

    print(f"Loading data from: {data_path}")
    dataframes = load_all_data(data_path)

    if not dataframes:
        print(f"No data files found at: {data_path}")
        sys.exit(1)

    print(f"Loaded {len(dataframes)} file(s): {', '.join(dataframes.keys())}")

    kpis = compute_kpis(dataframes)
    charts = compute_charts(dataframes)
    table_rows = compute_table(dataframes)

    source_name = os.path.basename(data_path.rstrip('/\\'))
    generate_html(kpis, charts, table_rows, source_name, output_path)

    print(f"\nDashboard ready! Open in browser:")
    print(f"  start {output_path}")
    print(f"  # or: open {output_path}")


if __name__ == '__main__':
    main()
