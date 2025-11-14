

Naming conventions: The foundation of discoverability
Names persist across your entire data stack—dbt models, database tables, BI tool fields, and metric definitions. Inconsistent naming creates friction: analysts waste hours searching for the "right" orders table, business users can't distinguish fct_orders_daily from int_orders_aggregated, and metrics like total_revenue vs revenue_total confuse rather than clarify.

Model naming pattern (dbt-style):



<dag_stage>_<source>__<entity>__<context>
Examples:
stg_stripe__payments          (staging layer, Stripe source)
int_transactions_joined       (intermediate transformation)
fct_card_transactions         (fact table, card domain)
dim_customers                 (dimension table)
mrt_customer_ltv__monthly     (mart with time grain)
Key principles:

Be verbose – "Extra characters are free"; full words beat abbreviations

Use underscores consistently – Single underscore separates words, double underscore separates major components

Indicate layer with prefix – stg_ (staging/bronze), int_ (intermediate/silver), fct_/dim_ (facts/dimensions/gold)

Business-friendly in presentation layer – Technical prefixes fine for models, but BI tools should expose "Customer Lifetime Value" not "fct_customer_ltv"

Metric naming standards:



<verb>_<noun>_<aggregation>
Examples:
total_transaction_amount
avg_order_value
count_active_accounts
sum_dispute_losses
median_balance_monthly
Requirements for dbt metrics: lowercase only, numbers allowed, underscores for separation, globally unique across all metrics. Avoid abbreviations in metric names—business users shouldn't need a decoder ring.

Essential resource:
Stakeholder-friendly model names: Model naming conventions that give context | dbt Developer Blog

Granularity: Transaction-level vs. aggregated approaches
The granularity decision is pivotal for semantic layer design. Bank of America Institute works with atomic transaction data, then applies aggregations (household-level, income terciles, generational cohorts) dynamically. This atomic-first approach provides maximum flexibility.

Ralph Kimball's grain declaration framework:

Transaction fact tables – One row per measurement event at a point in time

Most atomic and dimensional

Sparse (rows only when events occur)

Maximum analytical flexibility

For fintech: Individual card swipes, ACH transfers, dispute filings

Periodic snapshot fact tables – One row per standard period

Uniformly dense (row even with zero activity)

Good for trend analysis

For fintech: Daily account balances, monthly active user counts, weekly transaction volumes

Accumulating snapshot fact tables – One row per process from start to end

Multiple date columns for milestones

Rows UPDATED as process progresses

For fintech: Dispute lifecycle (filed → investigated → resolved), customer journey (registered → funded → active)

Decision framework:

Always start with atomic grain – You can aggregate up but never disaggregate down

Add aggregated tables only for performance – When same rollups run repeatedly and query time is critical

Use semantic layer for flexibility – Define metrics once at atomic level, let MetricFlow generate aggregations dynamically

The two-level approach: Fast and joinable
Traditional data warehouses create separate physical tables for each granularity combination—orders_daily, orders_weekly, orders_monthly, orders_by_customer, orders_by_product, etc. With 10 dimensions and 20 metrics, you face exponential table explosion.

Modern semantic layer pattern:

Store atomic data once – Transaction-level facts in Redshift with proper sortkeys/distkeys

Define metrics in semantic layer – Specify aggregation logic (sum, average, median, count distinct)

Query at any grain – MetricFlow generates optimized SQL for daily/weekly/monthly/customer/cohort aggregations on-the-fly

Materialize hot paths selectively – If executive dashboard runs hourly with same 5 metrics at monthly grain, create saved query with dbt export

For debit card programs specifically:

Atomic storage: fct_card_transactions with every swipe (merchant, amount, timestamp, auth/settle status)

Dynamic aggregation: Metrics like total_spend_amount queryable by day/week/month/merchant-category/customer-segment without pre-computation

Selective materialization: Monthly cohort retention dashboard uses saved query exported as incremental table for 2-second load time

Essential resource:
Why Semantic Layers Matter — and How to Build One with DuckDB - MotherDuck Blog

Data catalog & metadata management
Metrics are useless if nobody can find them. Data catalogs provide the discovery layer—search, lineage, trust signals, and social curation that make semantic layers accessible to business users.

Core metadata types to capture:

Technical metadata – Data types, schemas, refresh schedules, source systems (auto-extracted)

Business metadata – Definitions, glossary terms, use cases, ownership (human-curated)

Operational metadata – Usage patterns, query frequency, data quality scores, freshness (automatically tracked)

Catalog interface best practices:

Natural language search – Business users search "customer churn rate" not "dim_customers.churn_flag"

Lineage visualization – Click any metric to see full path from source tables through transformations to dashboards

Trust signals – Usage recency (last queried 2 hours ago), verification badges (Finance-approved), quality scores (99.8% complete)

Social curation – Users rate metrics (1-5 stars), comment on definitions, tag subject matter experts

Implementation pattern:

Auto-catalog dbt exposures – Every semantic model and metric automatically registered with descriptions, owners, and tags from YAML

Augment with usage data – Query logs show which metrics are actually used vs. defined-but-forgotten

Enable crowdsourcing – Business users add tips ("Use trailing_30d_actives for exec reporting, not monthly_actives"), flag issues, request clarifications

Organize by domain – Merchant Spend domain, ACH Payments domain, Fraud & Disputes domain, each with designated owner

Leading catalog tools:

Atlan – Active metadata, collaboration features, API-first architecture

Informatica Enterprise Data Catalog – AI-powered discovery, column-level lineage, social Q&A

Select Star – Lightweight, automated lineage, integrated business glossary

Essential resource:
Data Catalog Best Practices: Proven Strategies for Optimization