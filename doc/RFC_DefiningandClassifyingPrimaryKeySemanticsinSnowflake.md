# RFC: Defining and Classifying Primary Key Semantics in Snowflake (Enforced vs Informational Keys)

- [Abstract](#RFC:DefiningandClassifyingPrimaryKeySem)

- [Status Of This Memo](#RFC:DefiningandClassifyingPrimaryKeySem)

- [Introduction](#RFC:DefiningandClassifyingPrimaryKeySem)

- [Key Design Principle](#RFC:DefiningandClassifyingPrimaryKeySem)

  - [Objectives](#RFC:DefiningandClassifyingPrimaryKeySem)

  - [Terminology and
    Definitions](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [SQL Notation](#RFC:DefiningandClassifyingPrimaryKeySem)

- [✅ Recommended Pattern: "Declared Key + Enforcement
  Flag"](#RFC:DefiningandClassifyingPrimaryKeySem)

  - [1. Use Snowflake Constraints --- but mark them as
    informational](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Why?](#RFC:DefiningandClassifyingPrimaryKeySem)

  - [2. Add Explicit Metadata Flag
    (Critical)](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Table Tag (Best practice in
      Snowflake)](#RFC:DefiningandClassifyingPrimaryKeySem)

- [Standardized Values](#RFC:DefiningandClassifyingPrimaryKeySem)

  - [✅ 1. ENFORCED](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Definition](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Characteristics](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Typical Layers](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Example Interpretation](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Data Quality
      Expectation](#RFC:DefiningandClassifyingPrimaryKeySem)

  - [✅ 2.
    NON_ENFORCED_EXPECT_UNIQUES](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Definition](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Characteristics](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Typical Layers](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Example Interpretation](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Data Quality
      Expectation](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Operational Behavior](#RFC:DefiningandClassifyingPrimaryKeySem)

  - [✅ 3. NON_ENFORCED_DUPLICATES_ALLOWED ✅ (Used for landing
    tables)](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Definition](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Characteristics](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Typical Layers](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Example Interpretation](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Data Quality
      Expectation](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Operational Behavior](#RFC:DefiningandClassifyingPrimaryKeySem)

  - [✅ Comparison Summary](#RFC:DefiningandClassifyingPrimaryKeySem)

- [✅ Key Concept: "Intent vs Reality
  Gradient"](#RFC:DefiningandClassifyingPrimaryKeySem)

- [✅ Recommended Operational
  Use](#RFC:DefiningandClassifyingPrimaryKeySem)

  - [Example: Automated Data Quality
    Rules](#RFC:DefiningandClassifyingPrimaryKeySem)

  - [Example: dbt Test Logic](#RFC:DefiningandClassifyingPrimaryKeySem)

- [✅ Final Guidance](#RFC:DefiningandClassifyingPrimaryKeySem)

- [Example Snowflake
  Implementation](#RFC:DefiningandClassifyingPrimaryKeySem)

  - [Apply Tag to Tables](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Landing Example](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Staging Example](#RFC:DefiningandClassifyingPrimaryKeySem)

    - [Curated Example](#RFC:DefiningandClassifyingPrimaryKeySem)

  - [Require Declared Primary
    Keys](#RFC:DefiningandClassifyingPrimaryKeySem)

# Abstract

This RFC establishes a standardized approach for defining and
classifying primary key semantics in Snowflake, where constraints are
not physically enforced. It introduces a framework to distinguish
between a table's *intended grain* (declared primary key) and its
*actual data characteristics*, particularly in environments where
duplicates may exist, such as landing and staging layers. The proposal
defines three key enforcement classifications---**ENFORCED**,
**NON_ENFORCED_EXPECT_UNIQUES**, and
**NON_ENFORCED_DUPLICATES_ALLOWED**---and recommends implementing them
via Snowflake tags and metadata. This standard enables consistent data
modeling, improves data quality transparency, and supports automated
validation and governance across the data platform.

# Status Of This Memo

This is a draft standard and meant to convey concepts and ideas for
general review and discussion.

# Introduction

Snowflake allows the definition of primary key constraints, but does not
enforce them at the database level. As a result, there is an inherent
gap between how tables are *modeled* (declared keys and intended grain)
and how data *actually behaves* within those tables. This gap becomes
especially pronounced across different layers of the data
platform---particularly in landing and staging environments where
duplicates and data anomalies are expected due to upstream system
behavior or ingestion processes.

Today, there is no standardized way to indicate whether a declared
primary key represents a strictly enforced uniqueness guarantee, a
best-effort expectation, or merely a logical identifier in datasets
where duplicates are acceptable. This lack of clarity leads to several
challenges:

- **Ambiguity for data consumers**, who cannot reliably determine
  whether a table's primary key can be safely used for joins,
  aggregations, or deduplication.

- **Inconsistent data modeling practices**, where teams define keys
  without aligning on their meaning or level of trust.

- **Limited automation of data quality checks**, as validation rules
  cannot adapt to differing expectations around uniqueness.

- **Increased risk of data integrity issues**, particularly when
  downstream processes assume uniqueness that is not guaranteed.

Without a clear and standardized framework to define and communicate
primary key semantics, teams must rely on tribal knowledge, ad hoc
documentation, or implicit assumptions. This creates fragility in data
pipelines and undermines confidence in the data platform.

This RFC addresses the need for a consistent approach to explicitly
distinguish between a table's intended grain and its actual data quality
guarantees, enabling improved governance, transparency, and automation
across Snowflake-based architectures.

# Key Design Principle

We are modeling **two different truths**:


 |**Concept**|**Meaning**|
 |--------------------------|--------------------------|
 |**Declared Primary Key**|What the grain *should be*|
 |**Physical Reality**|What the data  *actually is*|

👉 In landing zones, **these are intentionally different**

## Objectives

In Snowflake, this is a very common pattern: **we want to document the
*intended grain* (business key) without asserting physical
enforcement**, especially in **landing/raw tables where duplicates are
expected**.

A clean solution is to **separate "semantic primary key" from
"enforced/guaranteed primary key"** in our metadata model. Below are
several practical approaches we can combine.

## Terminology and Definitions

### SQL Notation

Standard SQL notation is used to describe commands and outline naming
standards.

#### Syntax Conventions

SQL Syntax conventions are used in these document for better
understanding of any naming and code examples. Note naming guidance and
code examples will be clearly delineated in the text.

| Convention             | Used for                                                                  |
| -----------------------| ------------------------------------------------------------------------- |
|  UPPERCASE             |      SQL keywords.
|  *italic*              |      User-supplied parameters of SQL syntax. |
|  **bold**              |      Type database names, table names, column names, index names, stored procedures, utilities, data type names, and text exactly as shown. |
|  <u>underline</u>      |      Indicates the default value applied when the clause that contains the underlined value is omitted from the statement.| 
|  \| (vertical bar)     |      Separates syntax items enclosed in brackets or braces. You can use only one of the items.
|  \[ \] (brackets)      |      Optional syntax items. Don\'t type the brackets. |
|  { } (braces)          |      Required syntax items. Don\'t type the braces. |
|  \[,\...n\]            |      Indicates the preceding item can be repeated n number of times. The occurrences are separated by commas. |
|  \[\...n\]             |      Indicates the preceding item can be repeated n number of times. The occurrences are separated by blanks.
|  ;                     |      SQL statement terminator.
|  \<label\> ::=         |      The name for a block of syntax. Use this convention to group and label sections of lengthy syntax or a unit of syntax that you can use in more than one location within a statement. Each location in which the block of syntax could be used is indicated with the label enclosed in chevrons:\<label\>.

Sources: Microsoft, Snowflake, Ansi SQL

# ✅ Recommended Pattern: "Declared Key + Enforcement Flag"

## 1. Use Snowflake Constraints --- but mark them as informational

Define the primary key constraint (for lineage, documentation, and
tooling), but explicitly treat it as:

```{sql}
CREATE TABLE landing_orders (
order_id STRING,
order_date TIMESTAMP,
customer_id STRING,
ingestion_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
CONSTRAINT pk_orders PRIMARY KEY (order_id) NOT ENFORCED
);
```

### Why?

- Snowflake already treats constraints as **NOT ENFORCED by default**
- This gives us:
  - Column-level metadata
  - Visibility in INFORMATION_SCHEMA.TABLE_CONSTRAINTS
  - Compatibility with modeling tools (dbt, ERDs, etc.)

✅ BUT: This alone does **not** indicate duplicates are expected.

## 2. Add Explicit Metadata Flag (Critical)

We need a **machine-readable indicator** that the key is *not trusted*.

### Table Tag (Best practice in Snowflake)

```{sql}
use role tag_admin;

CREATE TAG GOVERNANCE.TAG_LIBRARY.data_quality_pk_status
ALLOWED_VALUES 'ENFORCED', 'NON_ENFORCED_EXPECT_UNIQUES',
'NON_ENFORCED_DUPLICATES_ALLOWED'
COMMENT = 'Primary key enforcement classification: ENFORCED,
NON_ENFORCED_EXPECT_UNIQUES, NON_ENFORCED_DUPLICATES_ALLOWED';

ALTER TABLE landing_orders
SET TAG data_quality_pk_status = 'NON_ENFORCED_DUPLICATES_ALLOWED';
```

We can use the following standardize values (further defined in the
Standardized Values section below):

- ENFORCED
- NON_ENFORCED_EXPECT_UNIQUES
- NON_ENFORCED_DUPLICATES_ALLOWED ✅ (for landing tables)

👉 This is the **cleanest Snowflake-native approach**

# Standardized Values

The values used to denote different levels of primary key status
quality.

## ✅ 1. ENFORCED

### Definition

The primary key is **guaranteed to be unique and non-null in practice**,
even if Snowflake does not physically enforce it.

### Characteristics

- No duplicate records exist for the key
- No NULLs in key columns
- Upstream or pipeline logic ensures integrity
- Safe to use for:
  - joins
  - deduplication assumptions
  - dimensional modeling
- Equivalent to a **trusted relational PK**

### Typical Layers

- Curated / Presentation layer
- Data marts
- Dimensions and facts after transformation

### Example Interpretation

"order_id uniquely identifies each row. No duplicates exist."

### Data Quality Expectation

- ✅ Uniqueness test must pass (100%)
- ✅ Null check must pass (100%)

### ENFORCED is the Default
If data_quality_pk_status is not specified for a table, consumers and automation should assume the default value is ENFORCED. In other words, an untagged table’s declared primary key is treated as sufficient to guarantee that the primary key is both unique and non-null.

## ✅ 2. NON_ENFORCED_EXPECT_UNIQUES

### Definition

The primary key is **intended to be unique**, and duplicates are **not
expected under normal conditions**, but enforcement is not guaranteed.

### Characteristics

- Represents a **"soft contract"**
- Duplicates indicate:
  - upstream data issue
  - pipeline defect
  - late arriving data anomaly
- Consumers **can usually trust it**, but should be cautious in critical
  logic

### Typical Layers

- Staging / refined staging
- Early transformation layers
- CDC-normalized tables

### Example Interpretation

"order_id should be unique, but occasional duplicates may occur due to processing anomalies."


### Data Quality Expectation

- ✅ Uniqueness test should pass \~99--100%
- ⚠️ Failures should trigger alerts / investigation
- ✅ Nulls generally not allowed

### Operational Behavior

- You monitor and **fix issues when duplicates appear**
- Not designed to permanently hold duplicates

## ✅ 3. NON_ENFORCED_DUPLICATES_ALLOWED ✅ (Used for landing tables)

### Definition

The primary key defines the **intended grain**, but **duplicates are
expected and acceptable** in this table.

### Characteristics

- Raw ingestion reality is preserved
- Duplicates arise from:
  - source retries
  - CDC overlaps
  - batching inconsistencies
  - upstream system defects
- Table is **not safe for direct analytical use without deduplication**

### Typical Layers

- Landing / Bronze (raw ingestion)
- Audit/history capture tables
- Event ingestion pipelines

### Example Interpretation

Plain Text

\"order_id defines the logical grain, but multiple records per order_id
are expected.\"

Show more lines

### Data Quality Expectation

- ❌ Uniqueness test is NOT applicable
- ✅ Null rules depend on source
- ✅ Duplicate volume is not considered a failure

### Operational Behavior

- Downstream models must:
  - deduplicate
  - apply survivorship rules (e.g., latest record)
- Table acts as **source-of-truth log, not a clean dataset**

## ✅ Comparison Summary

  |**Tag Value**|**Uniqueness Expected**|**Duplicates Allowed**|**Trust Level**|**Typical Layer**|
  |-------------|-----------------------|----------------------|---------------|-----------------|
  |**ENFORCED**|Yes (100%)|No|✅ High|Curated/Marts|
  |**NON_ENFORCED_EXPECT_UNIQUES**|Yes (soft expectation)|Rare / anomaly|⚠️ Medium|Staging|
  |**NON_ENFORCED_DUPLICATES_ALLOWED**|No|Yes (normal)|❌ Low|Landing|

# ✅ Key Concept: "Intent vs Reality Gradient"

These three values form a **maturity spectrum**

```
RAW (duplicates expected)
↓
STAGING (duplicates are errors)
↓
CURATED (duplicates eliminated)
```

# ✅ Recommended Operational Use

We can directly tie behavior to the tag:

### Example: Automated Data Quality Rules

  |**Tag**   |**Rule Behavior**|
  |----------|-------------------------|
  |ENFORCED  |Fail pipeline if duplicates exist|
  |NON_ENFORCED_EXPECT_UNIQUES|Warn or alert if duplicates exist|
  |NON_ENFORCED_DUPLICATES_ALLOWED|Skip uniqueness check|

### Example: dbt Test Logic

models:
\- name: orders

tests:
\- unique:

severity: \"{{ \'error\' if tag == \'ENFORCED\' else \'warn\' }}\"

# ✅ Final Guidance

The real power of this approach is consistency:

**Always define the key (structure) and always define its trust level
(behavior)**

This lets:

- Data engineers know how to process the data
- Analysts know how much to trust it
- Automation know how to validate it

# **Example Snowflake Implementation**

## Apply Tag to Tables

### Landing Example

```{sql}
ALTER TABLE landing.orders
SET TAG data_quality_pk_status = 'NON_ENFORCED_DUPLICATES_ALLOWED';
```

### Staging Example

```{sql}
ALTER TABLE staging.orders
SET TAG data_quality_pk_status = 'NON_ENFORCED_EXPECT_UNIQUES';
```

### Curated Example

```
ALTER TABLE mart.orders
SET TAG data_quality_pk_status = 'ENFORCED';
```

## Require Declared Primary Keys

Even if not enforced:

```
CONSTRAINT pk_orders PRIMARY KEY (order_id) NOT ENFORCED
```

👉 This ensures:

- Grain is always explicit
- Metadata is queryable
