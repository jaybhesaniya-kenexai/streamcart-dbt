# StreamCart dbt Project

## Project Overview

StreamCart is a dbt Core project built on Snowflake to transform raw e-commerce order and product data into analytics-ready datasets for reporting and business intelligence.

The project follows a layered architecture:

**Sources → Staging → Intermediate → Marts**

The pipeline includes source freshness checks, data quality tests, snapshots, seeds, documentation, hooks, and environment-specific deployments.

---

# Warehouse Requirements

This project uses Snowflake as the data warehouse.

### Required Components

* Snowflake Account
* Snowflake Warehouse
* dbt Core 1.11+
* dbt-snowflake adapter

### Databases

#### Development

```text
STREAMCART_DEV
```

#### Production

```text
STREAMCART_PROD
```

### Schemas

```text
raw_streamcart
staging
intermediate
marts
snapshots
DEV_SCHEMA
PROD_SCHEMA
```

---

# Project Architecture

## Sources

Raw data ingested into Snowflake.

### Source Tables

* raw_streamcart.raw_orders
* raw_streamcart.raw_products

Purpose:

* Store source-system data in original form
* Support auditing and reprocessing
* Act as input for downstream dbt models

---

## Staging Layer

Standardizes and cleans source data.

### Models

* stg_orders
* stg_products

### Key Transformations

* JSON parsing
* Data type conversion
* Deduplication
* Standardized naming conventions
* Data quality validation

Materialization:

```text
view
```

---

## Intermediate Layer

Applies business logic and enrichments.

### Models

* int_orders_enriched
* int_customer_summary

### Key Transformations

* Revenue calculations
* Margin calculations
* Customer aggregations
* Product enrichment
* Business rule implementation

Materialization:

```text
ephemeral
```

---

## Mart Layer

Analytics-ready models used for reporting and dashboards.

Materialization:

```text
table
```

### fct_orders

Fact table at order-line level.

Contains:

* Order information
* Customer information
* Product information
* Revenue metrics
* Margin metrics
* Discount metrics
* Channel information

Primary Key:

```text
order_line_key
```

---

### dim_customers

Customer dimension.

Contains:

* Customer profile details
* Customer tier
* Geographic information
* Revenue summaries
* Order summaries
* Customer segmentation

Primary Key:

```text
customer_id
```

---

### dim_date

Date dimension.

Contains:

* Calendar date
* Year
* Quarter
* Month
* Week
* Day attributes
* Weekend indicators

Primary Key:

```text
date
```

---

### channel_performance_summary

Contains channel-level sales, revenue, and performance metrics.

---

### channel_revenue_pivot

Contains pivoted revenue metrics by sales channel.

---

### monthly_revenue_summary

Contains monthly revenue trends and reporting metrics.

---

### product_performance

Contains product-level sales, revenue, and profitability metrics.

---

## Snapshots

Tracks historical changes in source data.

### Snapshots

* customer_tier_snapshot
* product_price_snapshot

---

## Seeds

Reference datasets used throughout the project.

### Seed Files

* channel_mapping
* country_config

---

# dbt Project Configuration

## Materializations

| Layer        | Materialization |
| ------------ | --------------- |
| Staging      | View            |
| Intermediate | Ephemeral       |
| Marts        | Table           |

---

## Hooks

### on-run-start

Creates and populates an audit log table:

```text
dbt_run_log
```

Captured fields:

* run_id
* started_at
* target_name

---

### on-run-end

Automatically grants SELECT access on all tables in the target schema to:

```text
reporting_role
```

---

### fct_orders Post Hook

The fct_orders model includes a post-hook that:

* Executes a warehouse-specific optimization command
* Grants SELECT access to role `prod_reader` when running in the production environment

---

# Source Freshness

Source freshness monitoring is configured for raw order data.

Run:

```bash
dbt source freshness
```

to validate source data arrival against configured SLA thresholds.

---

# Local profiles.yml Configuration

Store the profile in:

```text
~/.dbt/profiles.yml
```

Example configuration:

```yaml
StreamCart:
  outputs:

    dev:
      type: snowflake
      account: <account>
      user: <user>
      password: <password>
      role: ACCOUNTADMIN
      warehouse: COMPUTE_WH
      database: STREAMCART_DEV
      schema: DEV_SCHEMA
      threads: 1

    prod:
      type: snowflake
      account: <account>
      user: <user>
      password: <password>
      role: ACCOUNTADMIN
      warehouse: COMPUTE_WH
      database: STREAMCART_PROD
      schema: PROD_SCHEMA
      threads: 1

  target: dev
```

---

# Running the Project

## Install Dependencies

```bash
dbt deps
```

---

## Validate Connection

```bash
dbt debug
```

---

## Run Models

```bash
dbt run
```

---

## Run Specific Model

```bash
dbt run --select fct_orders
```

---

## Run Tests

```bash
dbt test
```

---

## Run Seeds

```bash
dbt seed
```

---

## Run Snapshots

```bash
dbt snapshot
```

---

## Build Entire Project

Runs models, tests, seeds, and snapshots.

```bash
dbt build
```

---

## Check Source Freshness

```bash
dbt source freshness
```

---

## Generate Documentation

```bash
dbt docs generate
```

---

## Launch Documentation Site

```bash
dbt docs serve
```

---

# Environment Execution

## Development

```bash
dbt build --target dev
```

---

## Production

```bash
dbt build --target prod
```

---

# Documentation

The project includes:

* Model documentation
* Column documentation
* Source documentation
* Custom docs blocks
* Data lineage graph
* Data tests
* Freshness checks

Generate documentation:

```bash
dbt docs generate
```

Launch documentation site:

```bash
dbt docs serve
```

---

# Project Owner

**Data Engineering Team**
