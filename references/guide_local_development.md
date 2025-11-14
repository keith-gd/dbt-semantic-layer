# Local Development Setup & Workflow

## Prerequisites

**Required:**
- Python 3.8+ (3.11 recommended)
- dbt Core installed
- Data warehouse connection configured (Snowflake, BigQuery, Redshift, Databricks)

**Recommended:**
- Virtual environment (`venv` or `conda`)
- Code editor with YAML support (VS Code, PyCharm)
- Git for version control

---

## Installation

### Step 1: Install dbt Core + MetricFlow

```bash
# Create virtual environment (recommended)
python -m venv dbt-env
source dbt-env/bin/activate  # On Windows: dbt-env\Scripts\activate

# Install dbt Core with adapter
pip install dbt-core dbt-snowflake  # Or: dbt-bigquery, dbt-redshift, dbt-databricks

# Install MetricFlow with same adapter
pip install "dbt-metricflow[snowflake]"  # Match your adapter

# Verify installation
dbt --version
mf --version
```

**Common Issue:** `mf` command conflicts with Metafont (LaTeX package)

```bash
# If you see "mf: command not found" after install
pip uninstall metafont  # Remove conflicting package
pip install "dbt-metricflow[snowflake]"  # Reinstall

# Verify mf now works
mf --version
```

---

### Step 2: Configure Shell for Template Wrappers

MetricFlow uses `{{ }}` syntax in CLI commands. Zsh/Bash interpret these as glob patterns, causing errors.

**Symptom:**
```bash
mf query --metrics revenue --where "{{ TimeDimension('order_date', 'day') }}"
# Error: zsh: no matches found: {{ TimeDimension('order_date', 'day') }}
```

**Fix Option 1: Configure Zsh (Recommended)**

Add to `~/.zshrc`:

```bash
# Enable brace character class for MetricFlow
setopt BRACECCL
```

Reload shell:
```bash
source ~/.zshrc
```

**Fix Option 2: Always Quote Commands**

```bash
# ✅ CORRECT - Quoted
mf query --metrics revenue --where "{{ TimeDimension('order_date', 'day') }}"

# ❌ WRONG - Unquoted
mf query --metrics revenue --where {{ TimeDimension('order_date', 'day') }}
```

**Automated Setup:**

Use the provided script (see `scripts/setup_shell_config.sh`):

```bash
cd .claude/skills/kb-dbt-semantic-layer-developer
bash scripts/setup_shell_config.sh
```

---

### Step 3: Verify dbt Project Configuration

**Check `dbt_project.yml`:**

```yaml
# dbt_project.yml
name: 'my_project'
version: '1.0.0'

model-paths: ["models"]
seed-paths: ["seeds"]
test-paths: ["tests"]

# Semantic models live in models/ directory
# MetricFlow scans all .yml files for semantic_models: blocks
```

**Check profiles:**

```bash
# Test warehouse connection
dbt debug

# Should show:
# Connection test: OK
```

---

## Development Workflow

### 5-Step Iterative Loop

```
1. EDIT   → Modify semantic_models/*.yml or models/*.sql
2. PARSE  → dbt parse (validates YAML + generates semantic graph)
3. QUERY  → mf query --metrics <metric> (tests metric calculation)
4. INSPECT → Review results + generated SQL
5. ITERATE → Refine definitions and repeat
```

---

### Step 1: EDIT - Create Semantic Model

**File:** `models/semantic_models/orders.yml`

```yaml
semantic_models:
  - name: orders
    description: Order transaction facts
    model: ref('stg_orders')  # References dbt model

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

      - name: order_status
        type: categorical

    measures:
      - name: revenue
        agg: sum
        expr: order_total

      - name: order_count
        agg: count
        expr: order_id

metrics:
  - name: total_revenue
    description: Sum of all order revenue
    type: simple
    type_params:
      measure: revenue

  - name: total_orders
    description: Count of all orders
    type: simple
    type_params:
      measure: order_count

  - name: average_order_value
    description: Revenue per order
    type: ratio
    type_params:
      numerator: total_revenue
      denominator: total_orders
```

---

### Step 2: PARSE - Validate Configuration

```bash
# Parse project (validates YAML + builds semantic graph)
dbt parse

# Output:
# Completed successfully
#
# Done. PASS=1 WARN=0 ERROR=0 SKIP=0 TOTAL=1
```

**If parse fails:**
- Check YAML indentation
- Verify model references exist (`ref('stg_orders')`)
- Ensure measure/dimension names don't conflict

**Tip:** Use `dbt parse --profiles-dir ~/.dbt` to explicitly set profile location

---

### Step 3: QUERY - Test Metrics

```bash
# List available metrics
mf list metrics

# Output:
# total_revenue
# total_orders
# average_order_value

# Query simple metric
mf query --metrics total_revenue

# Output:
# ┏━━━━━━━━━━━━━━━┓
# ┃ total_revenue ┃
# ┡━━━━━━━━━━━━━━━┩
# │     1,234,567 │
# └───────────────┘

# Query with time dimension
mf query --metrics total_revenue --group-by metric_time__day --limit 5

# Output:
# ┏━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━┓
# ┃ metric_time   ┃ total_revenue ┃
# ┡━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━┩
# │ 2024-01-01    │     45,000    │
# │ 2024-01-02    │     52,300    │
# │ 2024-01-03    │     48,700    │
# └───────────────┴──────────────┘

# Query ratio metric
mf query --metrics average_order_value --group-by metric_time__week --limit 4
```

---

### Step 4: INSPECT - Review Generated SQL

```bash
# Compile query without executing
mf query --metrics total_revenue --group-by metric_time__day --compile

# View generated SQL in target/compiled/
cat target/compiled/metrics/total_revenue.sql
```

**Example generated SQL:**

```sql
SELECT
  DATE_TRUNC('day', order_date) AS metric_time__day,
  SUM(order_total) AS total_revenue
FROM analytics.stg_orders
GROUP BY 1
ORDER BY 1 DESC
```

**What to check:**
- ✅ Correct aggregation function (`SUM`, `COUNT`, `AVG`)
- ✅ Proper time truncation (`DATE_TRUNC`)
- ✅ Joins look correct (if multi-entity query)
- ❌ No ambiguous column references
- ❌ No Cartesian products

---

### Step 5: ITERATE - Refine & Repeat

**Common refinements:**

1. **Add filters:**
```bash
mf query --metrics total_revenue \
  --where "order_status == 'completed'" \
  --group-by metric_time__month
```

2. **Add more dimensions:**
```yaml
# In semantic model
dimensions:
  - name: customer_segment
    type: categorical

  - name: product_category
    type: categorical
```

```bash
# Query with new dimension
mf query --metrics total_revenue --group-by customer__customer_segment
```

3. **Create saved query for repeated use:**
```yaml
saved_queries:
  - name: revenue_daily
    description: Daily revenue for dashboards
    query_params:
      metrics:
        - total_revenue
      group_by:
        - metric_time__day
      where:
        - "{{ TimeDimension('metric_time', 'day') }} >= '2024-01-01'"
```

```bash
# Use saved query
mf query --saved-query revenue_daily
```

---

## Local Development Best Practices

### 1. Use Virtual Environments

```bash
# Create project-specific environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Freeze dependencies for reproducibility
pip freeze > requirements.txt
```

### 2. Configure Shell Aliases

Add to `~/.zshrc` or `~/.bashrc`:

```bash
# MetricFlow shortcuts
alias mf-list-metrics='mf list metrics'
alias mf-list-dimensions='mf list dimensions'
alias mf-validate='dbt parse && mf validate-configs'
alias mf-test-metric='mf query --metrics'
```

### 3. Create Development Scripts

**File:** `scripts/dev_test_metric.sh`

```bash
#!/bin/bash
# Quick validation workflow for metric development

METRIC_NAME=$1

if [ -z "$METRIC_NAME" ]; then
  echo "Usage: ./dev_test_metric.sh <metric_name>"
  exit 1
fi

echo "Testing metric: $METRIC_NAME"
echo ""

echo "1. Parsing project..."
dbt parse
if [ $? -ne 0 ]; then
  echo "❌ Parse failed"
  exit 1
fi

echo "2. Validating semantic config..."
mf validate-configs
if [ $? -ne 0 ]; then
  echo "❌ Validation failed"
  exit 1
fi

echo "3. Querying metric (sample)..."
mf query --metrics "$METRIC_NAME" --limit 5

echo "4. Querying metric by day (last 7 days)..."
mf query --metrics "$METRIC_NAME" \
  --group-by metric_time__day \
  --where "{{ TimeDimension('metric_time', 'day') }} >= '2024-11-07'" \
  --limit 7

echo "✅ Test complete!"
```

Usage:
```bash
bash scripts/dev_test_metric.sh total_revenue
```

### 4. Use `--explain` for Debugging

```bash
# Show generated SQL + execution plan
mf query --metrics total_revenue --explain

# See detailed query compilation
mf query --metrics total_revenue --log-level debug
```

### 5. Maintain a Local Test Suite

**File:** `scripts/test_all_metrics.sh`

```bash
#!/bin/bash
# Test all metrics in project

echo "Listing all metrics..."
METRICS=$(mf list metrics --output json | jq -r '.[].name')

for metric in $METRICS; do
  echo "Testing: $metric"
  mf query --metrics "$metric" --limit 1
  if [ $? -ne 0 ]; then
    echo "❌ $metric FAILED"
  else
    echo "✅ $metric passed"
  fi
done
```

---

## Troubleshooting Common Local Issues

### Issue: `mf: command not found`

**Cause:** MetricFlow not installed or not in PATH

**Fix:**
```bash
# Verify installation
pip list | grep dbt-metricflow

# If not found, install
pip install "dbt-metricflow[snowflake]"

# If installed but not in PATH, check virtual environment
which python  # Should point to venv/bin/python
```

---

### Issue: `dbt parse` fails with "Could not find profile"

**Cause:** `profiles.yml` missing or misconfigured

**Fix:**
```bash
# Check profile location
dbt debug --config-dir

# Typical location: ~/.dbt/profiles.yml

# Create if missing (example for Snowflake)
mkdir -p ~/.dbt
cat <<EOF > ~/.dbt/profiles.yml
my_project:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: xy12345.us-east-1
      user: my_user
      password: "{{ env_var('DBT_PASSWORD') }}"
      role: transformer
      database: analytics
      warehouse: transforming
      schema: dbt_dev
      threads: 4
EOF
```

---

### Issue: Queries fail with "Dimension not found"

**Symptom:**
```bash
mf query --metrics revenue --group-by customer_segment
# Error: Dimension 'customer_segment' not found
```

**Cause:** Dimension not defined or incorrect name

**Fix:**
```bash
# List available dimensions for metric
mf list dimensions --metrics revenue

# Use exact name from output
mf query --metrics revenue --group-by customer__customer_segment
```

---

### Issue: Ratio metric returns NULL

**Symptom:**
```bash
mf query --metrics conversion_rate
# Returns: NULL
```

**Causes:**
1. Denominator is zero
2. Numerator/denominator reference measures instead of metrics
3. Entities don't align (can't join numerator and denominator)

**Fix:**
```bash
# Check numerator and denominator separately
mf query --metrics conversions
mf query --metrics impressions

# Verify ratio metric definition references METRICS, not MEASURES
# ✅ CORRECT:
# type_params:
#   numerator: total_conversions  # metric
#   denominator: total_impressions  # metric

# ❌ WRONG:
# type_params:
#   numerator: conversions  # measure (won't work)
#   denominator: impressions  # measure
```

---

### Issue: Generated SQL has Cartesian product

**Symptom:** Query returns far more rows than expected

**Cause:** Missing entity join path

**Fix:**
1. Run `mf list entities --show-joins` to see entity graph
2. Verify entities are defined in both semantic models
3. Add explicit entity reference if ambiguous:

```bash
# Instead of:
mf query --metrics order_count --group-by customer_segment

# Use qualified entity:
mf query --metrics order_count --group-by customer__customer_segment
```

---

## Development Environment Checklist

Before starting semantic layer development:

- [ ] Python 3.8+ installed
- [ ] Virtual environment created and activated
- [ ] `dbt-core` installed
- [ ] `dbt-metricflow[adapter]` installed
- [ ] `~/.dbt/profiles.yml` configured
- [ ] `dbt debug` passes connection test
- [ ] Shell configured for template wrappers (`setopt BRACECCL`)
- [ ] `dbt parse` runs successfully
- [ ] `mf list metrics` returns existing metrics
- [ ] Test query executes: `mf query --metrics <any_metric> --limit 1`

---

## Next Steps

Once local development is configured:

1. **Create first semantic model** - Start with core fact table
2. **Define 2-3 simple metrics** - Validate basic aggregations work
3. **Add dimensions** - Enable slicing by categorical/time dimensions
4. **Create ratio metric** - Test cross-metric calculations
5. **Build saved query** - Package common metric combination for BI tool

**References:**
- [Validation Workflow](guide_validation_workflow.md)
- [Query Syntax Guide](guide_query_syntax.md)
- [CLI Commands Reference](cli_commands_complete.md)
