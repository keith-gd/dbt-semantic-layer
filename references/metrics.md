# dbt Semantic Layer - Metrics Reference

Comprehensive reference for defining, configuring, and querying metrics in the dbt Semantic Layer.

---

## Metric Types

### Simple Metrics

Simple metrics point directly to a measure. They act as a pass-through with optional filtering and labeling.

**Use case**: Direct aggregation of a single measure (sum, count, average, etc.)

**Basic syntax:**
```yaml
metrics:
  - name: revenue
    description: Sum of the order total
    label: Revenue
    type: simple
    type_params:
      measure: order_total
```

**With filtering:**
```yaml
metrics:
  - name: cancellations
    description: The number of cancellations
    type: simple
    label: Cancellations
    type_params:
      measure:
        name: cancellations_usd
        fill_nulls_with: 0
        join_to_timespine: true
    filter: |
      {{ Dimension('order__value') }} > 100 and {{ Dimension('user__acquisition') }} is not null
```

**Multiple simple metrics:**
```yaml
metrics:
  - name: order_total
    description: Sum of orders value
    type: simple
    label: order_total
    type_params:
      measure:
        name: order_total

  - name: order_count
    description: Number of orders
    type: simple
    label: order_count
    type_params:
      measure:
        name: order_count

  - name: large_orders
    description: Count of orders with order total over 20
    type: simple
    label: Large Orders
    type_params:
      measure:
        name: order_count
    filter: |
      {{ Metric('order_total', group_by=['order_id']) }} >= 20
```

**Note:** If you've defined the measure with `create_metric: True`, you don't need to create a simple metric unless you want to add constraints via filters.

---

### Ratio Metrics

Ratio metrics divide a numerator metric by a denominator metric. Filters can be applied at the metric level or to individual components.

**Use case**: Calculating rates, percentages, averages (e.g., conversion rate, average order value)

**Basic syntax:**
```yaml
metrics:
  - name: avg_order_value
    label: avg_order_value
    description: Average value of each order
    type: ratio
    type_params:
      numerator: order_total
      denominator: order_count
```

**With metric-level filter:**
```yaml
metrics:
  - name: cancellation_rate
    type: ratio
    label: Cancellation rate
    type_params:
      numerator: cancellations
      denominator: transaction_amount
    filter: |
      {{ Dimension('customer__country') }} = 'MX'
```

**With component-level filters:**
```yaml
metrics:
  - name: enterprise_cancellation_rate
    type: ratio
    type_params:
      numerator:
        name: cancellations
        filter: {{ Dimension('company__tier') }} = 'enterprise'
      denominator: transaction_amount
    filter: |
      {{ Dimension('customer__country') }} = 'MX'
```

**Execution:** Both numerator and denominator filters are applied, then the final metric-level filter is applied to the result.

---

### Cumulative Metrics

Cumulative metrics aggregate a measure over a specified or infinite time window.

**Use case**: Running totals, month-to-date, rolling windows (e.g., weekly active users, cumulative revenue)

**Rolling window (finite):**
```yaml
metrics:
  - name: wau_rolling_7
    type: cumulative
    label: Weekly active users
    type_params:
      measure:
        name: active_users
        fill_nulls_with: 0
        join_to_timespine: true
      cumulative_type_params:
        window: 7 days
```

**Infinite window (all-time cumulative):**
```yaml
metrics:
  - name: current_revenue
    description: Current revenue
    label: Current Revenue
    type: cumulative
    type_params:
      measure: revenue
```

**Grain-to-date (month-to-date, year-to-date):**
```yaml
metrics:
  - name: cumulative_order_amount_mtd
    label: cumulative_order_amount_mtd
    description: The month to date value of all orders
    type: cumulative
    type_params:
      measure:
        name: order_total
      grain_to_date: month
```

**Multiple cumulative metrics:**
```yaml
measures:
  - name: revenue
    description: Total revenue
    agg: sum
    expr: revenue
  - name: subscription_count
    description: Count of active subscriptions
    agg: sum
    expr: event_type

metrics:
  - name: current_revenue
    description: Current revenue
    label: Current Revenue
    type: cumulative
    type_params:
      measure: revenue

  - name: active_subscriptions
    description: Count of active subscriptions
    label: Active Subscriptions
    type: cumulative
    type_params:
      measure: subscription_count
```

**Generated SQL example (7-day rolling window):**
```sql
select
  count(distinct distinct_users) as weekly_active_users,
  metric_time
from (
  select
    subq_2.distinct_users as distinct_users,
    subq_1.metric_time as metric_time
  from (
    select metric_time
    from transform_prod_schema.mf_time_spine subq_1356
    where metric_time >= cast('2000-01-01' as timestamp)
      and metric_time <= cast('2040-12-31' as timestamp)
  ) subq_1
  inner join (
    select
      distinct_users as distinct_users,
      date_trunc('day', ds) as metric_time
    from demo_schema.transactions transactions_src_426
    where date_trunc('day', ds) >= cast('1999-12-26' as timestamp)
      and date_trunc('day', ds) <= cast('2040-12-31' as timestamp)
  ) subq_2
  on subq_2.metric_time <= subq_1.metric_time
    and subq_2.metric_time > dateadd(day, -7, subq_1.metric_time)
) subq_3
group by metric_time
limit 100;
```

---

### Derived Metrics

Derived metrics are expressions combining other metrics using mathematical operations.

**Use case**: Complex calculations from multiple metrics (e.g., profit margin, percentage calculations)

**Basic syntax:**
```yaml
metrics:
  - name: order_gross_profit
    description: Gross profit from each order
    type: derived
    label: Order gross profit
    type_params:
      expr: revenue - cost
      metrics:
        - name: order_total
          alias: revenue
        - name: order_cost
          alias: cost
```

**Percentage calculation:**
```yaml
metrics:
  - name: pct_of_orders_that_are_large
    label: pct_of_orders_that_are_large
    description: Percent of orders that are large
    type: derived
    type_params:
      expr: large_orders / order_count
      metrics:
        - name: large_orders
        - name: order_count
```

**Note:** Aliases allow you to reference metrics with clearer names in your expression.

---

## Filters

Filters use Jinja templating to reference entities, dimensions, time dimensions, or metrics.

### Filter Syntax

**Entity filter:**
```yaml
filter: |
  {{ Entity('entity_name') }}
```

**Dimension filter:**
```yaml
filter: |
  {{ Dimension('primary_entity__dimension_name') }}
```

**Example:**
```yaml
filter: |
  {{ Dimension('customer__country') }} = 'MX'
```

**Time dimension filter:**
```yaml
filter: |
  {{ TimeDimension('time_dimension', 'granularity') }}
```

**Example:**
```yaml
filter: |
  {{ TimeDimension('order_date', 'month') }}
```

**Metric filter (metrics as dimensions):**
```yaml
filter: |
  {{ Metric('metric_name', group_by=['entity_name']) }}
```

**Example:**
```yaml
filter: |
  {{ Metric('order_total', group_by=['order_id']) }} >= 20
```

### Metric-Level Filters

Applied to the entire metric calculation:

```yaml
metrics:
  - name: cancellations
    type: simple
    type_params:
      measure:
        name: cancellations_usd
        fill_nulls_with: 0
        join_to_timespine: true
    filter: |
      {{ Dimension('order__value') }} > 100 and {{ Dimension('user__acquisition') }} is not null
```

### Component-Level Filters (Ratio Metrics)

Applied to numerator or denominator individually:

```yaml
metrics:
  - name: enterprise_cancellation_rate
    type: ratio
    type_params:
      numerator:
        name: cancellations
        filter: {{ Dimension('company__tier') }} = 'enterprise'
      denominator: transaction_amount
    filter: |
      {{ Dimension('customer__country') }} = 'MX'
```

**Execution order:**
1. Component-level filters applied to numerator/denominator
2. Ratio calculated
3. Metric-level filter applied to result

---

## Measures

Measures are aggregations of columns in your semantic models. They serve as the building blocks for metrics.

### Measure Configuration

**Aggregation types (`agg`):**
- `sum` - Sum of values
- `count` - Count of rows
- `count_distinct` - Count of unique values
- `avg` - Average value
- `min` - Minimum value
- `max` - Maximum value

**Basic measure:**
```yaml
measures:
  - name: order_total
    description: The total amount for each order including taxes
    agg: sum
```

**Measure with expression:**
```yaml
measures:
  - name: customers
    expr: customer_id
    agg: count_distinct
```

**Measure with expression and description:**
```yaml
measures:
  - name: order_count
    description: The count of individual orders
    expr: 1
    agg: sum
```

### Advanced Measure Parameters

**`fill_nulls_with`** - Replace null values with a default:
```yaml
type_params:
  measure:
    name: order_total
    fill_nulls_with: 0
    join_to_timespine: true
```

**`join_to_timespine`** - Join measure to time spine for complete time series:
```yaml
type_params:
  measure:
    name: active_users
    fill_nulls_with: 0
    join_to_timespine: true
```

**Why use these:**
- `fill_nulls_with: 0` ensures missing periods show 0 instead of null
- `join_to_timespine: true` creates rows for all time periods, even with no data

### Shorthand vs. Expanded Syntax

**Shorthand (measure name only):**
```yaml
type_params:
  measure: revenue
```

**Expanded (with parameters):**
```yaml
type_params:
  measure:
    name: order_total
    fill_nulls_with: 0
    join_to_timespine: true
```

### Complete Semantic Model Example with Measures

```yaml
semantic_models:
  - name: orders
    defaults:
      agg_time_dimension: ordered_at
    description: |
      Order fact table. This table is at the order grain with one row per order.
    model: ref('stg_orders')

    entities:
      - name: order_id
        type: primary
      - name: location
        type: foreign
        expr: location_id
      - name: customer
        type: foreign
        expr: customer_id

    dimensions:
      - name: ordered_at
        expr: date_trunc('day', ordered_at)
        type: time
        type_params:
          time_granularity: day
      - name: is_large_order
        type: categorical
        expr: case when order_total > 50 then true else false end

    measures:
      - name: order_total
        description: The total revenue for each order
        agg: sum
      - name: order_count
        description: The count of individual orders
        expr: 1
        agg: sum
      - name: tax_paid
        description: The total tax paid on each order
        agg: sum
```

---

## Time Spine Configuration

Time spines provide a complete set of dates/times for time-based queries. They're essential for cumulative metrics and ensuring complete time series.

### Daily Time Spine

**Model definition:**
```sql
{{
  config(
    materialized = 'table',
  )
}}

with base_dates as (
  {{
    dbt.date_spine(
      'day',
      "DATE('2000-01-01')",
      "DATE('2030-01-01')"
    )
  }}
),

final as (
  select
    cast(date_day as date) as date_day
  from base_dates
)

select *
from final
where date_day > dateadd(year, -5, current_date())
  and date_day < dateadd(day, 30, current_date())
```

**YAML configuration:**
```yaml
models:
  - name: time_spine_daily
    description: A time spine with one row per day, ranging from 5 years in the past to 30 days into the future
    time_spine:
      standard_granularity_column: date_day
    columns:
      - name: date_day
        description: The base date column for daily granularity
        granularity: day
```

**Commands:**
```bash
dbt run --select time_spine_daily
dbt show --select time_spine_daily  # Preview the model
dbt sl query --metrics revenue --group-by metric_time
```

### Using Existing Date Dimension as Time Spine

```yaml
models:
  - name: dim_date
    description: An existing date dimension model used as a time spine
    time_spine:
      standard_granularity_column: date_day
    columns:
      - name: date_day
        granularity: day
      - name: day_of_week
        granularity: day
      - name: full_date
        granularity: day
```

### Custom Granularities (Yearly)

**Model definition:**
```sql
{{
  config(
    materialized = 'table',
  )
}}

with years as (
  {{
    dbt.date_spine(
      'year',
      "to_date('01/01/2000','mm/dd/yyyy')",
      "to_date('01/01/2025','mm/dd/yyyy')"
    )
  }}
),

final as (
  select cast(date_year as date) as date_year
  from years
)

select * from final
where date_year >= date_trunc('year', dateadd(year, -4, current_timestamp()))
  and date_year < date_trunc('year', dateadd(year, 1, current_timestamp()))
```

**YAML configuration:**
```yaml
models:
  - name: time_spine_yearly
    description: Time spine with one row per year
    time_spine:
      standard_granularity_column: date_year
    columns:
      - name: date_year
        granularity: year
```

**Query example:**
```bash
dbt sl query --metrics orders --group-by metric_time__year
```

### Fiscal Calendar (Custom Granularities)

**Model definition:**
```sql
with date_spine as (
  select
    date_day,
    extract(year from date_day) as calendar_year,
    extract(week from date_day) as calendar_week
  from {{ ref('time_spine_daily') }}
),

fiscal_calendar as (
  select
    date_day,
    -- Define custom fiscal year starting in October
    case
      when extract(month from date_day) >= 10
        then extract(year from date_day) + 1
      else extract(year from date_day)
    end as fiscal_year,

    -- Define fiscal weeks (e.g., shift by 1 week)
    extract(week from date_day) + 1 as fiscal_week
  from date_spine
)

select * from fiscal_calendar
```

**YAML configuration:**
```yaml
models:
  - name: fiscal_calendar
    description: A custom fiscal calendar with fiscal year and fiscal week granularities
    time_spine:
      standard_granularity_column: date_day
      custom_granularities:
        - name: fiscal_year
          column_name: fiscal_year
        - name: fiscal_week
          column_name: fiscal_week
    columns:
      - name: date_day
        granularity: day
      - name: fiscal_year
        description: Custom fiscal year starting in October
      - name: fiscal_week
        description: Fiscal week, shifted by 1 week from standard calendar
```

**Query example:**
```bash
dbt sl query --metrics orders --group-by metric_time__fiscal_year
```

---

## Python SDK Patterns

The dbt Semantic Layer Python SDK enables programmatic access to metrics.

### Installation & Setup

```python
from dbtsl import SemanticLayerClient

client = SemanticLayerClient(
    environment_id=123,
    auth_token="<your-semantic-layer-api-token>",
    host="semantic-layer.cloud.getdbt.com",
)
```

### Basic Query Pattern

```python
def main():
    with client.session():
        metrics = client.metrics()
        table = client.query(
            metrics=[metrics[0].name],
            group_by=["metric_time"],
        )
        print(table)
```

**Important:** All API calls must be within a `client.session()` context manager. Create an application-wide session and reuse it for optimal performance.

### Asyncio Usage

```python
import asyncio
from dbtsl.asyncio import AsyncSemanticLayerClient

client = AsyncSemanticLayerClient(
    environment_id=123,
    auth_token="<your-semantic-layer-api-token>",
    host="semantic-layer.cloud.getdbt.com",
)

async def main():
    async with client.session():
        metrics = await client.metrics()
        table = await client.query(
            metrics=[metrics[0].name],
            group_by=["metric_time"],
        )
        print(table)
```

**Note:** `SemanticLayerClient` and `AsyncSemanticLayerClient` have identical APIs, but async methods must be awaited.

### Lazy Loading for Performance

By default, the SDK eagerly loads nested fields like `dimensions`, `entities`, and `measures` for each metric. In large projects, this can slow responses.

Enable lazy loading to fetch nested fields on-demand:

```python
from argparse import ArgumentParser
from dbtsl import SemanticLayerClient

def get_arg_parser() -> ArgumentParser:
    p = ArgumentParser()
    p.add_argument("--env-id", required=True, help="The dbt environment ID", type=int)
    p.add_argument("--token", required=True, help="The API auth token")
    p.add_argument("--host", required=True, help="The API host")
    return p

def main() -> None:
    arg_parser = get_arg_parser()
    args = arg_parser.parse_args()

    client = SemanticLayerClient(
        environment_id=args.env_id,
        auth_token=args.token,
        host=args.host,
        lazy=True,  # Enable lazy loading
    )

    with client.session():
        metrics = client.metrics()
        for i, m in enumerate(metrics):
            print(f"📈 {m.name}")
            print(f"     type={m.type}")
            print(f"     description={m.description}")

            # Dimensions not loaded yet
            assert len(m.dimensions) == 0

            # Load dimensions only for even-indexed metrics
            if i & 1:
                print("     dimensions=skipped")
                continue

            # Explicitly load dimensions
            m.load_dimensions()

            print("     dimensions=[")
            for dim in m.dimensions:
                print(f"        {dim.name},")
            print("     ]")

if __name__ == "__main__":
    main()
```

**Lazy loading currently supports:** `dimensions`, `entities`, and `measures` on `Metric` objects.

### DataFrame Integration

The Python SDK returns query data as [PyArrow](https://arrow.apache.org/docs/python/index.html) tables.

**Convert to Pandas:**
```python
import pandas as pd

with client.session():
    table = client.query(
        metrics=["order_total"],
        group_by=["metric_time"],
    )
    df = table.to_pandas()
```

**Convert to Polars:**
```python
import polars as pl

with client.session():
    table = client.query(
        metrics=["order_total"],
        group_by=["metric_time"],
    )
    df = pl.from_arrow(table)
```

**Note:** The SDK doesn't bundle Pandas or Polars. Add them as dependencies in your project if needed.

---

## Saved Queries

Saved queries are reusable metric queries defined in YAML that can be versioned and referenced.

### Definition

```yaml
saved_queries:
  - name: test_saved_query
    description: "{{ doc('saved_query_description') }}"
    label: Test saved query
    config:
      tags:
        - order_metrics
        - hourly
```

### Querying with Semantic Layer

**Using `semantic_layer.query()` macro:**
```sql
select * from
  {{ semantic_layer.query(
    metrics = [
      'order_total',
      'order_count',
      'large_orders',
      'customers_with_orders',
      'avg_order_value',
      'pct_of_orders_that_are_large'
    ],
    group_by = [Dimension('metric_time').grain('day')]
  ) }}
```

### Running Tagged Saved Queries

```bash
# Run all resources tagged "order_metrics"
dbt run --select tag:order_metrics

# Run all resources tagged "order_metrics" AND "hourly"
dbt build --select tag:order_metrics tag:hourly
```

---

## Complete Example: All Metric Types

```yaml
semantic_models:
  - name: customers
    defaults:
      agg_time_dimension: most_recent_order_date
    description: Semantic model for dim_customers
    model: ref('dim_customers')

    entities:
      - name: customer
        expr: customer_id
        type: primary

    dimensions:
      - name: customer_name
        type: categorical
        expr: first_name
      - name: first_order_date
        type: time
        type_params:
          time_granularity: day
      - name: most_recent_order_date
        type: time
        type_params:
          time_granularity: day

    measures:
      - name: count_lifetime_orders
        description: Total count of orders per customer
        agg: sum
        expr: number_of_orders
      - name: lifetime_spend
        agg: sum
        expr: lifetime_value
        description: Gross customer lifetime spend inclusive of taxes
      - name: customers
        expr: customer_id
        agg: count_distinct

metrics:
  # Simple type metrics
  - name: order_total
    description: Sum of orders value
    type: simple
    label: order_total
    type_params:
      measure:
        name: order_total

  - name: order_count
    description: Number of orders
    type: simple
    label: order_count
    type_params:
      measure:
        name: order_count

  - name: large_orders
    description: Count of orders with order total over 20
    type: simple
    label: Large Orders
    type_params:
      measure:
        name: order_count
    filter: |
      {{ Metric('order_total', group_by=['order_id']) }} >= 20

  - name: customers_with_orders
    label: customers_with_orders
    description: Unique count of customers placing orders
    type: simple
    type_params:
      measure:
        name: customers

  # Ratio type metric
  - name: avg_order_value
    label: avg_order_value
    description: Average value of each order
    type: ratio
    type_params:
      numerator: order_total
      denominator: order_count

  # Cumulative type metric
  - name: cumulative_order_amount_mtd
    label: cumulative_order_amount_mtd
    description: The month to date value of all orders
    type: cumulative
    type_params:
      measure:
        name: order_total
      grain_to_date: month

  # Derived metric
  - name: pct_of_orders_that_are_large
    label: pct_of_orders_that_are_large
    description: Percent of orders that are large
    type: derived
    type_params:
      expr: large_orders / order_count
      metrics:
        - name: large_orders
        - name: order_count
```

**Query all metrics:**
```bash
dbt sl query --metrics order_total,order_count --group-by order_date
```

---

## CLI Query Examples

**List available metrics:**
```bash
dbt sl list metrics
```

**List dimensions for a metric:**
```bash
dbt sl list dimensions --metrics revenue
```

**Query metric by time:**
```bash
dbt sl query --metrics revenue --group-by metric_time__month
```

**Query with specific grain:**
```bash
dbt sl query --metrics orders --group-by metric_time__year
```

**Compile query to view SQL:**
```bash
dbt sl query --metrics order_total --group-by order_date --compile
```

---

## Best Practices

1. **Use `create_metric: True` on measures** if you don't need filtering - avoids redundant simple metric definitions

2. **Enable lazy loading** for large projects with many metrics

3. **Use `fill_nulls_with: 0` and `join_to_timespine: true`** for cumulative metrics to ensure complete time series

4. **Define time spines** with appropriate date ranges - don't generate unnecessary dates

5. **Leverage saved queries** for commonly-used metric combinations

6. **Use tags** to organize and run related metrics together

7. **Reuse application-wide sessions** with the Python SDK for better performance

8. **Always run `dbt parse`** after changing metrics to update the semantic manifest
