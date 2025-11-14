# Dbt-Semantic-Layer - Examples

**Pages:** 5

---

## dbt Example Style Guide

**URL:** llms-txt#dbt-example-style-guide

**Contents:**
- SQL Style
- Model Organization
- Model Layers
- Model File Naming and Coding
- Model Configurations
- Testing
- CTEs
  - Refactor an existing rollup
  - Semantic structure
  - Set up the dbt Semantic Layer

- Use lowercase keywords.
- Use trailing commas.

## Model Organization

Our models (typically) fit into two main categories:\

- Staging &mdash; Contains models that clean and standardize data.        
- Marts &mdash; Contains models which combine or heavily transform data.

- There are different types of models that typically exist in each of the above categories. See Model Layers for more information.
- Read How we structure our dbt projects for an example and more details around organization.

- Only models in `staging` should select from sources.
- Models not in the `staging` folder should select from refs.

## Model File Naming and Coding

- All objects should be plural.  
  Example: `stg_stripe__invoices.sql` vs. `stg_stripe__invoice.sql`

- All models should use the naming convention `<type/dag_stage>_<source/topic>__<additional_context>`. See this article for more information.

- Models in the **staging** folder should use the source's name as the `<source/topic>` and the entity name as the `additional_context`.

- seed_snowflake_spend.csv
    - base_stripe\_\_invoices.sql
    - stg_stripe\_\_customers.sql
    - stg_salesforce\_\_customers.sql
    - int_customers\_\_unioned.sql
    - fct_orders.sql

- Schema, table, and column names should be in `snake_case`.

- Limit the use of abbreviations that are related to domain knowledge. An onboarding employee will understand `current_order_status` better than `current_os`.

- Use names based on the _business_ rather than the source terminology.

- Each model should have a primary key to identify the unique row and should be named `<object>_id`. For example, `account_id`. This makes it easier to know what `id` is referenced in downstream joined models.

- For `base` or `staging` models, columns should be ordered in categories, where identifiers are first and date/time fields are at the end.
- Date/time columns should be named according to these conventions:

- Timestamps: `<event>_at`  
    Format: UTC  
    Example: `created_at`

- Dates: `<event>_date`
    Format: Date  
    Example: `created_date`

- Booleans should be prefixed with `is_` or `has_`.
  Example: `is_active_customer` and `has_admin_access`

- Price/revenue fields should be in decimal currency (for example, `19.99` for $19.99; many app databases store prices as integers in cents). If a non-decimal currency is used, indicate this with suffixes. For example, `price_in_cents`.

- Avoid using reserved words (such as these for Snowflake) as column names.

- Consistency is key! Use the same field names across models where possible. For example, a key to the `customers` table should be named `customer_id` rather than `user_id`.

## Model Configurations

- Model configurations at the folder level should be considered (and if applicable, applied) first.
- More specific configurations should be applied at the model level using one of these methods.
- Models within the `marts` folder should be materialized as `table` or `incremental`.
  - By default, `marts` should be materialized as `table` within `dbt_project.yml`.
  - If switching to `incremental`, this should be specified in the model's configuration.

- At a minimum, `unique` and `not_null` tests should be applied to the expected primary key of each model.

For more information about why we use so many CTEs, read this glossary entry.

- Where performance permits, CTEs should perform a single, logical unit of work.
- CTE names should be as verbose as needed to convey what they do.
- CTEs with confusing or noteable logic should be commented with SQL comments as you would with any complex functions and should be located above the CTE.
- CTEs duplicated across models should be pulled out and created as their own models.

semantic_models:
  - name: locations
    description: |
      Location dimension table. The grain of the table is one row per location.
    model: ref('stg_locations')
    entities:
      - name: location
        type: primary
        expr: location_id
    dimensions:
      - name: location_name
        type: categorical
      - name: date_trunc('day', opened_at)
        type: time
        type_params:
          time_granularity: day
    measures:
      - name: average_tax_rate
        description: Average tax rate.
        expr: tax_rate
        agg: avg

{{
   config(
      materialized = 'table',
   )
}}

select * from {{ ref('stg_order_items') }}

select * from {{ ref('stg_orders')}}

select * from {{ ref('stg_products') }}

select * from {{ ref('stg_supplies') }}

order_supplies_summary as (

select
      product_id,
      sum(supply_cost) as supply_cost

select
      order_items.*,
      products.product_price,
      order_supplies_summary.supply_cost,
      products.is_food_item,
      products.is_drink_item,
      orders.ordered_at

left join orders on order_items.order_id  = orders.order_id

left join products on order_items.product_id = products.product_id

left join order_supplies_summary on order_items.product_id = order_supplies_summary.product_id

semantic_models:
   #The name of the semantic model.
   - name: order_items
      defaults:
         agg_time_dimension: ordered_at
      description: |
         Items contatined in each order. The grain of the table is one row per order item.
      model: ref('order_items')
      entities:
         - name: order_item
           type: primary
           expr: order_item_id
         - name: order_id
           type: foreign
           expr: order_id
         - name: product
           type: foreign
           expr: product_id
      dimensions:
         - name: ordered_at
           expr: date_trunc('day', ordered_at)
           type: time
           type_params:
             time_granularity: day
         - name: is_food_item
           type: categorical
         - name: is_drink_item
           type: categorical
      measures:
         - name: revenue
           description: The revenue generated for each order item. Revenue is calculated as a sum of revenue associated with each product in an order.
           agg: sum
           expr: product_price
         - name: food_revenue
           description: The revenue generated for each order item. Revenue is calculated as a sum of revenue associated with each product in an order.
           agg: sum
           expr: case when is_food_item = 1 then product_price else 0 end
         - name: drink_revenue
           description: The revenue generated for each order item. Revenue is calculated as a sum of revenue associated with each product in an order.
           agg: sum
           expr: case when is_drink_item = 1 then product_price else 0 end
         - name: median_revenue
           description: The median revenue generated for each order item.
           agg: median
           expr: product_price

metrics:
  - name: revenue
    description: Sum of the product revenue for each order item. Excludes tax.
    type: simple
    label: Revenue
    type_params:
      measure: revenue

dbt sl query --metrics revenue --group-by metric_time__month

✔ Success 🦄 - query completed after 1.02 seconds
| METRIC_TIME__MONTH   |   REVENUE |
|:---------------------|----------:|
| 2016-09-01 00:00:00  |  17032.00 |
| 2016-10-01 00:00:00  |  20684.00 |
| 2016-11-01 00:00:00  |  26338.00 |
| 2016-12-01 00:00:00  |  10685.00 |

models/staging
├── jaffle_shop
│   ├── _jaffle_shop__docs.md
│   ├── _jaffle_shop__models.yml
│   ├── _jaffle_shop__sources.yml
│   ├── base
│   │   ├── base_jaffle_shop__customers.sql
│   │   └── base_jaffle_shop__deleted_customers.sql
│   ├── stg_jaffle_shop__customers.sql
│   └── stg_jaffle_shop__orders.sql
└── stripe
    ├── _stripe__models.yml
    ├── _stripe__sources.yml
    └── stg_stripe__payments.sql

-- stg_stripe__payments.sql

select * from {{ source('stripe','payment') }}

select
        -- ids
        id as payment_id,
        orderid as order_id,

-- strings
        paymentmethod as payment_method,
        case
            when payment_method in ('stripe', 'paypal', 'credit_card', 'gift_card') then 'credit'
            else 'cash'
        end as payment_type,
        status,

-- numerics
        amount as amount_cents,
        amount / 100.0 as amount,

-- booleans
        case
            when status = 'successful' then true
            else false
        end as is_completed_payment,

-- dates
        date_trunc('day', created) as created_date,

-- timestamps
        created::timestamp_ltz as created_at

select * from renamed

models:
      jaffle_shop:
        staging:
          +materialized: view
    
    -- base_jaffle_shop__customers.sql

select * from {{ source('jaffle_shop','customers') }}

select
            id as customer_id,
            first_name,
            last_name

select * from customers
    
    -- base_jaffle_shop__deleted_customers.sql

select * from {{ source('jaffle_shop','customer_deletes') }}

deleted_customers as (

select
            id as customer_id,
            deleted as deleted_at

select * from deleted_customers
    
    -- stg_jaffle_shop__customers.sql

select * from {{ ref('base_jaffle_shop__customers') }}

deleted_customers as (

select * from {{ ref('base_jaffle_shop__deleted_customers') }}

join_and_mark_deleted_customers as (

select
            customers.*,
            case
                when deleted_customers.deleted_at is not null then true
                else false
            end as is_deleted

left join deleted_customers on customers.customer_id = deleted_customers.customer_id

select * from join_and_mark_deleted_customers
    
models
├── intermediate
│   └── finance
│       ├── _int_finance__models.yml
│       └── int_payments_pivoted_to_orders.sql
├── marts
│   ├── finance
│   │   ├── _finance__models.yml
│   │   ├── orders.sql
│   │   └── payments.sql
│   └── marketing
│       ├── _marketing__models.yml
│       └── customers.sql
├── staging
│   ├── jaffle_shop
│   │   ├── _jaffle_shop__docs.md
│   │   ├── _jaffle_shop__models.yml
│   │   ├── _jaffle_shop__sources.yml
│   │   ├── base
│   │   │   ├── base_jaffle_shop__customers.sql
│   │   │   └── base_jaffle_shop__deleted_customers.sql
│   │   ├── stg_jaffle_shop__customers.sql
│   │   └── stg_jaffle_shop__orders.sql
│   └── stripe
│       ├── _stripe__models.yml
│       ├── _stripe__sources.yml
│       └── stg_stripe__payments.sql
└── utilities
    └── all_dates.sql

models:
  jaffle_shop:
    staging:
      +materialized: view
    intermediate:
      +materialized: ephemeral
    marts:
      +materialized: table
      finance:
        +schema: finance
      marketing:
        +schema: marketing

jaffle_shop
├── analyses
├── seeds
│   └── employees.csv
├── macros
│   ├── _macros.yml
│   └── cents_to_dollars.sql
├── snapshots
└── tests
└── assert_positive_value_for_total_amount.sql

{% test is_even(model, column_name) %}

select
        {{ column_name }} as even_field

validation_errors as (

select
        even_field

from validation
    -- if this is true, then even_field is actually odd!
    where (even_field % 2) = 1

select *
from validation_errors

macros:
  - name: test_not_empty_string
    description: Complementary test to default `not_null` test as it checks that there is not an empty string. It only accepts columns of type string.
    arguments:
      - name: model 
        type: string
        description: Model Name
      - name: column_name
        type: string
        description: Column name that should not be an empty string

{% test relationships(model, column_name, field, to) %}

select
        {{ field }} as id

select
        {{ column_name }} as id

select *
from child
where id is not null
  and id not in (select id from parent)

{% test warn_if_odd(model, column_name) %}

{{ config(severity = 'warn') }}

select *
    from {{ model }}
    where ({{ column_name }} % 2) = 1

{% test unique(model, column_name) %}

-- whatever SQL you'd like!

packages:
- git: "https://{{env_var('DBT_ENV_SECRET_GIT_CREDENTIAL')}}@github.com/dbt-labs/awesome_repo.git"

query ($jobId: Int!) {
  models(jobId: $jobId){
      uniqueId
  }
  }

query ($jobId: BigInt!) {
  job(id: $jobId) {
      models {
      uniqueId
      }
  }
  }

query ($environmentId: Int!, $uniqueId: String) {
  modelByEnvironment(environmentId: $environmentId, uniqueId: $uniqueId) {
      uniqueId
      executionTime
      executeCompletedAt
  }
  }

query ($environmentId: BigInt!, $uniqueId: String) {
  environment(id: $environmentId) {
      applied {
      modelHistoricalRuns(uniqueId: $uniqueId) {
          uniqueId
          executionTime
          executeCompletedAt
      }
      }
  }
  }

query ($environmentId: Int!, $first: Int!) {
  environment(id: $environmentId) {
      applied {
      models(first: $first) {
          edges {
          node {
              uniqueId
              executionInfo {
              lastRunId
              }
          }
          }
      }
      }
  }
  }

query ($environmentId: BigInt!, $first: Int!) {
  environment(id: $environmentId) {
      applied {
      models(first: $first) {
          edges {
          node {
              uniqueId
              executionInfo {
              lastRunId
              }
          }
          }
      }
      }
  }
  }
  
  saved-queries:
    jaffle_shop:
      customer_order_metrics:
        +tags: order_metrics
  
$ dbt --version
Core:
  - installed: 1.8.0
  - latest:    1.8.0 - Up to date!

Plugins:
  - snowflake: 1.9.0 - Up to date!

[0m13:13:48.572182 [info ] [MainThread]: Registered adapter: snowflake=1.9.0

models:
  - name: events
    description: This table contains clickstream events from the marketing website

columns:
      - name: event_id
        description: This is a unique identifier for the event
        data_tests:
          - unique
          - not_null

- name: user-id
        quote: true
        description: The user who performed the event
        data_tests:
          - not_null

models:
  - name: customers
    description: >
      Lorem ipsum **dolor** sit amet, consectetur adipisicing elit, sed do eiusmod
      tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
      quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
      consequat.

models:
  - name: customers
    description: |
      ### Lorem ipsum

* dolor sit amet, consectetur adipisicing elit, sed do eiusmod
      * tempor incididunt ut labore et dolore magna aliqua.

{% docs table_events %}

This table contains clickstream events from the marketing website.

The events in this table are recorded by Snowplow and piped into the warehouse on an hourly basis. The following pages of the marketing site are tracked:
 - /
 - /about
 - /team
 - /contact-us

models:
  - name: events
    description: '{{ doc("table_events") }}'

columns:
      - name: event_id
        description: This is a unique identifier for the event
        data_tests:
            - unique
            - not_null

{% docs __overview__ %}

**Examples:**

Example 1 (unknown):
```unknown
#### Was this page helpful?

YesNo

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.


---

### Refactor an existing rollup

#### A new approach[​](#a-new-approach "Direct link to A new approach")

Now that we've set the stage, it's time to dig in to the fun and messy part: how do we refactor an existing rollup in dbt into semantic models and metrics?

Let's look at the differences we can observe in how we might approach this with MetricFlow supercharging dbt versus how we work without a Semantic Layer. These differences can then inform our structure.

* 🍊 In dbt, we tend to create **highly denormalized datasets** that bring **everything you want around a certain entity or process into a single table**.
* 💜 The problem is, this **limits the dimensionality available to MetricFlow**. The more we pre-compute and 'freeze' into place, the less flexible our data is.
* 🚰 In MetricFlow, we ideally want **highly normalized**, star schema-like data that then allows MetricFlow to shine as a **denormalization engine**.
* ∞ Another way to think about this is that instead of moving down a list of requested priorities trying to pre-make as many combinations of our marts as possible — increasing lines of code and complexity — we can **let MetricFlow present every combination possible without specifically coding it**.
* 🏗️ To resolve these approaches optimally, we'll need to shift some **fundamental aspects of our modeling strategy**.

#### Refactor steps outlined[​](#refactor-steps-outlined "Direct link to Refactor steps outlined")

We recommend an incremental implementation process that looks something like this:

1. 👉 Identify **an important output** (a revenue chart on a dashboard for example, and the mart model(s) that supplies this output.
2. 🔍 Examine all the **entities that are components** of this rollup (for instance, an `active_customers_per_week` rollup may include customers, shipping, and product data).
3. 🛠️ **Build semantic models** for all the underlying component marts.
4. 📏 **Build metrics** for the required aggregations in the rollup.
5. 👯 Create a **clone of the output** on top of the Semantic Layer.
6. 💻 Audit to **ensure you get accurate outputs**.
7. 👉 Identify **any other outputs** that point to the rollup and **move them to the Semantic Layer**.
8. ✌️ Put a **deprecation plan** in place for the now extraneous frozen rollup.

You would then **continue this process** on other outputs and marts moving down a list of **priorities**. Each model as you go along will be faster and easier as you'll **reuse many of the same components** that will already have been semantically modeled.

#### Let's make a `revenue` metric[​](#lets-make-a-revenue-metric "Direct link to lets-make-a-revenue-metric")

So far we've been working in new pointing at a staging model to simplify things as we build new mental models for MetricFlow. In reality, unless you're implementing MetricFlow in a green-field dbt project, you probably are going to have some refactoring to do. So let's get into that in detail.

1. 📚 Per the above steps, let's say we've identified our target as a revenue rollup that is built on top of `orders` and `order_items`. Now we need to identify all the underlying components, these will be all the 'import' CTEs at the top of these marts. So in the Jaffle Shop project we'd need: `orders`, `order_items`, `products`, `locations`, and `supplies`.

2. 🗺️ We'll next make semantic models for all of these. Let's walk through a straightforward conversion first with `locations`.

3. ⛓️ We'll want to first decide if we need to do any joining to get this into the shape we want for our semantic model. The biggest determinants of this are two factors:

   <!-- -->

   * 📏 Does this semantic model **contain measures**?
   * 🕥 Does this semantic model have a **primary timestamp**?
   * 🫂 If a semantic model **has measures but no timestamp** (for example, supplies in the example project, which has static costs of supplies), you'll likely want to **sacrifice some normalization and join it on to another model** that has a primary timestamp to allow for metric aggregation.

4. 🔄 If we *don't* need any joins, we'll just go straight to the staging model for our semantic model's `ref`. Locations does have a `tax_rate` measure, but it also has an `ordered_at` timestamp, so we can go **straight to the staging model** here.

5. 🥇 We specify our **primary entity** (based on `location_id`), dimensions (one categorical, `location_name`, and one **primary time dimension** `opened_at`), and lastly our measures, in this case just `average_tax_rate`.

models/marts/locations.yml
```

Example 2 (unknown):
```unknown
#### Semantic and logical interaction[​](#semantic-and-logical-interaction "Direct link to Semantic and logical interaction")

Now, let's tackle a thornier situation. Products and supplies both have dimensions and measures but no time dimension. Products has a one-to-one relationship with `order_items`, enriching that table, which is itself just a mapping table of products to orders. Additionally, products have a one-to-many relationship with supplies. The high-level ERD looks like the diagram below.

[![](/img/best-practices/semantic-layer/orders_erd.png?v=2)](#)

So to calculate, for instance, the cost of ingredients and supplies for a given order, we'll need to do some joining and aggregating, but again we **lack a time dimension for products and supplies**. This is the signal to us that we'll **need to build a logical mart** and point our semantic model at that.

tip

**dbt 🧡 MetricFlow.** This is where integrating your semantic definitions into your dbt project really starts to pay dividends. The interaction between the logical and semantic layers is so dynamic, you either need to house them in one codebase or facilitate a lot of cross-project communication and dependency.

1. 🎯 Let's aim at, to start, building a table at the `order_items` grain. We can aggregate supply costs up, map over the fields we want from products, such as price, and bring the `ordered_at` timestamp we need over from the orders table. You can see example code, copied below, in `models/marts/order_items.sql`.

models/marts/order\_items.sql
```

Example 3 (unknown):
```unknown
2. 🏗️ Now we've got a table that looks more like what we want to feed into the Semantic Layer. Next, we'll **build a semantic model on top of this new mart** in `models/marts/order_items.yml`. Again, we'll identify our **entities, then dimensions, then measures**.

models/marts/order\_items.yml
```

Example 4 (unknown):
```unknown
3. 📏 Finally, Let's **build a simple revenue metric** on top of our semantic model now.

models/marts/order\_items.yml
```

---

## Example of multiple emails supported

**URL:** llms-txt#example-of-multiple-emails-supported

**Contents:**
  - Model performance EnterpriseEnterprise +
  - Model performance [Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")
  - Model query history EnterpriseEnterprise +
  - Model query history [Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")
  - Model versions

- name: docs
    owner:
      name: "Documentation team"
      email: 
        - docs@dbtlabs.com
        - community@dbtlabs.com
        - product@dbtlabs.com
      favorite_food: pizza

models:
  - name: sales
    description: "Sales data model"
    config:
      group: finance

- name: campaigns
    description: "Campaigns data model"
    config:
      group: marketing

config-version: 2
name: "jaffle_shop"

models:
  jaffle_shop:
    staging:
      +group: data_engineering
    marts:
      sales:
        +group: finance
      campaigns:
        +group: marketing

GRANT DATABASE ROLE SNOWFLAKE.GOVERNANCE_VIEWER TO ROLE <YOUR_DBT_CLOUD_DEPLOYMENT_ROLE>;

selectors:
  - name: exclude_old_versions
    default: "{{ target.name == 'dev' }}"
    definition:
      method: fqn
      value: "*"
      exclude:
        - method: version
          value: old

Found an unpinned reference to versioned model 'dim_customers'.
Resolving to latest version: my_model.v2
A prerelease version 3 is available. It has not yet been marked 'latest' by its maintainer.
When that happens, this reference will resolve to my_model.v3 instead.

Try out v3: {{ ref('my_dbt_project', 'my_model', v='3') }}
  Pin to  v2: {{ ref('my_dbt_project', 'my_model', v='2') }}

final as (
  
    select
        customer_id,
        country_name
    from ...

models:
  - name: dim_customers
    config:
      materialized: table
      contract:
        enforced: true
    columns:
      - name: customer_id
        description: This is the primary key
        data_type: int
      - name: country_name
        description: Where this customer lives
        data_type: varchar

final as (
  
    select
        customer_id
        -- country_name has been removed!
    from ...

models:
  - name: dim_customers
    latest_version: 1
    config:
      materialized: table
      contract: {enforced: true}
    columns:
      - name: customer_id
        description: This is the primary key
        data_type: int
      - name: country_name
        description: Where this customer lives
        data_type: varchar
    
    # Declare the versions, and highlight the diffs
    versions:
    
      - v: 1
        # Matches what's above -- nothing more needed
    
      - v: 2
        # Removed a column -- this is the breaking change!
        columns:
          # This means: use the 'columns' list from above, but exclude country_name
          - include: all
            exclude: [country_name]

models:
  - name: dim_customers
    latest_version: 1
    
    # declare the versions, and fully specify them
    versions:
      - v: 2
        config:
          materialized: table
          contract: {enforced: true}
        columns:
          - name: customer_id
            description: This is the primary key
            data_type: int
          # no country_name column
      
      - v: 1
        config:
          materialized: table
          contract: {enforced: true}
        columns:
          - name: customer_id
            description: This is the primary key
            data_type: int
          - name: country_name
            description: Where this customer lives
            data_type: varchar

versions:
  - v: 2
    config:
      materialized: table
  - v: 1
    config:
      materialized: view

- v: 1
        config:
          alias: dim_customers   # keep v1 in its original database location

{% macro create_latest_version_view() %}

-- this hook will run only if the model is versioned, and only if it's the latest version
    -- otherwise, it's a no-op
    {% if model.get('version') and model.get('version') == model.get('latest_version') %}

{% set new_relation = this.incorporate(path={"identifier": model['name']}) %}

{% set existing_relation = load_relation(new_relation) %}

{% if existing_relation and not existing_relation.is_view %}
            {{ drop_relation_if_exists(existing_relation) }}
        {% endif %}
        
        {% set create_view_sql -%}
            -- this syntax may vary by data platform
            create or replace view {{ new_relation }}
              as select * from {{ this }}
        {%- endset %}
        
        {% do log("Creating view " ~ new_relation ~ " pointing to " ~ this, info = true) if execute %}
        
        {{ return(create_view_sql) }}
        
    {% else %}
    
        -- no-op
        select 1 as id
    
    {% endif %}

**Examples:**

Example 1 (unknown):
```unknown
tip

The `owner` key is flexible and accepts arbitrary inputs in addition to the required `email` field. For example, you could include a custom field like `favorite_food` to add context about the team.

#### Attach groups to models[​](#attach-groups-to-models "Direct link to Attach groups to models")

Attach groups to models as you would any other config, in either the `dbt_project.yml` or `whatever.yml` files. For example:

models/marts.yml
```

Example 2 (unknown):
```unknown
By assigning groups in the `dbt_project.yml` file, you can capture all models in a subdirectory at once.

In this example, model notifications related to staging models go to the data engineering group, `marts/sales` models to the finance team, and `marts/campaigns` models to the marketing team.

dbt\_project.yml
```

Example 3 (unknown):
```unknown
Attaching a group to a model also encompasses its tests, so you will also receive notifications for a model's test failures.

#### Enable access to model notifications[​](#enable-access-to-model-notifications "Direct link to Enable access to model notifications")

Provide dbt account members the ability to configure and receive alerts about issues with models or tests that are encountered during job runs.

To use model-level notifications, your dbt account must have access to the feature. Ask your dbt administrator to enable this feature for account members by following these steps:

1. Navigate to **Notification settings** from your profile name in the sidebar (lower left-hand side).
2. From **Email notifications**, enable the setting **Enable group/owner notifications on models** under the **Model notifications** section. Then, specify which statuses to receive notifications about (Success, Warning, and/or Fails).

[![Example of the setting Enable group/owner notifications on models](/img/docs/dbt-cloud/example-enable-model-notifications.png?v=2 "Example of the setting Enable group/owner notifications on models")](#)Example of the setting Enable group/owner notifications on models

3. Click **Save**.

#### Was this page helpful?

YesNo

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.


---

### Model performance EnterpriseEnterprise +

### Model performance [Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")

Catalog provides metadata on dbt runs for in-depth model performance and quality analysis. This feature assists in reducing infrastructure costs and saving time for data teams by highlighting where to fine-tune projects and deployments — such as model refactoring or job configuration adjustments.

[![Overview of Performance page navigation.](/img/docs/collaborate/dbt-explorer/explorer-model-performance.gif?v=2 "Overview of Performance page navigation.")](#)Overview of Performance page navigation.

<!-- -->

On-demand learning

If you enjoy video courses, check out our [dbt Catalog on-demand course](https://learn.getdbt.com/courses/dbt-catalog) and learn how to best explore your dbt project(s)!

#### The Performance overview page[​](#the-performance-overview-page "Direct link to The Performance overview page")

You can pinpoint areas for performance enhancement by using the Performance overview page. This page presents a comprehensive analysis across all project models and displays the longest-running models, those most frequently executed, and the ones with the highest failure rates during runs/tests. Data can be segmented by environment and job type which can offer insights into:

* Most executed models (total count).
* Models with the longest execution time (average duration).
* Models with the most failures, detailing run failures (percentage and count) and test failures (percentage and count).

Each data point links to individual models in Catalog.

[![Example of Performance overview page](/img/docs/collaborate/dbt-explorer/example-performance-overview-page.png?v=2 "Example of Performance overview page")](#)Example of Performance overview page

You can view historical metadata for up to the past three months. Select the time horizon using the filter, which defaults to a two-week lookback.

[![Example of dropdown](/img/docs/collaborate/dbt-explorer/ex-2-week-default.png?v=2 "Example of dropdown")](#)Example of dropdown

#### The Model performance tab[​](#the-model-performance-tab "Direct link to The Model performance tab")

You can view trends in execution times, counts, and failures by using the Model performance tab for historical performance analysis. Daily execution data includes:

* Average model execution time.
* Model execution counts, including failures/errors (total sum).

Clicking on a data point reveals a table listing all job runs for that day, with each row providing a direct link to the details of a specific run.

[![Example of the Model performance tab](/img/docs/collaborate/dbt-explorer/example-model-performance-tab.png?v=2 "Example of the Model performance tab")](#)Example of the Model performance tab

#### Was this page helpful?

YesNo

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.


---

### Model query history EnterpriseEnterprise +

### Model query history [Enterprise](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")[Enterprise +](https://www.getdbt.com/pricing "Go to https://www.getdbt.com/pricing")

Model query history helps data teams track model usage by analyzing query logs.

Model query history allows you to:

* View the count of consumption queries for a model based on the data warehouse's query logs.
* Provides data teams insight, so they can focus their time and infrastructure spend on the worthwhile used data products.
* Enable analysts to find the most popular models used by other people.

Model query history is powered by a single consumption query of the query log table in your data warehouse aggregated on a daily basis.

 What is a consumption query?

Consumption query is a metric of queries in your dbt project that has used the model in a given time. It filters down to `select` statements only to gauge model consumption and excludes dbt model build and test executions.

So for example, if `model_super_santi` was queried 10 times in the past week, it would count as having 10 consumption queries for that particular time period.

Support for Snowflake (Enterprise tier or higher) and BigQuery

Model query history for Snowflake users is **only available for Enterprise tier or higher**. The feature also supports BigQuery. Additional platforms coming soon.

#### Prerequisites[​](#prerequisites "Direct link to Prerequisites")

To access the features, you should meet the following:

1. You have a dbt account on an [Enterprise-tier plan](https://www.getdbt.com/pricing/). Single-tenant accounts should contact their account representative for setup.
2. You have set up a [production](https://docs.getdbt.com/docs/deploy/deploy-environments.md#set-as-production-environment) deployment environment for each project you want to explore, with at least one successful job run.
3. You have [admin permissions](https://docs.getdbt.com/docs/cloud/manage-access/enterprise-permissions.md) in dbt to edit project settings or production environment settings.
4. Use Snowflake or BigQuery as your data warehouse and can enable [query history permissions](#snowflake-model-query-history) or work with an admin to do so. Support for additional data platforms coming soon.
   <!-- -->
   * For Snowflake users: You **must** have a Snowflake Enterprise tier or higher subscription.

#### Enable query history in dbt[​](#enable-query-history-in-dbt "Direct link to Enable query history in dbt")

To enable model query history in dbt, follow these steps:

1. Navigate to **Deploy** and then **Environments**.

2. Select the environment marked **PROD** and click **Settings**.

3. Click **Edit** and scroll to the **Query History** section to enable the query history toggle. When it’s green and to the right, it's enabled.

4. Click the **Test Permissions** button to validate the deployment credentials permissions are sufficient to support query history.

5. dbt automatically enables query history for brand new environments. If query history fails to retrieve data, dbt automatically disables it to prevent unintended warehouse costs.

   <!-- -->

   * If the failure is temporary (like a network timeout), dbt may retry.
   * If the issue is permanent (like a missing permissions), dbt disables query history immediately.

   <!-- -->

   To re-enable it, please reach out to [dbt Support](mailto:support@getdbt.com).

[![Enable query history in your environment settings.](/img/docs/collaborate/dbt-explorer/enable-query-history.jpg?v=2 "Enable query history in your environment settings.")](#)Enable query history in your environment settings.

[![Example of permissions verified result after clicking Test Permissions.](/img/docs/collaborate/dbt-explorer/enable-query-history-success.jpg?v=2 "Example of permissions verified result after clicking Test Permissions.")](#)Example of permissions verified result after clicking Test Permissions.

#### Credential permissions[​](#credential-permissions "Direct link to Credential permissions")

This section explains the permissions and steps you need to enable and view model query history in Catalog.

The model query history feature uses the credentials in your production environment to gather metadata from your data warehouse’s query logs. This means you may need elevated permissions with the warehouse. Before making any changes to your data platform permissions, confirm the configured permissions in dbt:

1. Navigate to **Deploy** and then **Environments**.
2. Select the Environment marked **PROD** and click **Settings**.
3. Look at the information under **Deployment credentials**.
   <!-- -->
   * Note: Querying query history entails warehouse costs / uses credits.

[![Confirm your deployment credentials in your environment settings page.](/img/docs/collaborate/dbt-explorer/model-query-credentials.jpg?v=2 "Confirm your deployment credentials in your environment settings page.")](#)Confirm your deployment credentials in your environment settings page.

4. Copy or cross reference those credential permissions with the warehouse permissions and grant your user the right permissions.

###### Snowflake model query history[​](#snowflake-model-query-history "Direct link to Snowflake model query history")

Model query history makes use of metadata tables available to [Snowflake Enterprise tier](https://docs.snowflake.com/en/user-guide/intro-editions#enterprise-edition) accounts or higher, `QUERY_HISTORY` and `ACCESS_HISTORY`. The Snowflake user in the production environment must have the `GOVERNANCE_VIEWER` permission to view the data. Before enabling Model query history, your `ACCOUNTADMIN` must run the following grant statement in Snowflake to ensure for access:
```

Example 4 (unknown):
```unknown
Without this grant, model query history won't display any data. For more details, view the snowflake docs [here](https://docs.snowflake.com/en/sql-reference/account-usage#enabling-other-roles-to-use-schemas-in-the-snowflake-database).

###### BigQuery model query history[​](#bigquery-model-query-history "Direct link to BigQuery model query history")

Model query history uses the metadata from the `INFORMATION_SCHEMA.JOBS` view in BigQuery. To access this, the user configured for your production environment must have the following [IAM roles](https://cloud.google.com/bigquery/docs/access-control) for your BigQuery project:

* `roles/bigquery.resourceViewer`
* `roles/bigquery.jobs.create`

#### View query history in Explorer[​](#view-query-history-in-explorer "Direct link to View query history in Explorer")

To enhance your discovery, you can view your model query history in various locations within Catalog:

* [View from Performance charts](#view-from-performance-charts)
* [View from Project lineage](#view-from-project-lineage)
* [View from Model list](#view-from-model-list)

##### View from Performance charts[​](#view-from-performance-charts "Direct link to View from Performance charts")

1. Navigate to Catalog by clicking on the **Explore** link in the navigation.
2. In the main **Overview** page, click on **Performance** under the **Project details** section. Scroll down to view the **Most consumed models**.
3. Use the dropdown menu on the right to select the desired time period, with options available for up to the past 3 months.

[![View most consumed models on the 'Performance' page in dbt Catalog.](/img/docs/collaborate/dbt-explorer/most-consumed-models.jpg?v=2 "View most consumed models on the 'Performance' page in dbt Catalog.")](#)View most consumed models on the 'Performance' page in dbt Catalog.

4. Click on a model for more details and go to the **Performance** tab.
5. On the **Performance** tab, scroll down to the **Model performance** section.
6. Select the **Consumption queries** tab to view the consumption queries over a given time for that model.

[![View consumption queries over time for a given model.](/img/docs/collaborate/model-consumption-queries.jpg?v=2 "View consumption queries over time for a given model.")](#)View consumption queries over time for a given model.

##### View from Project lineage[​](#view-from-project-lineage "Direct link to View from Project lineage")

1. To view your model in your project lineage, go to the main **Overview page** and click on **Project lineage.**
2. In the lower left of your lineage, click on **Lenses** and select **Consumption queries**.

[![View model consumption queries in your lineage using the 'Lenses' feature.](/img/docs/collaborate/dbt-explorer/model-consumption-lenses.jpg?v=2 "View model consumption queries in your lineage using the 'Lenses' feature.")](#)View model consumption queries in your lineage using the 'Lenses' feature.

3. Your lineage should display a small red box above each model, indicating the consumption query number. The number for each model represents the model consumption over the last 30 days.

##### View from Model list[​](#view-from-model-list "Direct link to View from Model list")

1. To view a list of models, go to the main **Overview page**.
2. In the left navigation, go to the **Resources** tab and click on **Models** to view the models list.
3. You can view the consumption query count for the models and sort by most or least consumed. The consumption query number for each model represents the consumption over the last 30 days.

[![View models consumption in the 'Models' list page under the 'Consumption' column.](/img/docs/collaborate/dbt-explorer/model-consumption-list.jpg?v=2 "View models consumption in the 'Models' list page under the 'Consumption' column.")](#)View models consumption in the 'Models' list page under the 'Consumption' column.

#### Was this page helpful?

YesNo

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.


---

### Model versions

Model versions, dbt\_project.yml versions, and .yml versions

Take note that [model versions](https://docs.getdbt.com/docs/mesh/govern/model-versions.md) are different from [dbt\_project.yml versions](https://docs.getdbt.com/reference/project-configs/version.md#dbt_projectyml-versions) and [.yml property file versions](https://docs.getdbt.com/reference/project-configs/version.md#yml-property-file-versions).

Model versions is a *feature* that enables better governance and data model management by allowing you to track changes and updates to models over time. dbt\_project.yml versions refer to the compatibility of the dbt project with a specific version of dbt. Version numbers within .yml property files inform how dbt parses those YAML files. The latter two are completely optional starting from dbt v1.5.

Versioning APIs is a hard problem in software engineering. The root of the challenge is that the producers and consumers of an API have competing incentives:

* Producers of an API need the ability to modify its logic and structure. There is a real cost to maintaining legacy endpoints forever, but losing the trust of downstream users is far costlier.
* Consumers of an API need to trust in its stability: their queries will keep working, and won't break without warning. Although migrating to a newer API version incurs an expense, an unplanned migration is far costlier.

When sharing a final dbt model with other teams or systems, that model is operating like an API. When the producer of that model needs to make significant changes, how can they avoid breaking the queries of its users downstream?

Model versioning is a tool to tackle this problem, thoughtfully and head-on. The goal is not to make the problem go away entirely, nor to pretend it's easier or simpler than it is.

###### Considerations[​](#considerations "Direct link to Considerations")

There are some considerations to keep in mind when using model governance features:

* Model governance features like model access, contracts, and versions strengthen trust and stability in your dbt project. Because they add structure, they can make rollbacks harder (for example, removing model access) and increase maintenance if adopted too early. Before adding governance features, consider whether your dbt project is ready to benefit from them. Introducing governance while models are still changing can complicate future changes.

* Governance features are model-specific. They don't apply to other resource types, including snapshots, seeds, or sources. This is because these objects can change structure over time (for example, snapshots capture evolving historical data) and aren't suited to guarantees like contracts, access, or versioning.

#### Related documentation[​](#related-documentation "Direct link to Related documentation")

* [`versions`](https://docs.getdbt.com/reference/resource-properties/versions.md)
* [`latest_version`](https://docs.getdbt.com/reference/resource-properties/latest_version.md)
* [`include` and `exclude`](https://docs.getdbt.com/reference/resource-properties/versions.md#include)
* [`ref` with `version` argument](https://docs.getdbt.com/reference/dbt-jinja-functions/ref.md#versioned-ref)

#### Why version a model?[​](#why-version-a-model "Direct link to Why version a model?")

If a model defines a ["contract"](https://docs.getdbt.com/docs/mesh/govern/model-contracts.md) (a set of guarantees for its structure), it's also possible to change that model's structure in a way that breaks the previous set of guarantees. This could be as obvious as removing or renaming a column, or more subtle, like changing its data type or nullability.

One approach is to force every model consumer to immediately handle the breaking change as soon as it's deployed to production. This is actually the appropriate answer at many smaller organizations, or while rapidly iterating on a not-yet-mature set of data models. But it doesn’t scale well beyond that.

Instead, for mature models at larger organizations, powering queries inside & outside dbt, the model owner can use **model versions** to:

* Test "prerelease" changes (in production, in downstream systems)
* Bump the latest version, to be used as the canonical source of truth
* Offer a migration window off the "old" version

During that migration window, anywhere that model is being used downstream, it can continue to be referenced at a specific version.

dbt Core 1.6 introduced first-class support for **deprecating models** by specifying a [`deprecation_date`](https://docs.getdbt.com/reference/resource-properties/deprecation_date.md). Taken together, model versions and deprecation offer a pathway for model producers to *sunset* old models, and consumers the time to *migrate* across breaking changes. It's a way of managing change across an organization: develop a new version, bump the latest, slate the old version for deprecation, update downstream references, and then remove the old version.

There is a real trade-off that exists here—the cost to frequently migrate downstream code, and the cost (and clutter) of materializing multiple versions of a model in the data warehouse. Model versions do not make that problem go away, but by setting a deprecation date, and communicating a clear window for consumers to gracefully migrate off old versions, they put a known boundary on the cost of that migration.

#### When should you version a model?[​](#when-should-you-version-a-model "Direct link to When should you version a model?")

By enforcing a model's contract, dbt can help you catch unintended changes to column names and data types that could cause a big headache for downstream queriers. If you're making these changes intentionally, you should create a new model version. If you're making a non-breaking change, you don't need a new version—such as adding a new column, or fixing a bug in an existing column's calculation.

Of course, it's possible to change a model's definition in other ways—recalculating a column in a way that doesn't change its name, data type, or enforceable characteristics—but would substantially change the results seen by downstream queriers.

This is always a judgment call. As the maintainer of a widely-used model, you know best what's a bug fix and what's an unexpected behavior change.

The process of sunsetting and migrating model versions requires real work, and likely significant coordination across teams. You should opt for non-breaking changes whenever possible. Inevitably, however, these non-breaking additions will leave your most important models with lots of unused or deprecated columns.

Rather than constantly adding a new version for each small change, you should opt for a predictable cadence (once or twice a year, communicated well in advance) where you bump the "latest" version of your model, removing columns that are no longer being used.

#### How is this different from "version control"?[​](#how-is-this-different-from-version-control "Direct link to How is this different from \"version control\"?")

[Version control](https://docs.getdbt.com/docs/cloud/git/git-version-control.md) allows your team to collaborate simultaneously on a single code repository, manage conflicts between changes, and review changes before deploying into production. In that sense, version control is an essential tool for versioning the deployment of an entire dbt project—always the latest state of the `main` branch. In general, only one version of your project code is deployed into an environment at a time. If something goes wrong, you have the ability to roll back changes by reverting a commit or pull request, or by leveraging data platform capabilities around "time travel."

When you make updates to a model's source code — its logical definition, in SQL or Python, or related configuration — dbt can [compare your project to the previous state](https://docs.getdbt.com/reference/node-selection/syntax.md#about-node-selection), enabling you to rebuild only models that have changed, and models downstream of a change. In this way, it's possible to develop changes to a model, quickly test in CI, and efficiently deploy into production — all coordinated via your version control system.

**Versioned models are different.** Defining model `versions` is appropriate when people, systems, and processes beyond your team's control, inside or outside of dbt, depend on your models. You can neither simply go migrate them all, nor break their queries on a whim. You need to offer a migration path, with clear diffs and deprecation dates.

Multiple versions of a model will live in the same code repository at the same time, and be deployed into the same data environment simultaneously. This is similar to how web APIs are versioned: Multiple versions live simultaneously, two or three, and not more). Over time, newer versions come online, and older versions are sunsetted .

#### How is this different from just creating a new model?[​](#how-is-this-different-from-just-creating-a-new-model "Direct link to How is this different from just creating a new model?")

Honestly, it's only a little bit different! There isn't much magic here, and that's by design.

You've always been able to copy-paste, create a new model file, and name it `dim_customers_v2.sql`. Why should you opt for a "real" versioned model instead?

As the **producer** of a versioned model:

* You keep track of all live versions in one place, rather than scattering them throughout the codebase
* You can reuse the model's configuration, and highlight just the diffs between versions
* You can select models to build (or not) based on whether they're a `latest`, `prerelease`, or `old` version
* dbt will notify consumers of your versioned model when new versions become available, or when they are slated for deprecation

As the **consumer** of a versioned model:

* You use a consistent `ref`, with the option of pinning to a specific live version
* You will be notified throughout the life cycle of a versioned model

All versions of a model preserve the model's original name. They are `ref`'d by that name, rather than the name of the file that they're defined in. By default, the `ref` resolves to the latest version (as declared by that model's maintainer), but you can also `ref` a specific version of the model, with a `version` keyword.

Let's say that `dim_customers` has three versions defined: `v2` is the "latest", `v3` is "prerelease," and `v1` is an old version that's still within its deprecation window. Because `v2` is the latest version, it gets some special treatment: it can be defined in a file without a suffix, and `ref('dim_customers')` will resolve to `v2` if a version pin is not specified. The table below breaks down the standard conventions:

| v | version      | `ref` syntax                                               | File name                                         | Database relation                                                            |
| - | ------------ | ---------------------------------------------------------- | ------------------------------------------------- | ---------------------------------------------------------------------------- |
| 3 | "prerelease" | `ref('dim_customers', v=3)`                                | `dim_customers_v3.sql`                            | `analytics.dim_customers_v3`                                                 |
| 2 | "latest"     | `ref('dim_customers', v=2)` **and** `ref('dim_customers')` | `dim_customers_v2.sql` **or** `dim_customers.sql` | `analytics.dim_customers_v2` **and** `analytics.dim_customers` (recommended) |
| 1 | "old"        | `ref('dim_customers', v=1)`                                | `dim_customers_v1.sql`                            | `analytics.dim_customers_v1`                                                 |

As you'll see in the implementation section below, a versioned model can reuse the majority of its YAML properties and configuration. Each version needs to only say how it *differs* from the shared set of attributes. This gives you, as the producer of a versioned model, the opportunity to highlight the differences across versions—which is otherwise difficult to detect in models with dozens or hundreds of columns—and to clearly track, in one place, all versions of the model which are currently live.

dbt also supports [`version`-based selection](https://docs.getdbt.com/reference/node-selection/methods.md#version). For example, you could define a [default YAML selector](https://docs.getdbt.com/reference/node-selection/yaml-selectors.md#default) that avoids running any old model versions in development, even while you continue to run them in production through a sunset and migration period. (You could accomplish something similar by applying `tags` to these models, and cycling through those tags over time.)

selectors.yml
```

---

## Example usage:

**URL:** llms-txt#example-usage:

**Contents:**
  - dbt Command reference
  - dbt Jinja functions
  - dbt_project.yml
  - dbt_valid_to_current
  - Defer
  - Define configs
  - Define properties
  - Defining a database source property
  - Defining a schema source property
  - delimiter

col = Column('name', 'varchar', 255)
col.is_string() # True
col.is_numeric() # False
col.is_number() # False
col.is_integer() # False
col.is_float() # False
col.string_type() # character varying(255)
col.numeric_type('numeric', 12, 4) # numeric(12,4)

-- String column
{%- set string_column = api.Column('name', 'varchar', char_size=255) %}

-- Return true if the column is a string
{{ string_column.is_string() }}

-- Return true if the column is a numeric
{{ string_column.is_numeric() }}

-- Return true if the column is a number
{{ string_column.is_number() }}

-- Return true if the column is an integer
{{ string_column.is_integer() }}

-- Return true if the column is a float
{{ string_column.is_float() }}

-- Numeric column
{%- set numeric_column = api.Column('distance_traveled', 'numeric', numeric_precision=12, numeric_scale=4) %}

-- Return true if the column is a string
{{ numeric_column.is_string() }}

-- Return true if the column is a numeric
{{ numeric_column.is_numeric() }}

-- Return true if the column is a number
{{ numeric_column.is_number() }}

-- Return true if the column is an integer
{{ numeric_column.is_integer() }}

-- Return true if the column is a float
{{ numeric_column.is_float() }}

-- Return the string data type for this database adapter with a given size
{{ api.Column.string_type(255) }}

-- Return the numeric data type for this database adapter with a given precision and scale
{{ api.Column.numeric_type('numeric', 12, 4) }}

[{"hits": {"pageviews": 1, "bounces": 0}}]

[{"hits.pageviews": 1, "hits.bounces": 0}]

config-version: 2
version: version

model-paths: [directorypath]
seed-paths: [directorypath]
test-paths: [directorypath]
analysis-paths: [directorypath]
macro-paths: [directorypath]
snapshot-paths: [directorypath]
docs-paths: [directorypath]
asset-paths: [directorypath]
function-paths: [directorypath]

packages-install-path: directorypath

clean-targets: [directorypath]

query-comment: string

require-dbt-version: version-range | [version-range]

flags:
  <global-configs>

dbt-cloud:
  project-id: project_id # Required
  defer-env-id: environment_id # Optional

exposures:
  +enabled: true | false

quoting:
  database: true | false
  schema: true | false
  identifier: true | false
  snowflake_ignore_case: true | false  # Fusion-only config. Aligns with Snowflake's session parameter QUOTED_IDENTIFIERS_IGNORE_CASE behavior. 
                                       # Ignored by dbt Core and other adapters.
metrics:
  <metric-configs>

models:
  <model-configs>

seeds:
  <seed-configs>

semantic-models:
  <semantic-model-configs>

saved-queries:
  <saved-queries-configs>

snapshots:
  <snapshot-configs>

sources:
  <source-configs>
  
data_tests:
  <test-configs>

on-run-start: sql-statement | [sql-statement]
on-run-end: sql-statement | [sql-statement]

dispatch:
  - macro_namespace: packagename
    search_order: [packagename]

restrict-access: true | false

functions:
  <function-configs>

saved-queries:  # Use dashes for resource types in the dbt_project.yml file.
    my_saved_query:
      +cache:
        enabled: true
  
  saved_queries:  # Use underscores everywhere outside the dbt_project.yml file.
    - name: saved_query_name
      ... # Rest of the saved queries configuration.
      config:
        cache:
          enabled: true
  
snapshots:
  - name: my_snapshot
    config:
      dbt_valid_to_current: "string"

{{
    config(
        unique_key='id',
        strategy='timestamp',
        updated_at='updated_at',
        dbt_valid_to_current='string'
    )
}}

snapshots:
  <resource-path>:
    +dbt_valid_to_current: "string"

snapshots:
  - name: my_snapshot
    config:
      strategy: timestamp
      updated_at: updated_at
      dbt_valid_to_current: "to_date('9999-12-31')"
    columns:
      - name: dbt_valid_from
        description: The timestamp when the record became valid.
      - name: dbt_valid_to
        description: >
          The timestamp when the record ceased to be valid. For current records,
          this is either `NULL` or the value specified in `dbt_valid_to_current`
          (like `'9999-12-31'`).

dbt run --select [...] --defer --state path/to/artifacts
dbt test --select [...] --defer --state path/to/artifacts

from {{ ref('model_a') }}
group by 1

dbt run --select "model_b"

create or replace view dev_me.model_b as (

from dev_alice.model_a
    group by 1

dbt run --select "model_b" --defer --state prod-run-artifacts

create or replace view dev_me.model_b as (

from prod.model_a
    group by 1

models:
  - name: model_b
    columns:
      - name: id
        data_tests:
          - relationships:
              arguments: # available in v1.10.5 and higher. Older versions can set the <argument_name> as the top-level property.
                to: ref('model_a')
                field: id

dbt test --select "model_b"

select count(*) as validation_errors
from (
    select id as id from dev_alice.model_b
) as child
left join (
    select id as id from dev_alice.model_a
) as parent on parent.id = child.id
where child.id is not null
  and parent.id is null

dbt test --select "model_b" --defer --state prod-run-artifacts

select count(*) as validation_errors
from (
    select id as id from dev_alice.model_b
) as child
left join (
    select id as id from prod.model_a
) as parent on parent.id = child.id
where child.id is not null
  and parent.id is null

sources:
  - name: raw_jaffle_shop
    description: A replica of the postgres database used to power the jaffle_shop app.
    tables:
      - name: customers
        columns:
          - name: id
            description: Primary key of the table
            data_tests:
              - unique
              - not_null

- name: orders
        columns:
          - name: id
            description: Primary key of the table
            data_tests:
              - unique
              - not_null

- name: user_id
            description: Foreign key to customers

- name: status
            data_tests:
              - accepted_values:
                  arguments: # available in v1.10.5 and higher. Older versions can set the <argument_name> as the top-level property.
                    values: ['placed', 'shipped', 'completed', 'return_pending', 'returned']

models:
  - name: stg_jaffle_shop__customers #  Must match the filename of a model -- including case sensitivity.
    config:
      tags: ['pii']
    columns:
      - name: customer_id
        data_tests:
          - unique
          - not_null

- name: stg_jaffle_shop__orders
    config:
      materialized: view
    columns:
      - name: order_id
        data_tests:
          - unique
          - not_null
      - name: status
        data_tests:
          - accepted_values:
              values: ['placed', 'shipped', 'completed', 'return_pending', 'returned']
              config:
                severity: warn

* Invalid test config given in models/schema.yml near {'namee': 'event', ...}
  Invalid arguments passed to "UnparsedNodeUpdate" instance: 'name' is a required property, Additional properties are not allowed ('namee' was unexpected)

Runtime Error
  Syntax error near line 6
  ------------------------------
  5  |   - name: events
  6  |     description; "A table containing clickstream events from the marketing website"
  7  |

Raw Error:
  ------------------------------
  while scanning a simple key
    in "<unicode string>", line 6, column 5:
          description; "A table containing clickstream events from the marketing website"
          ^

sources:
  - name: raw_jaffle_shop
    description: A replica of the postgres database used to power the jaffle_shop app.
    tables:
      - name: customers
        columns:
          - name: id
            description: Primary key of the table
            data_tests:
              - unique
              - not_null

- name: orders
        columns:
          - name: id
            description: Primary key of the table
            data_tests:
              - unique
              - not_null

- name: user_id
            description: Foreign key to customers

- name: status
            data_tests:
              - accepted_values:
                  arguments: # available in v1.10.5 and higher. Older versions can set the <argument_name> as the top-level property.
                    values: ['placed', 'shipped', 'completed', 'return_pending', 'returned']

models:
  - name: stg_jaffle_shop__customers #  Must match the filename of a model -- including case sensitivity.
    config:
      tags: ['pii']
    columns:
      - name: customer_id
        data_tests:
          - unique
          - not_null

- name: stg_jaffle_shop__orders
    config:
      materialized: view
    columns:
      - name: order_id
        data_tests:
          - unique
          - not_null
      - name: status
        data_tests:
          - accepted_values:
              values: ['placed', 'shipped', 'completed', 'return_pending', 'returned']
              config:
                severity: warn

* Invalid test config given in models/schema.yml near {'namee': 'event', ...}
  Invalid arguments passed to "UnparsedNodeUpdate" instance: 'name' is a required property, Additional properties are not allowed ('namee' was unexpected)

Runtime Error
  Syntax error near line 6
  ------------------------------
  5  |   - name: events
  6  |     description; "A table containing clickstream events from the marketing website"
  7  |

Raw Error:
  ------------------------------
  while scanning a simple key
    in "<unicode string>", line 6, column 5:
          description; "A table containing clickstream events from the marketing website"
          ^

sources:
  - name: <source_name>
    database: <database_name>
    tables:
      - name: <table_name>
      - ...

sources:
  - name: jaffle_shop
    database: raw
    tables:
      - name: orders
      - name: customers

sources:
  - name: <source_name>
    database: <database_name>
    schema: <schema_name>
    tables:
      - name: <table_name>
      - ...

sources:
  - name: jaffle_shop
    schema: postgres_backend_public_schema
    tables:
      - name: orders

select * from {{ source('jaffle_shop', 'orders') }}

select * from postgres_backend_public_schema.orders

seeds:
  <project_name>:
     +delimiter: "|" # default project delimiter for seeds will be "|"
    <seed_subdirectory>:
      +delimiter: "," # delimiter for seeds in seed_subdirectory will be ","

seeds:
  - name: <seed_name>
    config: 
      delimiter: "|"

seeds:
  jaffle_shop: 
    +delimiter: "|" # default delimiter for seeds in jaffle_shop project will be "|"
    seed_a:
      +delimiter: "," # delimiter for seed_a will be ","

col_a|col_b|col_c
1|2|3
4|5|6
...

name,id
luna,1
doug,2
...

seeds:
  - name: country_codes
    config:
      delimiter: ";"

country_code;country_name
US;United States
CA;Canada
GB;United Kingdom
...

models:
  - name: my_model
    description: deprecated
    deprecation_date: 1999-01-01 00:00:00.00+00:00

models:
  - name: my_model
    description: deprecating in the future
    deprecation_date: 2999-01-01 00:00:00.00+00:00

$ dbt parse
15:48:14  Running with dbt=1.6.0
15:48:14  Registered adapter: postgres=1.6.0
15:48:14  [WARNING]: While compiling 'my_model_ref': Found a reference to my_model, which is slated for deprecation on '2038-01-19T03:14:07-00:00'.

dbt parse --no-partial-parse --show-all-deprecations

19:15:13 [WARNING]: Deprecated functionality
Summary of encountered deprecations:
- MFTimespineWithoutYamlConfigurationDeprecation: 1 occurrence

models:
  - name: my_model_with_generic_test
    data_tests:
      - my_custom_generic_test:
          arguments: [1,2,3]
          expression: "order_items_subtotal = subtotal"

models:
  - name: my_model_with_generic_test
    data_tests:
      - my_custom_generic_test:
          arguments: 
            arguments: [1,2,3]
            expression: "order_items_subtotal = subtotal"

models:
  - name: my_model_with_generic_test
    data_tests:
      - my_custom_generic_test:
          arguments:
            renamed_arguments: [1,2,3]
            expression: "order_items_subtotal = subtotal"

23:14:58  [WARNING]: Deprecated functionality
The `data-paths` config has been renamed to `seed-paths`. Please update your
`dbt_project.yml` configuration to reflect this change.

23:39:18  [WARNING]: Deprecated functionality
The `log-path` config in `dbt_project.yml` has been deprecated and will no
longer be supported in a future version of dbt-core. If you wish to write dbt
logs to a custom directory, please use the --log-path CLI flag or DBT_LOG_PATH
env var instead.

23:03:47  [WARNING]: Deprecated functionality
The `source-paths` config has been renamed to `model-paths`. Please update your
`dbt_project.yml` configuration to reflect this change.
23:03:47  Registered adapter: postgres=1.9.0

23:22:01  [WARNING]: Deprecated functionality
The `target-path` config in `dbt_project.yml` has been deprecated and will no
longer be supported in a future version of dbt-core. If you wish to write dbt
artifacts to a custom directory, please use the --target-path CLI flag or
DBT_TARGET_PATH env var instead.

models:
  - name: my_model
    config:
      custom_config_key: value

models:
  - name: my_model
    config:
      meta:
        custom_config_key: value

models:
  - name: my_model
    config:
      custom_config_key: value
    columns:
      - name: my_column
        meta:
          some_key: some_value

models:
  - name: my_model
    config:
      meta:
        custom_config_key: value
    columns:
      - name: my_column
        config:
          meta:
            some_key: some_value

{% set my_custom_config = config.get('custom_config_key') %}

{% set my_custom_config = config.get('meta').custom_config_key %}

models:
  my_project:
    staging:
      +materialized: view
    marts:
      +materialized: table

custom_metadata:
  owner: "data_team"
  description: "This project contains models for our analytics platform"
  last_updated: "2025-07-01"

models:
  my_project:
    staging:
      +materialized: view
    marts:
      +materialized: table

config:
  meta:
    custom_metadata:
      owner: "data_team"
      description: "This project contains models for our analytics platform"
      last_updated: "2025-07-01"

my_profile:
  target: 
  outputs:
...

my_profile: # dbt would use this profile key
  target: 
  outputs:
...

23:55:00  [WARNING]: Deprecated functionality
Starting in v1.3, the 'name' of an exposure should contain only letters,
numbers, and underscores. Exposures support a new property, 'label', which may
contain spaces, capital letters, and special characters. stg_&customers does not
follow this pattern. Please update the 'name', and use the 'label' property for
a human-friendly title. This will raise an error in a future version of
dbt-core.

15:36:22  [WARNING]: Cumulative fields `type_params.window` and
`type_params.grain_to_date` has been moved and will soon be deprecated. Please
nest those values under `type_params.cumulative_type_params.window` and
`type_params.cumulative_type_params.grain_to_date`. See documentation on
behavior changes:
https://docs.getdbt.com/reference/global-configs/behavior-changes.

19:56:41  [WARNING]: Time spines without YAML configuration are in the process of
deprecation. Please add YAML configuration for your 'metricflow_time_spine'
model. See documentation on MetricFlow time spines:
https://docs.getdbt.com/docs/build/metricflow-time-spine and behavior change
documentation:
https://docs.getdbt.com/reference/global-configs/behavior-changes

models:
  - name: my_model_with_generic_test
    data_tests:
      - dbt_utils.expression_is_true:
          expression: "order_items_subtotal = subtotal"

models:
  - name: my_model_with_generic_test
    data_tests:
    - name: arbitrary_name
      test_name: dbt_utils.expression_is_true
      expression: "order_items_subtotal = subtotal"
      where: "1=1"

models:
  - name: my_model_with_generic_test
    data_tests:
      - dbt_utils.expression_is_true:
          arguments: 
            expression: "order_items_subtotal = subtotal"

models:
  - name: my_model_with_generic_test
    data_tests:
    - name: arbitrary_name
      test_name: dbt_utils.expression_is_true
      arguments:
         expression: "order_items_subtotal = subtotal"
      config:
        where: "1=1"

18:16:06  [WARNING][MissingPlusPrefixDeprecation]: Deprecated functionality
Missing '+' prefix on `tags` found at `my_path.sub_path.another_path.tags` in
file `dbt_project.yml`. Hierarchical config
values without a '+' prefix are deprecated in dbt_project.yml.

models: 
  marts:
    materialized: table

models: 
  marts:
    +materialized: table

15:49:33  [WARNING]: Deprecated functionality
Usage of itertools modules is deprecated. Please use the built-in functions
instead.

{%- set A = [1, 2] -%}
{%- set B = ['x', 'y', 'z'] -%}
{%- set AB_cartesian = modules.itertools.product(A, B) -%}

{%- for item in AB_cartesian %}
  {{ item }}
{%- endfor -%}

{%- macro cartesian_product(list1, list2) -%}
  {%- set result = [] -%}
  {%- for item1 in list1 -%}
    {%- for item2 in list2 -%}
      {%- set _ = result.append((item1, item2)) -%}
    {%- endfor -%}
  {%- endfor -%}
  {{ return(result) }}
{%- endmacro -%}

{%- set A = [1, 2] -%}
{%- set B = ['x', 'y', 'z'] -%}
{%- set AB_cartesian = cartesian_product(A, B) -%}

{%- for item in AB_cartesian %}
  {{ item }}
{%- endfor -%}

22:48:01  [WARNING]: Deprecated functionality
The default package install path has changed from `dbt_modules` to
`dbt_packages`. Please update `clean-targets` in `dbt_project.yml` and
check `.gitignore`. Or, set `packages-install-path: dbt_modules`
If you'd like to keep the current value.

{% materialization table, snowflake %}
    {{ return (package_name.materialization_table_snowflake()) }}
{% endmaterialization %}

22:31:38  [WARNING]: Deprecated functionality
The `fishtown-analytics/dbt_utils` package is deprecated in favor of
`dbt-labs/dbt_utils`. Please update your `packages.yml` configuration to use
`dbt-labs/dbt_utils` instead.

00:08:12  [WARNING]: Deprecated functionality
User config should be moved from the 'config' key in profiles.yml to the 'flags' key in dbt_project.yml.

sources: 
  - name: ecom
    schema: raw
    description: E-commerce data for the Jaffle Shop
    freshness:
      warn_after:
        count: 24
        period: hour

sources: 
  - name: ecom
    schema: raw
    description: E-commerce data for the Jaffle Shop
    config:
      freshness:
        warn_after:
          count: 24
          period: hour

16:37:58  [WARNING]: Found spaces in the name of `model.jaffle_shop.stg supplies`

19:51:56  [WARNING]: In a future version of dbt, the `source freshness` command
will start running `on-run-start` and `on-run-end` hooks by default. For more
information: https://docs.getdbt.com/reference/global-configs/legacy-behaviors

{% endmacro %} # orphaned endmacro jinja block

{% macro hello() %}
hello!
{% endmacro %}

...
  flags:
    warn_error_options:
      include:
        - NoNodesForSelectionCriteria

...
  flags:
    warn_error_options:
      error:
        - NoNodesForSelectionCriteria

models:
  - name: model_name
    description: markdown_string

columns:
      - name: column_name
        description: markdown_string

sources:
  - name: source_name
    description: markdown_string

tables:
      - name: table_name
        description: markdown_string

columns:
          - name: column_name
            description: markdown_string

seeds:
  - name: seed_name
    description: markdown_string

columns:
      - name: column_name
        description: markdown_string

snapshots:
  - name: snapshot_name
    description: markdown_string

columns:
      - name: column_name
        description: markdown_string

analyses:
  - name: analysis_name
    description: markdown_string

columns:
      - name: column_name
        description: markdown_string

macros:
  - name: macro_name
    description: markdown_string

arguments:
      - name: argument_name
        description: markdown_string

unit_tests:
  - name: unit_test_name
    description: "markdown_string"
    model: model_name 
    given: ts
      - input: ref_or_source_call
        rows:
         - {column_name: column_value}
         - {column_name: column_value}
         - {column_name: column_value}
         - {column_name: column_value}
      - input: ref_or_source_call
        format: csv
        rows: dictionary | string
    expect: 
      format: dict | csv | sql
      fixture: fixture_name

models:
  - name: dim_customers
    description: One record per customer

columns:
      - name: customer_id
        description: Primary key

models:
  - name: dim_customers
    description: >
      One record per customer. Note that a customer must have made a purchase to
      be included in this <Term id="table" /> — customer accounts that were created but never
      used have been filtered out.

columns:
      - name: customer_id
        description: Primary key.

models:
  - name: dim_customers
    description: "**[Read more](https://www.google.com/)**"

columns:
      - name: customer_id
        description: Primary key.

models:
  - name: fct_orders
    description: This table has basic information about orders, as well as some derived facts based on payments

columns:
      - name: status
        description: '{{ doc("orders_status") }}'

{% docs orders_status %}

Orders can be one of the following statuses:

| status         | description                                                               |
|----------------|---------------------------------------------------------------------------|
| placed         | The order has been placed but has not yet left the warehouse              |
| shipped        | The order has been shipped to the customer and is currently in transit     |
| completed      | The order has been received by the customer                               |
| returned       | The order has been returned by the customer and received at the warehouse |

models:
  - name: customers
    description: "Filtering done based on [stg_stripe__payments](#!/model/model.jaffle_shop.stg_stripe__payments)"

columns:
      - name: customer_id
        description: Primary key

asset-paths: ["assets"]

models:
  - name: customers
    description: "![dbt Logo](assets/dbt-logo.svg)"

columns:
      - name: customer_id
        description: Primary key

models:
  - name: customers
    description: "![dbt Logo](https://github.com/dbt-labs/dbt-core/blob/main/etc/dbt-core.svg)"

columns:
      - name: customer_id
        description: Primary key

models:
  - name: orders
    columns:
      - name: order_id
        data_tests:
          - unique:
              description: "The order_id is unique for every row in the orders model"

data_tests:
  - name: assert_total_payment_amount_is_positive
    description: >
      Refunds have a negative amount, so the total amount should always be >= 0.
      Therefore return records where total amount < 0 to make the test fail.

unit_tests:
  - name: test_does_location_opened_at_trunc_to_date
    description: "Check that opened_at timestamp is properly truncated to a date."
    model: stg_locations
    given:
      - input: source('ecom', 'raw_stores')
        rows:
          - {id: 1, name: "Rego Park", tax_rate: 0.2, opened_at: "2016-09-01T00:00:00"}
          - {id: 2, name: "Jamaica", tax_rate: 0.1, opened_at: "2079-10-27T23:59:59.9999"}
    expect:
      rows:
        - {location_id: 1, location_name: "Rego Park", tax_rate: 0.2, opened_date: "2016-09-01"}
        - {location_id: 2, location_name: "Jamaica", tax_rate: 0.1, opened_date: "2079-10-27"}

dispatch:
  - macro_namespace: packagename
    search_order: [packagename]
  - macro_namespace: packagename
    search_order: [packagename]

dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']

dispatch:
  - macro_namespace: dbt_utils
    search_order: ['my_root_project', 'dbt_utils']

models:
  <resource-path>:
    +docs:
      show: true | false
      node_color: color_id # Use name (such as node_color: purple) or hex code with quotes (such as node_color: "#cd7f32")

models:
- name: model_name
  config:
    docs: # changed to config in v1.10
      show: true | false
      node_color: color_id # Use name (such as node_color: purple) or hex code with quotes (such as node_color: "#cd7f32")

seeds:
  <resource-path>:
    +docs:
      show: true | false
      node_color: color_id # Use name (such as node_color: purple) or hex code with quotes (such as node_color: "#cd7f32")

seeds:
  - name: seed_name
    config:
      docs: # changed to config in v1.10
        show: true | false
        node_color: color_id # Use name (such as node_color: purple) or hex code with quotes (such as node_color: "#cd7f32")

snapshots:
  <resource-path>:
    +docs:
      show: true | false
      node_color: color_id # Use name (such as node_color: purple) or hex code with quotes (such as node_color: "#cd7f32")

snapshots:
  - name: snapshot_name
    config:
      docs: # changed to config in v1.10
        show: true | false
        node_color: color_id # Use name (such as node_color: purple) or hex code with quotes (such as node_color: "#cd7f32")

analyses:
  - name: analysis_name
    config:
      docs: # changed to config in v1.10
        show: true | false
        node_color: color_id # Use name (such as node_color: purple) or hex code with quotes (such as node_color: "#cd7f32")

macros:
  - name: macro_name
    config:
      docs: # changed to config in v1.10
        show: true | false

models:
  - name: sessions__tmp
    docs:
      show: false

models:
  # hiding models within the staging subfolder
  tpch:
    staging:
      +materialized: view
      +docs:
        show: false
  
  # hiding a dbt package
  dbt_artifacts:
    +docs:
      show: false

models:
  tpch:
    staging:
      +materialized: view
      +docs:
        node_color: "#cd7f32"

marts:
      core:
        materialized: table
        +docs:
          node_color: "gold"

models:
  - name: dim_customers
    description: Customer dimensions table
    docs:
      node_color: '#000000'

{{
    config(
        materialized = 'view',
        tags=['finance'],
        docs={'node_color': 'red'}
    )
}}

with orders as (
    
    select * from {{ ref('stg_tpch_orders') }}

),
order_item as (
    
    select * from {{ ref('order_items') }}

),
order_item_summary as (

select 
        order_key,
        sum(gross_item_sales_amount) as gross_item_sales_amount,
        sum(item_discount_amount) as item_discount_amount,
        sum(item_tax_amount) as item_tax_amount,
        sum(net_item_sales_amount) as net_item_sales_amount
    from order_item
    group by
        1
),
final as (

orders.order_key, 
        orders.order_date,
        orders.customer_key,
        orders.status_code,
        orders.priority_code,
        orders.clerk_name,
        orders.ship_priority,
                
        1 as order_count,                
        order_item_summary.gross_item_sales_amount,
        order_item_summary.item_discount_amount,
        order_item_summary.item_tax_amount,
        order_item_summary.net_item_sales_amount
    from
        orders
        inner join order_item_summary
            on orders.order_key = order_item_summary.order_key
)
select 
    *
from
    final

order by
    order_date

Invalid color name for docs.node_color: aweioohafio23f. It is neither a valid HTML color name nor a valid HEX code.

models:
  tpch:
    marts:
      core:
        materialized: table
        +docs:
          node_color: "aweioohafio23f"

docs-paths: [directorypath]

docs-paths: ["docs"]
    
    docs-paths: ["/Users/username/project/docs"]
    
docs-paths: ["docs"]

models:
  <resource-path>:
    +materialized: view

{{ config(materialized = "view") }}

models:
  <resource-path>:
    +materialized: table
    +duplicate_key: [ <column-name>, ... ],
    +partition_by: [ <column-name>, ... ],
    +partition_type: <engine-type>,
    +partition_by_init: [<pertition-init>, ... ]
    +distributed_by: [ <column-name>, ... ],
    +buckets: int,
    +properties: {<key>:<value>,...}

{{ config(
    materialized = "table",
    duplicate_key = [ "<column-name>", ... ],
    partition_by = [ "<column-name>", ... ],
    partition_type = "<engine-type>",
    partition_by_init = ["<pertition-init>", ... ]
    distributed_by = [ "<column-name>", ... ],
    buckets = "int",
    properties = {"<key>":"<value>",...}
      ...
    ]
) }}

models:
  <resource-path>:
    +materialized: incremental
    +unique_key: [ <column-name>, ... ],
    +partition_by: [ <column-name>, ... ],
    +partition_type: <engine-type>,
    +partition_by_init: [<pertition-init>, ... ]
    +distributed_by: [ <column-name>, ... ],
    +buckets: int,
    +properties: {<key>:<value>,...}

{{ config(
    materialized = "incremental",
    unique_key = [ "<column-name>", ... ],
    partition_by = [ "<column-name>", ... ],
    partition_type = "<engine-type>",
    partition_by_init = ["<pertition-init>", ... ]
    distributed_by = [ "<column-name>", ... ],
    buckets = "int",
    properties = {"<key>":"<value>",...}
      ...
    ]
) }}

your_profile_name:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: 'file_path/database_name.duckdb'
      extensions:
        - httpfs
        - parquet
      settings:
        s3_region: my-aws-region
        s3_access_key_id: "{{ env_var('S3_ACCESS_KEY_ID') }}"
        s3_secret_access_key: "{{ env_var('S3_SECRET_ACCESS_KEY') }}"

default:
  outputs:
    dev:
      type: duckdb
      path: /tmp/dbt.duckdb
      filesystems:
        - fs: s3
          anon: false
          key: "{{ env_var('S3_ACCESS_KEY_ID') }}"
          secret: "{{ env_var('S3_SECRET_ACCESS_KEY') }}"
          client_kwargs:
            endpoint_url: "http://localhost:4566"
  target: dev

default:
  outputs:
    dev:
      type: duckdb
      path: /tmp/dbt.duckdb
      extensions:
        - httpfs
        - parquet
      secrets:
        - type: s3
          region: my-aws-region
          key_id: "{{ env_var('S3_ACCESS_KEY_ID') }}"
          secret: "{{ env_var('S3_SECRET_ACCESS_KEY') }}"
  target: dev

default:
  outputs:
    dev:
      type: duckdb
      path: /tmp/dbt.duckdb
      extensions:
        - httpfs
        - parquet
      secrets:
        - type: s3
          provider: credential_chain
  target: dev

default:
  outputs:
    dev:
      type: duckdb
      path: /tmp/dbt.duckdb
      attach:
        - path: /tmp/other.duckdb
        - path: ./yet/another.duckdb
          alias: yet_another
        - path: s3://yep/even/this/works.duckdb
          read_only: true
        - path: sqlite.db
          type: sqlite

default:
  outputs:
    dev:
      type: duckdb
      path: /tmp/dbt.duckdb
      plugins:
        - module: gsheet
          config:
            method: oauth
        - module: sqlalchemy
          alias: sql
          config:
            connection_url: "{{ env_var('DBT_ENV_SECRET_SQLALCHEMY_URI') }}"
        - module: path.to.custom_udf_module

def batcher(batch_reader: pa.RecordBatchReader):
    for batch in batch_reader:
        df = batch.to_pandas()
        # Do some operations on the DF...
        # ...then yield back a new batch
        yield pa.RecordBatch.from_pandas(df)

def model(dbt, session):
    big_model = dbt.ref("big_model")
    batch_reader = big_model.record_batch(100_000)
    batch_iter = batcher(batch_reader)
    return pa.RecordBatchReader.from_batches(batch_reader.schema, batch_iter)

sources:
  - name: external_source
    config:
      meta: # changed to config in v1.10
        external_location: "s3://my-bucket/my-sources/{name}.parquet"
    tables:
      - name: source1
      - name: source2

SELECT *
FROM {{ source('external_source', 'source1') }}

SELECT *
FROM 's3://my-bucket/my-sources/source1.parquet'

sources:
  - name: external_source
    config:
      meta: # changed to config in v1.10
        external_location: "s3://my-bucket/my-sources/{name}.parquet"
    tables:
      - name: source1
      - name: source2
        config:
          external_location: "read_parquet(['s3://my-bucket/my-sources/source2a.parquet', 's3://my-bucket/my-sources/source2b.parquet'])"

SELECT *
FROM {{ source('external_source', 'source2') }}

SELECT *
FROM read_parquet(['s3://my-bucket/my-sources/source2a.parquet', 's3://my-bucket/my-sources/source2b.parquet'])

sources:
  - name: flights_source
    tables:
      - name: flights
        config:
          external_location: "read_csv('flights.csv', types={'FlightDate': 'DATE'}, names=['FlightDate', 'UniqueCarrier'])"
          formatter: oldstyle

{{
  config(materialized='external', location='local/directory/file.parquet') 
}}

SELECT m.*, s.id IS NOT NULL as has_source_id
FROM {{ ref('upstream_model') }} m
LEFT JOIN {{ source('upstream', 'source') }} s USING (id)

on-run-start:
  - "{{ register_upstream_external_models() }}"

models:
  <resource-path>:
    +enabled: true | false

{{ config(
  enabled=true | false
) }}

seeds:
  <resource-path>:
    +enabled: true | false

snapshots:
  <resource-path>:
    +enabled: true | false

**Examples:**

Example 1 (unknown):
```unknown
##### Column API[​](#column-api "Direct link to Column API")

##### Properties[​](#properties "Direct link to Properties")

* **char\_size**: Returns the maximum size for character varying columns
* **column**: Returns the name of the column
* **data\_type**: Returns the data type of the column (with size/precision/scale included)
* **dtype**: Returns the data type of the column (without any size/precision/scale included)
* **name**: Returns the name of the column (identical to `column`, provided as an alias).
* **numeric\_precision**: Returns the maximum precision for fixed decimal columns
* **numeric\_scale**: Returns the maximum scale for fixed decimal columns
* **quoted**: Returns the name of the column wrapped in quotes

##### Instance methods[​](#instance-methods "Direct link to Instance methods")

* **is\_string()**: Returns True if the column is a String type (eg. text, varchar), else False
* **is\_numeric()**: Returns True if the column is a fixed-precision Numeric type (eg. `numeric`), else False
* **is\_number()**: Returns True if the column is a number-y type (eg. `numeric`, `int`, `float`, or similar), else False
* **is\_integer()**: Returns True if the column is an integer (eg. `int`, `bigint`, `serial` or similar), else False
* **is\_float()**: Returns True if the column is a float type (eg. `float`, `float64`, or similar), else False
* **string\_size()**: Returns the width of the column if it is a string type, else, an exception is raised

##### Static methods[​](#static-methods "Direct link to Static methods")

* **string\_type(size)**: Returns a database-useable representation of the string type (eg. `character varying(255)`)
* **numeric\_type(dtype, precision, scale)**: Returns a database-useable representation of the numeric type (eg. `numeric(12, 4)`)

##### Using columns[​](#using-columns "Direct link to Using columns")

column\_usage.sql
```

Example 2 (unknown):
```unknown
#### BigQuery columns[​](#bigquery-columns "Direct link to BigQuery columns")

The `Column` type is overridden as a `BigQueryColumn` in BigQuery dbt projects. This object works the same as the `Column` type described above, with the exception of extra properties and methods:

##### Properties[​](#properties-1 "Direct link to Properties")

* **fields**: Returns the list of subfields contained within a field (if the column is a STRUCT)
* **mode**: Returns the "mode" of the column, eg. `REPEATED`

##### Instance methods[​](#instance-methods-1 "Direct link to Instance methods")

**flatten()**: Return a flattened list of `BigQueryColumns` in which subfields are expanded into their own columns. For example, this nested field:
```

Example 3 (unknown):
```unknown
will be expanded to:
```

Example 4 (unknown):
```unknown
#### Result objects[​](#result-objects "Direct link to Result objects")

The execution of a resource in dbt generates a `Result` object. This object contains information about the executed node, timing, status, and metadata returned by the adapter. At the end of an invocation, dbt records these objects in [`run_results.json`](https://docs.getdbt.com/reference/artifacts/run-results-json.md).

* `node`: Full object representation of the dbt resource (model, seed, snapshot, test) executed, including its `unique_id`
* `status`: dbt's interpretation of runtime success, failure, or error
* `thread_id`: Which thread executed this node? E.g. `Thread-1`
* `execution_time`: Total time spent executing this node, measured in seconds.
* `timing`: Array that breaks down execution time into steps (often `compile` + `execute`)
* `message`: How dbt will report this result on the CLI, based on information returned from the database

<!-- -->

* `adapter_response`: Dictionary of metadata returned from the database, which varies by adapter. For example, success `code`, number of `rows_affected`, total `bytes_processed`, and so on. Not applicable for [data tests](https://docs.getdbt.com/docs/build/data-tests.md).
  <!-- -->
  * `rows_affected` returns the number of rows modified by the last statement executed. In cases where the query's row count can't be determined or isn't applicable (such as when creating a view), a [standard value](https://peps.python.org/pep-0249/#rowcount) of `-1` is returned for `rowcount`.

#### Was this page helpful?

YesNo

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.


---

### dbt Command reference

You can run dbt using the following tools:

* In your browser with the [Studio IDE](https://docs.getdbt.com/docs/cloud/dbt-cloud-ide/develop-in-the-cloud.md)
* On the command line interface using the [Cloud CLI](https://docs.getdbt.com/docs/cloud/cloud-cli-installation.md) or open-source [dbt Core](https://docs.getdbt.com/docs/core/installation-overview.md).

A key distinction with the tools mentioned, is that Cloud CLI and Studio IDE are designed to support safe parallel execution of dbt commands, leveraging dbt's infrastructure and its comprehensive [features](https://docs.getdbt.com/docs/cloud/about-cloud/dbt-cloud-features.md). In contrast, dbt Core *doesn't support* safe parallel execution for multiple invocations in the same process. Learn more in the [parallel execution](#parallel-execution) section.

#### Parallel execution[​](#parallel-execution "Direct link to Parallel execution")

dbt allows for concurrent execution of commands, enhancing efficiency without compromising data integrity. This enables you to run multiple commands at the same time. However, it's important to understand which commands can be run in parallel and which can't.

In contrast, [`dbt-core` *doesn't* support](https://docs.getdbt.com/reference/programmatic-invocations.md#parallel-execution-not-supported) safe parallel execution for multiple invocations in the same process, and requires users to manage concurrency manually to ensure data integrity and system stability.

To ensure your dbt workflows are both efficient and safe, you can run different types of dbt commands at the same time (in parallel) — for example, `dbt build` (write operation) can safely run alongside `dbt parse` (read operation) at the same time. However, you can't run `dbt build` and `dbt run` (both write operations) at the same time.

dbt commands can be `read` or `write` commands:

| Command type | Description                                                                                                                                                                                                                                                                                                                | Example                        |
| ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------ |
| **Write**    | These commands perform actions that change data or metadata in your data platform.<br /><br />Limited to one invocation at any given time, which prevents any potential conflicts, such as overwriting the same table in your data platform at the same time.                                                              | `dbt build`<br />`dbt run`     |
| **Read**     | These commands involve operations that fetch or read data without making any changes to your data platform.<br /><br />Can have multiple invocations in parallel and aren't limited to one invocation at any given time. This means read commands can run in parallel with other read commands and a single write command. | `dbt parse`<br />`dbt compile` |

#### Available commands[​](#available-commands "Direct link to Available commands")

The following sections outline the commands supported by dbt and their relevant flags. They are available in all tools and all [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md) unless noted otherwise. You can run these commands in your specific tool by prefixing them with `dbt` — for example, to run the `test` command, type `dbt test`.

For information about selecting models on the command line, refer to [Model selection syntax](https://docs.getdbt.com/reference/node-selection/syntax.md).

Commands with a ('❌') indicate write commands, commands with a ('✅') indicate read commands, and commands with a (N/A) indicate it's not relevant to the parallelization of dbt commands.

info

Some commands are not yet supported in the dbt Fusion Engine or have limited functionality. See the [Fusion supported features](https://docs.getdbt.com/docs/fusion/supported-features.md) page for details.

| Command                                                                      | Description                                                                                 | Parallel execution | Caveats                                                                                                                                                                          |
| ---------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [build](https://docs.getdbt.com/reference/commands/build.md)                 | Builds and tests all selected resources (models, seeds, tests, and more)                    | ❌                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                       |
| cancel                                                                       | Cancels the most recent invocation.                                                         | N/A                | Cloud CLI<br />Requires [dbt v1.6 or higher](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                  |
| [clean](https://docs.getdbt.com/reference/commands/clean.md)                 | Deletes artifacts present in the dbt project                                                | ✅                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                       |
| [clone](https://docs.getdbt.com/reference/commands/clone.md)                 | Clones selected models from the specified state                                             | ❌                 | All tools<br />Requires [dbt v1.6 or higher](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                  |
| [compile](https://docs.getdbt.com/reference/commands/compile.md)             | Compiles (but does not run) the models in a project                                         | ✅                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                       |
| [debug](https://docs.getdbt.com/reference/commands/debug.md)                 | Debugs dbt connections and projects                                                         | ✅                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                       |
| [deps](https://docs.getdbt.com/reference/commands/deps.md)                   | Downloads dependencies for a project                                                        | ✅                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                       |
| [docs](https://docs.getdbt.com/reference/commands/cmd-docs.md)               | Generates documentation for a project                                                       | ✅                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)<br />Not yet supported in Fusion                                                      |
| [environment](https://docs.getdbt.com/reference/commands/dbt-environment.md) | Enables you to interact with your dbt environment.                                          | N/A                | Cloud CLI<br />Requires [dbt v1.5 or higher](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                  |
| help                                                                         | Displays help information for any command                                                   | N/A                | dbt Core, Cloud CLI<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                             |
| [init](https://docs.getdbt.com/reference/commands/init.md)                   | Initializes a new dbt project                                                               | ✅                 | Fusion<br />dbt Core<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                            |
| [invocation](https://docs.getdbt.com/reference/commands/invocation.md)       | Enables users to debug long-running sessions by interacting with active invocations.        | N/A                | Cloud CLI<br />Requires [dbt v1.5 or higher](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                  |
| [list](https://docs.getdbt.com/reference/commands/list.md)                   | Lists resources defined in a dbt project                                                    | ✅                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                       |
| [parse](https://docs.getdbt.com/reference/commands/parse.md)                 | Parses a project and writes detailed timing info                                            | ✅                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                       |
| reattach                                                                     | Reattaches to the most recent invocation to retrieve logs and artifacts.                    | N/A                | Cloud CLI<br />Requires [dbt v1.6 or higher](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                  |
| [retry](https://docs.getdbt.com/reference/commands/retry.md)                 | Retry the last run `dbt` command from the point of failure                                  | ❌                 | All tools<br />Requires [dbt v1.6 or higher](https://docs.getdbt.com/docs/dbt-versions/core.md)<br />Not yet supported in Fusion                                                 |
| [run](https://docs.getdbt.com/reference/commands/run.md)                     | Runs the models in a project                                                                | ❌                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                       |
| [run-operation](https://docs.getdbt.com/reference/commands/run-operation.md) | Invokes a macro, including running arbitrary maintenance SQL against the database           | ❌                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                       |
| [seed](https://docs.getdbt.com/reference/commands/seed.md)                   | Loads CSV files into the database                                                           | ❌                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                       |
| [show](https://docs.getdbt.com/reference/commands/show.md)                   | Previews table rows post-transformation                                                     | ✅                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                       |
| [snapshot](https://docs.getdbt.com/reference/commands/snapshot.md)           | Executes "snapshot" jobs defined in a project                                               | ❌                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                       |
| [source](https://docs.getdbt.com/reference/commands/source.md)               | Provides tools for working with source data (including validating that sources are "fresh") | ✅                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)                                                                                       |
| [test](https://docs.getdbt.com/reference/commands/test.md)                   | Executes tests defined in a project                                                         | ✅                 | All tools<br />All [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md)<br />Fusion flags `--store-failures`, `--fail-fast`, `--warn-error` not yet supported |

Note, use the [`--version`](https://docs.getdbt.com/reference/commands/version.md) flag to display the installed dbt Core or Cloud CLI version. (Not applicable for the Studio IDE). Available on all [supported versions](https://docs.getdbt.com/docs/dbt-versions/core.md).

#### Was this page helpful?

YesNo

[Privacy policy](https://www.getdbt.com/cloud/privacy-policy)[Create a GitHub issue](https://github.com/dbt-labs/docs.getdbt.com/issues)

This site is protected by reCAPTCHA and the Google [Privacy Policy](https://policies.google.com/privacy) and [Terms of Service](https://policies.google.com/terms) apply.


---

### dbt Jinja functions

#### [📄️<!-- --> <!-- -->adapter](https://docs.getdbt.com/reference/dbt-jinja-functions/adapter.md)

[Wrap the internal database adapter with the Jinja object \`adapter\`.](https://docs.getdbt.com/reference/dbt-jinja-functions/adapter.md)


---

### dbt_project.yml

The dbt\_project.yml file is a required file for all dbt projects. It contains important information that tells dbt how to operate your project.

Every [dbt project](https://docs.getdbt.com/docs/build/projects.md) needs a `dbt_project.yml` file — this is how dbt knows a directory is a dbt project. It also contains important information that tells dbt how to operate your project. It works as follows:

* dbt uses [YAML](https://yaml.org/) in a few different places. If you're new to YAML, it would be worth learning how arrays, dictionaries, and strings are represented.

* By default, dbt looks for the `dbt_project.yml` in your current working directory and its parents, but you can set a different directory using the `--project-dir` flag or the `DBT_PROJECT_DIR` environment variable.

* Specify your dbt project ID in the `dbt_project.yml` file using `project-id` under the `dbt-cloud` config. Find your project ID in your dbt project URL: For example, in `https://YOUR_ACCESS_URL/11/projects/123456`, the project ID is `123456`.

* Note, you can't set up a "property" in the `dbt_project.yml` file if it's not a config (an example is [macros](https://docs.getdbt.com/reference/macro-properties.md)). This applies to all types of resources. Refer to [Configs and properties](https://docs.getdbt.com/reference/configs-and-properties.md) for more detail.

#### Example[​](#example "Direct link to Example")

The following example is a list of all available configurations in the `dbt_project.yml` file:

dbt\_project.yml
```

---

## Example dbt_project.yml file

**URL:** llms-txt#example-dbt_project.yml-file

name: 'jaffle_shop'
profile: 'jaffle_shop'
...

**Examples:**

Example 1 (unknown):
```unknown
dbt then checks your `profiles.yml` file for a profile with the same name. A profile contains all the details required to connect to your data warehouse.

dbt will search the current working directory for the `profiles.yml` file and will default to the `~/.dbt/` directory if not found.

This file generally lives outside of your dbt project to avoid sensitive credentials being checked in to version control, but `profiles.yml` can be safely checked in when [using environment variables](#advanced-using-environment-variables) to load sensitive credentials.

\~/.dbt/profiles.yml
```

---

## example profiles.yml file

**URL:** llms-txt#example-profiles.yml-file

jaffle_shop:
  target: dev
  outputs:
    dev:
      type: postgres
      host: localhost
      user: alice
      password: <password>
      port: 5432
      dbname: jaffle_shop
      schema: dbt_alice
      threads: 4

prod:  # additional prod target
      type: postgres
      host: prod.db.example.com
      user: alice
      password: <prod_password>
      port: 5432
      dbname: jaffle_shop
      schema: analytics
      threads: 8

profile:
  target: prod
  outputs:
    prod:
      type: postgres
      host: 127.0.0.1
      # IMPORTANT: Make sure to quote the entire Jinja string here
      user: "{{ env_var('DBT_USER') }}"
      password: "{{ env_var('DBT_PASSWORD') }}"
      ....

dbt run --profile my-profile-name --target dev

$ dbt debug --config-dir
To view your profiles.yml file, run:

open /Users/alice/.dbt

$ dbt run --profiles-dir path/to/directory

$ export DBT_PROFILES_DIR=path/to/directory

cratedb_analytics:
  target: dev
  outputs:
    dev:
      type: cratedb
      host: [clustername].aks1.westeurope.azure.cratedb.net
      port: 5432
      user: [username]
      pass: [password]
      dbname: crate         # Do not change this value. CrateDB's only catalog is `crate`.
      schema: doc           # Define the schema name. CrateDB's default schema is `doc`.

dbt-databend-cloud:
  target: dev
  outputs:
    dev:
      type: databend
      host: databend-cloud-host
      port: 443
      schema: database_name
      user: username
      pass: password

your_profile_name:
  target: dev
  outputs:
    dev:
      type: databricks
      catalog: CATALOG_NAME #optional catalog name if you are using Unity Catalog]
      schema: SCHEMA_NAME # Required
      host: YOURORG.databrickshost.com # Required
      http_path: /SQL/YOUR/HTTP/PATH # Required
      token: dapiXXXXXXXXXXXXXXXXXXXXXXX # Required Personal Access Token (PAT) if using token-based authentication
      threads: 1_OR_MORE  # Optional, default 1

your_profile_name:
  target: dev
  outputs:
    dev:
      type: databricks
      catalog: CATALOG_NAME #optional catalog name if you are using Unity Catalog
      schema: SCHEMA_NAME # Required
      host: YOUR_ORG.databrickshost.com # Required
      http_path: /SQL/YOUR/HTTP/PATH # Required
      auth_type: oauth # Required if using OAuth-based authentication
      client_id: OAUTH_CLIENT_ID # The ID of your OAuth application. Required if using OAuth-based authentication. Key should be azure_client_id for Azure Databricks.
      client_secret: XXXXXXXXXXXXXXXXXXXXXXXXXXX # OAuth client secret. Required if using OAuth-based authentication. Key should be azure_client_secret for Azure Databricks.
      threads: 1_OR_MORE  # Optional, default 1

your_profile_name:
  target: dev
  outputs:
    dev:
      type: databricks
      catalog: CATALOG_NAME #optional catalog name if you are using Unity Catalog
      schema: SCHEMA_NAME # Required
      host: YOUR_ORG.databrickshost.com # Required
      http_path: /SQL/YOUR/HTTP/PATH # Required
      auth_type: oauth # Required if using OAuth-based authentication
      threads: 1_OR_MORE  # Optional, default 1

dbt-decodable:       
  target: dev         
  outputs:           
    dev:              
      type: decodable
      database: None  
      schema: None    
      account_name: [your account]          
      profile_name: [name of the profile]   
      materialize_tests: [true | false]     
      timeout: [ms]                         
      preview_start: [earliest | latest]    
      local_namespace: [namespace prefix]

dbt run-operation delete_streams --args '{streams: [stream1, stream2], skip_errors: True}'

dbt-doris:
  target: dev
  outputs:
    dev:
      type: doris
      host: 127.0.0.1
      port: 9030
      schema: database_name
      username: username
      password: password

[project name]:
  outputs:
    dev:
      cloud_host: api.dremio.cloud
      cloud_project_id: [project ID]
      object_storage_source: [name]
      object_storage_path: [path]
      dremio_space: [name]
      dremio_space_folder: [path]
      pat: [personal access token]
      threads: [integer >= 1]
      type: dremio
      use_ssl: true
      user: [email address]
  target: dev

[project name]:
  outputs:
    dev:
      password: [password]
      port: [port]
      software_host: [hostname or IP address]
      object_storage_source: [name
      object_storage_path: [path]
      dremio_space: [name]
      dremio_space_folder: [path]
      threads: [integer >= 1]
      type: dremio
      use_ssl: [true|false]
      user: [username]
  target: dev

[project name]:
  outputs:
    dev:
      pat: [personal access token]
      port: [port]
      software_host: [hostname or IP address]
      object_storage_source: [name
      object_storage_path: [path]
      dremio_space: [name]
      dremio_space_folder: [path]
      threads: [integer >= 1]
      type: dremio
      use_ssl: [true|false]
      user: [username]
  target: dev

your_profile_name:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: 'file_path/database_name.duckdb'
      extensions:
        - httpfs
        - parquet
      settings:
        s3_region: my-aws-region
        s3_access_key_id: "{{ env_var('S3_ACCESS_KEY_ID') }}"
        s3_secret_access_key: "{{ env_var('S3_SECRET_ACCESS_KEY') }}"

dbt-exasol:
  target: dev
  outputs:
    dev:
      type: exasol
      threads: 1
      dsn: HOST:PORT
      user: USERNAME
      password: PASSWORD
      dbname: db
      schema: SCHEMA

<profile-name>:
  outputs:
    dev:
      type: extrica
      method: jwt 
      username: [username for jwt auth]
      password: [password for jwt auth]  
      host: [extrica hostname]
      port: [port number]
      schema: [dev_schema]
      catalog: [catalog_name]
      threads: [1 or more]

prod:
      type: extrica
      method: jwt 
      username: [username for jwt auth]
      password: [password for jwt auth]  
      host: [extrica hostname]
      port: [port number]
      schema: [dev_schema]
      catalog: [catalog_name]
      threads: [1 or more]
  target: dev

<profile-name>:
  target: <target-name>
  outputs:
    <target-name>:
      type: firebolt
      client_id: "<id>"
      client_secret: "<secret>"
      database: "<database-name>"
      engine_name: "<engine-name>"
      account_name: "<account-name>"
      schema: <tablename-prefix>
      threads: 1
      #optional fields
      host: "<hostname>"

-- macros/generate_alias_name.sql
{% macro generate_alias_name(custom_alias_name=none, node=none) -%}
    {%- if custom_alias_name is none -%}
        {{ node.schema }}__{{ node.name }}
    {%- else -%}
        {{ node.schema }}__{{ custom_alias_name | trim }}
    {%- endif -%}
{%- endmacro %}

company-name:
  target: dev
  outputs:
    dev:
      type: greenplum
      host: [hostname]
      user: [username]
      password: [password]
      port: [port]
      dbname: [database name]
      schema: [dbt schema]
      threads: [1 or more]
      keepalives_idle: 0 # default 0, indicating the system default. See below
      connect_timeout: 10 # default 10 seconds
      search_path: [optional, override the default postgres search_path]
      role: [optional, set the role dbt assumes when executing queries]
      sslmode: [optional, set the sslmode used to connect to the database]

your_profile_name:
  target: dev
  outputs:
    dev:
      type: ibmdb2
      schema: analytics
      database: test
      host: localhost
      port: 50000
      protocol: TCPIP
      username: my_username
      password: my_password

my_project:
  outputs:
    dev:
      type: netezza
      user: [user]
      password: [password]
      host: [hostname]
      database: [catalog name]
      schema: [schema name]
      port: 5480
      threads: [1 or more]

- !ETOptions
    SkipRows: "1"
    Delimiter: "','"
    DateDelim: "'-'"
    MaxErrors: " 0 "

my_project:
  outputs:
    software:
      type: watsonx_presto
      method: BasicAuth
      user: [user]
      password: [password]
      host: [hostname]
      catalog: [catalog_name]
      schema: [your dbt schema]
      port: [port number]
      threads: [1 or more]
      ssl_verify: path/to/certificate

saas:
      type: watsonx_presto
      method: BasicAuth
      user: [user]
      password: [api_key]
      host: [hostname]
      catalog: [catalog_name]
      schema: [your dbt schema]
      port: [port number]
      threads: [1 or more]

python -m pip install <Constant name="core" /> dbt-watsonx-spark

project_name:
  target: "dev"
  outputs:
    dev:
      type: watsonx_spark
      method: http
      schema: [schema name]
      host: [hostname]
      uri: [uri]
      catalog: [catalog name]
      use_ssl: false
      auth:
        instance: [Watsonx.data Instance ID]
        user: [username]
        apikey: [apikey]

pip install dbt-infer

<profile-name>:
  target: <target-name>
  outputs:
    <target-name>:
      type: infer
      url: "<infer-api-endpoint>"
      username: "<infer-api-username>"
      apikey: "<infer-apikey>"
      data_config:
        [configuration for your underlying data warehouse]

infer_bigquery:
  apikey: 1234567890abcdef
  username: my_name@example.com
  url: https://app.getinfer.io
  type: infer
  data_config:
    dataset: my_dataset
    job_execution_timeout_seconds: 300
    job_retries: 1
    keyfile: bq-user-creds.json
    location: EU
    method: service-account
    priority: interactive
    project: my-bigquery-project
    threads: 1
    type: bigquery

{{
  config(
    materialized = "table"
  )
}}

with predict_user_churn_input as (
    select * from {{ ref('user_features') }}
)

SELECT * FROM predict_user_churn_input PREDICT(has_churned, ignore=user_id)

iomete:
  target: dev
  outputs:
    dev:
      type: iomete
      cluster: cluster_name
      host: <region_name>.iomete.com
      port: 443
      schema: database_name
      account_number: iomete_account_number
      user: iomete_user_name
      password: iomete_user_password

layer-profile:
  target: dev
  outputs:
    dev:
      # Layer authentication
      type: layer_bigquery
      layer_api_key: [the API Key to access your Layer account (opt)]
      # Bigquery authentication
      method: service-account
      project: [GCP project id]
      dataset: [the name of your dbt dataset]
      threads: [1 or more]
      keyfile: [/path/to/bigquery/keyfile.json]

layer.automl("MODEL_TYPE", ARRAY[FEATURES], TARGET)

SELECT order_id,
       layer.automl(
           -- This is a regression problem
           'regressor',
           -- Data (input features) to train our model
           ARRAY[
           days_between_purchase_and_delivery, order_approved_late,
           actual_delivery_vs_expectation_bucket, total_order_price, total_order_freight, is_multiItems_order,seller_shipped_late],
           -- Target column we want to predict
           review_score
       )
FROM {{ ref('training_data') }}

layer.predict("LAYER_MODEL_PATH", ARRAY[FEATURES])

SELECT
    id,
    layer.predict("layer/clothing/models/objectdetection", ARRAY[image])
FROM
    {{ ref("products") }}

materialize:
  target: dev
  outputs:
    dev:
      type: materialize
      host: [host]
      port: [port]
      user: [user@domain.com]
      pass: [password]
      dbname: [database]
      cluster: [cluster] # default 'default'
      schema: [dbt schema]
      sslmode: require
      keepalives_idle: 0 # default: 0, indicating the system default
      connect_timeout: 10 # default: 10 seconds
      retries: 1 # default: 1, retry on error/timeout when opening connections

dbt-maxcompute: # this needs to match the profile in your dbt_project.yml file
  target: dev
  outputs:
    dev:
      type: maxcompute
      project: PROJECT_ID
      schema: SCHEMA_NAME
      endpoint: ENDPOINT
      auth_type: access_key
      access_key_id: ACCESS_KEY_ID
      access_key_secret: ACCESS_KEY_SECRET

jaffle_shop: # this needs to match the profile in your dbt_project.yml file
  target: dev
  outputs:
    dev:
      type: maxcompute
      project: dbt-example # Replace this with your project name
      schema: default # Replace this with schema name, for example, dbt_bilbo
      endpoint: http://service.cn-shanghai.maxcompute.aliyun.com/api # Replace this with your maxcompute endpoint
      auth_type: access_key # credential type, Optional, default is 'access_key'
      access_key_id: accessKeyId # AccessKeyId
      access_key_secret: accessKeySecret # AccessKeySecret

jaffle_shop: # this needs to match the profile in your dbt_project.yml file
  target: dev
  outputs:
    dev:
      type: maxcompute
      project: dbt-example # Replace this with your project name
      schema: default # Replace this with schema name, for example, dbt_bilbo
      endpoint: http://service.cn-shanghai.maxcompute.aliyun.com/api # Replace this with your maxcompute endpoint
      auth_type: sts # credential type
      access_key_id: accessKeyId # AccessKeyId
      access_key_secret: accessKeySecret # AccessKeySecret
      security_token: securityToken  # STS Token

jaffle_shop: # this needs to match the profile in your dbt_project.yml file
  target: dev
  outputs:
    dev:
      type: maxcompute
      project: dbt-example # Replace this with your project name
      schema: default # Replace this with schema name, for example, dbt_bilbo
      endpoint: http://service.cn-shanghai.maxcompute.aliyun.com/api # Replace this with your maxcompute endpoint
      auth_type: ram_role_arn # credential type
      access_key_id: accessKeyId # AccessKeyId
      access_key_secret: accessKeySecret # AccessKeySecret
      security_token: securityToken  # STS Token
      role_arn: roleArn # Format: acs:ram::USER_ID:role/ROLE_NAME
      role_session_name: roleSessionName # Role Session Name
      auth_policy: policy # Not required, limit the permissions of STS Token
      role_session_expiration: 3600 # Not required, limit the Valid time of STS Token

jaffle_shop: # this needs to match the profile in your dbt_project.yml file
  target: dev
  outputs:
    dev:
      type: maxcompute
      project: dbt-example # Replace this with your project name
      schema: default # Replace this with schema name, for example, dbt_bilbo
      endpoint: http://service.cn-shanghai.maxcompute.aliyun.com/api # Replace this with your maxcompute endpoint
      auth_type: oidc_role_arn # credential type
      access_key_id: accessKeyId # AccessKeyId
      access_key_secret: accessKeySecret # AccessKeySecret
      security_token: securityToken # STS Token
      role_arn: roleArn # Format: acs:ram::USER_ID:role/ROLE_NAME
      oidc_provider_arn: oidcProviderArn # Format: acs:ram::USER_Id:oidc-provider/OIDC Providers
      oidc_token_file_path: /Users/xxx/xxx # oidc_token_file_path can be replaced by setting environment variable: ALIBABA_CLOUD_OIDC_TOKEN_FILE
      role_session_name: roleSessionName # Role Session Name
      auth_policy: policy # Not required, limit the permissions of STS Token
      role_session_expiration: 3600 # Not required, limit the Valid time of STS Token

jaffle_shop: # this needs to match the profile in your dbt_project.yml file
  target: dev
  outputs:
    dev:
      type: maxcompute
      project: dbt-example # Replace this with your project name
      schema: default # Replace this with schema name, for example, dbt_bilbo
      endpoint: http://service.cn-shanghai.maxcompute.aliyun.com/api # Replace this with your maxcompute endpoint
      auth_type: ecs_ram_role # credential type
      role_name: roleName # `role_name` is optional. It will be retrieved automatically if not set. It is highly recommended to set it up to reduce requests.
      disable_imds_v1: True # Optional, whether to forcibly disable IMDSv1, that is, to use IMDSv2 hardening mode, which can be set by the environment variable ALIBABA_CLOUD_IMDSV1_DISABLED

jaffle_shop: # this needs to match the profile in your dbt_project.yml file
  target: dev
  outputs:
    dev:
      type: maxcompute
      project: dbt-example # Replace this with your project name
      schema: default # Replace this with schema name, for example, dbt_bilbo
      endpoint: http://service.cn-shanghai.maxcompute.aliyun.com/api # Replace this with your maxcompute endpoint
      auth_type: credentials_uri # credential type
      credentials_uri: http://local_or_remote_uri/ # Credentials URI

jaffle_shop: # this needs to match the profile in your dbt_project.yml file
  target: dev
  outputs:
    dev:
      type: maxcompute
      project: dbt-example # Replace this with your project name
      schema: default # Replace this with schema name, for example, dbt_bilbo
      endpoint: http://service.cn-shanghai.maxcompute.aliyun.com/api # Replace this with your maxcompute endpoint
      auth_type: bearer # credential type
      bearer_token: bearerToken # BearerToken

jaffle_shop: # this needs to match the profile in your dbt_project.yml file
  target: dev
  outputs:
    dev:
      type: maxcompute
      project: dbt-example # Replace this with your project name
      schema: default # Replace this with schema name, for example, dbt_bilbo
      endpoint: http://service.cn-shanghai.maxcompute.aliyun.com/api # Replace this with your maxcompute endpoint
      auth_type: chain

[default]                          # default setting
   enable = true                      # Enable，Enabled by default if this option is not present
   type = access_key                  # Certification type: access_key
   access_key_id = foo                # Key
   access_key_secret = bar            # Secret

[client1]                          # configuration that is named as `client1`
   type = ecs_ram_role                # Certification type: ecs_ram_role
   role_name = EcsRamRoleTest         # Role Name

[client2]                          # configuration that is named as `client2`
   enable = false                     # Disable
   type = ram_role_arn                # Certification type: ram_role_arn
   region_id = cn-test
   policy = test                      # optional Specify permissions
   access_key_id = foo
   access_key_secret = bar
   role_arn = role_arn
   role_session_name = session_name   # optional

[client3]                          # configuration that is named as `client3`
   enable = false                     # Disable
   type = oidc_role_arn               # Certification type: oidc_role_arn
   region_id = cn-test
   policy = test                      # optional Specify permissions
   access_key_id = foo                # optional
   access_key_secret = bar            # optional
   role_arn = role_arn
   oidc_provider_arn = oidc_provider_arn
   oidc_token_file_path = /xxx/xxx    # can be replaced by setting environment variable: ALIBABA_CLOUD_OIDC_TOKEN_FILE
   role_session_name = session_name   # optional
   
sudo apt install unixodbc-dev

your_profile_name:
  target: dev
  outputs:
    dev:
      type: synapse
      driver: 'ODBC Driver 17 for SQL Server' # (The ODBC Driver installed on your system)
      server: workspacename.sql.azuresynapse.net # (Dedicated SQL endpoint of your workspace here)
      port: 1433
      database: exampledb
      schema: schema_name
      user: username
      password: password

sudo apt install unixodbc-dev

your_profile_name:
  target: dev
  outputs:
    dev:
      type: fabric
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: ActiveDirectoryPassword
      user: bill.gates@microsoft.com
      password: iheartopensource

your_profile_name:
  target: dev
  outputs:
    dev:
      type: fabric
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: ServicePrincipal
      tenant_id: 00000000-0000-0000-0000-000000001234
      client_id: 00000000-0000-0000-0000-000000001234
      client_secret: S3cret!

your_profile_name:
  target: dev
  outputs:
    dev:
      type: fabric
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: environment

your_profile_name:
  target: dev
  outputs:
    dev:
      type: fabric
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: CLI

your_profile_name:
  target: dev
  outputs:
    dev:
      type: fabric
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: auto

your_profile_name:
  target: dev
  outputs:
    dev:
      type: fabric
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: ActiveDirectoryInteractive
      user: bill.gates@microsoft.com

your_profile_name:
  target: dev
  outputs:
    dev:
      type: fabric
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: ActiveDirectoryIntegrated

CREATE SCHEMA [schema_name] AUTHORIZATION [schema_authorization]

your_profile_name:
  target: dev
  outputs:
    dev:
      type: fabricspark
      method: livy
      authentication: CLI
      endpoint: https://api.fabric.microsoft.com/v1
      workspaceid: [Fabric Workspace GUID]
      lakehouseid: [Lakehouse GUID]
      lakehouse: [Lakehouse Name]
      schema: [Lakehouse Name]
      spark_config:
        name: [Application Name]
        # optional
        archives:
          - "example-archive.zip"
        conf:
            spark.executor.memory: "2g"
            spark.executor.cores: "2"
        tags:
          project: [Project Name]
          user: [User Email]
          driverMemory: "2g"
          driverCores: 2
          executorMemory: "4g"
          executorCores: 4
          numExecutors: 3
      # optional
      connect_retries: 0
      connect_timeout: 10
      retry_all: true

retry_all: true
connect_timeout: 5
connect_retries: 3

sudo apt install unixodbc-dev

your_profile_name:
  target: dev
  outputs:
    dev:
      type: sqlserver
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: database
      schema: schema_name
      user: username
      password: password

your_profile_name:
  target: dev
  outputs:
    dev:
      type: sqlserver
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      windows_login: True

your_profile_name:
  target: dev
  outputs:
    dev:
      type: sqlserver
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: ActiveDirectoryPassword
      user: bill.gates@microsoft.com
      password: iheartopensource

your_profile_name:
  target: dev
  outputs:
    dev:
      type: sqlserver
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: ServicePrincipal
      tenant_id: 00000000-0000-0000-0000-000000001234
      client_id: 00000000-0000-0000-0000-000000001234
      client_secret: S3cret!

your_profile_name:
  target: dev
  outputs:
    dev:
      type: sqlserver
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: ActiveDirectoryMsi

your_profile_name:
  target: dev
  outputs:
    dev:
      type: sqlserver
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: environment

your_profile_name:
  target: dev
  outputs:
    dev:
      type: sqlserver
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: CLI

your_profile_name:
  target: dev
  outputs:
    dev:
      type: sqlserver
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: auto

your_profile_name:
  target: dev
  outputs:
    dev:
      type: sqlserver
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: ActiveDirectoryInteractive
      user: bill.gates@microsoft.com

your_profile_name:
  target: dev
  outputs:
    dev:
      type: sqlserver
      driver: 'ODBC Driver 18 for SQL Server' # (The ODBC Driver installed on your system)
      server: hostname or IP of your server
      port: 1433
      database: exampledb
      schema: schema_name
      authentication: ActiveDirectoryIntegrated

CREATE SCHEMA [schema_name] AUTHORIZATION [schema_authorization]

mindsdb:
  outputs:
    dev:
      database: 'mindsdb'
      host: '127.0.0.1'
      password: ''
      port: 47335
      schema: 'mindsdb'
      type: mindsdb
      username: 'mindsdb'
  target: dev

your_profile_name:
  target: dev
  outputs:
    dev:
      type: mysql
      server: localhost
      port: 3306
      schema: analytics
      username: your_mysql_username
      password: your_mysql_password
      ssl_disabled: True

[mysqld]
  explicit_defaults_for_timestamp = true
  sql_mode = "ALLOW_INVALID_DATES,{other_sql_modes}"
  
export ORA_PYTHON_DRIVER_TYPE=thin # default

export ORA_PYTHON_DRIVER_TYPE=thick

mkdir -p /opt/oracle
cd /opt/oracle
unzip instantclient-basic-linux.x64-21.6.0.0.0.zip

sudo yum install libaio

sudo sh -c "echo /opt/oracle/instantclient_21_6 > /etc/ld.so.conf.d/oracle-instantclient.conf"
sudo ldconfig

export LD_LIBRARY_PATH=/opt/oracle/instantclient_21_6:$LD_LIBRARY_PATH

export TNS_ADMIN=/opt/oracle/your_config_dir

SET PATH=C:\oracle\instantclient_19_9;%PATH%
   
export WALLET_LOCATION=/path/to/directory_containing_ewallet.pem
export WALLET_PASSWORD=***
export TNS_ADMIN=/path/to/directory_containing_tnsnames.ora

export TNS_ADMIN=/path/to/directory_containing_tnsnames.ora

WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="/path/to/wallet/directory")))
SSL_SERVER_DN_MATCH=yes

export DBT_ORACLE_USER=<username>
export DBT_ORACLE_PASSWORD=***
export DBT_ORACLE_SCHEMA=<username>
export DBT_ORACLE_DATABASE=example_db2022adb

SELECT SYS_CONTEXT('userenv', 'DB_NAME') FROM DUAL

db2022adb_high = (description =
                 (retry_count=20)(retry_delay=3)
                 (address=(protocol=tcps)
                 (port=1522)
                 (host=adb.example.oraclecloud.com))
                 (connect_data=(service_name=example_high.adb.oraclecloud.com))
                 (security=(ssl_server_cert_dn="CN=adb.example.oraclecloud.com,
                 OU=Oracle BMCS US,O=Oracle Corporation,L=Redwood City,ST=California,C=US")))

export DBT_ORACLE_TNS_NAME=db2022adb_high

dbt_test:
   target: dev
   outputs:
      dev:
         type: oracle
         user: "{{ env_var('DBT_ORACLE_USER') }}"
         pass: "{{ env_var('DBT_ORACLE_PASSWORD') }}"
         database: "{{ env_var('DBT_ORACLE_DATABASE') }}"
         tns_name: "{{ env_var('DBT_ORACLE_TNS_NAME') }}"
         schema: "{{ env_var('DBT_ORACLE_SCHEMA') }}"
         threads: 4

export DBT_ORACLE_CONNECT_STRING="(description=(retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)
                                  (host=adb.example.oraclecloud.com))(connect_data=(service_name=example_high.adb.oraclecloud.com))
                                  (security=(ssl_server_cert_dn=\"CN=adb.example.oraclecloud.com,
                                  OU=Oracle BMCS US,O=Oracle Corporation,L=Redwood City,ST=California,C=US\")))"

dbt_test:
   target: "{{ env_var('DBT_TARGET', 'dev') }}"
   outputs:
      dev:
         type: oracle
         user: "{{ env_var('DBT_ORACLE_USER') }}"
         pass: "{{ env_var('DBT_ORACLE_PASSWORD') }}"
         database: "{{ env_var('DBT_ORACLE_DATABASE') }}"
         schema: "{{ env_var('DBT_ORACLE_SCHEMA') }}"
         connection_string: "{{ env_var('DBT_ORACLE_CONNECT_STRING') }}"

export DBT_ORACLE_HOST=adb.example.oraclecloud.com
export DBT_ORACLE_SERVICE=example_high.adb.oraclecloud.com

dbt_test:
   target: "{{ env_var('DBT_TARGET', 'dev') }}"
   outputs:
      dev:
         type: oracle
         user: "{{ env_var('DBT_ORACLE_USER') }}"
         pass: "{{ env_var('DBT_ORACLE_PASSWORD') }}"
         protocol: "tcps"
         host: "{{ env_var('DBT_ORACLE_HOST') }}"
         port: 1522
         service: "{{ env_var('DBT_ORACLE_SERVICE') }}"
         database: "{{ env_var('DBT_ORACLE_DATABASE') }}"
         schema: "{{ env_var('DBT_ORACLE_SCHEMA') }}"
         retry_count: 1
         retry_delay: 3
         threads: 4

quoting:
  database: false
  identifier: false
  schema: false

Compilation Error in model <model>
19:09:40    When searching for a relation, dbt found an approximate match. Instead of guessing
19:09:40    which relation to use, dbt will move on. Please delete <model>, or rename it to be less ambiguous.
  Searched for: <model>

quoting:
  database: true

https://tenant1-dbt.adb.us-sanjose-1.oraclecloudapps.com

dbt_test:
   target: dev
   outputs:
      dev:
         type: oracle
         user: "{{ env_var('DBT_ORACLE_USER') }}"
         pass: "{{ env_var('DBT_ORACLE_PASSWORD') }}"
         database: "{{ env_var('DBT_ORACLE_DATABASE') }}"
         tns_name: "{{ env_var('DBT_ORACLE_TNS_NAME') }}"
         schema: "{{ env_var('DBT_ORACLE_SCHEMA') }}"
         oml_cloud_service_url: "https://tenant1-dbt.adb.us-sanjose-1.oraclecloudapps.com"

def model(dbt, session):
    # Must be either table or incremental (view is not currently supported)
    dbt.config(materialized="table")
    # returns oml.core.DataFrame referring a dbt model
    s_df = dbt.ref("sales_cost")
    return s_df

def model(dbt, session):
    # Must be either table or incremental (view is not currently supported)
    dbt.config(materialized="table")
    # oml.core.DataFrame representing a datasource
    s_df = dbt.source("sh_database", "channels")
    return s_df

def model(dbt, session):
    # Must be either table or incremental
    dbt.config(materialized="incremental")
    # oml.DataFrame representing a datasource
    sales_cost_df = dbt.ref("sales_cost")

if dbt.is_incremental:
        cr = session.cursor()
        result = cr.execute(f"select max(cost_timestamp) from {dbt.this.identifier}")
        max_timestamp = result.fetchone()[0]
        # filter new rows
        sales_cost_df = sales_cost_df[sales_cost_df["COST_TIMESTAMP"] > max_timestamp]

def model(dbt, session):
    dbt.config(materialized="table")
    dbt.config(async_flag=True)
    dbt.config(timeout=1800)

sql = f"""SELECT customer.cust_first_name,
       customer.cust_last_name,
       customer.cust_gender,
       customer.cust_marital_status,
       customer.cust_street_address,
       customer.cust_email,
       customer.cust_credit_limit,
       customer.cust_income_level
    FROM sh.customers customer, sh.countries country
    WHERE country.country_iso_code = ''US''
    AND customer.country_id = country.country_id"""

# session.sync(query) will run the sql query and returns a oml.core.DataFrame
    us_potential_customers = session.sync(query=sql)

# Compute an ad-hoc anomaly score on the credit limit
    median_credit_limit = us_potential_customers["CUST_CREDIT_LIMIT"].median()
    mean_credit_limit = us_potential_customers["CUST_CREDIT_LIMIT"].mean()
    anomaly_score = (us_potential_customers["CUST_CREDIT_LIMIT"] - median_credit_limit)/(median_credit_limit - mean_credit_limit)

# Add a new column "CUST_CREDIT_ANOMALY_SCORE"
    us_potential_customers = us_potential_customers.concat({"CUST_CREDIT_ANOMALY_SCORE": anomaly_score.round(3)})

# Return potential customers dataset as a oml.core.DataFrame
    return us_potential_customers

conda create -n dbt_py_env -c conda-forge --override-channels --strict-channel-priority python=3.12.1 nltk gensim

conda upload --overwrite dbt_py_env -t application OML4PY

**Examples:**

Example 1 (unknown):
```unknown
To add an additional target (like `prod`) to your existing `profiles.yml`, you can add another entry under the `outputs` key.

#### The `env_var` function[​](#the-env_var-function "Direct link to the-env_var-function")

<!-- -->

The `env_var` function can be used to incorporate environment variables from the system into your dbt project. You can use the `env_var` function in your `profiles.yml` file, the `dbt_project.yml` file, the `sources.yml` file, your `schema.yml` files, and in model `.sql` files. Essentially, `env_var` is available anywhere dbt processes Jinja code.

When used in a `profiles.yml` file (to avoid putting credentials on a server), it can be used like this:

profiles.yml
```

Example 2 (unknown):
```unknown
#### About the `profiles.yml` file[​](#about-the-profilesyml-file "Direct link to about-the-profilesyml-file")

In your `profiles.yml` file, you can store as many profiles as you need. Typically, you would have one profile for each warehouse you use. Most organizations only have one profile.

#### About profiles[​](#about-profiles "Direct link to About profiles")

A profile consists of *targets*, and a specified *default target*.

Each *target* specifies the type of warehouse you are connecting to, the credentials to connect to the warehouse, and some dbt-specific configurations.

The credentials you need to provide in your target varies across warehouses — sample profiles for each supported warehouse are available in the [Supported Data Platforms](https://docs.getdbt.com/docs/supported-data-platforms.md) section.

**Pro Tip:** You may need to surround your password in quotes if it contains special characters. More details [here](https://stackoverflow.com/a/37015689/10415173).

#### Setting up your profile[​](#setting-up-your-profile "Direct link to Setting up your profile")

To set up your profile, copy the correct sample profile for your warehouse into your `profiles.yml` file and update the details as follows:

* Profile name: Replace the name of the profile with a sensible name – it’s often a good idea to use the name of your organization. Make sure that this is the same name as the `profile` indicated in your `dbt_project.yml` file.

* `target`: This is the default target your dbt project will use. It must be one of the targets you define in your profile. Commonly it is set to `dev`.

* Populating your target:

  <!-- -->

  * `type`: The type of data warehouse you are connecting to
  * Warehouse credentials: Get these from your database administrator if you don’t already have them. Remember that user credentials are very sensitive information that should not be shared.
  * `schema`: The default schema that dbt will build objects in.
  * `threads`: The number of threads the dbt project will run on.

You can find more information on which values to use in your targets below.

Use the [debug](https://docs.getdbt.com/reference/dbt-jinja-functions/debug-method.md) command to validate your warehouse connection. Run `dbt debug` from within a dbt project to test your connection.

#### Understanding targets in profiles[​](#understanding-targets-in-profiles "Direct link to Understanding targets in profiles")

dbt supports multiple targets within one profile to encourage the use of separate development and production environments as discussed in [dbt environments](https://docs.getdbt.com/docs/core/dbt-core-environments.md).

A typical profile for an analyst using dbt locally will have a target named `dev`, and have this set as the default.

You may also have a `prod` target within your profile, which creates the objects in your production schema. However, since it's often desirable to perform production runs on a schedule, we recommend deploying your dbt project to a separate machine other than your local machine. Most dbt users only have a `dev` target in their profile on their local machine.

If you do have multiple targets in your profile, and want to use a target other than the default, you can do this using the `--target` option when issuing a dbt command.

##### Overriding profiles and targets[​](#overriding-profiles-and-targets "Direct link to Overriding profiles and targets")

When running dbt commands, you can specify which profile and target to use from the CLI using the `--profile` and `--target` [flags](https://docs.getdbt.com/reference/global-configs/about-global-configs.md#available-flags). These flags override what’s defined in your `dbt_project.yml` as long as the specified profile and target are already defined in your `profiles.yml` file.

To run your dbt project with a different profile or target than the default, you can do so using the followingCLI flags:

* `--profile` flag — Overrides the profile set in `dbt_project.yml` by pointing to another profile defined in `profiles.yml`.
* `--target` flag — Specifies the target within that profile to use (as defined in `profiles.yml`).

These flags help when you're working with multiple profiles and targets and want to override defaults without changing your files.
```

Example 3 (unknown):
```unknown
In this example, the `dbt run` command will use the `my-profile-name` profile and the `dev` target.

#### Understanding warehouse credentials[​](#understanding-warehouse-credentials "Direct link to Understanding warehouse credentials")

We recommend that each dbt user has their own set of database credentials, including a separate user for production runs of dbt – this helps debug rogue queries, simplifies ownerships of schemas, and improves security.

To ensure the user credentials you use in your target allow dbt to run, you will need to ensure the user has appropriate privileges. While the exact privileges needed varies between data warehouses, at a minimum your user must be able to:

* read source data
* create schemas¹
* read system tables

Running dbt without create schema privileges

If your user is unable to be granted the privilege to create schemas, your dbt runs should instead target an existing schema that your user has permission to create relations within.

#### Understanding target schemas[​](#understanding-target-schemas "Direct link to Understanding target schemas")

The target schema represents the default schema that dbt will build objects into, and is often used as the differentiator between separate environments within a warehouse.

Schemas in BigQuery

dbt uses the term "schema" in a target across all supported warehouses for consistency. Note that in the case of BigQuery, a schema is actually a dataset.

The schema used for production should be named in a way that makes it clear that it is ready for end-users to use for analysis – we often name this `analytics`.

In development, a pattern we’ve found to work well is to name the schema in your `dev` target `dbt_<username>`. Suffixing your name to the schema enables multiple users to develop in dbt, since each user will have their own separate schema for development, so that users will not build over the top of each other, and ensuring that object ownership and permissions are consistent across an entire schema.

Note that there’s no need to create your target schema beforehand – dbt will check if the schema already exists when it runs, and create it if it doesn’t.

While the target schema represents the default schema that dbt will use, it may make sense to split your models into separate schemas, which can be done by using [custom schemas](https://docs.getdbt.com/docs/build/custom-schemas.md).

#### Understanding threads[​](#understanding-threads "Direct link to Understanding threads")

When dbt runs, it creates a directed acyclic graph (DAG) of links between models. The number of threads represents the maximum number of paths through the graph dbt may work on at once – increasing the number of threads can minimize the run time of your project. The default value for threads in user profiles is 4 threads.

For more information, check out [using threads](https://docs.getdbt.com/docs/running-a-dbt-project/using-threads.md).

#### Advanced: Customizing a profile directory[​](#advanced-customizing-a-profile-directory "Direct link to Advanced: Customizing a profile directory")

The parent directory for `profiles.yml` is determined using the following precedence:

1. `--profiles-dir` option
2. `DBT_PROFILES_DIR` environment variable
3. current working directory
4. `~/.dbt/` directory

To check the expected location of your `profiles.yml` file for your installation of dbt, you can run the following:
```

Example 4 (unknown):
```unknown
You may want to have your `profiles.yml` file stored in a different directory than `~/.dbt/` – for example, if you are [using environment variables](#advanced-using-environment-variables) to load your credentials, you might choose to include this file in the root directory of your dbt project.

Note that the file always needs to be called `profiles.yml`, regardless of which directory it is in.

There are multiple ways to direct dbt to a different location for your `profiles.yml` file:

##### 1. Use the `--profiles-dir` option when executing a dbt command[​](#1-use-the---profiles-dir-option-when-executing-a-dbt-command "Direct link to 1-use-the---profiles-dir-option-when-executing-a-dbt-command")

This option can be used as follows:
```

---
