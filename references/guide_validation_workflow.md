# Validation Workflow - 3-Layer Approach

## Overview

MetricFlow uses a **3-layer validation architecture** to catch errors at different stages:

1. **Parse-time Validation** - YAML syntax and dbt compilation
2. **Semantic Syntax Validation** - MetricFlow semantic graph construction
3. **Data Platform Validation** - SQL execution against warehouse

Each layer catches different error types. Understanding this progression helps debug faster.

---

## Layer 1: Parse-Time Validation

**Trigger:** `dbt parse` or `dbt build`

**What It Checks:**
- YAML syntax correctness
- Schema validity (properties match spec)
- File references (model exists, columns exist)
- Jinja compilation

**Common Errors:**

```yaml
# ❌ WRONG - Invalid YAML indentation
metrics:
- name: total_revenue
type: simple
  measure: revenue

# ✅ CORRECT
metrics:
  - name: total_revenue
    type: simple
    measure: revenue
```

```yaml
# ❌ WRONG - References non-existent measure
metrics:
  - name: total_revenue
    type: simple
    measure: revenue_amt  # But measure is called "revenue"

# ✅ CORRECT
metrics:
  - name: total_revenue
    type: simple
    measure: revenue
```

**How to Fix:**
- Run `dbt parse` to isolate parse errors
- Check indentation (YAML is whitespace-sensitive)
- Verify measure/dimension names match exactly
- Use `dbt run-operation compile` to test Jinja

**Exit Early:** If parse fails, fix YAML before moving to Layer 2

---

## Layer 2: Semantic Syntax Validation

**Trigger:** `mf validate-configs`

**What It Checks:**
- Semantic graph construction
- Entity linkages (primary/foreign keys valid)
- Metric definitions (measures exist, ratio metrics reference metrics not measures)
- Time spine configuration
- Dimension/measure uniqueness

**Common Errors:**

### Error: Ratio Metric References Measure Instead of Metric

```yaml
# ❌ WRONG - Ratio metrics must reference METRICS, not MEASURES
metrics:
  - name: conversion_rate
    type: ratio
    type_params:
      numerator: conversions        # measure, not metric
      denominator: impressions      # measure, not metric

# ✅ CORRECT
metrics:
  - name: total_conversions
    type: simple
    measure: conversions

  - name: total_impressions
    type: simple
    measure: impressions

  - name: conversion_rate
    type: ratio
    type_params:
      numerator: total_conversions   # metric wrapping conversions
      denominator: total_impressions # metric wrapping impressions
```

### Error: Missing Time Spine

```yaml
# ❌ WRONG - Using time dimension without time spine configured
semantic_models:
  - name: orders
    dimensions:
      - name: order_date
        type: time
        type_params:
          time_granularity: day

# ✅ CORRECT - Add time spine reference
semantic_models:
  - name: orders
    dimensions:
      - name: order_date
        type: time
        type_params:
          time_granularity: day
          time_spine: metricflow_time_spine
```

### Error: Invalid Entity Reference

```yaml
# ❌ WRONG - Entity doesn't exist in semantic model
metrics:
  - name: revenue_per_customer
    type: ratio
    type_params:
      numerator: total_revenue
      denominator: customer_count
    filter: customer_segment == 'enterprise'  # No customer entity defined

# ✅ CORRECT - Define entity in semantic model
semantic_models:
  - name: orders
    entities:
      - name: customer
        type: foreign
        expr: customer_id
```

**How to Fix:**
- Run `mf validate-configs` after parse succeeds
- Check error messages for entity/measure names
- Verify ratio metrics reference metrics, not measures
- Ensure time spine exists if using time dimensions

**Exit Early:** If validation fails, fix semantic issues before querying

---

## Layer 3: Data Platform Validation

**Trigger:** `mf query --metrics <metric> --group-by <dimension>`

**What It Checks:**
- SQL generation correctness
- Join logic validity
- Data types compatible
- Warehouse execution (syntax, permissions, data availability)

**Common Errors:**

### Error: Ambiguous Column Reference

```sql
-- ❌ Generated SQL fails due to ambiguous join
SELECT
  orders.order_date,
  revenue  -- Which table's revenue column?
FROM orders
JOIN order_items USING (order_id)
```

**Fix:** Use `expr` parameter in dimension/measure to fully qualify:

```yaml
semantic_models:
  - name: orders
    measures:
      - name: revenue
        agg: sum
        expr: orders.revenue_amount  # Fully qualified
```

### Error: Template Wrapper Not Escaped

```bash
# ❌ WRONG - Zsh interprets {{ }} as glob pattern
mf query --metrics revenue --where created_at >= {{TimeDimension('order__order_date', 'day')}}

# Zsh error: "zsh: no matches found"

# ✅ CORRECT - Escape with quotes
mf query --metrics revenue --where "created_at >= {{TimeDimension('order__order_date', 'day')}}"
```

### Error: Invalid Time Granularity

```bash
# ❌ WRONG - Requesting unsupported granularity
mf query --metrics revenue --group-by metric_time__hour

# Error: "time_granularity 'hour' not supported for metric_time dimension"

# ✅ CORRECT - Check supported granularities first
mf list dimensions --metrics revenue
# Shows: metric_time (day, week, month, quarter, year)
```

**How to Fix:**
- Run query in verbose mode: `mf query --explain`
- Check generated SQL for joins/aggregations
- Use `--compile` flag to see SQL without execution
- Verify shell escaping for template wrappers

---

## CI/CD Integration Patterns

### Development Workflow (Local)

```bash
#!/bin/bash
# dev_validate.sh - Run before committing

echo "Layer 1: Parse validation..."
dbt parse --profiles-dir ~/.dbt
if [ $? -ne 0 ]; then
  echo "❌ Parse failed. Fix YAML syntax."
  exit 1
fi

echo "Layer 2: Semantic validation..."
mf validate-configs
if [ $? -ne 0 ]; then
  echo "❌ Semantic validation failed. Fix metric definitions."
  exit 1
fi

echo "Layer 3: Query validation (smoke test)..."
mf query --metrics total_revenue --group-by metric_time__day --limit 1
if [ $? -ne 0 ]; then
  echo "❌ Query execution failed. Check SQL generation."
  exit 1
fi

echo "✅ All validations passed!"
```

### CI Pipeline (GitHub Actions)

```yaml
name: Semantic Layer Validation

on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dbt + MetricFlow
        run: |
          pip install dbt-core dbt-snowflake
          pip install "dbt-metricflow[snowflake]"

      - name: Layer 1 - Parse
        run: dbt parse --profiles-dir ./ci_profiles

      - name: Layer 2 - Semantic Validation
        run: mf validate-configs

      - name: Layer 3 - Query Smoke Test
        run: |
          # Test 5 most critical metrics
          mf query --metrics total_revenue --limit 1
          mf query --metrics active_customers --limit 1
          mf query --metrics conversion_rate --limit 1
          # Add more critical metrics...

      - name: Upload Logs
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: validation-logs
          path: logs/
```

### Production Deployment

```bash
#!/bin/bash
# prod_deploy.sh - Run before deploying to production

# 1. Parse validation
dbt parse --target prod || exit 1

# 2. Semantic validation
mf validate-configs --target prod || exit 1

# 3. Query validation (extended test suite)
for metric in $(mf list metrics --output json | jq -r '.[].name'); do
  echo "Testing metric: $metric"
  mf query --metrics "$metric" --group-by metric_time__day --limit 1 --target prod
  if [ $? -ne 0 ]; then
    echo "❌ Metric $metric failed validation"
    exit 1
  fi
done

echo "✅ Production deployment validated!"
```

---

## Validation Best Practices

### 1. Run Validations in Order

```bash
# ✅ CORRECT - Sequential validation
dbt parse && mf validate-configs && mf query --metrics <test>

# ❌ WRONG - Skipping layers wastes time
mf query --metrics revenue  # Will fail at parse if YAML broken
```

### 2. Use Compiled Output for Debugging

```bash
# Generate SQL without executing
mf query --metrics revenue --compile

# Check target/compiled/ for generated SQL
cat target/compiled/metrics/revenue.sql
```

### 3. Test Metric Changes with Saved Queries

```yaml
# Define saved query for regression testing
saved_queries:
  - name: revenue_daily_test
    description: Regression test for revenue metric changes
    query_params:
      metrics:
        - total_revenue
      group_by:
        - metric_time__day
      where:
        - "{{ TimeDimension('metric_time', 'day') }} >= '2024-01-01'"
```

```bash
# Run regression test
mf query --saved-query revenue_daily_test
```

### 4. Validate Entity Joins

```bash
# List all entities and their relationships
mf list entities --show-joins

# Test join by querying cross-entity metric
mf query --metrics order_count --group-by customer__customer_segment
```

### 5. Check Time Spine Coverage

```bash
# Verify time spine has sufficient date range
mf query --metrics total_revenue --group-by metric_time__day \
  --where "{{ TimeDimension('metric_time', 'day') }} >= '2020-01-01'" \
  --limit 1
```

---

## Common Validation Scenarios

### Scenario 1: New Metric Added

```bash
# 1. Parse validation
dbt parse

# 2. Semantic validation
mf validate-configs

# 3. Smoke test new metric
mf query --metrics new_metric_name --limit 1

# 4. Test with dimensions
mf query --metrics new_metric_name --group-by metric_time__day --limit 10
```

### Scenario 2: Refactored Semantic Model

```bash
# 1. Check for breaking changes
mf list metrics --show-semantic-model

# 2. Validate all metrics still resolve
for metric in $(mf list metrics --output json | jq -r '.[].name'); do
  mf query --metrics "$metric" --limit 1 || echo "❌ $metric broken"
done

# 3. Verify entity joins still work
mf list entities --show-joins
```

### Scenario 3: Updated Ratio Metric

```bash
# 1. Validate numerator and denominator exist
mf list metrics | grep numerator_metric_name
mf list metrics | grep denominator_metric_name

# 2. Test ratio calculation
mf query --metrics ratio_metric_name --limit 1

# 3. Compare with legacy calculation (if migrating)
mf query --metrics ratio_metric_name,legacy_ratio_metric --limit 10
```

---

## Troubleshooting Guide

### Error: "Measure not found"

**Symptom:**
```
Error: Measure 'revenue_amt' not found in semantic model 'orders'
```

**Fix:**
1. Run `mf list measures --semantic-models orders`
2. Check exact measure name (case-sensitive)
3. Verify measure exists in semantic_models/*.yml

---

### Error: "Ambiguous time dimension"

**Symptom:**
```
Error: Multiple time dimensions found. Specify using TimeDimension()
```

**Fix:**
1. Run `mf list dimensions --metrics <metric>`
2. Use qualified syntax: `order__order_date` instead of `order_date`

---

### Error: "Invalid filter expression"

**Symptom:**
```
Error: Filter expression 'customer_segment == "enterprise"' failed to parse
```

**Fix:**
1. Check if dimension exists: `mf list dimensions --metrics <metric>`
2. Use entity qualification: `customer__customer_segment`
3. Escape quotes: `customer__customer_segment == 'enterprise'`

---

### Error: "Time spine not configured"

**Symptom:**
```
Error: No time spine configured for time dimension 'order_date'
```

**Fix:**
1. Create time spine model:
```sql
-- models/metricflow_time_spine.sql
{{ config(materialized='table') }}
{{ dbt_utils.date_spine(
    datepart="day",
    start_date="cast('2020-01-01' as date)",
    end_date="cast('2030-12-31' as date)"
)}}
```

2. Reference in semantic model:
```yaml
dimensions:
  - name: order_date
    type: time
    type_params:
      time_granularity: day
      time_spine: metricflow_time_spine
```

---

## References

- [MetricFlow Validation Docs](https://docs.getdbt.com/docs/build/validation)
- [CI/CD Patterns](https://docs.getdbt.com/docs/deploy/ci-jobs)
- [Troubleshooting Guide](../troubleshooting.md)
