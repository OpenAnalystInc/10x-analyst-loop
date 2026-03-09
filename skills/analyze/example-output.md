# Example Output — Full Analysis Pipeline

This is a reference example of what a completed `:analyze` pipeline produces. Use this to verify quality and completeness.

---

## Expected Output Structure

```
output/example-project/
├── data-profile.md          # From profiler.py
├── cleaning-log.md          # From data_cleaner.py (inside cleaned-data/)
├── cleaned-data/            # Cleaned CSVs
│   ├── orders_cleaned.csv
│   ├── customers_cleaned.csv
│   └── products_cleaned.csv
├── insights.json            # Structured insights array
├── charts/                  # PNG visualizations
│   ├── revenue_trend.png
│   ├── top_products.png
│   ├── customer_segments.png
│   └── quality_heatmap.png
├── report.md                # Full Markdown report
├── dashboard.html           # Interactive HTML dashboard
├── api-export.json          # (if :api was run)
├── watch-log.md             # (if :watch was run)
├── .webhook-config.json     # (if :notify was configured)
└── .mcp-config.json         # (if :connect was configured)
```

## Example insights.json

```json
[
  {
    "id": "insight-001",
    "headline": "Revenue Grew 23% MoM Driven by Electronics Category",
    "category": "revenue",
    "value": 145230,
    "change_pct": 23.1,
    "implication": "Electronics category is the primary growth driver, contributing 60% of total revenue increase",
    "priority": "P0",
    "chart": "charts/revenue_trend.png"
  },
  {
    "id": "insight-002",
    "headline": "Top 10 Products Account for 72% of Revenue (Pareto Effect)",
    "category": "product_concentration",
    "value": 72,
    "change_pct": null,
    "implication": "High concentration risk — losing any top-10 product would significantly impact revenue",
    "priority": "P1",
    "chart": "charts/top_products.png"
  },
  {
    "id": "insight-003",
    "headline": "Customer Retention Dropped from 45% to 38% in Last Quarter",
    "category": "retention",
    "value": 38,
    "change_pct": -15.6,
    "implication": "Increasing churn suggests product-market fit issues or competitive pressure",
    "priority": "P0",
    "chart": "charts/customer_segments.png"
  }
]
```

## Example KPI Card Data

```json
[
  {"label": "Total Revenue", "value": "$145,230", "delta": 23.1, "period": "vs. last month"},
  {"label": "Orders", "value": "1,847", "delta": 12.5, "period": "vs. last month"},
  {"label": "Avg Order Value", "value": "$78.60", "delta": 9.4, "period": "vs. last month"},
  {"label": "Active Customers", "value": "892", "delta": -3.2, "period": "vs. last month"},
  {"label": "Data Quality", "value": "94.2%", "delta": 0, "period": "stable"}
]
```

## Quality Checklist

After a full `:analyze` run, verify:

- [ ] `data-profile.md` — exists, has per-file stats table
- [ ] `cleaned-data/` — has one cleaned file per input file
- [ ] `insights.json` — valid JSON array, each insight has id + headline + category
- [ ] `charts/` — at least 3 PNG charts, each >10KB (not empty)
- [ ] `report.md` — has Executive Summary, Key Findings, Recommendations sections
- [ ] `dashboard.html` — opens in browser, shows KPI cards and charts
- [ ] All chart titles include the key takeaway (not just metric name)
- [ ] Report branding includes "10x.in" and session ID
- [ ] No hardcoded file paths (all use project-relative paths)

---
*10x-Analyst-Loop v2.0.0 | Powered by [10x.in](https://10x.in)*
