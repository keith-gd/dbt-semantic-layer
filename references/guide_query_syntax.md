# Query Syntax Guide - Template Wrappers & Entity Qualification

## Overview

MetricFlow CLI uses special syntax for querying metrics with filters and dimensions:

1. **Template Wrappers** - `{{ Dimension() }}` and `{{ TimeDimension() }}` for where clauses
2. **Entity Qualification** - `entity__dimension_name` for disambiguating columns
3. **Time Granularity** - `metric_time__day`, `metric_time__week`, etc.

This guide covers correct syntax patterns with examples.

---

## Template Wrapper Syntax

### When to Use Template Wrappers

**Required in:**
- `--where` filters referencing dimensions
- Saved query `where:` blocks

**Not required in:**
- `--group-by` arguments (use plain dimension names)
- `--order-by` arguments

---

### Dimension() Wrapper

**Purpose:** Reference categorical or non-time dimensions in filters

**Syntax:**
```bash
{{ Dimension('entity__dimension_name') }}
```

**Examples:**

```bash
# Filter by customer segment
mf query --metrics total_revenue \
  --where "{{ Dimension('customer__customer_segment') }} == 'enterprise'"

# Filter by order status
mf query --metrics order_count \
  --where "{{ Dimension('order__order_status') }} IN ('completed', 'shipped')"

# Multiple dimension filters
mf query --metrics total_revenue \
  --where "{{ Dimension('customer__segment') }} == 'enterprise' AND {{ Dimension('order__status') }} == 'completed'"
```

**Common Mistakes:**

```bash
# ❌ WRONG - Missing quotes around entire where clause
mf query --metrics revenue --where {{ Dimension('customer__segment') }} == 'enterprise'
# Error: zsh: no matches found

# ❌ WRONG - Unqualified dimension name
mf query --metrics revenue --where "{{ Dimension('customer_segment') }}"
# Error: Dimension 'customer_segment' not found (should be 'customer__customer_segment')

# ✅ CORRECT
mf query --metrics revenue --where "{{ Dimension('customer__customer_segment') }} == 'enterprise'"
```

---

### TimeDimension() Wrapper

**Purpose:** Reference time dimensions in filters with granularity specification

**Syntax:**
```bash
{{ TimeDimension('entity__dimension_name', 'granularity') }}
```

**Supported Granularities:**
- `day`
- `week`
- `month`
- `quarter`
- `year`

**Examples:**

```bash
# Filter by date range (day granularity)
mf query --metrics total_revenue \
  --where "{{ TimeDimension('order__order_date', 'day') }} >= '2024-01-01'"

# Filter last 30 days
mf query --metrics order_count \
  --where "{{ TimeDimension('metric_time', 'day') }} >= current_date - interval '30 days'"

# Filter by month
mf query --metrics total_revenue \
  --where "{{ TimeDimension('order__order_date', 'month') }} == '2024-11'"

# Combine date range with dimension filter
mf query --metrics total_revenue \
  --where "{{ TimeDimension('order__order_date', 'day') }} >= '2024-01-01' AND {{ Dimension('customer__segment') }} == 'enterprise'"
```

**Common Mistakes:**

```bash
# ❌ WRONG - Missing granularity parameter
mf query --metrics revenue --where "{{ TimeDimension('order__order_date') }} >= '2024-01-01'"
# Error: TimeDimension requires granularity

# ❌ WRONG - Invalid granularity
mf query --metrics revenue --where "{{ TimeDimension('order__order_date', 'hour') }}"
# Error: time_granularity 'hour' not supported

# ❌ WRONG - Using Dimension() instead of TimeDimension()
mf query --metrics revenue --where "{{ Dimension('order__order_date') }} >= '2024-01-01'"
# May fail or produce incorrect results

# ✅ CORRECT
mf query --metrics revenue --where "{{ TimeDimension('order__order_date', 'day') }} >= '2024-01-01'"
```

---

## Entity Qualification Syntax

### Why Entity Qualification?

When multiple semantic models have dimensions with the same name, MetricFlow requires **entity qualification** to disambiguate:

```
Syntax: entity__dimension_name
```

**Example scenario:**

- `orders` semantic model has `customer_id` entity → dimension `customer_segment`
- `customers` semantic model has `customer` entity → dimension `customer_segment`

Without qualification, `customer_segment` is ambiguous.

---

### Qualified Dimension Names

**Pattern:**
```bash
mf query --metrics <metric> --group-by entity__dimension_name
```

**Examples:**

```bash
# Group by customer segment (qualified)
mf query --metrics total_revenue --group-by customer__customer_segment

# Group by order status (qualified)
mf query --metrics order_count --group-by order__order_status

# Group by product category from product entity
mf query --metrics units_sold --group-by product__product_category
```

**When qualification is optional:**

If dimension name is unique across all semantic models, qualification is optional:

```bash
# If only one 'order_status' dimension exists
mf query --metrics order_count --group-by order_status

# Equivalent to:
mf query --metrics order_count --group-by order__order_status
```

**Best practice:** Always use qualified names for clarity and future-proofing.

---

### Finding Entity Names

**List entities in project:**
```bash
mf list entities

# Output:
# order (primary in 'orders')
# customer (foreign in 'orders', primary in 'customers')
# product (foreign in 'orders', primary in 'products')
```

**List dimensions for metric:**
```bash
mf list dimensions --metrics total_revenue

# Output shows qualified names:
# order__order_date (time)
# order__order_status (categorical)
# customer__customer_segment (categorical)
# customer__customer_name (categorical)
```

**Use qualified name directly in queries:**
```bash
mf query --metrics total_revenue --group-by customer__customer_segment
```

---

## Time Granularity Syntax

### metric_time Dimension

Every metric has a **default time dimension** called `metric_time`, aliased from the semantic model's `agg_time_dimension`.

**Querying by time:**
```bash
# Group by day
mf query --metrics total_revenue --group-by metric_time__day

# Group by week
mf query --metrics total_revenue --group-by metric_time__week

# Group by month
mf query --metrics total_revenue --group-by metric_time__month

# Group by quarter
mf query --metrics total_revenue --group-by metric_time__quarter

# Group by year
mf query --metrics total_revenue --group-by metric_time__year
```

---

### Custom Time Dimensions

If semantic model has multiple time dimensions, reference them by entity-qualified name:

**Example semantic model:**
```yaml
semantic_models:
  - name: orders
    dimensions:
      - name: order_date
        type: time
        type_params:
          time_granularity: day

      - name: shipped_date
        type: time
        type_params:
          time_granularity: day
```

**Query by custom time dimension:**
```bash
# Group by order date (day granularity)
mf query --metrics order_count --group-by order__order_date__day

# Group by shipped date (week granularity)
mf query --metrics shipment_count --group-by order__shipped_date__week
```

**Pattern:**
```
entity__time_dimension__granularity
```

---

## Combining Filters and Grouping

### Example 1: Time Range + Dimension Filter + Grouping

```bash
mf query --metrics total_revenue,order_count \
  --where "{{ TimeDimension('order__order_date', 'day') }} >= '2024-01-01' AND {{ Dimension('customer__segment') }} == 'enterprise'" \
  --group-by customer__customer_region,metric_time__month \
  --order-by -metric_time__month \
  --limit 20
```

**Breakdown:**
- `--metrics`: Query 2 metrics (revenue and order count)
- `--where`: Filter orders from 2024 onwards, enterprise customers only
- `--group-by`: Slice by customer region and month
- `--order-by`: Sort descending by month (`-` prefix = descending)
- `--limit`: Return top 20 rows

---

### Example 2: Multi-Entity Query

```bash
mf query --metrics units_sold \
  --where "{{ Dimension('product__category') }} IN ('Electronics', 'Apparel')" \
  --group-by product__product_name,order__order_status \
  --order-by -units_sold
```

**Breakdown:**
- Joins `product` and `order` entities
- Filters to 2 product categories
- Groups by product name and order status
- Sorts by units sold (highest first)

---

## Saved Query Syntax

Saved queries define reusable metric combinations with predefined filters and groupings.

**Example:**

```yaml
saved_queries:
  - name: enterprise_revenue_monthly
    description: Monthly revenue from enterprise customers
    query_params:
      metrics:
        - total_revenue
        - order_count
      group_by:
        - customer__customer_region
        - metric_time__month
      where:
        - "{{ Dimension('customer__segment') }} == 'enterprise'"
        - "{{ TimeDimension('metric_time', 'day') }} >= '2024-01-01'"
```

**Execute saved query:**
```bash
mf query --saved-query enterprise_revenue_monthly

# Optionally override limit
mf query --saved-query enterprise_revenue_monthly --limit 50
```

**Limitations:**
- ❌ Cannot override `metrics`, `group_by`, or `where` in saved queries
- ✅ Can override `--limit`, `--order-by`, and `--output` format

---

## Advanced Query Patterns

### Pattern 1: Cohort Analysis

```bash
# Revenue by customer cohort (month they joined) and order month
mf query --metrics total_revenue \
  --group-by customer__signup_month,metric_time__month \
  --where "{{ TimeDimension('customer__signup_date', 'month') }} >= '2024-01'" \
  --order-by customer__signup_month,metric_time__month
```

---

### Pattern 2: Period-over-Period Comparison

```bash
# Current month vs. prior month revenue
mf query --metrics total_revenue \
  --group-by metric_time__month \
  --where "{{ TimeDimension('metric_time', 'month') }} IN ('2024-10', '2024-11')" \
  --order-by metric_time__month
```

**Tip:** Use BI tool's calculated fields or dbt macros for % change calculations.

---

### Pattern 3: Conversion Funnel Metrics

```bash
# Conversion rate by customer segment
mf query --metrics impressions,clicks,conversions,conversion_rate \
  --group-by customer__segment \
  --order-by -conversion_rate
```

---

### Pattern 4: Top-N Analysis

```bash
# Top 10 products by revenue in Q4 2024
mf query --metrics total_revenue \
  --group-by product__product_name \
  --where "{{ TimeDimension('order__order_date', 'quarter') }} == '2024-Q4'" \
  --order-by -total_revenue \
  --limit 10
```

---

## Query Output Formats

MetricFlow supports multiple output formats:

```bash
# Default table format
mf query --metrics total_revenue --group-by metric_time__month

# JSON output
mf query --metrics total_revenue --group-by metric_time__month --output json

# CSV output
mf query --metrics total_revenue --group-by metric_time__month --output csv > revenue.csv
```

---

## Troubleshooting Query Errors

### Error: "Dimension not found"

```bash
mf query --metrics revenue --group-by customer_segment
# Error: Dimension 'customer_segment' not found
```

**Fix:** Use entity-qualified name

```bash
# 1. Find correct dimension name
mf list dimensions --metrics revenue

# 2. Use qualified name
mf query --metrics revenue --group-by customer__customer_segment
```

---

### Error: "Invalid time granularity"

```bash
mf query --metrics revenue --group-by metric_time__hour
# Error: time_granularity 'hour' not supported
```

**Fix:** Check supported granularities

```bash
# List valid granularities for metric
mf list dimensions --metrics revenue | grep metric_time

# Use supported granularity (day, week, month, quarter, year)
mf query --metrics revenue --group-by metric_time__day
```

---

### Error: "No matches found" (zsh)

```bash
mf query --metrics revenue --where {{ Dimension('customer__segment') }}
# zsh: no matches found: {{ Dimension('customer__segment') }}
```

**Fix:** Quote the where clause

```bash
mf query --metrics revenue --where "{{ Dimension('customer__segment') }} == 'enterprise'"
```

Or configure shell (see [Local Development Guide](guide_local_development.md)):
```bash
# Add to ~/.zshrc
setopt BRACECCL
```

---

### Error: "Ambiguous dimension reference"

```bash
mf query --metrics revenue --group-by created_at
# Error: Multiple dimensions named 'created_at' found
```

**Fix:** Use entity qualification

```bash
mf query --metrics revenue --group-by order__created_at
```

---

## Query Best Practices

### 1. Always Quote Where Clauses

```bash
# ✅ CORRECT
mf query --metrics revenue --where "{{ Dimension('status') }} == 'active'"

# ❌ WRONG
mf query --metrics revenue --where {{ Dimension('status') }} == 'active'
```

### 2. Use Entity Qualification

```bash
# ✅ CORRECT - Explicit entity
mf query --metrics revenue --group-by customer__segment

# ⚠️  RISKY - Works if unique, but ambiguous if dimension added elsewhere
mf query --metrics revenue --group-by segment
```

### 3. Specify Time Granularity in Filters

```bash
# ✅ CORRECT
--where "{{ TimeDimension('order__order_date', 'day') }} >= '2024-01-01'"

# ❌ WRONG - Missing granularity
--where "{{ TimeDimension('order__order_date') }} >= '2024-01-01'"
```

### 4. Test Queries Incrementally

```bash
# Start simple
mf query --metrics revenue

# Add time dimension
mf query --metrics revenue --group-by metric_time__day --limit 5

# Add filters
mf query --metrics revenue --group-by metric_time__day --where "{{ Dimension('status') }} == 'active'" --limit 5

# Add more dimensions
mf query --metrics revenue --group-by metric_time__day,customer__segment --where "{{ Dimension('status') }} == 'active'" --limit 10
```

### 5. Use --explain for Debugging

```bash
# Show generated SQL and execution plan
mf query --metrics revenue --group-by metric_time__day --explain
```

---

## Quick Reference

| **Syntax** | **Usage** | **Example** |
|------------|-----------|-------------|
| `{{ Dimension('entity__dim') }}` | Categorical filter | `--where "{{ Dimension('customer__segment') }} == 'enterprise'"` |
| `{{ TimeDimension('entity__dim', 'gran') }}` | Time filter | `--where "{{ TimeDimension('order__date', 'day') }} >= '2024-01-01'"` |
| `entity__dimension` | Qualified grouping | `--group-by customer__segment` |
| `metric_time__day` | Time grouping | `--group-by metric_time__day` |
| `--order-by -metric` | Sort descending | `--order-by -total_revenue` |
| `--limit N` | Limit rows | `--limit 10` |
| `--output json` | JSON format | `--output json` |
| `--explain` | Show SQL | `--explain` |

---

## Next Steps

- [CLI Commands Complete Reference](cli_commands_complete.md)
- [Validation Workflow](guide_validation_workflow.md)
- [Local Development Setup](guide_local_development.md)
