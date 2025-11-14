# MetricFlow CLI Commands - Complete Reference

## Overview

MetricFlow provides CLI commands for listing metadata, querying metrics, and validating configurations. Commands use different prefixes depending on your environment:
- **dbt Cloud:** Use `dbt sl` prefix (e.g., `dbt sl list metrics`)
- **dbt Core:** Use `mf` prefix (e.g., `mf list metrics`)

**Installation:**
```bash
# Install MetricFlow with your adapter
python -m pip install "dbt-metricflow[snowflake]"
# Or: dbt-metricflow[bigquery], dbt-metricflow[redshift], dbt-metricflow[databricks]

# Verify installation
dbt --version
mf --version

# If mf conflicts with Metafont latex package, uninstall it
pip uninstall metafont
```

---

## Discovery Commands

### List Metrics

**Purpose:** Display all available metrics with their dimensions

```bash
# dbt Cloud
dbt sl list metrics

# dbt Core
mf list metrics

# Options
--search TEXT           # Filter metrics by search term
--show-all-dimensions   # Show all dimensions for each metric
--help                  # Show help message
```

**Example:**
```bash
dbt sl list metrics --search revenue --show-all-dimensions
```

---

### List Dimensions

**Purpose:** Show unique dimensions available for one or more metrics

```bash
# dbt Cloud
dbt sl list dimensions --metrics <metric_name>

# dbt Core
mf list dimensions --metrics <metric_name>

# Options
--metrics SEQUENCE  # One or more metrics (comma-separated, no spaces)
                    # Example: --metrics bookings,messages
--help              # Show help message
```

**Example:**
```bash
# Single metric
dbt sl list dimensions --metrics order_total

# Multiple metrics (shows common dimensions only)
dbt sl list dimensions --metrics order_total,revenue
```

**Note:** When querying multiple metrics, only **common dimensions** (intersection) are displayed.

---

### List Dimension Values

**Purpose:** Display all values for a specific dimension

```bash
# dbt Cloud
dbt sl list dimension-values --metrics <metric_name> --dimension <dimension_name>

# dbt Core
mf list dimension-values --metrics <metric_name> --dimension <dimension_name>

# Options
--dimension TEXT    # Dimension to query values from (REQUIRED)
--metrics SEQUENCE  # Metrics associated with dimension (REQUIRED)
--start-time TEXT   # ISO8601 timestamp (inclusive) - dbt Core only
--end-time TEXT     # ISO8601 timestamp (inclusive) - dbt Core only
--help              # Show help message
```

**Example:**
```bash
dbt sl list dimension-values --metrics order_total --dimension order_status
```

---

### List Entities

**Purpose:** Show all unique entities (join keys) for metrics

```bash
# dbt Cloud
dbt sl list entities --metrics <metric_name>

# dbt Core
mf list entities --metrics <metric_name>

# Options
--metrics SEQUENCE  # One or more metrics (comma-separated, no spaces)
                    # Example: --metrics bookings,messages
--help              # Show help message
```

**Example:**
```bash
dbt sl list entities --metrics order_total,customer_lifetime_value
```

---

### List Saved Queries

**Purpose:** Display all available saved queries and their exports

```bash
# dbt Cloud
dbt sl list saved-queries

# Options
--show-exports     # Show exports under each saved query
--show-parameters  # Show full query parameters each saved query uses
--help             # Show help message
```

**Example with Output:**
```bash
$ dbt sl list saved-queries --show-exports

The list of available saved queries:
- new_customer_orders
  exports:
    - Export(new_customer_orders_table, exportAs=TABLE)
    - Export(new_customer_orders_view, exportAs=VIEW)
    - Export(new_customer_orders, alias=orders, schemas=customer_schema, exportAs=TABLE)
```

---

## Query Commands

### Query Metrics

**Purpose:** Execute queries against metrics and dimensions

```bash
# dbt Cloud
dbt sl query --metrics <metric_name> --group-by <dimension_name>
dbt sl query --saved-query <name>

# dbt Core
mf query --metrics <metric_name> --group-by <dimension_name>

# Core Options
--metrics SEQUENCE       # One or more metrics (comma-separated, NO SPACES)
                        # Example: --metrics bookings,messages

--group-by SEQUENCE     # One or more dimensions/entities (comma-separated, NO SPACES)
                        # Example: --group-by ds,org

--where TEXT            # Filter using template wrappers (see Query Syntax below)
                        # Example: --where "{{ Dimension('order_id__is_food') }} = True"

--limit INTEGER         # Limit rows returned (default: 100 in dbt Cloud)

--order-by SEQUENCE     # Sort results (- prefix for DESC, no prefix for ASC)
                        # Example: --order-by -metric_time,revenue

--start-time TEXT       # ISO8601 timestamp filter (inclusive) - dbt Core only
--end-time TEXT         # ISO8601 timestamp filter (inclusive) - dbt Core only

--compile               # Show generated SQL (dbt Cloud)
--explain               # Show generated SQL (dbt Core)

--csv FILENAME          # Export to CSV file - dbt Core only

--show-dataflow-plan    # Display dataflow plan in output
--display-plans         # Display plans in browser
--decimals INTEGER      # Decimal places for numeric values
--show-sql-descriptions # Show inline SQL node descriptions

--help                  # Show help message
```

---

## Query Syntax & Examples

### Basic Query

```bash
# Single metric
dbt sl query --metrics order_total --group-by metric_time

# Multiple metrics (NO SPACES after commas)
dbt sl query --metrics order_total,users_active --group-by metric_time
```

**Output:**
```
✔ Success 🦄 - query completed after 1.24 seconds
| METRIC_TIME   |   ORDER_TOTAL |   USERS_ACTIVE |
|:--------------|---------------:|---------------:|
| 2024-06-16    |       792.17   |            145 |
| 2024-06-17    |       458.35   |            132 |
```

---

### Query with Dimensions

**Important:** When querying dimensions, specify the **primary entity** using double underscore syntax: `entity__dimension`

```bash
# Query dimension (requires entity qualification)
dbt sl query --metrics order_total --group-by order_id__is_food_order
```

**Output:**
```
| METRIC_TIME   | IS_FOOD_ORDER   |   ORDER_TOTAL |
|:--------------|:----------------|---------------:|
| 2024-06-16    | True            |        499.27 |
| 2024-06-16    | False           |        292.90 |
```

---

### Order and Limit

**Use `-` prefix for descending order, no prefix for ascending**

```bash
dbt sl query \
  --metrics order_total \
  --group-by order_id__is_food_order \
  --limit 10 \
  --order-by -metric_time
```

**Multiple sort columns:**
```bash
# Sort by metric_time ASC, then revenue DESC
--order-by metric_time,-revenue
```

---

### Where Clause (CRITICAL: Template Wrappers Required)

**You MUST use template wrappers for dimensions and time dimensions:**

```bash
# Single where clause
dbt sl query \
  --metrics order_total \
  --group-by order_id__is_food_order \
  --where "{{ Dimension('order_id__is_food_order') }} = True"

# Multiple where clauses (each wrapped in quotes)
dbt sl query \
  --metrics order_total \
  --group-by metric_time__week \
  --where "{{ Dimension('order_id__is_food_order') }} = True" \
  --where "{{ TimeDimension('metric_time', 'week') }} >= '2024-02-01'"
```

**Template Wrapper Types:**
- `{{ Dimension('entity__dimension_name') }}` - For categorical/regular dimensions
- `{{ TimeDimension('metric_time', 'grain') }}` - For time-based filters

**Critical Shell Configuration:**
```bash
# Required for template wrappers to work in zsh
echo "setopt BRACECCL" >> ~/.zshrc
source ~/.zshrc
```

Without this configuration, curly braces will cause shell expansion errors.

---

### Time Filtering (Optimized Pushdown)

**Use dedicated time options for better performance:**

```bash
# dbt Core (start/end time available)
mf query \
  --metrics order_total \
  --group-by order_id__is_food_order \
  --start-time '2024-08-22' \
  --end-time '2024-08-27' \
  --limit 10 \
  --order-by -metric_time
```

**Note:** `--start-time` and `--end-time` allow MetricFlow to optimize query performance by pushing down time filters.

---

### Time Granularity

**Specify time grain by appending double underscore and grain to `metric_time`:**

```bash
# Daily grain
dbt sl query --metrics revenue --group-by metric_time__day

# Weekly grain
dbt sl query --metrics revenue --group-by metric_time__week

# Monthly grain
dbt sl query --metrics revenue --group-by metric_time__month

# Quarterly grain
dbt sl query --metrics revenue --group-by metric_time__quarter

# Yearly grain
dbt sl query --metrics revenue --group-by metric_time__year
```

---

### Show Generated SQL

**View the SQL that MetricFlow generates:**

```bash
# dbt Cloud
dbt sl query --metrics order_total --group-by metric_time --compile

# dbt Core
mf query --metrics order_total --group-by metric_time --explain
```

**Output:**
```sql
🔎 SQL:
select
  metric_time,
  sum(order_cost) as order_total
from (
  select
    cast(ordered_at as date) as metric_time,
    order_cost
  from analytics.orders orders_src_1
  where cast(ordered_at as date) between '2024-01-01' and '2024-12-31'
) subq_3
group by metric_time
order by metric_time desc
```

---

### Export to CSV (dbt Core Only)

```bash
mf query \
  --metrics order_total,revenue \
  --group-by metric_time \
  --csv output.csv
```

**Output:**
```
✔ Success 🦄 - query completed after 0.83 seconds
🖨 Successfully written query output to output.csv
```

---

### Query Saved Queries

```bash
# Query saved query by name
dbt sl query --saved-query new_customer_orders
```

**Important Limitations:**
- ✅ Can use: `--where`, `--limit`, `--order`, `--compile`
- ❌ Cannot use: `--metrics`, `--group-by` (predetermined in saved query definition)

---

## Validation Commands

### Validate Configurations

**Purpose:** Run 3-layer validation on semantic models and metrics

```bash
# dbt Cloud
dbt sl validate

# dbt Core
mf validate-configs

# dbt Cloud Options
--timeout INTEGER       # Timeout for data warehouse validation

# dbt Core Options
--dw-timeout INTEGER    # Data warehouse validation timeout
--skip-dw               # Skip data warehouse validation (faster CI)
--show-all              # Print warnings and future errors
--verbose-issues        # Print extra details about issues
--semantic-validation-workers INTEGER  # Number of workers for large configs
--help                  # Show help message
```

**Validation Layers:**
1. **Parsing Validation** - YAML schema adherence (required fields, structure)
2. **Semantic Syntax Validation** - Graph constraints (unique names, valid time dims, entity relationships)
3. **Data Platform Validation** - Physical table existence, SQL execution tests

**Example:**
```bash
# Full validation (all 3 layers)
dbt sl validate

# Skip warehouse checks (useful for CI - faster feedback)
mf validate-configs --skip-dw

# Verbose output for debugging
mf validate-configs --verbose-issues --show-all
```

---

### Health Checks (dbt Core Only)

**Purpose:** Verify data platform connectivity

```bash
mf health-checks
```

**Note:** In dbt Cloud, health checks aren't needed as it uses dbt's credentials automatically.

---

## Export Commands (dbt Cloud Only)

### Export Single Saved Query

**Purpose:** Run exports for a specific saved query (development testing)

```bash
dbt sl export --saved-query <name>

# Select specific export
dbt sl export --saved-query <name> --select <export_name>
```

**Use Case:** Test and generate exports in development environment before production deployment.

---

### Export All Saved Queries

**Purpose:** Run exports for multiple saved queries simultaneously

```bash
dbt sl export-all
```

**Use Case:** Bulk export generation for multiple saved queries, saving time in development workflows.

---

## Utility Commands (dbt Core Only)

### Tutorial

**Purpose:** Interactive MetricFlow tutorial

```bash
mf tutorial
```

Launches step-by-step tutorial to help you get started with MetricFlow.

---

## Development Workflow

### Standard Development Loop

```bash
# 1. Edit semantic models/metrics YAML files
# Edit: models/semantic/orders_semantic.yml

# 2. Parse project (generates semantic_manifest.json)
dbt parse

# 3. Validate configurations
dbt sl validate

# 4. Test query locally
dbt sl query --metrics order_total --group-by metric_time__day --limit 10

# 5. Review generated SQL
dbt sl query --metrics order_total --group-by metric_time__day --compile

# 6. Iterate based on results (go back to step 1 if needed)

# 7. Commit changes
git add models/semantic/
git commit -m "Add order metrics"
```

**Critical Note:** Always run `dbt parse` after changing metrics/semantic models to update `semantic_manifest.json`.

---

## Common Query Patterns

### Pattern 1: Daily Revenue Trend
```bash
dbt sl query \
  --metrics total_revenue \
  --group-by metric_time__day \
  --start-time '2024-01-01' \
  --end-time '2024-12-31' \
  --order-by -metric_time \
  --limit 100
```

---

### Pattern 2: Revenue by Region with Filter
```bash
dbt sl query \
  --metrics total_revenue,order_count \
  --group-by customer_id__region \
  --where "{{ Dimension('order_id__status') }} = 'completed'" \
  --order-by -total_revenue \
  --limit 10
```

---

### Pattern 3: Multi-Dimensional Analysis
```bash
dbt sl query \
  --metrics revenue,customer_count \
  --group-by metric_time__month,customer_id__segment,product_id__category \
  --where "{{ TimeDimension('metric_time', 'month') }} >= '2024-01-01'" \
  --order-by metric_time__month,-revenue
```

---

### Pattern 4: Export for Analysis
```bash
# dbt Core only
mf query \
  --metrics revenue,orders,customers \
  --group-by metric_time__week,region \
  --start-time '2024-01-01' \
  --end-time '2024-12-31' \
  --order-by metric_time__week \
  --csv weekly_analysis.csv
```

---

### Pattern 5: Debug Query with SQL
```bash
dbt sl query \
  --metrics order_total \
  --group-by metric_time,is_food_order \
  --where "{{ Dimension('order_id__is_food_order') }} = True" \
  --compile
```

---

## FAQs & Troubleshooting

### Q: How do I query multiple metrics or dimensions?

**A:** Use comma-separated values with **NO SPACES**:

```bash
# ✅ CORRECT - No spaces
--metrics order_total,revenue,customer_count
--group-by metric_time,region,product_category

# ❌ WRONG - Spaces will cause errors
--metrics order_total, revenue, customer_count
```

---

### Q: Why is my query limited to 100 rows?

**A:** dbt Cloud CLI has a default limit of 100 rows to prevent large data sets during development.

**Solution:** Explicitly set limit:
```bash
dbt sl query --metrics revenue --group-by metric_time --limit 1000
```

---

### Q: How do I add dimension filters in where clauses?

**A:** Use template wrappers to indicate the filter is part of your model:

```bash
--where "{{ Dimension('entity__dimension_name') }}"
```

**Example:**
```bash
dbt sl query \
  --metrics order_total \
  --where "{{ Dimension('order_id__is_food_order') }} = True"
```

**Shell Setup Required:** Configure your shell to escape curly braces:
```bash
# For zsh (.zshrc)
echo "setopt BRACECCL" >> ~/.zshrc
source ~/.zshrc

# For bash (.bashrc)
# No configuration needed
```

---

### Q: How do I sort in ascending vs descending order?

**A:** Use `-` prefix for descending, no prefix for ascending:

```bash
# Descending order
--order-by -metric_time

# Ascending order
--order-by metric_time

# Mixed
--order-by metric_time,-revenue  # time ASC, revenue DESC
```

---

### Q: What's the difference between --where and --start-time/--end-time?

**A:** Time-specific filters enable query optimization:
- `--where` - General filter conditions (any dimension)
- `--start-time` / `--end-time` - Optimized for time filtering (pushdown optimization)

**Use --start-time/--end-time when possible for better performance.**

---

### Q: Can I override metrics in saved queries?

**A:** No. Saved queries have predetermined `metrics` and `group_by` parameters.

**You CAN use:** `--where`, `--limit`, `--order-by`, `--compile`
**You CANNOT use:** `--metrics`, `--group-by`

**To query different metrics:** Use standard query format, not saved query.

---

### Q: Why does my mf command fail with "command not found"?

**A:** Two common causes:

1. **MetricFlow not installed:**
   ```bash
   python -m pip install "dbt-metricflow[your-adapter]"
   ```

2. **Metafont latex package conflict:**
   ```bash
   pip uninstall metafont
   ```

---

### Q: How do I specify time grain for metric_time?

**A:** Append double underscore and grain:

```bash
--group-by metric_time__day
--group-by metric_time__week
--group-by metric_time__month
--group-by metric_time__quarter
--group-by metric_time__year
```

---

### Q: What does "entity__dimension" syntax mean?

**A:** When querying dimensions, you must qualify them with their primary entity:

```bash
# If order_id is the primary entity for is_food_order dimension
--group-by order_id__is_food_order

# If customer_id is the primary entity for segment dimension
--group-by customer_id__segment
```

This tells MetricFlow which entity relationship to use for the dimension.

---

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Validate Semantic Layer
on: [pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Python
        uses: actions/setup-python@v2
        with:
          python-version: '3.10'
      
      - name: Install dbt + MetricFlow
        run: pip install "dbt-metricflow[snowflake]"
      
      - name: Configure profiles.yml
        run: |
          mkdir -p ~/.dbt
          echo "$DBT_PROFILES" > ~/.dbt/profiles.yml
        env:
          DBT_PROFILES: ${{ secrets.DBT_PROFILES }}
      
      - name: Install dependencies
        run: dbt deps
      
      - name: Parse semantic layer
        run: dbt parse
      
      - name: Validate configurations (skip warehouse for speed)
        run: mf validate-configs --skip-dw
      
      - name: Run semantic tests
        run: dbt test --select tag:semantic_layer
```

---

## Command Cheatsheet

```bash
# Discovery
dbt sl list metrics --search <term>
dbt sl list dimensions --metrics <metric>
dbt sl list dimension-values --metrics <m> --dimension <d>
dbt sl list entities --metrics <metric>
dbt sl list saved-queries --show-exports

# Query
dbt sl query --metrics <m> --group-by <d>
dbt sl query --saved-query <name>

# Validation
dbt sl validate
mf validate-configs --skip-dw

# Development
dbt parse  # ALWAYS run after YAML changes
dbt sl query --metrics <m> --compile  # Debug SQL

# Export (dbt Cloud only)
dbt sl export --saved-query <name>
dbt sl export-all
```

---

## Quick Tips

1. ✅ **Always run `dbt parse` after changing semantic models/metrics**
2. ✅ **Use `--skip-dw` in CI for faster validation feedback**
3. ✅ **Use `--compile` to debug generated SQL**
4. ✅ **Configure shell for template wrappers (`.zshrc`)**
5. ✅ **Use `--start-time`/`--end-time` instead of where for time filters (optimization)**
6. ✅ **No spaces in comma-separated lists** (metrics, group-by, order-by)
7. ✅ **Qualify dimensions with entity** (`order_id__dimension_name`)
8. ✅ **Use `-` prefix for descending sort** (`--order-by -metric_time`)
9. ✅ **Default limit is 100 rows in dbt Cloud** (change with `--limit`)
10. ✅ **Uninstall metafont if mf command conflicts**

---

## Related Resources

- See `guide_validation_workflow.md` for validation details
- See `guide_local_development.md` for setup instructions
- See `guide_query_syntax.md` for advanced query patterns
- See official docs: https://docs.getdbt.com/docs/build/metricflow-commands
