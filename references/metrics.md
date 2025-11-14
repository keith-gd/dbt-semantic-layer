# Dbt-Semantic-Layer - Metrics

**Pages:** 6

---

## query the first metric by `metric_time`

**URL:** llms-txt#query-the-first-metric-by-`metric_time`

def main():
    with client.session():
        metrics = client.metrics()
        table = client.query(
            metrics=[metrics[0].name],
            group_by=["metric_time"],
        )
        print(table)

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

"""Fetch all available metrics from the metadata API and display only the dimensions of certain metrics."""

from argparse import ArgumentParser

from dbtsl import SemanticLayerClient

def get_arg_parser() -> ArgumentParser:
    p = ArgumentParser()

p.add_argument("--env-id", required=True, help="The dbt environment ID", type=int)
    p.add_argument("--token", required=True, help="The API auth token")
    p.add_argument("--host", required=True, help="The API host")

def main() -> None:
    arg_parser = get_arg_parser()
    args = arg_parser.parse_args()

client = SemanticLayerClient(
        environment_id=args.env_id,
        auth_token=args.token,
        host=args.host,
        lazy=True,
    )

with client.session():
        metrics = client.metrics()
        for i, m in enumerate(metrics):
            print(f"📈 {m.name}")
            print(f"     type={m.type}")
            print(f"     description={m.description}")

assert len(m.dimensions) == 0

# skip if index is odd
            if i & 1:
                print("     dimensions=skipped")
                continue

# load dimensions only if index is even
            m.load_dimensions()

print("     dimensions=[")
            for dim in m.dimensions:
                print(f"        {dim.name},")
            print("     ]")

if __name__ == "__main__":
    main()

**Examples:**

Example 1 (unknown):
```unknown
**Note**: All method calls that reach out to the APIs need to be within a `client.session()` context manager. This allows the client to establish a connection to the APIs only once and reuse the same connection between API calls.

We recommend creating an application-wide session and reusing the same session throughout the application for optimal performance. Creating a session per request is discouraged and inefficient.

##### asyncio usage[​](#asyncio-usage "Direct link to asyncio usage")

If you're using asyncio, import `AsyncSemanticLayerClient` from `dbtsl.asyncio`. The `SemanticLayerClient` and `AsyncSemanticLayerClient` APIs are identical, but the async version has async methods that you need to `await`.
```

Example 2 (unknown):
```unknown
##### Lazy loading for large fields[​](#lazy-loading-for-large-fields "Direct link to Lazy loading for large fields")

By default, the Python SDK eagerly loads nested lists of objects such as `dimensions`, `entities`, and `measures` for each `Metric` — even if you don't need them. This is generally convenient, but in large projects, it can lead to slower responses due to the amount of data returned.

To improve performance, you can opt into lazy loading by passing `lazy=True` when creating the client. With lazy loading enabled, the SDK skips fetching large nested fields until you explicitly request them on a per-model basis.

Lazy loading is currently only supported for `dimensions`, `entities`, and `measures` on `Metric` objects.

For example, the following code fetches all available metrics from the metadata API and displays only the dimensions of certain metrics:

list\_metrics\_lazy\_sync.py
```

Example 3 (unknown):
```unknown
Refer to the [lazy loading example](https://github.com/dbt-labs/semantic-layer-sdk-python/blob/main/examples/list_metrics_lazy_sync.py) for more details.

#### Integrate with dataframe libraries[​](#integrate-with-dataframe-libraries "Direct link to Integrate with dataframe libraries")

The Python SDK returns all query data as [pyarrow](https://arrow.apache.org/docs/python/index.html) tables.

The Python SDK library doesn't come bundled with [Polars](https://pola.rs/) or [Pandas](https://pandas.pydata.org/). If you use these libraries, add them as dependencies in your project.

To use the data with libraries like Polars or Pandas, manually convert the data into the desired format. For example:

###### If you're using pandas[​](#if-youre-using-pandas "Direct link to If you're using pandas")
```

---

## job 2

**URL:** llms-txt#job-2

**Contents:**
  - Building metrics
  - Building semantic models
  - Clone incremental models as the first step of your CI job
  - Conclusion
  - Configuring materializations
  - dbt Mesh FAQs
  - Deciding how to structure your dbt Mesh
  - Don't nest your curlies
  - Examining our builds
  - How we structure our dbt projects

dbt source freshness # must be run again to compare current to previous state
dbt build --select source_status:fresher+ --state path/to/prod/artifacts

select
*
from event_tracking.events
{% if target.name == 'dev' %}
where created_at >= dateadd('day', -3, current_date)
{% endif %}

{% if env_var('DBT_CLOUD_INVOCATION_CONTEXT') != 'prod' %}

metrics:
  - name: revenue
    description: Sum of the order total.
    label: Revenue
    type: simple
    type_params:
      measure: order_total

dbt sl query revenue --group-by metric_time__month
dbt sl list dimensions --metrics revenue # list all dimensions available for the revenue metric

semantic_models:
  - name: orders
    entities: ... # we'll define these later
    dimensions: ... # we'll define these later
    measures: ... # we'll define these later

semantic_models:
  - name: orders
    description: |
      Model containing order data. The grain of the table is the order id.
    model: ref('stg_orders')
    entities: ...
    dimensions: ...
    measures: ...

----------  ids
        id as order_id,
        store_id as location_id,
        customer as customer_id,

---------- properties
        (order_total / 100.0) as order_total,
        (tax_paid / 100.0) as tax_paid,

---------- timestamps
        ordered_at

semantic_models:
  - name: orders
    ...
    entities:
      # we use the column for the name here because order is a reserved word in SQL
      - name: order_id
        type: primary
      - name: location
        type: foreign
        expr: location_id
      - name: customer
        type: foreign
        expr: customer_id

dimensions:
      ...
    measures:
      ...

----------  ids -> entities
    id as order_id,
    store_id as location_id,
    customer as customer_id,

---------- numerics -> measures
    (order_total / 100.0) as order_total,
    (tax_paid / 100.0) as tax_paid,

---------- timestamps -> dimensions
    ordered_at

dimensions:
  - name: ordered_at
    expr: date_trunc('day', ordered_at)
    type: time
    type_params:
      time_granularity: day

dimensions:
  - name: ordered_at
    expr: date_trunc('day', ordered_at)
    type: time
    type_params:
      time_granularity: day
  - name: is_large_order
    type: categorical
    expr: case when order_total > 50 then true else false end

----------  ids -> entities
    id as order_id,
    store_id as location_id,
    customer as customer_id,

---------- numerics -> measures
    (order_total / 100.0) as order_total,
    (tax_paid / 100.0) as tax_paid,

---------- timestamps -> dimensions
    ordered_at

measures:
  - name: order_total
    description: The total amount for each order including taxes.
    agg: sum
  - name: tax_paid
    description: The total tax paid on each order.
    agg: sum

- name: order_count
  description: The count of individual orders.
  expr: 1
  agg: sum

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
        # use date_trunc(ordered_at, DAY) if using BigQuery
        type: time
        type_params:
          time_granularity: day
      - name: is_large_order
        type: categorical
        expr: case when order_total > 50 then true else false end

measures:
      - name: order_total
        description: The total revenue for each order.
        agg: sum
      - name: order_count
        description: The count of individual orders.
        expr: 1
        agg: sum
      - name: tax_paid
        description: The total tax paid on each order.
        agg: sum

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
        # use date_trunc(ordered_at, DAY) if using BigQuery
        type: time
        type_params:
          time_granularity: day
      - name: is_large_order
        type: categorical
        expr: case when order_total > 50 then true else false end

measures:
      - name: order_total
        description: The total revenue for each order.
        agg: sum
      - name: order_count
        description: The count of individual orders.
        expr: 1
        agg: sum
      - name: tax_paid
        description: The total tax paid on each order.
        agg: sum

dbt clone --select state:modified+,config.materialized:incremental,state:old

dbt build --select state:modified+

{{
    config(
        materialized='incremental',
        unique_key='unique_id',
        on_schema_change='fail'
    )
}}

{{
        config(
            materialized='view'
        )
    }}

{{
    config(
        materialized='table'
    )
}}

def model(dbt, session):

dbt.config(materialized="table")

semantic_models:
  - name: customer_orders
    defaults:
      agg_time_dimension: first_ordered_at
    description: |
      Customer grain mart that aggregates customer orders.
    model: ref('jaffle_finance', 'fct_orders') # ref('project_name', 'model_name')
    entities:
      ...rest of configuration...
    dimensions:
      ...rest of configuration...
    measures:
      ...rest of configuration...

{{ dbt_utils.date_spine(
      datepart="day",
      start_date=[ USE JINJA HERE ]
      )
  }}

{{ dbt_utils.date_spine(
      datepart="day",
      start_date=var('start_date')
      )
  }}

-- Do not do this! It will not work!

{{ dbt_utils.date_spine(
      datepart="day",
      start_date="{{ var('start_date') }}"
      )
  }}

{# Either of these work #}

{% set query_sql = 'select * from ' ~ ref('my_model') %}

{% set query_sql %}
select * from {{ ref('my_model') }}
{% endset %}

{# This does not #}
{% set query_sql = "select * from {{ ref('my_model')}}" %}

{{ config(post_hook="grant select on {{ this }} to role bi_role") }}

20:24:51  5 of 10 START sql view model main.stg_products ......... [RUN]
20:24:51  5 of 10 OK created sql view model main.stg_products .... [OK in 0.13s]

jaffle_shop
├── README.md
├── analyses
├── seeds
│   └── employees.csv
├── dbt_project.yml
├── macros
│   └── cents_to_dollars.sql
├── models
│   ├── intermediate
│   │   └── finance
│   │       ├── _int_finance__models.yml
│   │       └── int_payments_pivoted_to_orders.sql
│   ├── marts
│   │   ├── finance
│   │   │   ├── _finance__models.yml
│   │   │   ├── orders.sql
│   │   │   └── payments.sql
│   │   └── marketing
│   │       ├── _marketing__models.yml
│   │       └── customers.sql
│   ├── staging
│   │   ├── jaffle_shop
│   │   │   ├── _jaffle_shop__docs.md
│   │   │   ├── _jaffle_shop__models.yml
│   │   │   ├── _jaffle_shop__sources.yml
│   │   │   ├── base
│   │   │   │   ├── base_jaffle_shop__customers.sql
│   │   │   │   └── base_jaffle_shop__deleted_customers.sql
│   │   │   ├── stg_jaffle_shop__customers.sql
│   │   │   └── stg_jaffle_shop__orders.sql
│   │   └── stripe
│   │       ├── _stripe__models.yml
│   │       ├── _stripe__sources.yml
│   │       └── stg_stripe__payments.sql
│   └── utilities
│       └── all_dates.sql
├── packages.yml
├── snapshots
└── tests
    └── assert_positive_value_for_total_amount.sql

select * from {{ source('ecom', 'raw_orders') }}

----------  ids
        id as order_id,
        store_id as location_id,
        customer as customer_id,

---------- strings
        status as order_status,

---------- numerics
        (order_total / 100.0)::float as order_total,
        (tax_paid / 100.0)::float as tax_paid,

---------- booleans
        is_fulfilled,

---------- dates
        date(order_date) as ordered_date,

---------- timestamps
        ordered_at

select * from renamed

{% macro make_cool(uncool_id) %}

do_cool_thing({{ uncool_id }})

select
    entity_id,
    entity_type,
    {% if this %}

{{ the_other_thing }},

{% endif %}
    {{ make_cool('uncool_id') }} as cool_id

def model(dbt, session):
    # set length of time considered a churn
    pd.Timedelta(days=2)

dbt.config(enabled=False, materialized="table", packages=["pandas==1.5.2"])

orders_relation = dbt.ref("stg_orders")

# converting a DuckDB Python Relation into a pandas DataFrame
    orders_df = orders_relation.df()

orders_df.sort_values(by="ordered_at", inplace=True)
    orders_df["previous_order_at"] = orders_df.groupby("customer_id")[
        "ordered_at"
    ].shift(1)
    orders_df["next_order_at"] = orders_df.groupby("customer_id")["ordered_at"].shift(
        -1
    )
    return orders_df

select
        order_id,
        customer_id,
        order_total,
        order_date

from {{ ref('orders') }}

where order_date >= '2020-01-01'

{{
    config(
      materialized = 'table',
      sort = 'id',
      dist = 'id'
    )
}}

{# CTE comments go here #}
filtered_events as (

select * from filtered_events

select
        field_1,
        field_2,
        field_3,
        cancellation_date,
        expiration_date,
        start_date

from {{ ref('my_data') }}

select
        id,
        field_4,
        field_5

from {{ ref('some_cte') }}

select
        id,
        sum(field_4) as total_field_4,
        max(field_5) as max_field_5

select
        my_data.field_1,
        my_data.field_2,
        my_data.field_3,

-- use line breaks to visually separate calculations into blocks
        case
            when my_data.cancellation_date is null
                and my_data.expiration_date is not null
                then expiration_date
            when my_data.cancellation_date is null
                then my_data.start_date + 7
            else my_data.cancellation_date
        end as cancellation_date,

some_cte_agg.total_field_4,
        some_cte_agg.max_field_5

left join some_cte_agg
        on my_data.id = some_cte_agg.id

where my_data.field_1 = 'abc' and
        (
            my_data.field_2 = 'def' or
            my_data.field_2 = 'ghi'
        )

models:
  - name: events
    columns:
      - name: event_id
        description: This is a unique identifier for the event
        data_tests:
          - unique
          - not_null

- name: event_time
        description: "When the event occurred in UTC (eg. 2018-01-01 12:00:00)"
        data_tests:
          - not_null

- name: user_id
        description: The ID of the user who recorded the event
        data_tests:
          - not_null
          - relationships:
              arguments: # available in v1.10.5 and higher. Older versions can set the <argument_name> as the top-level property.
                to: ref('users')
                field: id

**Examples:**

Example 1 (unknown):
```unknown
To learn more, read the docs on [state](https://docs.getdbt.com/reference/node-selection/syntax.md#about-node-selection).

#### Pro-tips for dbt Projects[​](#pro-tips-for-dbt-projects "Direct link to Pro-tips for dbt Projects")

##### Limit the data processed when in development[​](#limit-the-data-processed-when-in-development "Direct link to Limit the data processed when in development")

In a development environment, faster run times allow you to iterate your code more quickly. We frequently speed up our runs by using a pattern that limits data based on the [target](https://docs.getdbt.com/reference/dbt-jinja-functions/target.md) name:
```

Example 2 (unknown):
```unknown
Another option is to use the [environment variable `DBT_CLOUD_INVOCATION_CONTEXT`](https://docs.getdbt.com/docs/build/environment-variables.md#dbt-platform-context). This environment variable provides metadata about the execution context of dbt. The possible values are `prod`, `dev`, `staging`, and `ci`.

**Example usage**:
```

Example 3 (unknown):
```unknown
##### Use grants to manage privileges on objects that dbt creates[​](#use-grants-to-manage-privileges-on-objects-that-dbt-creates "Direct link to Use grants to manage privileges on objects that dbt creates")

Use `grants` in [resource configs](https://docs.getdbt.com/reference/resource-configs/grants.md) to ensure that permissions are applied to the objects created by dbt. By codifying these grant statements, you can version control and repeatably apply these permissions.

##### Separate source-centric and business-centric transformations[​](#separate-source-centric-and-business-centric-transformations "Direct link to Separate source-centric and business-centric transformations")

When modeling data, we frequently find there are two stages:

1. Source-centric transformations to transform data from different sources into a consistent structure, for example, re-aliasing and recasting columns, or unioning, joining or deduplicating source data to ensure your model has the correct grain; and
2. Business-centric transformations that transform data into models that represent entities and processes relevant to your business, or implement business definitions in SQL.

We find it most useful to separate these two types of transformations into different models, to make the distinction between source-centric and business-centric logic clear.

##### Managing whitespace generated by Jinja[​](#managing-whitespace-generated-by-jinja "Direct link to Managing whitespace generated by Jinja")

If you're using macros or other pieces of Jinja in your models, your compiled SQL (found in the `target/compiled` directory) may contain unwanted whitespace. Check out the [Jinja documentation](http://jinja.pocoo.org/docs/2.10/templates/#whitespace-control) to learn how to control generated whitespace.

#### Related docs[​](#related-docs "Direct link to Related docs")

* [Updating our permissioning guidelines: grants as configs in dbt Core v1.2](https://docs.getdbt.com/blog/configuring-grants)

#### Was this page helpful?

YesNo

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.


---

### Building metrics

#### How to build metrics[​](#how-to-build-metrics "Direct link to How to build metrics")

* 💹 We'll start with one of the most important metrics for any business: **revenue**.
* 📖 For now, our metric for revenue will be **defined as the sum of order totals excluding tax**.

#### Defining revenue[​](#defining-revenue "Direct link to Defining revenue")

* 🔢 Metrics have four basic properties:

  <!-- -->

  * `name:` We'll use 'revenue' to reference this metric.
  * `description:` For documentation.
  * `label:` The display name for the metric in downstream tools.
  * `type:` one of `simple`, `ratio`, or `derived`.

* 🎛️ Each type has different `type_params`.

* 🛠️ We'll build a **simple metric** first to get the hang of it, and move on to ratio and derived metrics later.

* 📏 Simple metrics are built on a **single measure defined as a type parameter**.

* 🔜 Defining **measures as their own distinct component** on semantic models is critical to allowing the **flexibility of more advanced metrics**, though simple metrics act mainly as **pass-through that provide filtering** and labeling options.

models/marts/orders.yml
```

Example 4 (unknown):
```unknown
#### Query your metric[​](#query-your-metric "Direct link to Query your metric")

You can use the Cloud CLI for metric validation or queries during development, via the `dbt sl` set of subcommands. Here are some useful examples:
```

---

## Cumulative metrics aggregate a measure over a given window. The window is considered infinite if no window parameter is passed (accumulate the measure over all of time)

**URL:** llms-txt#cumulative-metrics-aggregate-a-measure-over-a-given-window.-the-window-is-considered-infinite-if-no-window-parameter-is-passed-(accumulate-the-measure-over-all-of-time)

**Contents:**
  - Cumulative metrics
  - Custom aliases
  - Custom databases
  - Custom schemas

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

metrics:
  - name: order_gross_profit
    description: Gross profit from each order.
    type: derived
    label: Order gross profit
    type_params:
      expr: revenue - cost
      metrics:
        - name: order_total
          alias: revenue
        - name: order_cost
          alias: cost

metrics:
  - name: cancellation_rate
    type: ratio
    label: Cancellation rate
    type_params:
      numerator: cancellations
      denominator: transaction_amount
    filter: |   
      {{ Dimension('customer__country') }} = 'MX'
  - name: enterprise_cancellation_rate
    type: ratio
    type_params:
      numerator:
        name: cancellations
        filter: {{ Dimension('company__tier') }} = 'enterprise'  
      denominator: transaction_amount
    filter: | 
      {{ Dimension('customer__country') }} = 'MX'

metrics:
  - name: cancellations
    description: The number of cancellations
    type: simple
    label: Cancellations
    type_params:
      measure:
        name: cancellations_usd  # Specify the measure you are creating a proxy for.
        fill_nulls_with: 0
        join_to_timespine: true
    filter: |
      {{ Dimension('order__value')}} > 100 and {{Dimension('user__acquisition')}} is not null

filter: | 
  {{ Entity('entity_name') }}

filter: |  
  {{ Dimension('primary_entity__dimension_name') }}

filter: |  
  {{ TimeDimension('time_dimension', 'granularity') }}

filter: |  
 {{ Metric('metric_name', group_by=['entity_name']) }}

filter: |  
  {{ TimeDimension('order_date', 'month') }}

type_params:
    measure: revenue
  
  type_params:
    measure:
      name: order_total
      fill_nulls_with: 0
      join_to_timespine: true
  
measures:
  - name: customers
    expr: customer_id
    agg: count_distinct

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

measures:
      - name: order_total
        agg: sum

select
  count(distinct distinct_users) as weekly_active_users,
  metric_time
from (
  select
    subq_3.distinct_users as distinct_users,
    subq_3.metric_time as metric_time
  from (
    select
      subq_2.distinct_users as distinct_users,
      subq_1.metric_time as metric_time
    from (
      select
        metric_time
      from transform_prod_schema.mf_time_spine subq_1356
      where (
        metric_time >= cast('2000-01-01' as timestamp)
      ) and (
        metric_time <= cast('2040-12-31' as timestamp)
      )
    ) subq_1
    inner join (
      select
        distinct_users as distinct_users,
        date_trunc('day', ds) as metric_time
      from demo_schema.transactions transactions_src_426
      where (
        (date_trunc('day', ds)) >= cast('1999-12-26' as timestamp)
      ) AND (
        (date_trunc('day', ds)) <= cast('2040-12-31' as timestamp)
      )
    ) subq_2
    on
      (
        subq_2.metric_time <= subq_1.metric_time
      ) and (
        subq_2.metric_time > dateadd(day, -7, subq_1.metric_time)
      )
  ) subq_3
)
group by
  metric_time,
limit 100;

select
  count(distinct subq_3.distinct_users) as weekly_active_users,
  subq_3.metric_time
from (
  select
    subq_2.distinct_users as distinct_users,
    subq_1.metric_time as metric_time
group by
  subq_3.metric_time

-- This model will be created in the database with the identifier `sessions`
-- Note that in this example, `alias` is used along with a custom schema
{{ config(alias='sessions', schema='google_analytics') }}

models:
  - name: ga_sessions
    config:
      alias: sessions

-- Use the model's filename in ref's, regardless of any aliasing configs

select * from {{ ref('ga_sessions') }}
union all
select * from {{ ref('snowplow_sessions') }}

{% macro generate_alias_name(custom_alias_name=none, node=none) -%}

{%- if custom_alias_name -%}

{{ custom_alias_name | trim }}

{%- elif node.version -%}

{{ return(node.name ~ "_v" ~ (node.version | replace(".", "_"))) }}

{{ config(alias='sessions') }}

$ dbt compile
Encountered an error:
Compilation Error
  dbt found two resources with the database representation "analytics.sessions".
  dbt cannot create two resources with identical database representations. To fix this,
  change the "schema" or "alias" configuration of one of these resources:
  - model.my_project.snowplow_sessions (models/snowplow_sessions.sql)
  - model.my_project.sessions (models/sessions.sql)

models:
  jaffle_shop:
    +database: jaffle_shop

# For BigQuery users:
    # project: jaffle_shop

{{ config(database="jaffle_shop") }}

{% macro generate_database_name(custom_database_name=none, node=none) -%}

{%- set default_database = target.database -%}
    {%- if custom_database_name is none -%}

{{ default_database }}

{{ custom_database_name | trim }}

{{ config(schema='marketing') }}

**Examples:**

Example 1 (unknown):
```unknown
#### Derived metrics[​](#derived-metrics "Direct link to Derived metrics")

[Derived metrics](https://docs.getdbt.com/docs/build/derived.md) are defined as an expression of other metrics. Derived metrics allow you to do calculations on top of metrics.

models/metrics/file\_name.yml
```

Example 2 (unknown):
```unknown
#### Ratio metrics[​](#ratio-metrics "Direct link to Ratio metrics")

[Ratio metrics](https://docs.getdbt.com/docs/build/ratio.md) involve a numerator metric and a denominator metric. A `filter` string can be applied to both the numerator and denominator or separately to the numerator or denominator.

models/metrics/file\_name.yml
```

Example 3 (unknown):
```unknown
#### Simple metrics[​](#simple-metrics "Direct link to Simple metrics")

[Simple metrics](https://docs.getdbt.com/docs/build/simple.md) point directly to a measure. You may think of it as a function that takes only one measure as the input.

* `name` — Use this parameter to define the reference name of the metric. The name must be unique amongst metrics and can include lowercase letters, numbers, and underscores. You can use this name to call the metric from the Semantic Layer API.

**Note:** If you've already defined the measure using the `create_metric: True` parameter, you don't need to create simple metrics. However, if you would like to include a constraint on top of the measure, you will need to create a simple type metric.

models/metrics/file\_name.yml
```

Example 4 (unknown):
```unknown
#### Filters[​](#filters "Direct link to Filters")

A filter is configured using Jinja templating. Use the following syntax to reference entities, dimensions, time dimensions, or metrics in filters.

Refer to [Metrics as dimensions](https://docs.getdbt.com/docs/build/ref-metrics-in-filters.md) for details on how to use metrics as dimensions with metric filters:

models/metrics/file\_name.yml
```

---

## Run all resources tagged "order_metrics"

**URL:** llms-txt#run-all-resources-tagged-"order_metrics"

dbt run --select tag:order_metrics

saved_queries:
  - name: test_saved_query
    description: "{{ doc('saved_query_description') }}"
    label: Test saved query
    config:
      tags: 
        - order_metrics
        - hourly

**Examples:**

Example 1 (unknown):
```unknown
The second example shows how to apply multiple tags to a saved query in the `semantic_model.yml` file. The saved query is then tagged with `order_metrics` and `hourly`.

semantic\_model.yml
```

Example 2 (unknown):
```unknown
Run resources with multiple tags using the following commands:
```

---

## Newly added

**URL:** llms-txt#newly-added

**Contents:**
  - Quickstart with dbt Mesh
  - Quickstart with MetricFlow time spine
  - Refactoring legacy SQL to dbt
  - Refresh a Mode dashboard when a job completes

metrics: 
  # Simple type metrics
  - name: "order_total"
    description: "Sum of orders value"
    type: simple
    label: "order_total"
    type_params:
      measure:
        name: order_total
  - name: "order_count"
    description: "number of orders"
    type: simple
    label: "order_count"
    type_params:
      measure:
        name: order_count
  - name: large_orders
    description: "Count of orders with order total over 20."
    type: simple
    label: "Large Orders"
    type_params:
      measure:
        name: order_count
    filter: |
      {{ Metric('order_total', group_by=['order_id']) }} >=  20
  # Ratio type metric
  - name: "avg_order_value"
    label: "avg_order_value"
    description: "average value of each order"
    type: ratio
    type_params:
      numerator: 
        name: order_total
      denominator: 
        name: order_count
  # Cumulative type metrics
  - name: "cumulative_order_amount_mtd"
    label: "cumulative_order_amount_mtd"
    description: "The month to date value of all orders"
    type: cumulative
    type_params:
      measure:
        name: order_total
      grain_to_date: month
  # Derived metric
  - name: "pct_of_orders_that_are_large"
    label: "pct_of_orders_that_are_large"
    description: "percent of orders that are large"
    type: derived
    type_params:
      expr: large_orders/order_count
      metrics:
        - name: large_orders
        - name: order_count

semantic_models:
  - name: customers
    defaults:
      agg_time_dimension: most_recent_order_date
    description: |
      semantic model for dim_customers
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
        description: Total count of orders per customer.
        agg: sum
        expr: number_of_orders
      - name: lifetime_spend
        agg: sum
        expr: lifetime_value
        description: Gross customer lifetime spend inclusive of taxes.
      - name: customers
        expr: customer_id
        agg: count_distinct

metrics:
  - name: "customers_with_orders"
    label: "customers_with_orders"
    description: "Unique count of customers placing orders"
    type: simple
    type_params:
      measure:
        name: customers

dbt sl query --metrics order_total,order_count --group-by order_date
   
select * from
  {{ semantic_layer.query (
    metrics = ['order_total', 'order_count', 'large_orders', 'customers_with_orders', 'avg_order_value', pct_of_orders_that_are_large'],
    group_by = 
    [Dimension('metric_time').grain('day') ]
) }}

sources:
  - name: jaffle_shop
    description: This is a replica of the Postgres database used by our app
    database: raw
    schema: jaffle_shop
    tables:
      - name: customers
        description: One record per customer.
      - name: orders
        description: One record per order. Includes cancelled and deleted orders.

select
    id as customer_id,
    first_name,
    last_name

from {{ source('jaffle_shop', 'customers') }}

select
    id as order_id,
    user_id as customer_id,
    order_date,
    status

from {{ source('jaffle_shop', 'orders') }}

with customers as (
    select * 
    from {{ ref('stg_customers') }}
),

orders as (
    select * 
    from {{ ref('stg_orders') }}
),

customer_orders as (
    select
        customer_id,
        min(order_date) as first_order_date
    from orders
    group by customer_id
),

final as (
    select
        o.order_id,
        o.order_date,
        o.status,
        c.customer_id,
        c.first_name,
        c.last_name,
        co.first_order_date,
        -- Note that we've used a macro for this so that the appropriate DATEDIFF syntax is used for each respective data platform
        {{ datediff('first_order_date', 'order_date', 'day') }} as days_as_customer_at_purchase
    from orders o
    left join customers c using (customer_id)
    left join customer_orders co using (customer_id)
)

models:
  - name: fct_orders
    config:
      access: public # changed to config in v1.10
    description: "Customer and order details"
    columns:
      - name: order_id
        data_type: number
        description: ""

- name: order_date
        data_type: date
        description: ""

- name: status
        data_type: varchar
        description: "Indicates the status of the order"

- name: customer_id
        data_type: number
        description: ""

- name: first_name
        data_type: varchar
        description: ""

- name: last_name
        data_type: varchar
        description: ""

- name: first_order_date
        data_type: date
        description: ""

- name: days_as_customer_at_purchase
        data_type: number
        description: "Days between this purchase and customer's first purchase"

packages:
  - package: dbt-labs/dbt_utils
    version: 1.1.1

projects:
  - name: analytics

sources:
     - name: stripe
       database: raw
       schema: stripe 
       tables:
         - name: payment

with payments as (
       select * from {{ source('stripe', 'payment') }}
   ),

final as (
       select 
           id as payment_id,
           orderID as order_id,
           paymentMethod as payment_method,
           amount,
           created as payment_date 
       from payments
   )

with stg_payments as (
       select * from {{ ref('stg_payments') }}
   ),

fct_orders as (
       select * from {{ ref('analytics', 'fct_orders') }}
   ),

final as (
       select 
           days_as_customer_at_purchase,
           -- we use the pivot macro in the dbt_utils package to create columns that total payments for each method
           {{ dbt_utils.pivot(
               'payment_method',
               dbt_utils.get_column_values(ref('stg_payments'), 'payment_method'),
               agg='sum',
               then_value='amount',
               prefix='total_',
               suffix='_amount'
           ) }}, 
           sum(amount) as total_amount
       from fct_orders
       left join stg_payments using (order_id)
       group by 1
   )

select * from final
   
models:
  - name: fct_orders
    description: “Customer and order details”
    config:
      access: public # changed to config in v1.10
      contract:
        enforced: true
    columns:
      - name: order_id
        .....

models:
  - name: fct_orders
    description: "Customer and order details"
    latest_version: 2
    config:
      access: public # changed to config in v1.10
      contract:
        enforced: true
    columns:
      - name: order_id
        data_type: number
        description: ""

- name: order_date
        data_type: date
        description: ""

- name: status
        data_type: varchar
        description: "Indicates the status of the order"

- name: is_return
        data_type: boolean
        description: "Indicates if an order was returned"

- name: customer_id
        data_type: number
        description: ""

- name: first_name
        data_type: varchar
        description: ""

- name: last_name
        data_type: varchar
        description: ""

- name: first_order_date
        data_type: date
        description: ""

- name: days_as_customer_at_purchase
        data_type: number
        description: "Days between this purchase and customer's first purchase"

# Declare the versions, and highlight the diffs
    versions:
    
      - v: 1
        deprecation_date: 2024-06-30 00:00:00.00+00:00
        columns:
          # This means: use the 'columns' list from above, but exclude is_return
          - include: all
            exclude: [is_return]
        
      - v: 2
        columns:
          # This means: use the 'columns' list from above, but exclude status
          - include: all
            exclude: [status]

select * from {{ ref('fct_orders', v=1) }}
select * from {{ ref('fct_orders', v=2) }}
select * from {{ ref('fct_orders') }}

with stg_payments as (
    select * from {{ ref('stg_payments') }}
),

fct_orders as (
    select * from {{ ref('analytics', 'fct_orders', v=1) }}
),

final as (
    select 
        days_as_customer_at_purchase,
        -- we use the pivot macro in the dbt_utils package to create columns that total payments for each method
        {{ dbt_utils.pivot(
            'payment_method',
            dbt_utils.get_column_values(ref('stg_payments'), 'payment_method'),
            agg='sum',
            then_value='amount',
            prefix='total_',
            suffix='_amount'
        ) }}, 
        sum(amount) as total_amount
    from fct_orders
    left join stg_payments using (order_id)
    group by 1
)

{{
       config(
           materialized = 'table',
       )
   }}

base_dates as (
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
   where date_day > dateadd(year, -5, current_date())  -- Keep recent dates only
     and date_day < dateadd(day, 30, current_date())
   
   dbt run --select time_spine_daily 
   dbt show --select time_spine_daily # Use this command to preview the model if developing locally
   
   models:
     - name: time_spine_daily
       description: A time spine with one row per day, ranging from 5 years in the past to 30 days into the future.
       time_spine:
         standard_granularity_column: date_day  # The base column used for time joins
       columns:
         - name: date_day
           description: The base date column for daily granularity
           granularity: day
   
   models:
     - name: dim_date
       description: An existing date dimension model used as a time spine.
       time_spine:
         standard_granularity_column: date_day
       columns:
         - name: date_day
           granularity: day
         - name: day_of_week
           granularity: day
         - name: full_date
           granularity: day
   
   dbt run --select time_spine_daily
   dbt show --select time_spine_daily # Use this command to preview the model if developing locally
   
   dbt sl query --metrics revenue --group-by metric_time
   
   {{
       config(
           materialized = 'table',
       )
   }}

{{
           dbt.date_spine(
               'year',
               "to_date('01/01/2000','mm/dd/yyyy')",
               "to_date('01/01/2025','mm/dd/yyyy')"
           )
       }}

final as (
       select cast(date_year as date) as date_year
       from years
   )

select * from final
   -- filter the time spine to a specific range
   where date_year >= date_trunc('year', dateadd(year, -4, current_timestamp())) 
     and date_year < date_trunc('year', dateadd(year, 1, current_timestamp()))
   
   models:
     - name: time_spine_daily
       ... rest of the daily time spine config ...

- name: time_spine_yearly
       description: time spine one row per house
       time_spine:
         standard_granularity_column: date_year
       columns:
         - name: date_year
           granularity: year
   
   dbt run --select time_spine_yearly
   dbt show --select time_spine_yearly # Use this command to preview the model if developing locally
   
   dbt sl query --metrics orders --group-by metric_time__year
   
       with date_spine as (

select 
           date_day,
           extract(year from date_day) as calendar_year,
           extract(week from date_day) as calendar_week

from {{ ref('time_spine_daily') }}

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

select * from fiscal_calendar
   
   models:
     - name: time_spine_yearly
       ... rest of the yearly time spine config ...  
       
     - name: fiscal_calendar
       description: A custom fiscal calendar with fiscal year and fiscal week granularities.
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
           description: "Custom fiscal year starting in October"
         - name: fiscal_week
           description: "Fiscal week, shifted by 1 week from standard calendar"
   
   dbt run --select fiscal_calendar
   dbt show --select fiscal_calendar # Use this command to preview the model if developing locally
   
   dbt sl query --metrics orders --group-by metric_time__fiscal_year
   
sources:
  - name: jaffle_shop
    tables:
      - name: orders
      - name: customers

-- query only non-test orders
    select * from {{ source('jaffle_shop', 'orders') }}
    where amount > 0
),

import_customers as (
    select * from {{ source('jaffle_shop', 'customers') }}
),

-- perform some math on import_orders

-- perform some math on import_customers
),

-- join together logical_cte_1 and logical_cte_2
)

select * from final_cte

store = StoreClient('abc123') #replace with your UUID secret
store.set('DBT_WEBHOOK_KEY', 'abc123') #replace with your <Constant name="cloud" /> API token
store.set('MODE_API_TOKEN', 'abc123') #replace with your Mode API Token
store.set('MODE_API_SECRET', 'abc123') #replace with your Mode API Secret

import hashlib
import hmac
import json

#replace with the report token you want to run
account_username = 'YOUR_MODE_ACCOUNT_USERNAME_HERE'
report_token = 'YOUR_REPORT_TOKEN_HERE'

auth_header = input_data['auth_header']
raw_body = input_data['raw_body']

**Examples:**

Example 1 (unknown):
```unknown
##### Add second semantic model to your project[​](#add-second-semantic-model-to-your-project "Direct link to Add second semantic model to your project")

Great job, you've successfully built your first semantic model! It has all the required elements: entities, dimensions, measures, and metrics.

Let’s expand your project's analytical capabilities by adding another semantic model in your other marts model, such as: `dim_customers.yml`.

After setting up your orders model:

1. In the `metrics` sub-directory, create the file `dim_customers.yml`.
2. Copy the following query into the file and click **Save**.

models/metrics/dim\_customers.yml
```

Example 2 (unknown):
```unknown
This semantic model uses simple metrics to focus on customer metrics and emphasizes customer dimensions like name, type, and order dates. It uniquely analyzes customer behavior, lifetime value, and order patterns.

#### Test and query metrics[​](#test-and-query-metrics "Direct link to Test and query metrics")

To work with metrics in dbt, you have several tools to validate or run commands. Here's how you can test and query metrics depending on your setup:

* [**Studio IDE users**](#dbt-cloud-ide-users) — Run [MetricFlow commands](https://docs.getdbt.com/docs/build/metricflow-commands.md#metricflow-commands) directly in the [Studio IDE](https://docs.getdbt.com/docs/cloud/dbt-cloud-ide/develop-in-the-cloud.md) to query/preview metrics. View metrics visually in the **Lineage** tab.
* [**Cloud CLI users**](#dbt-cloud-cli-users) — The [Cloud CLI](https://docs.getdbt.com/docs/cloud/cloud-cli-installation.md) enables you to run [MetricFlow commands](https://docs.getdbt.com/docs/build/metricflow-commands.md#metricflow-commands) to query and preview metrics directly in your command line interface.
* **dbt Core users** — Use the MetricFlow CLI for command execution. While this guide focuses on dbt users, dbt Core users can find detailed MetricFlow CLI setup instructions in the [MetricFlow commands](https://docs.getdbt.com/docs/build/metricflow-commands.md#metricflow-commands) page. Note that to use the Semantic Layer, you need to have a [Starter or Enterprise-tier account](https://www.getdbt.com/).

Alternatively, you can run commands with SQL client tools like DataGrip, DBeaver, or RazorSQL.

##### Studio IDE users[​](#studio-ide-users "Direct link to Studio IDE users")

You can use the `dbt sl` prefix before the command name to execute them in dbt. For example, to list all metrics, run `dbt sl list metrics`. For a complete list of the MetricFlow commands available in the Studio IDE, refer to the [MetricFlow commands](https://docs.getdbt.com/docs/build/metricflow-commands.md#metricflow-commandss) page.

The Studio IDE **Status button** (located in the bottom right of the editor) displays an **Error** status if there's an error in your metric or semantic model definition. You can click the button to see the specific issue and resolve it.

Once viewed, make sure you commit and merge your changes in your project.

[![Validate your metrics using the Lineage tab in the IDE.](/img/docs/dbt-cloud/semantic-layer/sl-ide-dag.png?v=2 "Validate your metrics using the Lineage tab in the IDE.")](#)Validate your metrics using the Lineage tab in the IDE.

##### Cloud CLI users[​](#cloud-cli-users "Direct link to Cloud CLI users")

This section is for Cloud CLI users. MetricFlow commands are integrated with dbt, which means you can run MetricFlow commands as soon as you install the Cloud CLI. Your account will automatically manage version control for you.

Refer to the following steps to get started:

1. Install the [Cloud CLI](https://docs.getdbt.com/docs/cloud/cloud-cli-installation.md) (if you haven't already). Then, navigate to your dbt project directory.
2. Run a dbt command, such as `dbt parse`, `dbt run`, `dbt compile`, or `dbt build`. If you don't, you'll receive an error message that begins with: "ensure that you've ran an artifacts....".
3. MetricFlow builds a semantic graph and generates a `semantic_manifest.json` file in dbt, which is stored in the `/target` directory. If using the Jaffle Shop example, run `dbt seed && dbt run` to ensure the required data is in your data platform before proceeding.

Run dbt parse to reflect metric changes

When you make changes to metrics, make sure to run `dbt parse` at a minimum to update the Semantic Layer. This updates the `semantic_manifest.json` file, reflecting your changes when querying metrics. By running `dbt parse`, you won't need to rebuild all the models.

4. Run `dbt sl --help` to confirm you have MetricFlow installed and that you can view the available commands.

5. Run `dbt sl query --metrics <metric_name> --group-by <dimension_name>` to query the metrics and dimensions. For example, to query the `order_total` and `order_count` (both metrics), and then group them by the `order_date` (dimension), you would run:
```

Example 3 (unknown):
```unknown
6. Verify that the metric values are what you expect. To further understand how the metric is being generated, you can view the generated SQL if you type `--compile` in the command line.

7. Commit and merge the code changes that contain the metric definitions.

#### Run a production job[​](#run-a-production-job "Direct link to Run a production job")

This section explains how you can perform a job run in your deployment environment in dbt to materialize and deploy your metrics. Currently, the deployment environment is only supported.

1. Once you’ve [defined your semantic models and metrics](https://docs.getdbt.com/guides/sl-snowflake-qs.md?step=10), commit and merge your metric changes in your dbt project.

2. In dbt, create a new [deployment environment](https://docs.getdbt.com/docs/deploy/deploy-environments.md#create-a-deployment-environment) or use an existing environment on dbt 1.6 or higher.

   * Note — Deployment environment is currently supported (*development experience coming soon*)

3. To create a new environment, navigate to **Deploy** in the navigation menu, select **Environments**, and then select **Create new environment**.

4. Fill in your deployment credentials with your Snowflake username and password. You can name the schema anything you want. Click **Save** to create your new production environment.

5. [Create a new deploy job](https://docs.getdbt.com/docs/deploy/deploy-jobs.md#create-and-schedule-jobs) that runs in the environment you just created. Go back to the **Deploy** menu, select **Jobs**, select **Create job**, and click **Deploy job**.

6. Set the job to run a `dbt parse` job to parse your projects and generate a [`semantic_manifest.json` artifact](https://docs.getdbt.com/reference/artifacts/sl-manifest.md) file. Although running `dbt build` isn't required, you can choose to do so if needed.

   note

   If you are on the dbt Fusion engine, add the `dbt docs generate` command to your job to successfully deploy your metrics.

7. Run the job by clicking the **Run now** button. Monitor the job's progress in real-time through the **Run summary** tab.

   Once the job completes successfully, your dbt project, including the generated documentation, will be fully deployed and available for use in your production environment. If any issues arise, review the logs to diagnose and address any errors.

What’s happening internally?

* Merging the code into your main branch allows dbt to pull those changes and build the definition in the manifest produced by the run. <br />
* Re-running the job in the deployment environment helps materialize the models, which the metrics depend on, in the data platform. It also makes sure that the manifest is up to date. <br />
* The Semantic Layer APIs pull in the most recent manifest and enables your integration to extract metadata from it.

#### Administer the Semantic Layer[​](#administer-the-semantic-layer "Direct link to Administer the Semantic Layer")

In this section, you will learn how to add credentials and create service tokens to start querying the dbt Semantic Layer. This section goes over the following topics:

* [Select environment](#1-select-environment)
* [Configure credentials and create tokens](#2-configure-credentials-and-create-tokens)
* [View connection detail](#3-view-connection-detail)
* [Add more credentials](#4-add-more-credentials)
* [Delete configuration](#delete-configuration)

You must be part of the Owner group and have the correct [license](https://docs.getdbt.com/docs/cloud/manage-access/seats-and-users.md) and [permissions](https://docs.getdbt.com/docs/cloud/manage-access/enterprise-permissions.md) to administer the Semantic Layer at the environment and project level.

* Enterprise+ and Enterprise plan:

  <!-- -->

  * Developer license with Account Admin permissions, or
  * Owner with a Developer license, assigned Project Creator, Database Admin, or Admin permissions.

* Starter plan: Owner with a Developer license.

* Free trial: You are on a free trial of the Starter plan as an Owner, which means you have access to the dbt Semantic Layer.

##### 1. Select environment[​](#1-select-environment "Direct link to 1. Select environment")

Select the environment where you want to enable the Semantic Layer:

1. Navigate to **Account settings** in the navigation menu.
2. Under **Settings**, click **Projects** and select the specific project you want to enable the Semantic Layer for.
3. In the **Project details** page, navigate to the **Semantic Layer** section. Select **Configure Semantic Layer**.

[![Semantic Layer section in the 'Project details' page](/img/docs/dbt-cloud/semantic-layer/new-sl-configure.png?v=2 "Semantic Layer section in the 'Project details' page")](#)Semantic Layer section in the 'Project details' page

4. In the **Set Up Semantic Layer Configuration** page, select the deployment environment you want for the Semantic Layer and click **Save**. This provides administrators with the flexibility to choose the environment where the Semantic Layer will be enabled.

[![Select the deployment environment to run your Semantic Layer against.](/img/docs/dbt-cloud/semantic-layer/sl-select-env.png?v=2 "Select the deployment environment to run your Semantic Layer against.")](#)Select the deployment environment to run your Semantic Layer against.

##### 2. Configure credentials and create tokens[​](#2-configure-credentials-and-create-tokens "Direct link to 2. Configure credentials and create tokens")

There are two options for setting up Semantic Layer using API tokens:

* [Add a credential and create service tokens](#add-a-credential-and-create-service-tokens)
* [Configure development credentials and create personal tokens](#configure-development-credentials-and-create-a-personal-token)

###### Add a credential and create service tokens[​](#add-a-credential-and-create-service-tokens "Direct link to Add a credential and create service tokens")

The first option is to use [service tokens](https://docs.getdbt.com/docs/dbt-cloud-apis/service-tokens.md) for authentication which are tied to an underlying data platform credential that you configure. The credential configured is used to execute queries that the Semantic Layer issues against your data platform.

This credential controls the physical access to underlying data accessed by the Semantic Layer, and all access policies set in the data platform for this credential will be respected.

| Feature                                             | Starter plan                                                 | Enterprise+ and Enterprise plan                                                                                                                                 |
| --------------------------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Service tokens                                      | Can create multiple service tokens linked to one credential. | Can use multiple credentials and link multiple service tokens to each credential. Note that you cannot link a single service token to more than one credential. |
| Credentials per project                             | One credential per project.                                  | Can [add multiple](#4-add-more-credentials) credentials per project.                                                                                            |
| Link multiple service tokens to a single credential | ✅                                                           | ✅                                                                                                                                                              |

*If you're on a Starter plan and need to add more credentials, consider upgrading to our [Enterprise+ or Enterprise plan](https://www.getdbt.com/contact). All Enterprise users can refer to [Add more credentials](#4-add-more-credentials) for detailed steps on adding multiple credentials.*

###### 1. Select deployment environment[​](#1--select-deployment-environment "Direct link to 1.  Select deployment environment")

* After selecting the deployment environment, you should see the **Credentials & service tokens** page.
* Click the **Add Semantic Layer credential** button.

###### 2. Configure credential[​](#2-configure-credential "Direct link to 2. Configure credential")

* In the **1. Add credentials** section, enter the credentials specific to your data platform that you want the Semantic Layer to use.

* Use credentials with minimal privileges. The Semantic Layer requires read access to the schema(s) containing the dbt models used in your semantic models for downstream applications

* Use [Extended Attributes](https://docs.getdbt.com/docs/dbt-cloud-environments.md#extended-attributes) and [Environment Variables](https://docs.getdbt.com/docs/build/environment-variables.md) when connecting to the Semantic Layer. If you set a value directly in the Semantic Layer Credentials, it will have a higher priority than Extended Attributes. When using environment variables, the default value for the environment will be used.

  For example, set the warehouse by using `{{env_var('DBT_WAREHOUSE')}}` in your Semantic Layer credentials.

  Similarly, if you set the account value using `{{env_var('DBT_ACCOUNT')}}` in Extended Attributes, dbt will check both the Extended Attributes and the environment variable.

[![Add credentials and map them to a service token. ](/img/docs/dbt-cloud/semantic-layer/sl-add-credential.png?v=2 "Add credentials and map them to a service token. ")](#)Add credentials and map them to a service token.

###### 3. Create or link service tokens[​](#3-create-or-link-service-tokens "Direct link to 3. Create or link service tokens")

* If you have permission to create service tokens, you’ll see the [**Map new service token** option](https://docs.getdbt.com/docs/use-dbt-semantic-layer/setup-sl.md#map-service-tokens-to-credentials) after adding the credential. Name the token, set permissions to 'Semantic Layer Only' and 'Metadata Only', and click **Save**.
* Once the token is generated, you won't be able to view this token again, so make sure to record it somewhere safe.
* If you don’t have access to create service tokens, you’ll see a message prompting you to contact your admin to create one for you. Admins can create and link tokens as needed.

[![If you don’t have access to create service tokens, you can create a credential and contact your admin to create one for you.](/img/docs/dbt-cloud/semantic-layer/sl-credential-no-service-token.png?v=2 "If you don’t have access to create service tokens, you can create a credential and contact your admin to create one for you.")](#)If you don’t have access to create service tokens, you can create a credential and contact your admin to create one for you.

info

* Starter plans can create multiple service tokens that link to a single underlying credential, but each project can only have one credential.
* All Enterprise plans can [add multiple credentials](#4-add-more-credentials) and map those to service tokens for tailored access.

[Book a free live demo](https://www.getdbt.com/contact) to discover the full potential of dbt Enterprise and higher plans.

###### Configure development credentials and create a personal token[​](#configure-development-credentials-and-create-a-personal-token "Direct link to Configure development credentials and create a personal token")

Using [personal access tokens (PATs)](https://docs.getdbt.com/docs/dbt-cloud-apis/user-tokens.md) is also a supported authentication method for the dbt Semantic Layer. This enables user-level authentication, reducing the need for sharing tokens between users. When you authenticate using PATs, queries are run using your personal development credentials.

To use PATs in Semantic Layer:

1. Configure your development credentials.

   <!-- -->

   1. Click your account name at the bottom left-hand menu and go to **Account settings** > **Credentials**.
   2. Select your project.
   3. Click **Edit**.
   4. Go to **Development credentials** and enter your details.
   5. Click **Save**.

2. [Create a personal access token](https://docs.getdbt.com/docs/dbt-cloud-apis/user-tokens.md). Make sure to copy the token.

You can use the generated PAT as the authentication method for Semantic Layer [APIs](https://docs.getdbt.com/docs/dbt-cloud-apis/sl-api-overview.md) and [integrations](https://docs.getdbt.com/docs/cloud-integrations/avail-sl-integrations.md).

##### 3. View connection detail[​](#3-view-connection-detail "Direct link to 3. View connection detail")

1. Go back to the **Project details** page for connection details to connect to downstream tools.

2. Copy and share the Environment ID, service or personal token, Host, as well as the service or personal token name to the relevant teams for BI connection setup. If your tool uses the GraphQL API, save the GraphQL API host information instead of the JDBC URL.

   For info on how to connect to other integrations, refer to [Available integrations](https://docs.getdbt.com/docs/cloud-integrations/avail-sl-integrations.md).

[![After configuring, you'll be provided with the connection details to connect to you downstream tools.](/img/docs/dbt-cloud/semantic-layer/sl-configure-example.png?v=2 "After configuring, you'll be provided with the connection details to connect to you downstream tools.")](#)After configuring, you'll be provided with the connection details to connect to you downstream tools.

##### 4. Add more credentials [Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[​](#4-add-more-credentials- "Direct link to 4-add-more-credentials-")

All dbt Enterprise plans can optionally add multiple credentials and map them to service tokens, offering more granular control and tailored access for different teams, which can then be shared to relevant teams for BI connection setup. These credentials control the physical access to underlying data accessed by the Semantic Layer.

We recommend configuring credentials and service tokens to reflect your teams and their roles. For example, create tokens or credentials that align with your team's needs, such as providing access to finance-related schemas to the Finance team.

 Considerations for linking credentials

* Admins can link multiple service tokens to a single credential within a project, but each service token can only be linked to one credential per project.

* When you send a request through the APIs, the service token of the linked credential will follow access policies of the underlying view and tables used to build your semantic layer requests.

* Use [Extended Attributes](https://docs.getdbt.com/docs/dbt-cloud-environments.md#extended-attributes) and [Environment Variables](https://docs.getdbt.com/docs/build/environment-variables.md) when connecting to the Semantic Layer. If you set a value directly in the Semantic Layer Credentials, it will have a higher priority than Extended Attributes. When using environment variables, the default value for the environment will be used.

  For example, set the warehouse by using `{{env_var('DBT_WAREHOUSE')}}` in your Semantic Layer credentials.

  Similarly, if you set the account value using `{{env_var('DBT_ACCOUNT')}}` in Extended Attributes, dbt will check both the Extended Attributes and the environment variable.

###### 1. Add more credentials[​](#1-add-more-credentials "Direct link to 1. Add more credentials")

* After configuring your environment, on the **Credentials & service tokens** page, click the **Add Semantic Layer credential** button to create multiple credentials and map them to a service token. <br />
* In the **1. Add credentials** section, fill in the data platform's credential fields. We recommend using “read-only” credentials.
  <!-- -->
  [![Add credentials and map them to a service token. ](/img/docs/dbt-cloud/semantic-layer/sl-add-credential.png?v=2 "Add credentials and map them to a service token. ")](#)Add credentials and map them to a service token.

###### 2. Map service tokens to credentials[​](#2-map-service-tokens-to-credentials "Direct link to 2. Map service tokens to credentials")

* In the **2. Map new service token** section, [map a service token to the credential](https://docs.getdbt.com/docs/use-dbt-semantic-layer/setup-sl.md#map-service-tokens-to-credentials) you configured in the previous step. dbt automatically selects the service token permission set you need (Semantic Layer Only and Metadata Only).
* To add another service token during configuration, click **Add Service Token**.
* You can link more service tokens to the same credential later on in the **Semantic Layer Configuration Details** page. To add another service token to an existing Semantic Layer configuration, click **Add service token** under the **Linked service tokens** section.
* Click **Save** to link the service token to the credential. Remember to copy and save the service token securely, as it won't be viewable again after generation.

[![Use the configuration page to manage multiple credentials or link or unlink service tokens for more granular control.](/img/docs/dbt-cloud/semantic-layer/sl-credentials-service-token.png?v=2 "Use the configuration page to manage multiple credentials or link or unlink service tokens for more granular control.")](#)Use the configuration page to manage multiple credentials or link or unlink service tokens for more granular control.

###### 3. Delete credentials[​](#3-delete-credentials "Direct link to 3. Delete credentials")

* To delete a credential, go back to the **Credentials & service tokens** page.

* Under **Linked Service Tokens**, click **Edit** and, select **Delete Credential** to remove a credential.

  When you delete a credential, any service tokens mapped to that credential in the project will no longer work and will break for any end users.

##### Delete configuration[​](#delete-configuration "Direct link to Delete configuration")

You can delete the entire Semantic Layer configuration for a project. Note that deleting the Semantic Layer configuration will remove all credentials and unlink all service tokens to the project. It will also cause all queries to the Semantic Layer to fail.

Follow these steps to delete the Semantic Layer configuration for a project:

1. Navigate to the **Project details** page.
2. In the **Semantic Layer** section, select **Delete Semantic Layer**.
3. Confirm the deletion by clicking **Yes, delete semantic layer** in the confirmation pop up.

To re-enable the dbt Semantic Layer setup in the future, you will need to recreate your setup configurations by following the [previous steps](#set-up-dbt-semantic-layer). If your semantic models and metrics are still in your project, no changes are needed. If you've removed them, you'll need to set up the YAML configs again.

[![Delete the Semantic Layer configuration for a project.](/img/docs/dbt-cloud/semantic-layer/sl-delete-config.png?v=2 "Delete the Semantic Layer configuration for a project.")](#)Delete the Semantic Layer configuration for a project.

#### Additional configuration[​](#additional-configuration "Direct link to Additional configuration")

The following are the additional flexible configurations for Semantic Layer credentials.

##### Map service tokens to credentials[​](#map-service-tokens-to-credentials "Direct link to Map service tokens to credentials")

* After configuring your environment, you can map additional service tokens to the same credential if you have the required [permissions](https://docs.getdbt.com/docs/cloud/manage-access/about-user-access.md#permission-sets).
* Go to the **Credentials & service tokens** page and click the **+Add Service Token** button in the **Linked Service Tokens** section.
* Type the service token name and select the permission set you need (Semantic Layer Only and Metadata Only).
* Click **Save** to link the service token to the credential.
* Remember to copy and save the service token securely, as it won't be viewable again after generation.

[![Map additional service tokens to a credential.](/img/docs/dbt-cloud/semantic-layer/sl-add-service-token.gif?v=2 "Map additional service tokens to a credential.")](#)Map additional service tokens to a credential.

##### Unlink service tokens[​](#unlink-service-tokens "Direct link to Unlink service tokens")

* Unlink a service token from the credential by clicking **Unlink** under the **Linked service tokens** section. If you try to query the Semantic Layer with an unlinked credential, you'll experience an error in your BI tool because no valid token is mapped.

##### Manage from service token page[​](#manage-from-service-token-page "Direct link to Manage from service token page")

**View credential from service token**

* View your Semantic Layer credential directly by navigating to the **API tokens** and then **Service tokens** page.
* Select the service token to view the credential it's linked to. This is useful if you want to know which service tokens are mapped to credentials in your project.

###### Create a new service token[​](#create-a-new-service-token "Direct link to Create a new service token")

* From the **Service tokens** page, create a new service token and map it to the credential(s) (assuming the semantic layer permission exists). This is useful if you want to create a new service token and directly map it to a credential in your project.
* Make sure to select the correct permission set for the service token (Semantic Layer Only and Metadata Only).

[![Create a new service token and map credentials directly on the separate 'Service tokens page'.](/img/docs/dbt-cloud/semantic-layer/sl-create-service-token-page.png?v=2 "Create a new service token and map credentials directly on the separate 'Service tokens page'.")](#)Create a new service token and map credentials directly on the separate 'Service tokens page'.

#### Query the Semantic Layer[​](#query-the-semantic-layer "Direct link to Query the Semantic Layer")

This page will guide you on how to connect and use the following integrations to query your metrics:

* [Connect and query with Google Sheets](#connect-and-query-with-google-sheets)
* [Connect and query with Hex](#connect-and-query-with-hex)
* [Connect and query with Sigma](#connect-and-query-with-sigma)

The Semantic Layer enables you to connect and query your metric with various available tools like [PowerBI](https://docs.getdbt.com/docs/cloud-integrations/semantic-layer/power-bi.md), [Google Sheets](https://docs.getdbt.com/docs/cloud-integrations/semantic-layer/gsheets.md), [Hex](https://learn.hex.tech/docs/connect-to-data/data-connections/dbt-integration#dbt-semantic-layer-integration), [Microsoft Excel](https://docs.getdbt.com/docs/cloud-integrations/semantic-layer/excel.md), [Tableau](https://docs.getdbt.com/docs/cloud-integrations/semantic-layer/tableau.md), and more.

Query metrics using other tools such as [first-class integrations](https://docs.getdbt.com/docs/cloud-integrations/avail-sl-integrations.md), [Semantic Layer APIs](https://docs.getdbt.com/docs/dbt-cloud-apis/sl-api-overview.md), and [exports](https://docs.getdbt.com/docs/use-dbt-semantic-layer/exports.md) to expose tables of metrics and dimensions in your data platform and create a custom integrations.

##### Connect and query with Google Sheets[​](#connect-and-query-with-google-sheets "Direct link to Connect and query with Google Sheets")

The Google Sheets integration allows you to query your metrics using Google Sheets. This section will guide you on how to connect and use the Google Sheets integration.

To query your metrics using Google Sheets:

1. Make sure you have a [Gmail](http://gmail.com/) account.

2. To set up Google Sheets and query your metrics, follow the detailed instructions on [Google Sheets integration](https://docs.getdbt.com/docs/cloud-integrations/semantic-layer/gsheets.md).

3. Start exploring and querying metrics!

   <!-- -->

   * Query a metric, like `order_total`, and filter it with a dimension, like `order_date`.
   * You can also use the `group_by` parameter to group your metrics by a specific dimension.

[![Use the dbt Semantic Layer's Google Sheet integration to query metrics with a Query Builder menu.](/img/docs/dbt-cloud/semantic-layer/sl-gsheets.jpg?v=2 "Use the dbt Semantic Layer's Google Sheet integration to query metrics with a Query Builder menu.")](#)Use the dbt Semantic Layer's Google Sheet integration to query metrics with a Query Builder menu.

##### Connect and query with Hex[​](#connect-and-query-with-hex "Direct link to Connect and query with Hex")

This section will guide you on how to use the Hex integration to query your metrics using Hex. Select the appropriate tab based on your connection method:

* Query Semantic Layer with Hex
* Getting started with the Semantic Layer workshop

1. Navigate to the [Hex login page](https://app.hex.tech/login).
2. Sign in or make an account (if you don’t already have one).

* You can make Hex free trial accounts with your work email or a .edu email.

3. In the top left corner of your page, click on the **HEX** icon to go to the home page.
4. Then, click the **+ New project** button on the top right.

[![Click the '+ New project' button on the top right](/img/docs/dbt-cloud/semantic-layer/hex_new.png?v=2 "Click the '+ New project' button on the top right")](#)Click the '+ New project' button on the top right

5. Go to the menu on the left side and select **Data browser**. Then select **Add a data connection**.
6. Click **Snowflake**. Provide your data connection a name and description. You don't need to your data warehouse credentials to use the Semantic Layer.

[![Select 'Data browser' and then 'Add a data connection' to connect to Snowflake.](/img/docs/dbt-cloud/semantic-layer/hex_new_data_connection.png?v=2 "Select 'Data browser' and then 'Add a data connection' to connect to Snowflake.")](#)Select 'Data browser' and then 'Add a data connection' to connect to Snowflake.

7. Under **Integrations**, toggle the dbt switch to the right to enable the dbt integration.

[![Click on the dbt toggle to enable the integration. ](/img/docs/dbt-cloud/semantic-layer/hex_dbt_toggle.png?v=2 "Click on the dbt toggle to enable the integration. ")](#)Click on the dbt toggle to enable the integration.

8. Enter the following information:

   <!-- -->

   * Select your version of dbt as 1.6 or higher
   * Enter your Environment ID
   * Enter your service or personal token
   * Make sure to click on the **Use Semantic Layer** toggle. This way, all queries are routed through dbt.
   * Click **Create connection** in the bottom right corner.

9. Hover over **More** on the menu shown in the following image and select **Semantic Layer**.

[![Hover over 'More' on the menu and select 'dbt Semantic Layer'.](/img/docs/dbt-cloud/semantic-layer/hex_make_sl_cell.png?v=2 "Hover over 'More' on the menu and select 'dbt Semantic Layer'.")](#)Hover over 'More' on the menu and select 'dbt Semantic Layer'.

10. Now, you should be able to query metrics using Hex! Try it yourself:

    <!-- -->

    * Create a new cell and pick a metric.
    * Filter it by one or more dimensions.
    * Create a visualization.

1) Click on the link provided to you in the workshop’s chat.
   <!-- -->
   * Look at the **Pinned message** section of the chat if you don’t see it right away.
2) Enter your email address in the textbox provided. Then, select **SQL and Python** to be taken to Hex’s home screen.

[![The 'Welcome to Hex' homepage.](/img/docs/dbt-cloud/semantic-layer/welcome_to_hex.png?v=2 "The 'Welcome to Hex' homepage.")](#)The 'Welcome to Hex' homepage.

3. Then click the purple Hex button in the top left corner.
4. Click the **Collections** button on the menu on the left.
5. Select the **Semantic Layer Workshop** collection.
6. Click the **Getting started with the Semantic Layer** project collection.

[![Click 'Collections' to select the 'Semantic Layer Workshop' collection.](/img/docs/dbt-cloud/semantic-layer/hex_collections.png?v=2 "Click 'Collections' to select the 'Semantic Layer Workshop' collection.")](#)Click 'Collections' to select the 'Semantic Layer Workshop' collection.

7. To edit this Hex notebook, click the **Duplicate** button from the project dropdown menu (as displayed in the following image). This creates a new copy of the Hex notebook that you own.

[![Click the 'Duplicate' button from the project dropdown menu to create a Hex notebook copy.](/img/docs/dbt-cloud/semantic-layer/hex_duplicate.png?v=2 "Click the 'Duplicate' button from the project dropdown menu to create a Hex notebook copy.")](#)Click the 'Duplicate' button from the project dropdown menu to create a Hex notebook copy.

8. To make it easier to find, rename your copy of the Hex project to include your name.

[![Rename your Hex project to include your name.](/img/docs/dbt-cloud/semantic-layer/hex_rename.png?v=2 "Rename your Hex project to include your name.")](#)Rename your Hex project to include your name.

9. Now, you should be able to query metrics using Hex! Try it yourself with the following example queries:

   * In the first cell, you can see a table of the `order_total` metric over time. Add the `order_count` metric to this table.
   * The second cell shows a line graph of the `order_total` metric over time. Play around with the graph! Try changing the time grain using the **Time unit** drop-down menu.
   * The next table in the notebook, labeled “Example\_query\_2”, shows the number of customers who have made their first order on a given day. Create a new chart cell. Make a line graph of `first_ordered_at` vs `customers` to see how the number of new customers each day changes over time.
   * Create a new semantic layer cell and pick one or more metrics. Filter your metric(s) by one or more dimensions.

[![Query metrics using Hex ](/img/docs/dbt-cloud/semantic-layer/hex_make_sl_cell.png?v=2 "Query metrics using Hex ")](#)Query metrics using Hex

##### Connect and query with Sigma[​](#connect-and-query-with-sigma "Direct link to Connect and query with Sigma")

This section will guide you on how to use the Sigma integration to query your metrics using Sigma. If you already have a Sigma account, simply log in and skip to step 6. Otherwise, you'll be using a Sigma account you'll create with Snowflake Partner Connect.

1. Go back to your Snowflake account. In the Snowflake UI, click on the home icon in the upper left corner. In the left sidebar, select **Data Products**. Then, select **Partner Connect**. Find the Sigma tile by scrolling or by searching for Sigma in the search bar. Click the tile to connect to Sigma.

[![Click the '+ New project' button on the top right](/img/docs/dbt-cloud/semantic-layer/sl-sigma-partner-connect.png?v=2 "Click the '+ New project' button on the top right")](#)Click the '+ New project' button on the top right

2. Select the Sigma tile from the list. Click the **Optional Grant** dropdown menu. Write **RAW** and **ANALYTICS** in the text box and then click **Connect**.

[![Click the '+ New project' button on the top right](/img/docs/dbt-cloud/semantic-layer/sl-sigma-optional-grant.png?v=2 "Click the '+ New project' button on the top right")](#)Click the '+ New project' button on the top right

3. Make up a company name and URL to use. It doesn’t matter what URL you use, as long as it’s unique.

[![Click the '+ New project' button on the top right](/img/docs/dbt-cloud/semantic-layer/sl-sigma-company-name.png?v=2 "Click the '+ New project' button on the top right")](#)Click the '+ New project' button on the top right

4. Enter your name and email address. Choose a password for your account.

[![Click the '+ New project' button on the top right](/img/docs/dbt-cloud/semantic-layer/sl-sigma-create-profile.png?v=2 "Click the '+ New project' button on the top right")](#)Click the '+ New project' button on the top right

5. Great! You now have a Sigma account. Before we get started, go back to Snowlake and open a blank worksheet. Run these lines.

* `grant all privileges on all views in schema analytics.SCHEMA to role pc_sigma_role;`
* `grant all privileges on all tables in schema analytics.SCHEMA to role pc_sigma_role;`

6. Click on your bubble in the top right corner. Click the **Administration** button from the dropdown menu.

[![Click the '+ New project' button on the top right](/img/docs/dbt-cloud/semantic-layer/sl-sigma-admin.png?v=2 "Click the '+ New project' button on the top right")](#)Click the '+ New project' button on the top right

7. Scroll down to the integrations section, then select **Add** next to the dbt integration.

[![Click the '+ New project' button on the top right](/img/docs/dbt-cloud/semantic-layer/sl-sigma-add-integration.png?v=2 "Click the '+ New project' button on the top right")](#)Click the '+ New project' button on the top right

8. In the **dbt Integration** section, fill out the required fields, and then hit save:

* Your dbt [service account token](https://docs.getdbt.com/docs/dbt-cloud-apis/service-tokens.md) or [personal access tokens](https://docs.getdbt.com/docs/dbt-cloud-apis/user-tokens.md).
* Your access URL of your existing Sigma dbt integration. Use `cloud.getdbt.com` as your access URL.
* Your dbt Environment ID.

[![Click the '+ New project' button on the top right](/img/docs/dbt-cloud/semantic-layer/sl-sigma-add-info.png?v=2 "Click the '+ New project' button on the top right")](#)Click the '+ New project' button on the top right

9. Return to the Sigma home page. Create a new workbook.

[![Click the '+ New project' button on the top right](/img/docs/dbt-cloud/semantic-layer/sl-sigma-make-workbook.png?v=2 "Click the '+ New project' button on the top right")](#)Click the '+ New project' button on the top right

10. Click on **Table**, then click on **SQL**. Select Snowflake `PC_SIGMA_WH` as your data connection.

[![Click the '+ New project' button on the top right](/img/docs/dbt-cloud/semantic-layer/sl-sigma-make-table.png?v=2 "Click the '+ New project' button on the top right")](#)Click the '+ New project' button on the top right

11. Go ahead and query a working metric in your project! For example, let's say you had a metric that measures various order-related values. Here’s how you would query it:
```

Example 4 (unknown):
```unknown
#### What's next[​](#whats-next "Direct link to What's next")

Great job on completing the comprehensive Semantic Layer guide 🎉! You should hopefully have gained a clear understanding of what the Semantic Layer is, its purpose, and when to use it in your projects.

You've learned how to:

* Set up your Snowflake environment and dbt, including creating worksheets and loading data.
* Connect and configure dbt with Snowflake.
* Build, test, and manage dbt projects, focusing on metrics and semantic layers.
* Run production jobs and query metrics with our available integrations.

For next steps, you can start defining your own metrics and learn additional configuration options such as [exports](https://docs.getdbt.com/docs/use-dbt-semantic-layer/exports.md), [fill null values](https://docs.getdbt.com/docs/build/advanced-topics.md), [implementing Mesh with the Semantic Layer](https://docs.getdbt.com/docs/use-dbt-semantic-layer/sl-faqs.md#how-can-i-implement-dbt-mesh-with-the-dbt-semantic-layer), and more.

Here are some additional resources to help you continue your journey:

* [Semantic Layer FAQs](https://docs.getdbt.com/docs/use-dbt-semantic-layer/sl-faqs.md)
* [Available integrations](https://docs.getdbt.com/docs/cloud-integrations/avail-sl-integrations.md)
* Demo on [how to define and query metrics with MetricFlow](https://www.loom.com/share/60a76f6034b0441788d73638808e92ac?sid=861a94ac-25eb-4fd8-a310-58e159950f5a)
* [Join our live demos](https://www.getdbt.com/resources/webinars/dbt-cloud-demos-with-experts)

#### Was this page helpful?

YesNo

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.


---

### Quickstart with dbt Mesh

[Back to guides](https://docs.getdbt.com/guides.md)

dbt platform

Quickstart

Intermediate

[Menu ]()

#### Introduction[​](#introduction "Direct link to Introduction")

Mesh is a framework that helps organizations scale their teams and data assets effectively. It promotes governance best practices and breaks large projects into manageable sections — for faster data development. Mesh is available for [dbt Enterprise](https://www.getdbt.com/) accounts.

This guide will teach you how to set up a multi-project design using foundational concepts of [Mesh](https://www.getdbt.com/blog/what-is-data-mesh-the-definition-and-importance-of-data-mesh) and how to implement a data mesh in dbt:

* Set up a foundational project called “Jaffle | Data Analytics”
* Set up a downstream project called “Jaffle | Finance”
* Add model access, versions, and contracts
* Set up a dbt job that is triggered on completion of an upstream job

For more information on why data mesh is important, read this post: [What is data mesh? The definition and importance of data mesh](https://www.getdbt.com/blog/what-is-data-mesh-the-definition-and-importance-of-data-mesh).

Videos for you

You can check out [dbt Fundamentals](https://learn.getdbt.com/courses/dbt-fundamentals) for free if you're interested in course learning with videos.

You can also watch the [YouTube video on dbt and Snowflake](https://www.youtube.com/watch?v=kbCkwhySV_I\&list=PL0QYlrC86xQm7CoOH6RS7hcgLnd3OQioG).

##### Related content:[​](#related-content "Direct link to Related content:")

* [Data mesh concepts: What it is and how to get started](https://www.getdbt.com/blog/data-mesh-concepts-what-it-is-and-how-to-get-started)
* [Deciding how to structure your Mesh](https://docs.getdbt.com/best-practices/how-we-mesh/mesh-3-structures.md)
* [Mesh best practices guide](https://docs.getdbt.com/best-practices/how-we-mesh/mesh-4-implementation.md)
* [Mesh FAQs](https://docs.getdbt.com/best-practices/how-we-mesh/mesh-5-faqs.md)

#### Prerequisites​[​](#prerequisites "Direct link to Prerequisites​")

To leverage Mesh, you need the following:

* You must have a [dbt Enterprise-tier account](https://www.getdbt.com/get-started/enterprise-contact-pricing) [Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")

* You have access to a cloud data platform, permissions to load the sample data tables, and dbt permissions to create new projects.

* This guide uses the Jaffle Shop sample data, including `customers`, `orders`, and `payments` tables. Follow the provided instructions to load this data into your respective data platform:

  <!-- -->

  * [Snowflake](https://docs.getdbt.com/guides/snowflake.md?step=3)
  * [Databricks](https://docs.getdbt.com/guides/databricks.md?step=3)
  * [Redshift](https://docs.getdbt.com/guides/redshift.md?step=3)
  * [BigQuery](https://docs.getdbt.com/guides/bigquery.md?step=3)
  * [Fabric](https://docs.getdbt.com/guides/microsoft-fabric.md?step=2)
  * [Starburst Galaxy](https://docs.getdbt.com/guides/starburst-galaxy.md?step=2)

This guide assumes you have experience with or fundamental knowledge of dbt. Take the [dbt Fundamentals](https://learn.getdbt.com/courses/dbt-fundamentals) course first if you are brand new to dbt.

#### Create and configure two projects[​](#create-and-configure-two-projects "Direct link to Create and configure two projects")

In this section, you'll create two new, empty projects in dbt to serve as your foundational and downstream projects:

* **Foundational projects** (or upstream projects) typically contain core models and datasets that serve as the base for further analysis and reporting.
* **Downstream projects** build on these foundations, often adding more specific transformations or business logic for dedicated teams or purposes.

For example, the always-enterprising and fictional account "Jaffle Labs" will create two projects for their data analytics and finance team: Jaffle | Data Analytics and Jaffle | Finance.

[![Create two new dbt projects named 'Jaffle | Data Analytics' and 'Jaffle Finance' ](/img/guides/dbt-mesh/project_names.png?v=2 "Create two new dbt projects named 'Jaffle | Data Analytics' and 'Jaffle Finance' ")](#)Create two new dbt projects named 'Jaffle | Data Analytics' and 'Jaffle Finance'

To [create](https://docs.getdbt.com/docs/cloud/about-cloud-setup.md) a new project in dbt:

1. From **Account settings**, go to **Projects**. Click **New project**.

2. Enter a project name and click **Continue**.

   <!-- -->

   * Use "Jaffle | Data Analytics" for one project
   * Use "Jaffle | Finance" for the other project

3. Select your data platform, then **Next** to set up your connection.

4. In the **Configure your environment** section, enter the **Settings** for your new project.

5. Click **Test Connection**. This verifies that dbt can access your data platform account.

6. Click **Next** if the test succeeded. If it fails, you might need to go back and double-check your settings.

   <!-- -->

   * For this guide, make sure you create a single [development](https://docs.getdbt.com/docs/dbt-cloud-environments.md#create-a-development-environment) and [Deployment](https://docs.getdbt.com/docs/deploy/deploy-environments.md) per project.

     <!-- -->

     * For "Jaffle | Data Analytics", set the default database to `jaffle_da`.
     * For "Jaffle | Finance", set the default database to `jaffle_finance`.

7. Continue the prompts to complete the project setup. Once configured, each project should have:

   <!-- -->

   * A data platform connection
   * New git repo
   * One or more [environments](https://docs.getdbt.com/docs/deploy/deploy-environments.md) (such as development, deployment)

[![Navigate to Account settings.](/img/guides/dbt-ecosystem/dbt-python-snowpark/5-development-schema-name/1-settings-gear-icon.png?v=2 "Navigate to Account settings.")](#)Navigate to Account settings.

[![Select projects from the menu.](/img/guides/dbt-mesh/select_projects.png?v=2 "Select projects from the menu.")](#)Select projects from the menu.

[![Create a new project in the Studio IDE.](/img/guides/dbt-mesh/create_a_new_project.png?v=2 "Create a new project in the Studio IDE.")](#)Create a new project in the Studio IDE.

[![Name your project.](/img/guides/dbt-mesh/enter_project_name.png?v=2 "Name your project.")](#)Name your project.

[![Select the relevant connection for your projects.](/img/guides/dbt-mesh/select_a_connection.png?v=2 "Select the relevant connection for your projects.")](#)Select the relevant connection for your projects.

##### Create a production environment[​](#create-a-production-environment "Direct link to Create a production environment")

In dbt, each project can have one deployment environment designated as "Production.". You must set up a ["Production" or "Staging" deployment environment](https://docs.getdbt.com/docs/deploy/deploy-environments.md) for each project you want to "mesh" together. This enables you to leverage Catalog in the [later steps](https://docs.getdbt.com/guides/mesh-qs.md?step=5#create-and-run-a-dbt-cloud-job) of this guide.

To set a production environment:

1. Navigate to **Deploy** -> **Environments**, then click **Create New Environment**.
2. Select **Deployment** as the environment type.
3. Under **Set deployment type**, select the **Production** button.
4. Select the dbt version.
5. Continue filling out the fields as necessary in the **Deployment connection** and **Deployment credentials** sections.
6. Click **Test Connection** to confirm the deployment connection.
7. Click **Save** to create a production environment.

[![Set your production environment as the default environment in your Environment Settings](/img/docs/dbt-cloud/using-dbt-cloud/prod-settings-1.png?v=2 "Set your production environment as the default environment in your Environment Settings")](#)Set your production environment as the default environment in your Environment Settings

#### Set up a foundational project[​](#set-up-a-foundational-project "Direct link to Set up a foundational project")

This upstream project is where you build your core data assets. This project will contain the raw data sources, staging models, and core business logic.

dbt enables data practitioners to develop in their tool of choice and comes equipped with a local [dbt CLI](https://docs.getdbt.com/docs/cloud/cloud-cli-installation.md) or in-browser [Studio IDE](https://docs.getdbt.com/docs/cloud/dbt-cloud-ide/develop-in-the-cloud.md).

In this section of the guide, you will set the "Jaffle | Data Analytics" project as your foundational project using the Studio IDE.

1. First, navigate to the **Develop** page to verify your setup.
2. Click **Initialize dbt project** if you’ve started with an empty repo.
3. Delete the `models/example` folder.
4. Navigate to the `dbt_project.yml` file and rename the project (line 5) from `my_new_project` to `analytics`.
5. In your `dbt_project.yml` file, remove lines 39-42 (the `my_new_project` model reference).
6. In the **File Catalog**, hover over the project directory and click the **...**, then select **Create file**.
7. Create two new folders: `models/staging` and `models/core`.

##### Staging layer[​](#staging-layer "Direct link to Staging layer")

Now that you've set up the foundational project, let's start building the data assets. Set up the staging layer as follows:

1. Create a new YAML file `models/staging/sources.yml`.
2. Declare the sources by copying the following into the file and clicking **Save**.

models/staging/sources.yml
```

---

## Run all resources tagged "order_metrics" and "hourly"

**URL:** llms-txt#run-all-resources-tagged-"order_metrics"-and-"hourly"

**Contents:**
  - target_database
  - target_schema
  - Teradata configurations
  - Test selection examples

dbt build --select tag:order_metrics tag:hourly

sources:
  - name: ecom
    schema: raw
    description: E-commerce data for the Jaffle Shop
    config:
      tags:
        my_tag: "my_value". # invalid
    tables:
      - name: raw_customers
        config:
          tags:
            my_tag: "my_value". # invalid

Field config.tags: {'my_tag': 'my_value'} is not valid for source (ecom)

exposures:
  - name: my_exposure
    config:
      tags: ['exposure_tag'] # changed to config in v1.10
    ...

sources:
  - name: source_name
    config:
      tags: ['top_level'] # changed to config in v1.10

tables:
      - name: table_name
        config:
          tags: ['table_level'] # changed to config in v1.10

columns:
          - name: column_name
            config:
              tags: ['column_level'] # changed to config in v1.10 and backported to 1.9
            data_tests:
              - unique:
                config:
                  tags: ['test_level'] # changed to config in v1.10

dbt test --select tag:top_level
dbt test --select tag:table_level
dbt test --select tag:column_level
dbt test --select tag:test_level

snapshots:
  <resource-path>:
    +target_database: string

{{ config(
  target_database="string"
) }}

Encountered an error:
Runtime Error
  Cross-db references not allowed in redshift (raw vs analytics)

snapshots:
  +target_database: snapshots

snapshots:
  +target_database: "{% if target.name == 'dev' %}dev{% else %}{{ target.database }}{% endif %}"

{{
    config(
      target_database=generate_database_name('snapshots')
    )
}}

snapshots:
  <resource-path>:
    +target_schema: string

{{ config(
      target_schema="string"
) }}

snapshots:
  +target_schema: snapshots

seeds:
    +quote_columns: false  #or `true` if you have CSV column headers with spaces
  
    {{
      config(
          materialized="table",
          table_kind="SET"
      )
    }}
    
    seeds:
      <project-name>:
        table_kind: "SET"
    
  { MAP = map_name [COLOCATE USING colocation_name] |
    [NO] FALLBACK [PROTECTION] |
    WITH JOURNAL TABLE = table_specification |
    [NO] LOG |
    [ NO | DUAL ] [BEFORE] JOURNAL |
    [ NO | DUAL | LOCAL | NOT LOCAL ] AFTER JOURNAL |
    CHECKSUM = { DEFAULT | ON | OFF } |
    FREESPACE = integer [PERCENT] |
    mergeblockratio |
    datablocksize |
    blockcompression |
    isolated_loading
  }
  
    { DEFAULT MERGEBLOCKRATIO |
      MERGEBLOCKRATIO = integer [PERCENT] |
      NO MERGEBLOCKRATIO
    }
    
    DATABLOCKSIZE = {
      data_block_size [ BYTES | KBYTES | KILOBYTES ] |
      { MINIMUM | MAXIMUM | DEFAULT } DATABLOCKSIZE
    }
    
    BLOCKCOMPRESSION = { AUTOTEMP | MANUAL | ALWAYS | NEVER | DEFAULT }
      [, BLOCKCOMPRESSIONALGORITHM = { ZLIB | ELZS_H | DEFAULT } ]
      [, BLOCKCOMPRESSIONLEVEL = { value | DEFAULT } ]
    
    WITH [NO] [CONCURRENT] ISOLATED LOADING [ FOR { ALL | INSERT | NONE } ]
    
    {{
      config(
          materialized="table",
          table_option="NO FALLBACK"
      )
    }}
    
    {{
      config(
          materialized="table",
          table_option="NO FALLBACK, NO JOURNAL"
      )
    }}
    
    {{
      config(
          materialized="table",
          table_option="NO FALLBACK, NO JOURNAL, CHECKSUM = ON,
            NO MERGEBLOCKRATIO,
            WITH CONCURRENT ISOLATED LOADING FOR ALL"
      )
    }}
    
    seeds:
      <project-name>:
        table_option:"NO FALLBACK"
    
    seeds:
      <project-name>:
        table_option:"NO FALLBACK, NO JOURNAL"
    
    seeds:
      <project-name>:
        table_option: "NO FALLBACK, NO JOURNAL, CHECKSUM = ON,
          NO MERGEBLOCKRATIO,
          WITH CONCURRENT ISOLATED LOADING FOR ALL"
    
  {{
    config(
        materialized="table",
        with_statistics="true"
    )
  }}
  
  [UNIQUE] PRIMARY INDEX [index_name] ( index_column_name [,...] ) |
  NO PRIMARY INDEX |
  PRIMARY AMP [INDEX] [index_name] ( index_column_name [,...] ) |
  PARTITION BY { partitioning_level | ( partitioning_level [,...] ) } |
  UNIQUE INDEX [ index_name ] [ ( index_column_name [,...] ) ] [loading] |
  INDEX [index_name] [ALL] ( index_column_name [,...] ) [ordering] [loading]
  [,...]
  
    { partitioning_expression |
      COLUMN [ [NO] AUTO COMPRESS |
      COLUMN [ [NO] AUTO COMPRESS ] [ ALL BUT ] column_partition ]
    } [ ADD constant ]
    
    ORDER BY [ VALUES | HASH ] [ ( order_column_name ) ]
    
    WITH [NO] LOAD IDENTITY
    
    {{
      config(
          materialized="table",
          index="UNIQUE PRIMARY INDEX ( GlobalID )"
      )
    }}
    
    {{
      config(
          materialized="table",
          index="PRIMARY INDEX(id)
          PARTITION BY RANGE_N(create_date
                        BETWEEN DATE '2020-01-01'
                        AND     DATE '2021-01-01'
                        EACH INTERVAL '1' MONTH)"
      )
    }}
    
    {{
      config(
          materialized="table",
          index="PRIMARY INDEX(id)
          PARTITION BY RANGE_N(create_date
                        BETWEEN DATE '2020-01-01'
                        AND     DATE '2021-01-01'
                        EACH INTERVAL '1' MONTH)
          INDEX index_attrA (attrA) WITH LOAD IDENTITY"
      )
    }}
    
    seeds:
      <project-name>:
        index: "UNIQUE PRIMARY INDEX ( GlobalID )"
    
    seeds:
      <project-name>:
        index: "PRIMARY INDEX(id)
          PARTITION BY RANGE_N(create_date
                        BETWEEN DATE '2020-01-01'
                        AND     DATE '2021-01-01'
                        EACH INTERVAL '1' MONTH)"
    
    seeds:
      <project-name>:
        index: "PRIMARY INDEX(id)
          PARTITION BY RANGE_N(create_date
                        BETWEEN DATE '2020-01-01'
                        AND     DATE '2021-01-01'
                        EACH INTERVAL '1' MONTH)
          INDEX index_attrA (attrA) WITH LOAD IDENTITY"
    
  seeds:
    <project-name>:
      +use_fastload: true
  
{% snapshot snapshot_example %}
{{
  config(
    target_schema='snapshots',
    unique_key='id',
    strategy='check',
    check_cols=["c2"],
    snapshot_hash_udf='GLOBAL_FUNCTIONS.hash_md5'
  )
}}
select * from {{ ref('order_payments') }}
{% endsnapshot %}

models:
  - name: model_name
    config:
      grants:
        select: ['user_a', 'user_b']

models:
- name: model_name
  config:
    materialized: table
    grants:
      select: ["user_b"]
      insert: ["user_c"]

query_band: 'application=dbt;'
   
     models:
     Project_name:
        +query_band: "app=dbt;model={model};"
   
   {{ config( query_band='sql={model};' ) }}
   
models:
Project_name:
  +query_band: "app=dbt;model={model};"

{{
      config(
          materialized='incremental',
          unique_key='id',
          on_schema_change='fail',
          incremental_strategy='valid_history',
          valid_period='valid_period_col',
          use_valid_to_time='no',
  )
  }}

An illustration demonstrating the source sample data and its corresponding target data:

-- Source data
      pk |       valid_from          | value_txt1 | value_txt2
      ======================================================================
      1  | 2024-03-01 00:00:00.0000  | A          | x1
      1  | 2024-03-12 00:00:00.0000  | B          | x1
      1  | 2024-03-12 00:00:00.0000  | B          | x2
      1  | 2024-03-25 00:00:00.0000  | A          | x2
      2  | 2024-03-01 00:00:00.0000  | A          | x1
      2  | 2024-03-12 00:00:00.0000  | C          | x1
      2  | 2024-03-12 00:00:00.0000  | D          | x1
      2  | 2024-03-13 00:00:00.0000  | C          | x1
      2  | 2024-03-14 00:00:00.0000  | C          | x1
  
  -- Target data
      pk | valid_period                                                       | value_txt1 | value_txt2
      ===================================================================================================
      1  | PERIOD(TIMESTAMP)[2024-03-01 00:00:00.0, 2024-03-12 00:00:00.0]    | A          | x1
      1  | PERIOD(TIMESTAMP)[2024-03-12 00:00:00.0, 2024-03-25 00:00:00.0]    | B          | x1
      1  | PERIOD(TIMESTAMP)[2024-03-25 00:00:00.0, 9999-12-31 23:59:59.9999] | A          | x2
      2  | PERIOD(TIMESTAMP)[2024-03-01 00:00:00.0, 2024-03-12 00:00:00.0]    | A          | x1
      2  | PERIOD(TIMESTAMP)[2024-03-12 00:00:00.0, 9999-12-31 23:59:59.9999] | C          | x1

{{ config(
    post_hook=[
      "COLLECT STATISTICS ON  {{ this }} COLUMN (column_1,  column_2  ...);"
      ]
  )}}
  
packages:
  - package: dbt-labs/dbt_external_tables
    version: [">=0.9.0", "<1.0.0"]

dispatch:
  - macro_namespace: dbt_external_tables
    search_order: ['dbt', 'dbt_external_tables']

sources:
  - name: teradata_external
    schema: "{{ target.schema }}"
    loader: S3

tables:
      - name: people_csv_partitioned
        external: 
          location: "/s3/s3.amazonaws.com/dbt-external-tables-testing/csv/"
          file_format: "TEXTFILE"
          row_format: '{"field_delimiter":",","record_delimiter":"\n","character_set":"LATIN"}'
          using: |
            PATHPATTERN  ('$var1/$section/$var3')
          tbl_properties: |
            MAP = TD_MAP1
            ,EXTERNAL SECURITY  MyAuthObj
          partitions:
            - name: section
              data_type: CHAR(1)
        columns:
          - name: id
            data_type: int
          - name: first_name
            data_type: varchar(64)
          - name: last_name
            data_type: varchar(64)
          - name: email
            data_type: varchar(64)

sources:
  - name: teradata_external
    schema: "{{ target.schema }}"
    loader: S3

tables:
      - name: people_json_partitioned
        external:
          location: '/s3/s3.amazonaws.com/dbt-external-tables-testing/json/'
          using: |
            STOREDAS('TEXTFILE')
            ROWFORMAT('{"record_delimiter":"\n", "character_set":"cs_value"}')
            PATHPATTERN  ('$var1/$section/$var3')
          tbl_properties: |
            MAP = TD_MAP1
            ,EXTERNAL SECURITY  MyAuthObj
          partitions:
            - name: section
              data_type: CHAR(1)

vars:
  temporary_metadata_generation_schema: <schema-name>

dbt test --select "test_type:generic"

dbt test --select "test_type:singular"

dbt test --select "orders"
dbt build --select "orders"

dbt test --select "orders" --indirect-selection=buildable
dbt build --select "orders" --indirect-selection=buildable

dbt test --select "orders" --indirect-selection=cautious
dbt build --select "orders" --indirect-selection=cautious

dbt test --select "orders" --indirect-selection=empty
dbt build --select "orders" --indirect-selection=empty

**Examples:**

Example 1 (unknown):
```unknown
#### Usage notes[​](#usage-notes "Direct link to Usage notes")

##### Tags must be strings[​](#tags-must-be-strings "Direct link to Tags must be strings")

Each individual tag must be a string value (for example, `marketing` or `daily`).

In the following example, `my_tag: "my_value"` is invalid because it is a key-value pair.
```

Example 2 (unknown):
```unknown
A warning is raised when the `tags` value is not a string. For example:
```

Example 3 (unknown):
```unknown
##### Tags are additive[​](#tags-are-additive "Direct link to Tags are additive")

Tags accumulate hierarchically. The [earlier example](https://docs.getdbt.com/reference/resource-configs/tags.md#use-tags-to-run-parts-of-your-project) would result in:

| Model                             | Tags                                  |
| --------------------------------- | ------------------------------------- |
| models/staging/stg\_customers.sql | `contains_pii`, `hourly`              |
| models/staging/stg\_payments.sql  | `contains_pii`, `hourly`, `finance`   |
| models/marts/dim\_customers.sql   | `contains_pii`, `hourly`, `published` |
| models/metrics/daily\_metrics.sql | `contains_pii`, `daily`, `published`  |

##### Other resource types[​](#other-resource-types "Direct link to Other resource types")

Tags can also be applied to [sources](https://docs.getdbt.com/docs/build/sources.md), [exposures](https://docs.getdbt.com/docs/build/exposures.md), and even *specific columns* in a resource. These resources do not yet support the `config` property, so you'll need to specify the tags as a top-level key instead.

models/schema.yml
```

Example 4 (unknown):
```unknown
In the example above, the `unique` test would be selected by any of these four tags:
```

---
