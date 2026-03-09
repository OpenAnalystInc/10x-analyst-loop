# Data Quality Standards

Quality benchmarks and cleaning rules used by 10x-Analyst Data Engineer agent.

---

## Quality Score Calculation

```
Quality Score = (1 - (total_missing_cells / total_cells)) * 100
```

| Score | Grade | Action |
|-------|-------|--------|
| 95-100% | Excellent | Proceed with analysis |
| 85-94% | Good | Minor cleaning needed |
| 70-84% | Fair | Significant cleaning required, flag issues |
| <70% | Poor | Warn user, cleaning may alter results |

---

## Cleaning Rules

### Column Name Standardization
```python
df.columns = df.columns.str.strip().str.lower().str.replace(r'[^a-z0-9]+', '_', regex=True).str.strip('_')
```

### Missing Value Strategy

| Missing % | Numeric Columns | Categorical Columns |
|-----------|----------------|-------------------|
| 0% | No action | No action |
| 0.1-5% | Median imputation | Mode imputation |
| 5-20% | Median imputation + flag column | "Unknown" fill + flag column |
| 20-50% | Keep as-is, flag in report | Keep as-is, flag in report |
| >50% | Drop column, warn user | Drop column, warn user |

### Duplicate Detection
- Exact duplicates: drop, report count
- Near-duplicates: flag, do not auto-drop

### Date Parsing
Keywords in column names that trigger date parsing:
`date`, `time`, `created`, `updated`, `timestamp`, `_at`, `_on`

```python
date_keywords = ['date', 'time', 'created', 'updated', 'timestamp', '_at', '_on']
date_cols = [c for c in df.columns if any(kw in c.lower() for kw in date_keywords)]
for col in date_cols:
    df[col] = pd.to_datetime(df[col], errors='coerce')
```

### Currency Detection
Heuristic: if >50% of non-null string values match `^\$?[\d,]+\.?\d*$`, treat as currency.

```python
for col in df.select_dtypes(include='object').columns:
    sample = df[col].dropna().head(20).astype(str)
    if sample.str.match(r'^\$?[\d,]+\.?\d*$').mean() > 0.5:
        df[col] = df[col].astype(str).str.replace(r'[$,]', '', regex=True)
        df[col] = pd.to_numeric(df[col], errors='coerce')
```

### Outlier Detection
IQR method — flag but do not remove:

```python
Q1 = df[col].quantile(0.25)
Q3 = df[col].quantile(0.75)
IQR = Q3 - Q1
lower = Q1 - 1.5 * IQR
upper = Q3 + 1.5 * IQR
outlier_count = ((df[col] < lower) | (df[col] > upper)).sum()
```

---

## Relationship Detection

### Join Key Identification
Columns that likely serve as join keys:
- Named `id` or ending in `_id`
- Matching column names across files (e.g., `customer_id` in both orders and customers)
- Unique or near-unique values in one table (primary key candidate)

### Cardinality Checks
```python
# Before joining
left_unique = df_left['key'].nunique()
right_unique = df_right['key'].nunique()
left_total = len(df_left)
right_total = len(df_right)

# one-to-one: both unique == total
# one-to-many: one side unique == total, other side has repeats
# many-to-many: both sides have repeats (WARN)
```

### Referential Integrity
```python
# Check for orphans
orphans = set(df_child['foreign_key']) - set(df_parent['primary_key'])
match_rate = 1 - len(orphans) / df_child['foreign_key'].nunique()
```

---
*10x.in Data Quality Standards | 10x-Analyst-Loop v2.0.0*
