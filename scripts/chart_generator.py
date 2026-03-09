"""
10x-Analyst Chart Generator
Generates publication-ready charts using matplotlib and seaborn.

Usage:
    python chart_generator.py <data-file> <chart-type> <x-column> <y-column> [output-path] [title]

Chart types: line, bar, hbar, stacked, donut, heatmap, scatter, boxplot, histogram

Works with any model size — the model just calls with the right arguments.
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os
import sys
import json

# 10x Style Configuration
COLORS = ['#FF6B35', '#004E89', '#00A878', '#FFD166', '#EF476F', '#118AB2', '#073B4C']
POSITIVE = '#00A878'
NEGATIVE = '#EF476F'
NEUTRAL = '#004E89'

plt.style.use('seaborn-v0_8-whitegrid')
sns.set_palette(COLORS)
plt.rcParams.update({
    'figure.figsize': (12, 6),
    'figure.dpi': 150,
    'font.size': 11,
    'axes.titlesize': 14,
    'axes.titleweight': 'bold',
    'axes.labelsize': 12,
    'legend.fontsize': 10,
    'figure.facecolor': 'white',
    'axes.facecolor': 'white',
    'axes.edgecolor': '#dddddd',
    'grid.color': '#eeeeee',
    'grid.linewidth': 0.8,
})


def load_data(filepath):
    """Load a data file."""
    ext = os.path.splitext(filepath)[1].lower()
    if ext == '.csv':
        return pd.read_csv(filepath)
    elif ext in ['.xlsx', '.xls']:
        return pd.read_excel(filepath)
    elif ext == '.json':
        return pd.read_json(filepath)
    return None


def format_number(val):
    """Format numbers for chart labels."""
    if abs(val) >= 1_000_000:
        return f'${val/1_000_000:.1f}M' if val > 0 else f'-${abs(val)/1_000_000:.1f}M'
    elif abs(val) >= 1_000:
        return f'${val/1_000:.1f}K' if val > 0 else f'-${abs(val)/1_000:.1f}K'
    return f'${val:,.0f}'


def generate_line_chart(df, x_col, y_col, output_path, title=None):
    """Generate a line chart for trend data."""
    fig, ax = plt.subplots(figsize=(12, 6))
    ax.plot(df[x_col], df[y_col], color=COLORS[0], linewidth=2.5, marker='o', markersize=4)
    ax.fill_between(df[x_col], df[y_col], alpha=0.1, color=COLORS[0])
    ax.set_title(title or f'{y_col} Over {x_col}', fontsize=14, fontweight='bold')
    ax.set_xlabel(x_col.replace('_', ' ').title())
    ax.set_ylabel(y_col.replace('_', ' ').title())
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Line chart saved: {output_path}")


def generate_bar_chart(df, x_col, y_col, output_path, title=None, top_n=10):
    """Generate a vertical bar chart for top-N comparisons."""
    plot_df = df.nlargest(top_n, y_col) if len(df) > top_n else df
    fig, ax = plt.subplots(figsize=(12, 6))
    bars = ax.bar(range(len(plot_df)), plot_df[y_col], color=COLORS[:len(plot_df)])
    ax.set_xticks(range(len(plot_df)))
    ax.set_xticklabels(plot_df[x_col], rotation=45, ha='right')
    ax.set_title(title or f'Top {len(plot_df)} by {y_col}', fontsize=14, fontweight='bold')
    ax.set_ylabel(y_col.replace('_', ' ').title())

    for bar, val in zip(bars, plot_df[y_col]):
        ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height(),
                format_number(val), ha='center', va='bottom', fontsize=9)

    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Bar chart saved: {output_path}")


def generate_hbar_chart(df, x_col, y_col, output_path, title=None, top_n=10):
    """Generate a horizontal bar chart for ranked data."""
    plot_df = df.nlargest(top_n, y_col).sort_values(y_col) if len(df) > top_n else df.sort_values(y_col)
    fig, ax = plt.subplots(figsize=(12, max(6, len(plot_df) * 0.5)))
    bars = ax.barh(range(len(plot_df)), plot_df[y_col], color=COLORS[:len(plot_df)])
    ax.set_yticks(range(len(plot_df)))
    ax.set_yticklabels(plot_df[x_col])
    ax.set_title(title or f'Top {len(plot_df)} by {y_col}', fontsize=14, fontweight='bold')
    ax.set_xlabel(y_col.replace('_', ' ').title())

    for bar, val in zip(bars, plot_df[y_col]):
        ax.text(bar.get_width(), bar.get_y() + bar.get_height() / 2,
                f' {format_number(val)}', ha='left', va='center', fontsize=9)

    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Horizontal bar chart saved: {output_path}")


def generate_donut_chart(df, label_col, value_col, output_path, title=None, top_n=8):
    """Generate a donut chart for proportional data."""
    if len(df) > top_n:
        top = df.nlargest(top_n, value_col)
        other_val = df[~df.index.isin(top.index)][value_col].sum()
        other_row = pd.DataFrame({label_col: ['Other'], value_col: [other_val]})
        plot_df = pd.concat([top, other_row], ignore_index=True)
    else:
        plot_df = df

    fig, ax = plt.subplots(figsize=(8, 8))
    wedges, texts, autotexts = ax.pie(
        plot_df[value_col], labels=plot_df[label_col],
        colors=COLORS[:len(plot_df)], autopct='%1.1f%%',
        startangle=90, pctdistance=0.85,
        wedgeprops={'width': 0.4, 'edgecolor': 'white', 'linewidth': 2}
    )
    ax.set_title(title or f'{value_col} Breakdown', fontsize=14, fontweight='bold')
    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Donut chart saved: {output_path}")


def generate_heatmap(df, output_path, title=None):
    """Generate a correlation heatmap for numeric columns."""
    numeric_df = df.select_dtypes(include='number')
    if len(numeric_df.columns) < 2:
        print("Not enough numeric columns for heatmap")
        return

    corr = numeric_df.corr()
    fig, ax = plt.subplots(figsize=(10, 10))
    sns.heatmap(corr, annot=True, fmt='.2f', cmap='RdYlBu_r', center=0,
                square=True, linewidths=0.5, ax=ax,
                vmin=-1, vmax=1, cbar_kws={'shrink': 0.8})
    ax.set_title(title or 'Correlation Matrix', fontsize=14, fontweight='bold')
    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Heatmap saved: {output_path}")


def generate_scatter(df, x_col, y_col, output_path, title=None):
    """Generate a scatter plot."""
    fig, ax = plt.subplots(figsize=(10, 8))
    ax.scatter(df[x_col], df[y_col], c=COLORS[0], alpha=0.6, s=40, edgecolors='white', linewidth=0.5)
    ax.set_title(title or f'{y_col} vs {x_col}', fontsize=14, fontweight='bold')
    ax.set_xlabel(x_col.replace('_', ' ').title())
    ax.set_ylabel(y_col.replace('_', ' ').title())
    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Scatter plot saved: {output_path}")


def generate_boxplot(df, x_col, y_col, output_path, title=None):
    """Generate a box plot for distribution comparison."""
    fig, ax = plt.subplots(figsize=(12, 6))
    unique_vals = df[x_col].nunique()
    if unique_vals > 10:
        top_cats = df[x_col].value_counts().head(10).index
        plot_df = df[df[x_col].isin(top_cats)]
    else:
        plot_df = df

    sns.boxplot(data=plot_df, x=x_col, y=y_col, palette=COLORS, ax=ax)
    ax.set_title(title or f'{y_col} by {x_col}', fontsize=14, fontweight='bold')
    plt.xticks(rotation=45, ha='right')
    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Box plot saved: {output_path}")


def generate_histogram(df, col, output_path, title=None, bins=30):
    """Generate a histogram for distribution analysis."""
    fig, ax = plt.subplots(figsize=(10, 6))
    ax.hist(df[col].dropna(), bins=bins, color=COLORS[0], edgecolor='white', linewidth=0.5, alpha=0.8)
    ax.axvline(df[col].median(), color=COLORS[1], linestyle='--', linewidth=2, label=f'Median: {df[col].median():.2f}')
    ax.axvline(df[col].mean(), color=COLORS[2], linestyle='--', linewidth=2, label=f'Mean: {df[col].mean():.2f}')
    ax.set_title(title or f'Distribution of {col}', fontsize=14, fontweight='bold')
    ax.set_xlabel(col.replace('_', ' ').title())
    ax.set_ylabel('Count')
    ax.legend()
    plt.tight_layout()
    plt.savefig(output_path, bbox_inches='tight')
    plt.close()
    print(f"Histogram saved: {output_path}")


CHART_FUNCTIONS = {
    'line': generate_line_chart,
    'bar': generate_bar_chart,
    'hbar': generate_hbar_chart,
    'donut': generate_donut_chart,
    'heatmap': generate_heatmap,
    'scatter': generate_scatter,
    'boxplot': generate_boxplot,
    'histogram': generate_histogram,
}


def main():
    if len(sys.argv) < 4:
        print("Usage: python chart_generator.py <data-file> <chart-type> <x-column> [y-column] [output-path] [title]")
        print(f"Chart types: {', '.join(CHART_FUNCTIONS.keys())}")
        sys.exit(1)

    data_file = sys.argv[1]
    chart_type = sys.argv[2]
    x_col = sys.argv[3]
    y_col = sys.argv[4] if len(sys.argv) > 4 else None
    output_path = sys.argv[5] if len(sys.argv) > 5 else f'output/charts/{chart_type}_{x_col}.png'
    title = sys.argv[6] if len(sys.argv) > 6 else None

    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    df = load_data(data_file)
    if df is None:
        print(f"Could not load: {data_file}")
        sys.exit(1)

    if chart_type not in CHART_FUNCTIONS:
        print(f"Unknown chart type: {chart_type}. Available: {', '.join(CHART_FUNCTIONS.keys())}")
        sys.exit(1)

    func = CHART_FUNCTIONS[chart_type]

    if chart_type == 'heatmap':
        func(df, output_path, title)
    elif chart_type == 'histogram':
        func(df, x_col, output_path, title)
    elif chart_type == 'donut':
        func(df, x_col, y_col, output_path, title)
    else:
        if y_col is None:
            print(f"Chart type '{chart_type}' requires a y-column")
            sys.exit(1)
        func(df, x_col, y_col, output_path, title)


if __name__ == '__main__':
    main()
