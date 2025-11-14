# Semantic Layer Skill for dbt with Redshift

## Overview

This skill provides guidance for building AI-ready semantic layers using dbt MetricFlow on Amazon Redshift. It's based on comprehensive research into semantic layer best practices specifically for fintech debit card programs, but the principles apply broadly.

**Key Principle**: The semantic layer is NOT an LLM generating SQL. It's a business logic layer that encodes rules LLMs can't see in raw schemas, preventing syntactically correct SQL from calculating wrong numbers.

## When to Use This Skill

Use this skill when:
- Building new dbt semantic models
- Defining metrics in MetricFlow
- Designing data models for AI/LLM consumption
- Implementing fintech metrics (transactions, payments, fraud, customer lifecycle)
- Creating composable, reusable metrics
- Ensuring metric consistency across tools

## Core Architecture Principles

### 1. Atomic-First Granularity

**Always start with atomic grain** - You can aggregate up but never disaggregate down.

```yaml
# Store transaction-level facts once
models:
  - name: fct_card_transactions
    description: "Atomic grain: one row per card transaction"
    columns:
      - name: transaction_id
        description: "Primary key"
      - name: customer_id
      - name: merchant_id
      - name: transaction_timestamp
      - name: amount_usd
      - name: transaction_status  # authorized, settled, declined, reversed
```

**Three fact table patterns** (Ralph Kimball framework):

1. **Transaction facts** (one row per event) - Most atomic, maximum flexibility
   - For fintech: Individual swipes, ACH transfers, dispute filings
   
2. **Periodic snapshots** (one row per standard period) - Dense, good for trends
   - For fintech: Daily account balances, monthly active counts
   
3. **Accumulating snapshots** (one row per process lifecycle) - Multiple date columns
   - For fintech: Dispute journey (filed → investigated → resolved)

### 2. Domain-Driven Data Products

Treat each pipeline as a separate data product with clear ownership:

**Domain Structure for Fintech:**
- **Merchant Spend domain** - Transaction facts (swipes, amounts, MCCs)
- **ACH Payments domain** - Transfer events (payroll, bill pay, P2P)
- **Disputes & Fraud domain** - Risk events (disputes, fraud flags, losses)
- **Customer Lifecycle domain** - Engagement signals (registration, funding, activation)

**Data Product Requirements:**
- Discoverable (registered in catalog with metadata)
- Addressable (global naming conventions enable joins)
- Trustworthy (SLOs for quality, lineage tracked)
- Self-describing (schemas, samples, metric definitions published)
- Interoperable (standard formats: UTC timestamps, decimal(18,2) amounts)
- Secure (RBAC at dataset level)

**Critical**: Each domain needs an explicit data product owner accountable for quality and evolution.

### 3. Composable Metrics Architecture

Metrics as modular, version-controlled components that extend without overwriting.

```yaml
# Base measure (atomic)
semantic_models:
  - name: transactions
    model: ref('fct_card_transactions')
    entities:
      - name: transaction_id
        type: primary
      - name: customer_id
        type: foreign
    measures:
      - name: transaction_amount_usd
        agg: sum
        expr: amount_usd

# Simple metric (direct aggregation)
metrics:
  - name: total_transaction_volume
    type: simple
    type_params:
      measure: transaction_amount_usd
    description: "Total dollar value of all transactions"

  - name: total_transaction_count
    type: simple
    type_params:
      measure: transaction_id
      agg: count_distinct
    description: "Total number of transactions"

# Ratio metric (composing existing metrics)
  - name: avg_transaction_value
    type: ratio
    type_params:
      numerator: total_transaction_volume
      denominator: total_transaction_count
    description: "Average dollar value per transaction"

# Derived metric (extending with new logic)
  - name: net_settlement_volume
    type: derived
    type_params:
      expr: total_transaction_volume - declined_transaction_volume
      metrics:
        - total_transaction_volume
        - declined_transaction_volume
    description: "Net value of settled transactions (authorized minus declined)"
```

**Key Advantage**: When you update `total_transaction_volume` definition (e.g., exclude pending), every downstream metric inherits the change automatically.

## Naming Conventions

### Model Naming Pattern

```
<dag_stage>_<source>__<entity>__<context>
```

**Examples:**
```
stg_stripe__payments          # staging layer, Stripe source
int_transactions_joined       # intermediate transformation
fct_card_transactions         # fact table, card domain
dim_customers                 # dimension table
mrt_customer_ltv__monthly     # mart with time grain
```

**Key Principles:**
- **Be verbose** - Extra characters are free; full words beat abbreviations
- **Use underscores consistently** - Single `_` separates words, double `__` separates major components
- **Indicate layer with prefix** - `stg_` (staging), `int_` (intermediate), `fct_/dim_` (facts/dimensions)
- **Business-friendly in presentation** - Technical prefixes fine for models, but expose "Customer Lifetime Value" not "fct_customer_ltv" to business users

### Metric Naming Standards

```
<verb>_<noun>_<aggregation>
```

**Examples:**
```
total_transaction_amount
avg_order_value
count_active_accounts
sum_dispute_losses
median_balance_monthly
```

**Requirements for dbt metrics:**
- Lowercase only
- Numbers allowed
- Underscores for separation
- Globally unique across all metrics
- No abbreviations (business users shouldn't need a decoder ring)

## Essential Metric Patterns for Fintech

### Transaction Volume Metrics

```yaml
metrics:
  - name: total_transaction_volume
    type: simple
    type_params:
      measure: transaction_amount_usd
    
  - name: total_transaction_count
    type: simple
    type_params:
      measure: transaction_id
      agg: count_distinct
  
  - name: median_transaction_amount
    type: simple
    type_params:
      measure: transaction_amount_usd
      agg: median
    description: "More robust to outliers than average"
```

### Normalized Metrics (Remove Growth Effects)

```yaml
# Per-active-user normalization
metrics:
  - name: spend_per_active_user
    type: ratio
    type_params:
      numerator: total_transaction_volume
      denominator: monthly_active_users
    description: "Isolates per-user behavior from growth"

# Per-funded-account (filters dormant)
  - name: spend_per_funded_account
    type: ratio
    type_params:
      numerator: total_transaction_volume
      denominator: funded_accounts
    description: "Only accounts with balance > $10"
```

### Cohort & Retention Metrics

```yaml
# Trailing window metrics
metrics:
  - name: trailing_30d_active_users
    type: simple
    type_params:
      measure: customer_id
      agg: count_distinct
    filter: |
      {{ Dimension('customer__last_transaction_date') }} >= {{ TimeDimension('metric_time', 'day') }} - interval '30 days'
  
  - name: trailing_30d_transaction_volume
    type: cumulative
    type_params:
      measure: transaction_amount_usd
      window: 30 days
    description: "Rolling 30-day transaction volume"
```

### Financial Health Indicators

```yaml
metrics:
  - name: median_balance_by_cohort
    type: simple
    type_params:
      measure: balance_amount
      agg: median
    dimensions:
      - customer_cohort
      - income_bracket
  
  - name: savings_rate
    type: ratio
    type_params:
      numerator: net_deposits
      denominator: total_inflows
    description: "Net deposits / (direct deposit + transfers)"
  
  - name: share_of_income_to_bills
    type: ratio
    type_params:
      numerator: recurring_debits
      denominator: total_inflows
    description: "Recurring debits / total inflows"
```

### Fraud & Risk Metrics

```yaml
metrics:
  - name: fraud_rate_bps
    type: ratio
    type_params:
      numerator: fraud_transaction_volume
      denominator: total_transaction_volume
    formula: "numerator / denominator * 10000"
    description: "Fraud losses in basis points"
  
  - name: dispute_rate_bps
    type: ratio
    type_params:
      numerator: disputed_transaction_count
      denominator: settled_transaction_count
    formula: "numerator / denominator * 10000"
    description: "Chargebacks per settled transaction in bps"
  
  - name: authorization_success_rate
    type: ratio
    type_params:
      numerator: authorized_transactions
      denominator: total_authorization_attempts
    description: "Approved / total authorization attempts"
```

## Context-Aware Dimensions for Flexible Segmentation

**The Problem**: Marketing requests customer persona segmentation. Traditional approach = add persona columns to 30+ tables, rewrite 100+ queries.

**The Solution**: Add dimension once to semantic model, instantly queryable across all metrics.

```yaml
# Step 1: Create dimension table
models:
  - name: dim_customer_personas
    columns:
      - name: customer_id
        description: "Foreign key to customers"
      - name: persona_name
        description: "Budget-Conscious, Reward-Seekers, Premium-Lifestyle"

# Step 2: Add to semantic model as dimension
semantic_models:
  - name: customers
    model: ref('dim_customers')
    entities:
      - name: customer_id
        type: primary
    dimensions:
      - name: persona_name
        type: categorical
        expr: persona_name

# Step 3: Query ANY metric by persona (no refactoring needed)
# "Show me total_transaction_volume by customer_persona"
# "Show me avg_transaction_value by customer_persona and month"
```

**Additional Context Dimensions:**
- Income bracket (lower tercile, middle tercile, upper tercile, top 5%)
- Generation cohort (Gen Z, Millennials, Gen X, Boomers)
- Geographic region (census regions, MSA-level)
- Account tenure (0-30 days, 31-90 days, 91-180 days, 180+ days)
- Spend category affinity (grocery-heavy, dining-heavy, travel-heavy)

## Redshift-Specific Optimizations

### Distribution and Sort Keys

```sql
-- Atomic transaction table
CREATE TABLE fct_card_transactions (
    transaction_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    transaction_timestamp TIMESTAMP,
    amount_usd DECIMAL(18,2),
    merchant_category VARCHAR(50),
    transaction_status VARCHAR(20)
)
DISTKEY(customer_id)        -- Distribute by customer for join performance
SORTKEY(transaction_timestamp, customer_id);  -- Sort by time and customer

-- Periodic snapshot table
CREATE TABLE fct_daily_balances (
    customer_id VARCHAR(50),
    balance_date DATE,
    balance_amount DECIMAL(18,2),
    account_status VARCHAR(20)
)
DISTKEY(customer_id)
SORTKEY(balance_date);       -- Dense time series benefits from date sort
```

**Guidelines:**
- DISTKEY on high-cardinality join columns (customer_id, account_id)
- SORTKEY on time dimensions for range queries
- Compound sortkeys for multiple filter conditions
- Monitor query plans with `EXPLAIN` to validate optimizations

### Selective Materialization

```yaml
# Define saved query for frequently-run executive dashboard
saved_queries:
  - name: executive_monthly_metrics
    description: "Monthly metrics by customer segment - runs hourly"
    query_params:
      metrics:
        - total_transaction_volume
        - monthly_active_users
        - avg_transaction_value
        - median_balance
      group_by:
        - metric_time__month
        - customer_segment
      where:
        - "{{ TimeDimension('metric_time', 'month') }} >= current_date - interval '12 months'"
    exports:
      - name: monthly_exec_metrics
        config:
          alias: mrt_executive_metrics__monthly
          export_as: table
          schema: analytics_marts
```

**When to materialize:**
- Same rollup runs repeatedly (hourly exec dashboard)
- Query time > 10 seconds with semantic layer query
- Users need 2-second response time
- Hot path justifies storage cost

## Testing & Validation Framework

### Automated Validation

```yaml
# In .github/workflows/semantic-layer-test.yml
name: Semantic Layer Validation
on: [pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Validate semantic models
        run: dbt sl validate
      - name: List valid dimensions per metric
        run: |
          dbt sl list dimensions --metrics total_transaction_volume
          dbt sl list dimensions --metrics fraud_rate_bps
      - name: Check compiled SQL
        run: dbt sl query --metrics total_transaction_volume --compile
```

### Schema Tests

```yaml
# In models/marts/schema.yml
version: 2
models:
  - name: fct_card_transactions
    tests:
      - dbt_utils.expression_is_true:
          expression: "amount_usd > 0"
          config:
            where: "transaction_status = 'settled'"
    columns:
      - name: transaction_id
        tests:
          - unique
          - not_null
      - name: customer_id
        tests:
          - not_null
          - relationships:
              to: ref('dim_customers')
              field: customer_id
      - name: transaction_status
        tests:
          - accepted_values:
              values: ['authorized', 'settled', 'declined', 'reversed']
      - name: amount_usd
        tests:
          - not_null
          - dbt_utils.expression_is_true:
              expression: "amount_usd <= 50000"
              config:
                error_if: ">10"
                warn_if: ">5"
```

### Custom Business Rule Tests

```sql
-- tests/transaction_daily_reconciliation.sql
-- Test: Daily transaction totals should match settled batch totals
WITH semantic_layer_total AS (
  SELECT 
    transaction_date,
    SUM(amount_usd) as sl_total 
  FROM {{ ref('fct_card_transactions') }}
  WHERE transaction_status = 'settled'
    AND transaction_date = CURRENT_DATE - 1
  GROUP BY transaction_date
),
batch_total AS (
  SELECT 
    settlement_date as transaction_date,
    SUM(settlement_amount) as batch_total 
  FROM {{ source('payments', 'settlement_batches') }}
  WHERE settlement_date = CURRENT_DATE - 1
  GROUP BY settlement_date
)
SELECT 
  sl.transaction_date,
  sl.sl_total,
  bt.batch_total,
  ABS(sl.sl_total - bt.batch_total) as difference
FROM semantic_layer_total sl
FULL OUTER JOIN batch_total bt USING (transaction_date)
WHERE ABS(COALESCE(sl.sl_total, 0) - COALESCE(bt.batch_total, 0)) > 0.01
```

## Discovery & Governance

### Metadata Best Practices

```yaml
semantic_models:
  - name: transactions
    description: |
      Atomic transaction facts from card authorization and settlement events.
      
      **Grain**: One row per card transaction (authorization or settlement)
      **Owner**: Payments Team (@payments-team)
      **SLA**: Refreshed every 15 minutes
      **Data Quality**: 99.8% complete, monitored via re_data
      
      Use Cases:
      - Transaction volume analysis
      - Merchant category spend breakdowns
      - Authorization vs. settlement reconciliation
    
    meta:
      owner: "@payments-team"
      domain: "merchant_spend"
      refresh_schedule: "*/15 * * * *"
      quality_score: 99.8
      governance_tier: "tier_1_critical"
      related_documentation: "https://wiki.company.com/payments/transaction-data"
```

### Tags for Organization

```yaml
metrics:
  - name: total_transaction_volume
    tags: 
      - "executive_dashboard"
      - "regulatory_reporting"
      - "tier_1_critical"
      - "finance_certified"
  
  - name: trailing_30d_fraud_rate_bps
    tags:
      - "risk_monitoring"
      - "daily_alerting"
      - "tier_1_critical"
```

### Data Catalog Integration

Your semantic models automatically register with data catalogs (Atlan, Select Star, Informatica) providing:

- **Natural language search** - Business users search "customer churn" not "dim_customers.churn_flag"
- **Lineage visualization** - Click metric → see path from source through transformations
- **Trust signals** - Last queried, verification badges, quality scores
- **Social curation** - Users rate metrics, comment, tag experts

## Intake Process for Metric Requests

**Critical Questions** (filter out low-value requests):

1. **"What decision will you make with this data?"**
   - Good: "Decide whether to increase marketing spend in high-churn segments"
   - Bad: "My boss wants to see the numbers"

2. **"What problem are you trying to solve?"**
   - Reveals underlying need vs. stated request
   - Requester asks for "DAU by feature" but needs "feature adoption rate among new users"

3. **"Who will see this deliverable?"**
   - Executive summary vs. technical deep-dive
   - Determines metric naming (business-friendly vs. technical)

4. **"Will this deliver business value within 90 days?"**
   - Aligns work with quarterly OKRs
   - Filters low-priority "someday" projects

## Common Anti-Patterns to Avoid

### ❌ Don't: Dewey Decimal Style Naming
```
# BAD - cryptic abbreviations
fct_txn_001
dim_cst_seg_v2
mrt_rev_003_final_v3
```

### ✅ Do: Verbose, Self-Documenting Names
```
# GOOD - explicit meaning
fct_card_transactions
dim_customer_segments
mrt_revenue_by_segment__monthly
```

### ❌ Don't: Pre-Aggregate Everything
```
# BAD - creates table explosion
fct_transactions_daily
fct_transactions_weekly
fct_transactions_monthly
fct_transactions_by_customer_daily
fct_transactions_by_merchant_weekly
# ... 100 more combinations
```

### ✅ Do: Atomic Storage + Dynamic Aggregation
```
# GOOD - single source, infinite aggregations
fct_card_transactions  # atomic grain
# Query at any grain via semantic layer:
# - daily/weekly/monthly
# - by customer/merchant/category
# - any time window
```

### ❌ Don't: Duplicate Metric Definitions
```
# BAD - inconsistent logic across tools
# Finance Tableau: SUM(CASE WHEN status='complete' THEN amount END)
# Marketing Mode: SUM(amount) WHERE status IN ('complete', 'settled')
# Exec Dashboard: SUM(settled_amount)
```

### ✅ Do: Single Source of Truth
```yaml
# GOOD - one definition
metrics:
  - name: total_revenue
    type: simple
    type_params:
      measure: transaction_amount
    filter: "transaction_status = 'settled'"
# Same logic everywhere: Tableau, Mode, AI agents
```

## AI Readiness

### Why This Matters for AI Agents

Traditional LLMs generating SQL fail because:
- Can't see business rules encoded in metrics
- Don't know that "revenue" excludes refunds
- Can't handle complex multi-table joins correctly
- Produce syntactically valid but semantically wrong results

**Semantic Layer solves this:**
- AI queries "revenue last month" → semantic layer translates to correct SQL
- Business rules embedded (revenue = settled transactions only)
- Relationships handled (auto-joins transaction → customer → segment)
- Consistent definitions (Finance and Marketing get same number)

### Natural Language → Semantic Layer Pattern

```
User: "What was our interchange revenue yesterday?"

AI Agent: Translates to semantic layer query
  Metric: interchange_revenue_amount
  Time grain: day
  Filter: metric_time = yesterday

Semantic Layer: Generates SQL
  - Joins fct_card_transactions → dim_merchants
  - Applies interchange rate logic
  - Filters to settled transactions only
  - Groups by transaction_date
  
Result: Single, correct number (not 3 different "revenue" definitions)
```

## Phased Implementation Roadmap

### Phase 1: Foundation (Months 1-3)
- ✅ Set up dbt project with Redshift connection
- ✅ Define domain boundaries and owners
- ✅ Build first semantic model (Merchant Spend domain)
- ✅ Create 10-15 core transaction metrics
- ✅ Implement testing framework with CI/CD

### Phase 2: Expansion (Months 4-6)
- Add remaining domains (ACH, Fraud, Customer Lifecycle)
- Implement advanced metrics (cumulative, conversion funnels)
- Build saved queries for common dashboards
- Set up data catalog
- Integrate with Tableau

### Phase 3: Optimization (Months 7-9)
- Add segmentation dimensions (personas, cohorts)
- Implement behavior analysis metrics
- Performance optimization (selective materialization)
- Pilot AI BI tool (ThoughtSpot, Sigma, Mode)
- Automated monitoring (re_data)

### Phase 4: Scale & Governance (Months 10-12)
- Governance framework (certification, approval process)
- Self-service enablement (training, office hours)
- Cross-domain analytics
- Expand AI BI adoption
- Continuous improvement (deprecate unused, add requested)

## Quick Reference Commands

```bash
# Validate semantic models
dbt sl validate

# List all metrics
dbt sl list metrics

# List dimensions for a specific metric
dbt sl list dimensions --metrics total_transaction_volume

# Query metrics (test query generation)
dbt sl query \
  --metrics total_transaction_volume,avg_transaction_value \
  --group-by metric_time__month,customer_segment \
  --where "metric_time >= '2024-01-01'" \
  --compile  # Show SQL without executing

# Query and execute
dbt sl query \
  --metrics total_transaction_volume \
  --group-by metric_time__day \
  --where "metric_time >= current_date - interval '7 days'" \
  --order metric_time__day

# Export saved query
dbt sl export --saved-query executive_monthly_metrics
```

## Resources & Further Reading

### Essential Foundations
- [dbt MetricFlow Docs](https://docs.getdbt.com/docs/build/about-metricflow)
- [dbt Semantic Layer Getting Started](https://docs.getdbt.com/docs/build/sl-getting-started)
- [Stakeholder-Friendly Model Names](https://docs.getdbt.com/blog/stakeholder-friendly-model-names)

### Architecture Patterns
- [Martin Fowler - Data Mesh](https://martinfowler.com/articles/data-monolith-to-mesh.html)
- [AtScale Composable Models](https://atscale.com/blog/composable-models-future-semantic-layer)
- [Meta Composable Data Management](https://engineering.fb.com/2024/05/22/data-infrastructure/composable-data-management-at-meta/)

### Operations
- [dbt MetricFlow Commands](https://docs.getdbt.com/docs/build/metricflow-commands)
- [Metaplane dbt Quality Guide](https://www.metaplane.dev/blog/guide-to-dbt-data-quality-checks)
- [Caitlin Hudon Intake Form](https://www.caitlinhudon.com/posts/2020/09/16/data-intake-form)

### BI Integration
- [Tableau dbt Integration](https://docs.getdbt.com/docs/cloud-integrations/semantic-layer/tableau)
- [Holistics AI BI Comparison](https://www.holistics.io/bi-tools/ai-powered/)

---

## Critical Success Factors

1. **Start atomic, aggregate dynamically** - Store facts once, let semantic layer generate rollups
2. **Domain ownership** - Each pipeline has explicit data product owner
3. **Composable metrics** - Git-versioned components that extend without overwriting
4. **Context dimensions** - Add segments to semantic layer, no refactoring needed
5. **Strong intake** - Filter requests with key questions, prioritize ruthlessly
6. **Comprehensive testing** - Automated validation, custom SQL tests, ongoing monitoring
7. **Discovery infrastructure** - Catalog with search, lineage, trust signals
8. **Incremental migration** - Narrow scope first, build parallel, switch when validated

---

**This skill embodies the principle**: AI agents are only as good as the semantic layer they query. Extra work upfront on definitions, testing, and governance prevents "syntactically correct but semantically wrong" results at scale.