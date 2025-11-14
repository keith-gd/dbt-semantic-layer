# BI Tool Integrations Guide

## Overview

The dbt Semantic Layer provides native integrations with major BI tools, allowing analysts to query metrics directly without SQL knowledge. This guide covers setup and usage patterns for each integration.

**Supported Tools:**
- Tableau (Desktop & Cloud)
- Google Sheets
- Hex
- Mode
- Power BI (via JDBC)
- Looker (via custom integration)
- Sigma

---

## Integration Architecture

**Two connection methods:**

1. **Native Integrations** - Direct connectors (Tableau, Sheets, Hex, Sigma)
2. **JDBC/ODBC** - Universal SQL interface (Power BI, Mode, custom tools)

**Authentication:**
- dbt Cloud service tokens (production)
- Environment-specific API keys
- Row-level security via dbt Cloud permissions

---

## Tableau Integration

### Prerequisites

- dbt Cloud account with Semantic Layer enabled
- Tableau Desktop 2023.1+ or Tableau Cloud
- dbt Cloud service token with Semantic Layer permissions

### Setup Steps

#### 1. Generate dbt Cloud Service Token

```bash
# In dbt Cloud UI:
# Account Settings → Service Tokens → Create Token
# Permissions: "Semantic Layer Only" or "Metadata Only"

# Save token securely
export DBT_CLOUD_TOKEN="your-token-here"
```

#### 2. Connect Tableau to Semantic Layer

**Tableau Desktop:**

1. Open Tableau Desktop
2. Connect → More → "dbt Semantic Layer"
3. Enter connection details:
   - **Host**: `semantic-layer.cloud.getdbt.com`
   - **Environment ID**: Find in dbt Cloud (Deploy → Environments)
   - **Service Token**: Paste token from step 1
4. Click "Sign In"

**Tableau Cloud:**

1. Navigate to data sources
2. New Data Source → "dbt Semantic Layer"
3. Enter same connection details as Desktop
4. Authenticate

#### 3. Query Metrics in Tableau

**Drag-and-drop interface:**

1. **Dimensions pane** - Shows all available dimensions (categorical, time)
2. **Measures pane** - Shows all metrics
3. Drag metric to "Rows" or "Columns"
4. Drag dimension to "Rows", "Columns", or "Filters"

**Example visualization:**
- Drag `Total Revenue` (metric) to Rows
- Drag `Order Date` (time dimension) to Columns
- Drag `Customer Segment` (categorical dimension) to Color
- Result: Line chart of revenue over time, colored by segment

**Filtering:**
- Right-click dimension → "Show Filter"
- Set filter values (e.g., Order Status = 'completed')
- Filters applied server-side via Semantic Layer

### Best Practices

**✅ DO:**
- Use Tableau's date functions with time dimensions (`YEAR(Order Date)`, `QUARTER(Order Date)`)
- Create calculated fields for Tableau-specific logic (not in Semantic Layer)
- Use extracts for large datasets (faster performance)

**❌ DON'T:**
- Recreate metrics in Tableau (define once in Semantic Layer)
- Join additional data sources (defeats single source of truth)
- Use Tableau's LOD calculations for metrics (use Semantic Layer metrics instead)

---

## Google Sheets Integration

### Prerequisites

- dbt Cloud account with Semantic Layer enabled
- Google Workspace account
- dbt Semantic Layer for Sheets add-on

### Setup Steps

#### 1. Install Add-On

1. Open Google Sheets
2. Extensions → Add-ons → Get add-ons
3. Search "dbt Semantic Layer"
4. Install and authorize

#### 2. Connect to Semantic Layer

1. Extensions → dbt Semantic Layer → Connect
2. Enter connection details:
   - **Environment ID**: From dbt Cloud
   - **Service Token**: Generate in dbt Cloud (see Tableau section)
3. Click "Connect"

#### 3. Query Metrics

**Using sidebar:**

1. Extensions → dbt Semantic Layer → Open Sidebar
2. Select metrics from dropdown (multi-select supported)
3. Select dimensions for grouping
4. Add filters (optional)
5. Click "Run Query"
6. Results populate in active sheet

**Formula method:**

```
=DBT_QUERY(
  "metrics", "total_revenue,order_count",
  "group_by", "customer__customer_segment,metric_time__month",
  "where", "order__order_status = 'completed'",
  "limit", 100
)
```

### Use Cases

**✅ Best for:**
- Executive dashboards (monthly/quarterly KPIs)
- Ad hoc analysis by non-technical users
- Quick metric spot-checks
- Sharing read-only snapshots

**❌ Not ideal for:**
- Real-time dashboards (Sheets refresh is manual)
- Large datasets (> 50k rows, use Tableau/Mode instead)
- Complex visualizations (limited charting vs. Tableau)

---

## Hex Integration

### Prerequisites

- Hex account (Team or Enterprise tier)
- dbt Cloud account with Semantic Layer enabled
- Python SDK access (optional, for advanced use)

### Setup Steps

#### 1. Add dbt Cloud Connection

1. In Hex workspace → Data Sources
2. Add Connection → "dbt Cloud"
3. Configure:
   - **Name**: `dbt_semantic_layer`
   - **Host**: `semantic-layer.cloud.getdbt.com`
   - **Environment ID**: From dbt Cloud
   - **Service Token**: Generate in dbt Cloud
4. Test connection

#### 2. Query in Hex Notebooks

**SQL cell:**

```sql
-- Use dbt_semantic_layer connection
SELECT *
FROM {{ metrics('total_revenue', 'order_count') }}
GROUP BY {{ dimension('customer__customer_segment') }}
ORDER BY total_revenue DESC
LIMIT 10
```

**Python cell (using dbtsl SDK):**

```python
from dbtsl import SemanticLayerClient
import pandas as pd

# Initialize client
client = SemanticLayerClient(
    environment_id=os.getenv("DBT_ENV_ID"),
    auth_token=os.getenv("DBT_CLOUD_TOKEN"),
    host="semantic-layer.cloud.getdbt.com"
)

# Query metrics
with client.session():
    table = client.query(
        metrics=["total_revenue", "order_count"],
        group_by=["customer__customer_segment", "metric_time__month"],
        where=["{{ Dimension('order__order_status') }} = 'completed'"],
        order_by=["metric_time__month"]
    )

    # Convert to pandas
    df = table.to_pandas()
    print(df.head())
```

**Chart cell:**

```python
import plotly.express as px

# Use df from previous cell
fig = px.line(
    df,
    x="metric_time__month",
    y="total_revenue",
    color="customer__customer_segment",
    title="Revenue by Customer Segment Over Time"
)
fig.show()
```

### Best Practices

**✅ DO:**
- Use Python SDK for complex transformations
- Cache query results for expensive computations
- Use Hex's parameterization for dashboard filters
- Version control notebooks in Git

**❌ DON'T:**
- Re-create metric logic in Python (query from Semantic Layer)
- Query raw tables directly (bypass Semantic Layer)
- Hard-code filter values (use parameters instead)

---

## Mode Integration

### Prerequisites

- Mode account (Team or Business tier)
- dbt Cloud JDBC connection details

### Setup Steps

#### 1. Add JDBC Data Source

1. Mode workspace → Data Sources → Add Data Source
2. Select "PostgreSQL" (JDBC driver compatible)
3. Configure:
   - **Host**: `semantic-layer.cloud.getdbt.com`
   - **Port**: `443`
   - **Database**: `dbt`
   - **Username**: `token`
   - **Password**: `<dbt-cloud-service-token>`
   - **SSL**: Enabled
4. Test and save

#### 2. Query Metrics in Mode

**SQL Editor:**

```sql
SELECT
  customer__customer_segment,
  metric_time__month,
  total_revenue,
  order_count,
  total_revenue / NULLIF(order_count, 0) AS avg_order_value
FROM semantic_layer.metrics
WHERE order__order_status = 'completed'
  AND metric_time__month >= '2024-01-01'
ORDER BY metric_time__month DESC
LIMIT 100
```

**Note:** Exact SQL syntax depends on dbt Cloud JDBC implementation (consult dbt docs for current syntax).

### Best Practices

**✅ DO:**
- Create Mode datasets for commonly-used metric queries
- Use Mode's scheduler for recurring reports
- Build dashboards from Semantic Layer queries

**❌ DON'T:**
- Join Semantic Layer results with other data sources (defeats SoT)
- Cache excessively (metrics may update frequently)

---

## Power BI Integration

### Prerequisites

- Power BI Desktop or Power BI Service
- JDBC driver for PostgreSQL
- dbt Cloud service token

### Setup Steps

#### 1. Install PostgreSQL JDBC Driver

1. Download PostgreSQL JDBC driver (https://jdbc.postgresql.org/)
2. Install driver on Power BI Desktop machine
3. Restart Power BI Desktop

#### 2. Connect to Semantic Layer

1. Power BI Desktop → Get Data → More → Database → PostgreSQL
2. Enter connection details:
   - **Server**: `semantic-layer.cloud.getdbt.com:443`
   - **Database**: `dbt`
3. Authentication:
   - **Username**: `token`
   - **Password**: `<dbt-cloud-service-token>`
4. Select tables (metrics, dimensions)

#### 3. Build Visuals

**In Power BI:**
- Metrics appear as measures
- Dimensions appear as attributes
- Drag metrics/dimensions to visuals as usual

**Example:**
1. Add Table visual
2. Drag `customer__customer_segment` to Rows
3. Drag `total_revenue` to Values
4. Result: Revenue by customer segment

### Limitations

- JDBC interface may have higher latency than native integrations
- Some Power BI features (DirectQuery, incremental refresh) may not work
- Consult dbt docs for current Power BI support status

---

## Sigma Integration

### Prerequisites

- Sigma account (Team or Enterprise tier)
- dbt Cloud Semantic Layer enabled

### Setup Steps

#### 1. Add dbt Connection

1. Sigma → Connections → Add Connection
2. Select "dbt Semantic Layer"
3. Configure:
   - **Environment ID**: From dbt Cloud
   - **Service Token**: Generate in dbt Cloud
   - **Host**: `semantic-layer.cloud.getdbt.com`
4. Test connection

#### 2. Build Workbooks

**Spreadsheet interface:**
1. New Workbook → Select dbt connection
2. Metrics appear as columns
3. Drag dimensions to rows/columns (like pivot table)
4. Apply filters, sorts, formatting

**Formula bar:**
```
=METRIC("total_revenue",
        GROUP_BY("customer__segment", "metric_time__month"),
        WHERE("order__status = 'completed'"))
```

### Best Practices

**✅ DO:**
- Use Sigma's input controls for interactive dashboards
- Leverage Sigma's write-back features (if metric thresholds need updates)
- Create templates for common metric views

---

## Comparison Matrix

| Feature | Tableau | Sheets | Hex | Mode | Power BI | Sigma |
|---------|---------|--------|-----|------|----------|-------|
| **Ease of Setup** | Easy | Easiest | Easy | Medium | Medium | Easy |
| **Real-time Refresh** | Yes | Manual | Yes | Yes | Yes | Yes |
| **Max Dataset Size** | Large | Small | Large | Large | Large | Large |
| **Advanced Visuals** | ✅ | ❌ | ✅ | ✅ | ✅ | ✅ |
| **Python/R Support** | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ |
| **Collaboration** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Cost** | $$$ | $ | $$$ | $$$ | $$ | $$$ |

---

## Common Integration Patterns

### Pattern 1: Executive Dashboard (Tableau)

**Use case:** Monthly KPIs for C-suite

**Setup:**
1. Connect Tableau to Semantic Layer
2. Create dashboard with 5-7 key metrics:
   - Total Revenue (current month)
   - MoM Growth %
   - Active Customers
   - Average Order Value
   - Conversion Rate
3. Add filters: Date range, customer segment
4. Publish to Tableau Server/Cloud
5. Schedule daily refresh

**Benefits:**
- ✅ Single source of truth (no metric discrepancies)
- ✅ Self-service filtering (executives explore without SQL)
- ✅ Consistent definitions across all dashboards

---

### Pattern 2: Ad Hoc Analysis (Sheets)

**Use case:** Quick metric checks by ops team

**Setup:**
1. Install Sheets add-on
2. Create template sheet with common queries
3. Share with ops team (view-only or edit)
4. Ops team runs queries via sidebar
5. Results populate in sheet for further Excel-like analysis

**Benefits:**
- ✅ No SQL knowledge required
- ✅ Familiar spreadsheet interface
- ✅ Easy sharing (link or export to PDF)

---

### Pattern 3: Data Science Workflow (Hex)

**Use case:** Analyst building predictive model

**Setup:**
1. Hex notebook queries metrics via Python SDK
2. Join metrics with ML features (external data)
3. Train model, visualize results
4. Deploy model as Hex app

**Benefits:**
- ✅ Programmatic metric access (not just drag-and-drop)
- ✅ Version-controlled notebooks
- ✅ Integration with scikit-learn, TensorFlow, etc.

---

## Troubleshooting

### Issue: "Connection Timeout"

**Causes:**
- Incorrect host URL
- Firewall blocking HTTPS (port 443)
- Invalid service token

**Fixes:**
1. Verify host: `semantic-layer.cloud.getdbt.com`
2. Check firewall rules (whitelist dbt Cloud IPs)
3. Regenerate service token

---

### Issue: "Metric Not Found"

**Causes:**
- Metric not deployed to environment
- Typo in metric name
- Service token doesn't have access to environment

**Fixes:**
1. Run `dbt parse` and deploy to environment
2. Verify metric name (case-sensitive)
3. Check token permissions in dbt Cloud

---

### Issue: "Slow Query Performance"

**Causes:**
- Querying fine grain (hourly instead of daily)
- Too many dimensions in single query
- Warehouse compute resource constraints

**Fixes:**
1. Use coarser grain (metric_time__day instead of metric_time__hour)
2. Limit dimensions (5-7 max per query)
3. Scale up warehouse (Snowflake, BigQuery, etc.)
4. Create saved queries with optimized parameters

---

## Best Practices Across All Tools

### 1. Use Saved Queries for Common Patterns

**Define in dbt:**
```yaml
saved_queries:
  - name: executive_dashboard_kpis
    description: Monthly KPIs for executive dashboard
    query_params:
      metrics:
        - total_revenue
        - active_customers
        - conversion_rate
      group_by:
        - metric_time__month
      where:
        - "{{ TimeDimension('metric_time', 'day') }} >= '2024-01-01'"
```

**Use in BI tools:**
- Tableau: Create data source from saved query
- Sheets: Reference saved query by name
- Hex: Query saved query via SDK

**Benefits:**
- ✅ Consistent metric combinations across tools
- ✅ Pre-optimized queries (faster performance)
- ✅ Easier to update (change saved query, all dashboards update)

---

### 2. Implement Row-Level Security

**dbt Cloud setup:**
1. Define user groups (e.g., `sales_team`, `exec_team`)
2. Map groups to dimension values:
   - `sales_team` → `customer__region IN ('North America')`
   - `exec_team` → No restrictions
3. Assign service tokens to groups

**Result:** BI tool queries automatically filtered by user's permissions

---

### 3. Monitor Query Performance

**Track metrics:**
- Query execution time (target: < 5s for dashboards)
- Query frequency (identify hot queries for optimization)
- Error rate (connection failures, timeouts)

**Tools:**
- dbt Cloud analytics (query logs)
- BI tool performance dashboards (Tableau Server, Mode)

---

## Next Steps

- **Optimize queries** → [Redshift Optimization Guide](../../kb-dbt-redshift-optimization/SKILL.md)
- **Govern metrics** → [Enterprise Patterns Guide](guide_enterprise_patterns.md)
- **Migrate from legacy** → [Iterative Migration Guide](guide_iterative_migration.md)

---

## References

- [Tableau Integration Docs](https://docs.getdbt.com/docs/use-dbt-semantic-layer/tableau)
- [Google Sheets Add-On](https://workspace.google.com/marketplace/)
- [Hex Integration Guide](https://learn.hex.tech/docs/connect-to-data/dbt-semantic-layer)
- [dbt Cloud JDBC Docs](https://docs.getdbt.com/docs/dbt-cloud-apis/sl-jdbc)
