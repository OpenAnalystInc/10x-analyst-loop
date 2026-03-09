# Analysis Patterns Reference

Common analysis patterns used by 10x-Analyst agents. These patterns work across all model sizes — instructions are explicit and step-by-step.

---

## E-Commerce Analysis Patterns

### Revenue Analysis
```python
# Monthly revenue trend
revenue_monthly = df.groupby(pd.Grouper(key='order_date', freq='M'))['total_price'].sum().reset_index()
revenue_monthly.columns = ['month', 'revenue']
revenue_monthly['mom_growth'] = revenue_monthly['revenue'].pct_change() * 100
```

### Top Products
```python
# Top 10 products by revenue
top_products = df.groupby('product_name').agg(
    revenue=('total_price', 'sum'),
    quantity=('quantity', 'sum'),
    orders=('order_id', 'nunique')
).nlargest(10, 'revenue').reset_index()
```

### Average Order Value (AOV)
```python
# AOV over time
order_totals = df.groupby(['order_id', 'order_date'])['total_price'].sum().reset_index()
aov_monthly = order_totals.groupby(pd.Grouper(key='order_date', freq='M'))['total_price'].mean()
```

### RFM Segmentation
```python
# Compute RFM scores
snapshot_date = df['order_date'].max() + pd.Timedelta(days=1)
rfm = df.groupby('customer_id').agg(
    recency=('order_date', lambda x: (snapshot_date - x.max()).days),
    frequency=('order_id', 'nunique'),
    monetary=('total_price', 'sum')
).reset_index()

# Score 1-5 using quartiles
for col in ['recency', 'frequency', 'monetary']:
    rfm[f'{col}_score'] = pd.qcut(rfm[col], 5, labels=[5,4,3,2,1] if col == 'recency' else [1,2,3,4,5], duplicates='drop')

# Segment mapping
rfm['segment'] = rfm['recency_score'].astype(str) + rfm['frequency_score'].astype(str)
segment_map = {
    '55': 'Champions', '54': 'Champions', '45': 'Loyal',
    '44': 'Loyal', '35': 'Potential Loyal', '34': 'Potential Loyal',
    '53': 'New Customers', '52': 'Promising', '43': 'Promising',
    '33': 'Need Attention', '32': 'About to Sleep', '23': 'About to Sleep',
    '15': 'Cant Lose', '14': 'At Risk', '25': 'At Risk',
    '24': 'At Risk', '13': 'Hibernating', '12': 'Lost', '11': 'Lost',
    '22': 'Hibernating', '21': 'Lost'
}
rfm['segment_name'] = rfm['segment'].map(segment_map).fillna('Other')
```

### Cohort Retention
```python
# Monthly cohort analysis
df['cohort_month'] = df.groupby('customer_id')['order_date'].transform('min').dt.to_period('M')
df['order_month'] = df['order_date'].dt.to_period('M')
df['cohort_index'] = (df['order_month'] - df['cohort_month']).apply(lambda x: x.n)

cohort = df.groupby(['cohort_month', 'cohort_index'])['customer_id'].nunique().reset_index()
cohort_pivot = cohort.pivot(index='cohort_month', columns='cohort_index', values='customer_id')
cohort_pct = cohort_pivot.div(cohort_pivot[0], axis=0) * 100
```

### Price Elasticity
```python
# If price_changes data available
merged = pd.merge(price_changes, order_items, on='product_id')
merged['period'] = merged['order_date'].apply(lambda x: 'before' if x < merged['change_date'] else 'after')
elasticity = merged.groupby(['product_id', 'period']).agg(
    avg_price=('price', 'mean'),
    total_qty=('quantity', 'sum')
).reset_index()
```

---

## General Tabular Patterns

### Correlation Analysis
```python
# Correlation matrix for numeric columns
corr = df.select_dtypes(include='number').corr()
# Flag strong correlations (|r| > 0.7)
strong = [(corr.columns[i], corr.columns[j], corr.iloc[i,j])
          for i in range(len(corr)) for j in range(i+1, len(corr))
          if abs(corr.iloc[i,j]) > 0.7]
```

### Pareto Analysis (80/20)
```python
# Find items that drive 80% of total
sorted_df = df.groupby('category')['value'].sum().sort_values(ascending=False)
sorted_df_cumsum = sorted_df.cumsum() / sorted_df.sum() * 100
pareto_items = sorted_df_cumsum[sorted_df_cumsum <= 80].index.tolist()
```

### Anomaly Detection
```python
# IQR method
Q1 = df['column'].quantile(0.25)
Q3 = df['column'].quantile(0.75)
IQR = Q3 - Q1
outliers = df[(df['column'] < Q1 - 1.5 * IQR) | (df['column'] > Q3 + 1.5 * IQR)]
```

### Time Series Decomposition
```python
# Simple trend + seasonality
df['rolling_mean'] = df['value'].rolling(window=7).mean()
df['detrended'] = df['value'] - df['rolling_mean']
```

---

## Report Patterns

### Finding Format
```
### Finding: {Metric} {Direction} {Magnitude}
{2-3 sentences with specific numbers}
![Chart](charts/chart_name.png)
**Implication:** {Business meaning}
**Recommendation:** {Action to take}
```

### KPI Card Format
```json
{
  "label": "Total Revenue",
  "value": "$45,230",
  "delta": 23.1,
  "period": "vs. last month"
}
```

---
*10x.in Analysis Patterns Reference | 10x-Analyst-Loop v2.0.0*
