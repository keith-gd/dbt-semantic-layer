# Iterative Migration to Semantic Layer

## Overview

Migrating to the Semantic Layer doesn't require a "big bang" rewrite. Use an **iterative, piece-by-piece approach** to gradually adopt MetricFlow while maintaining existing workflows.

**Source:** dbt Blog - "Building a Semantic Layer in Pieces" (2024)

---

## 4-Step Iterative Migration Process

### Step 1: Identify "Frozen Rollups" to Melt

**What are frozen rollups?**
Pre-aggregated tables created for performance, often materialized as tables/incremental models.

**Example:**
```sql
-- models/marts/fct_daily_revenue.sql (frozen rollup)
{{ config(materialized='table') }}

SELECT
  DATE_TRUNC('day', order_date) AS order_day,
  customer_segment,
  SUM(order_total) AS total_revenue,
  COUNT(DISTINCT order_id) AS order_count,
  SUM(order_total) / COUNT(DISTINCT order_id) AS avg_order_value
FROM {{ ref('stg_orders') }}
WHERE order_status = 'completed'
GROUP BY 1, 2
```

**Why "melt" them?**
- Frozen rollups lock you into specific granularities (day, week, etc.)
- Adding new dimensions requires rebuilding the entire table
- Semantic Layer can dynamically aggregate at query time

**Decision criteria:**
| Keep Frozen Rollup | Melt to Semantic Layer |
|--------------------|------------------------|
| Ultra-high query volume (1000s/min) | Moderate query volume |
| Performance critical (< 1s SLA) | Flexibility more important than speed |
| Dimensions rarely change | Dimensions evolve frequently |
| Simple aggregations only | Complex metrics (ratios, conversions) |

---

### Step 2: Start with Normalized Fact Tables

**Create semantic model from base fact table:**

```yaml
# models/semantic_models/orders.yml
semantic_models:
  - name: orders
    description: Order transaction facts (replaces fct_daily_revenue frozen rollup)
    model: ref('stg_orders')  # Point to normalized source, not rollup

    defaults:
      agg_time_dimension: order_date

    entities:
      - name: order
        type: primary
        expr: order_id

      - name: customer
        type: foreign
        expr: customer_id

    dimensions:
      - name: order_date
        type: time
        type_params:
          time_granularity: day

      - name: customer_segment
        type: categorical

      - name: order_status
        type: categorical

    measures:
      - name: revenue
        description: Sum of order totals
        agg: sum
        expr: order_total

      - name: order_count
        description: Count of orders
        agg: count_distinct
        expr: order_id
```

**Key principle:** Use normalized tables (stg_orders), not pre-aggregated rollups (fct_daily_revenue).

---

### Step 3: Define Metrics Incrementally

**Start with simple metrics:**

```yaml
# models/metrics/revenue_metrics.yml
metrics:
  - name: total_revenue
    description: Sum of all completed order revenue
    type: simple
    label: Total Revenue
    type_params:
      measure: revenue
    filter: |
      {{ Dimension('order__order_status') }} = 'completed'

  - name: total_orders
    description: Count of completed orders
    type: simple
    label: Total Orders
    type_params:
      measure: order_count
    filter: |
      {{ Dimension('order__order_status') }} = 'completed'
```

**Then add ratio metrics:**

```yaml
metrics:
  - name: average_order_value
    description: Revenue per order
    type: ratio
    label: Average Order Value
    type_params:
      numerator: total_revenue
      denominator: total_orders
```

**Incremental adoption:**
1. Week 1: Simple metrics only (revenue, order count)
2. Week 2: Add ratio metrics (AOV, conversion rate)
3. Week 3: Add cumulative metrics (running totals)
4. Week 4: Add derived metrics (complex calculations)

---

### Step 4: Run Parallel Queries During Transition

**Validate Semantic Layer metrics match legacy rollups:**

```sql
-- validation/compare_semantic_layer_to_legacy.sql
WITH semantic_layer_results AS (
  -- Query from Semantic Layer (via saved query or dbt-sl export)
  SELECT
    order_day,
    customer_segment,
    total_revenue,
    order_count,
    average_order_value
  FROM {{ ref('saved_query_daily_revenue') }}  -- Exported from Semantic Layer
),

legacy_rollup_results AS (
  -- Query from existing frozen rollup
  SELECT
    order_day,
    customer_segment,
    total_revenue,
    order_count,
    avg_order_value
  FROM {{ ref('fct_daily_revenue') }}
),

comparison AS (
  SELECT
    COALESCE(sl.order_day, lr.order_day) AS order_day,
    COALESCE(sl.customer_segment, lr.customer_segment) AS customer_segment,
    sl.total_revenue AS sl_revenue,
    lr.total_revenue AS legacy_revenue,
    ABS(sl.total_revenue - lr.total_revenue) AS revenue_diff,
    sl.order_count AS sl_orders,
    lr.order_count AS legacy_orders,
    ABS(sl.order_count - lr.order_count) AS order_diff
  FROM semantic_layer_results sl
  FULL OUTER JOIN legacy_rollup_results lr
    ON sl.order_day = lr.order_day
    AND sl.customer_segment = lr.customer_segment
)

SELECT *
FROM comparison
WHERE revenue_diff > 0.01  -- Flag any discrepancies > $0.01
ORDER BY revenue_diff DESC
```

**Parallel operation timeline:**
- **Week 1-2:** Semantic Layer in dev only, validate against legacy
- **Week 3-4:** Run both in prod, compare results
- **Week 5+:** Gradually switch dashboards to Semantic Layer
- **After 100% migration:** Deprecate legacy rollups

---

## Migration Patterns by Use Case

### Pattern 1: Daily Aggregation Rollup → Semantic Layer

**Before (Frozen Rollup):**
```sql
-- models/marts/daily_kpis.sql
SELECT
  DATE_TRUNC('day', event_date) AS event_day,
  SUM(revenue) AS daily_revenue,
  COUNT(DISTINCT user_id) AS daily_active_users,
  COUNT(*) AS daily_events
FROM {{ ref('fct_events') }}
GROUP BY 1
```

**After (Semantic Layer):**
```yaml
semantic_models:
  - name: events
    model: ref('fct_events')
    measures:
      - name: revenue
        agg: sum
      - name: active_users
        agg: count_distinct
        expr: user_id
      - name: event_count
        agg: count

metrics:
  - name: daily_revenue
    type: simple
    type_params:
      measure: revenue

saved_queries:
  - name: daily_kpis
    query_params:
      metrics:
        - daily_revenue
        - daily_active_users
        - daily_events
      group_by:
        - metric_time__day
```

**Benefits:**
- ✅ Can now query by week/month/quarter without rebuilding
- ✅ Can add dimensions (user_segment, event_type) without schema changes
- ✅ Can filter dynamically at query time

---

### Pattern 2: Multi-Grain Rollups → Single Semantic Model

**Before (Multiple Frozen Rollups):**
```sql
-- models/marts/revenue_daily.sql
SELECT DATE_TRUNC('day', ...) AS day, ...

-- models/marts/revenue_weekly.sql
SELECT DATE_TRUNC('week', ...) AS week, ...

-- models/marts/revenue_monthly.sql
SELECT DATE_TRUNC('month', ...) AS month, ...
```

**After (One Semantic Model):**
```yaml
semantic_models:
  - name: orders
    # Single source, multiple granularities at query time

# Query as needed:
# mf query --metrics total_revenue --group-by metric_time__day
# mf query --metrics total_revenue --group-by metric_time__week
# mf query --metrics total_revenue --group-by metric_time__month
```

**Benefits:**
- ✅ Eliminate 3 materialized tables (reduced storage/compute)
- ✅ Single source of truth (no sync issues between rollups)
- ✅ Add new granularities instantly (no dbt build required)

---

### Pattern 3: Denormalized Mart → Normalized Semantic Models

**Before (Wide Denormalized Table):**
```sql
-- models/marts/wide_revenue_mart.sql
SELECT
  o.order_id,
  o.order_date,
  o.order_total,
  c.customer_name,
  c.customer_segment,
  c.customer_region,
  p.product_name,
  p.product_category
FROM {{ ref('fct_orders') }} o
LEFT JOIN {{ ref('dim_customers') }} c ON o.customer_id = c.customer_id
LEFT JOIN {{ ref('dim_products') }} p ON o.product_id = p.product_id
```

**After (Normalized Semantic Models):**
```yaml
# Semantic model for orders (fact)
semantic_models:
  - name: orders
    model: ref('fct_orders')
    entities:
      - name: order
        type: primary
      - name: customer
        type: foreign
      - name: product
        type: foreign
    measures:
      - name: revenue
        agg: sum
        expr: order_total

# Semantic model for customers (dimension)
semantic_models:
  - name: customers
    model: ref('dim_customers')
    entities:
      - name: customer
        type: primary
    dimensions:
      - name: customer_segment
        type: categorical
      - name: customer_region
        type: categorical

# Semantic model for products (dimension)
semantic_models:
  - name: products
    model: ref('dim_products')
    entities:
      - name: product
        type: primary
    dimensions:
      - name: product_category
        type: categorical
```

**Query joins automatically:**
```bash
# MetricFlow handles joins via entities
mf query --metrics total_revenue \
  --group-by customer__customer_segment,product__product_category
```

**Benefits:**
- ✅ No more wide denormalized tables (reduced redundancy)
- ✅ Joins happen at query time (more flexible)
- ✅ Add new dimensions without rebuilding entire mart

---

## Migration Checklist

### Pre-Migration Assessment

- [ ] Identify all frozen rollups (materialized tables with GROUP BY)
- [ ] Document current query patterns (which dimensions/granularities used?)
- [ ] Measure current query performance (establish baseline SLAs)
- [ ] Identify stakeholders consuming rollups (dashboards, reports, APIs)

### Migration Execution

- [ ] Create semantic models from normalized fact tables
- [ ] Define simple metrics first (direct measure aggregations)
- [ ] Validate metrics match legacy rollups (run parallel comparison queries)
- [ ] Create saved queries for common dashboard patterns
- [ ] Update BI tool connections to Semantic Layer
- [ ] Run parallel operations (legacy + Semantic Layer) for 2-4 weeks
- [ ] Monitor query performance (compare to baseline SLAs)
- [ ] Migrate dashboards/reports incrementally (10% per week)

### Post-Migration Cleanup

- [ ] Deprecate legacy rollups after 100% migration
- [ ] Remove frozen rollup dbt models
- [ ] Update documentation to reference Semantic Layer
- [ ] Train team on MetricFlow CLI and query syntax

---

## Common Migration Challenges

### Challenge 1: Performance Regression

**Symptom:** Semantic Layer queries slower than frozen rollups

**Causes:**
- Querying at finer grain than original rollup (day vs. hour)
- Joining too many entities in single query
- Missing warehouse optimizations (DISTKEY, SORTKEY in Redshift)

**Solutions:**
1. Create saved queries with pre-defined granularity (limits flexibility but improves speed)
2. Add warehouse-specific optimizations to base models (see [Redshift Optimization Guide](../../kb-dbt-redshift-optimization/SKILL.md))
3. Consider hybrid approach: Keep ultra-high-volume rollups, use Semantic Layer for exploratory queries

---

### Challenge 2: Metric Discrepancies

**Symptom:** Semantic Layer metrics don't match legacy rollups

**Causes:**
- Different filter logic (legacy had implicit WHERE clause)
- Different aggregation (legacy used COUNT vs. COUNT_DISTINCT)
- Timezone handling differences

**Solutions:**
1. Use validation queries (see Step 4 above)
2. Add explicit filters to metrics to match legacy logic
3. Document and communicate intentional changes (e.g., fixing COUNT to COUNT_DISTINCT)

**Example fix:**
```yaml
# Legacy query implicitly filtered to completed orders
# Semantic Layer metric must make this explicit
metrics:
  - name: total_revenue
    type: simple
    type_params:
      measure: revenue
    filter: |
      {{ Dimension('order__order_status') }} = 'completed'
```

---

### Challenge 3: Stakeholder Resistance

**Symptom:** Teams don't want to change from familiar frozen rollups

**Solutions:**
1. **Show, don't tell:** Build side-by-side dashboards (legacy vs. Semantic Layer)
2. **Start with power users:** Migrate analytics team first, then broader org
3. **Highlight new capabilities:** Show how to slice by new dimensions instantly
4. **Provide migration support:** Office hours, documentation, training sessions

**Communication template:**
> "We're migrating from `fct_daily_revenue` to the Semantic Layer. Your existing queries will continue working for the next 2 months while we validate results. The new system lets you slice by any dimension (not just the 3 pre-defined ones) and query at any time grain (day/week/month) without waiting for new tables to build."

---

## Success Metrics for Migration

**Track these KPIs during migration:**

| Metric | Target | How to Measure |
|--------|--------|----------------|
| **Metric parity** | > 99.9% match with legacy | Validation queries (see Step 4) |
| **Query performance** | Within 20% of legacy SLA | Monitor query execution time |
| **Dashboard migration %** | 100% within 8 weeks | Track # dashboards using Semantic Layer |
| **Developer satisfaction** | > 80% positive feedback | Survey analytics team post-migration |
| **Storage reduction** | > 50% decrease in rollup tables | Measure before/after warehouse storage |

---

## Advanced Migration Patterns

### Hybrid Approach: Keep Critical Rollups

**When to use:**
- Ultra-high query volume (1000s queries/min)
- Sub-second SLA requirements
- Dashboard loads must be instant

**Pattern:**
```yaml
# Keep frozen rollup for dashboard
# models/marts/daily_revenue_rollup.sql (materialized='table')

# Also define in Semantic Layer for ad hoc queries
semantic_models:
  - name: orders
    # Used for exploratory analysis, not dashboard
```

**Decision tree:**
- **Dashboard with 10k views/day** → Keep frozen rollup
- **Ad hoc analysis by analysts** → Use Semantic Layer
- **Executive report (weekly)** → Semantic Layer is fine

---

### Incremental Metric Adoption

**Don't migrate all metrics at once:**

**Phase 1:** Core revenue metrics (total revenue, order count)
**Phase 2:** Customer metrics (active users, retention)
**Phase 3:** Product metrics (units sold, inventory)
**Phase 4:** Advanced metrics (conversion funnels, cohort analysis)

**Benefit:** Learn and iterate without disrupting entire org

---

## Migration Timeline Example

**8-Week Migration Plan:**

| Week | Activities | Deliverables |
|------|-----------|--------------|
| 1 | Assessment + planning | List of frozen rollups, stakeholder map |
| 2 | Create semantic models | 3-5 core semantic models in dev |
| 3 | Define simple metrics | 10-15 simple metrics, validation queries |
| 4 | Parallel operation | Semantic Layer in prod, compare to legacy |
| 5 | Migrate 10% dashboards | 2-3 dashboards using Semantic Layer |
| 6 | Migrate 50% dashboards | 10+ dashboards migrated, training sessions |
| 7 | Migrate 90% dashboards | Most dashboards migrated, deprecate rollups |
| 8 | Cleanup + retrospective | Remove legacy rollups, document learnings |

---

## Next Steps

After completing iterative migration:

1. **Optimize performance** → See [Redshift Optimization Guide](../../kb-dbt-redshift-optimization/SKILL.md)
2. **Integrate with BI tools** → See [BI Tool Integrations Guide](guide_bi_tool_integrations.md)
3. **Establish governance** → See [Enterprise Patterns Guide](guide_enterprise_patterns.md)

---

## References

- [dbt Blog: Building a Semantic Layer in Pieces](https://www.getdbt.com/blog/building-semantic-layer-in-pieces)
- [MetricFlow Migration Docs](https://docs.getdbt.com/docs/build/metricflow-migration)
- [Validation Workflow](guide_validation_workflow.md)
