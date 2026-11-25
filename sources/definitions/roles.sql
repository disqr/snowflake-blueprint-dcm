-- ===================================================================
--  ROLES AND GRANTS
--  Role hierarchies are avoided here for simplicity and to provide maximum flexibility in role assignment.
--  In most cases, account level roles are only granted database-level roles as needed, and do not inherit from other account-level roles.
--  DB_OWNER needs no grants here: it owns each database and holds its DB_CRUD and DB_R roles (see create_db_roles).
--  To let DB_OWNER create databases itself, grant it CREATE DATABASE ON ACCOUNT (see README.md).
-- ===================================================================

-- ===================================================================
--  SHARED ACCOUNT-LEVEL ROLES (grants only)
--  Role creation is handled in manual/2.pre_deploy.sql using CREATE ROLE IF NOT EXISTS.
--  Only environment-specific grants to these roles are defined here.
-- ===================================================================

{# --- ANALYST: env-specific grants --- #}
---- DB Roles Read
{% if env_prefix == "PRD_" %}
-- Analysts have access to prod only.
GRANT DATABASE ROLE {{env_prefix}}SILVER.DB_R TO ROLE ANALYST;
GRANT DATABASE ROLE {{env_prefix}}GOLD.DB_R TO ROLE ANALYST;
GRANT DATABASE ROLE {{env_prefix}}COMMON.DB_R TO ROLE ANALYST;
GRANT USAGE   ON WAREHOUSE {{env_prefix}}{{bi_wh}}      TO ROLE ANALYST;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}{{bi_wh}}      TO ROLE ANALYST;
{% endif %}
---- WH
GRANT USAGE   ON WAREHOUSE {{env_prefix}}{{analyst_wh}} TO ROLE ANALYST;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}{{analyst_wh}} TO ROLE ANALYST;

{# --- TESTER: env-specific grants --- #}
---- DB Roles Read
GRANT DATABASE ROLE {{env_prefix}}BRONZE.DB_R TO ROLE TESTER;
GRANT DATABASE ROLE {{env_prefix}}SILVER.DB_R TO ROLE TESTER;
GRANT DATABASE ROLE {{env_prefix}}GOLD.DB_R TO ROLE TESTER;
GRANT DATABASE ROLE {{env_prefix}}COMMON.DB_R TO ROLE TESTER;
GRANT DATABASE ROLE {{env_prefix}}ADMIN.DB_R  TO ROLE TESTER;
---- WH
GRANT USAGE   ON WAREHOUSE {{env_prefix}}{{bi_wh}}      TO ROLE TESTER;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}{{bi_wh}}      TO ROLE TESTER;

{# --- DEVELOPER env-specific grants --- #}
---- DB Roles
{% if env_prefix == "PRD_" or env_prefix == "TST_" %}
    ---- DB Roles Read (TST and PRD)
    GRANT DATABASE ROLE {{env_prefix}}BRONZE.DB_R TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}SILVER.DB_R TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}GOLD.DB_R   TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}COMMON.DB_R TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}ADMIN.DB_R  TO ROLE DEVELOPER;
{% else %}
    ---- DB Roles Crud (DEV and sandboxes, whose env_prefix is <NAME>_)
    GRANT DATABASE ROLE {{env_prefix}}BRONZE.DB_CRUD TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}SILVER.DB_CRUD TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}GOLD.DB_CRUD   TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}COMMON.DB_CRUD TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}ADMIN.DB_CRUD  TO ROLE DEVELOPER;
{% endif %}
---- WH
GRANT USAGE   ON WAREHOUSE {{env_prefix}}{{developer_wh}} TO ROLE DEVELOPER;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}{{developer_wh}} TO ROLE DEVELOPER;

{# --- DEVOPS: env-specific grants --- #}

---- DB Roles Crud
GRANT DATABASE ROLE {{env_prefix}}BRONZE.DB_CRUD TO ROLE DEVOPS;
GRANT DATABASE ROLE {{env_prefix}}SILVER.DB_CRUD TO ROLE DEVOPS;
GRANT DATABASE ROLE {{env_prefix}}GOLD.DB_CRUD   TO ROLE DEVOPS;
GRANT DATABASE ROLE {{env_prefix}}COMMON.DB_CRUD TO ROLE DEVOPS;
GRANT DATABASE ROLE {{env_prefix}}ADMIN.DB_CRUD  TO ROLE DEVOPS;
---- WH
GRANT USAGE   ON WAREHOUSE {{env_prefix}}{{ops_wh}}        TO ROLE DEVOPS;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}{{ops_wh}}        TO ROLE DEVOPS;
GRANT USAGE   ON WAREHOUSE {{env_prefix}}{{deployment_wh}} TO ROLE DEVOPS;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}{{deployment_wh}} TO ROLE DEVOPS;

-- ===================================================================
--  SERVICE ACCOUNT ROLES
--  Account roles for service accounts and automation only.
--  Service roles receive direct grants and do not inherit to or from peer roles.
-- ===================================================================

--Work separation here.  ETL reads from bronze, but does not write anything in it.
{# --- ETL --- #}
DEFINE ROLE {{env_prefix}}ETL
    COMMENT = 'ETL service - Read on Bronze, CRUD on Silver and Gold';

GRANT OWNERSHIP ON ROLE {{env_prefix}}ETL TO ROLE USERADMIN;

---- DB Roles
GRANT DATABASE ROLE {{env_prefix}}BRONZE.DB_R TO ROLE {{env_prefix}}ETL;
GRANT DATABASE ROLE {{env_prefix}}SILVER.DB_CRUD TO ROLE {{env_prefix}}ETL;
GRANT DATABASE ROLE {{env_prefix}}GOLD.DB_CRUD TO ROLE {{env_prefix}}ETL;
GRANT DATABASE ROLE {{env_prefix}}COMMON.DB_CRUD TO ROLE {{env_prefix}}ETL;
---- DB Roles Read
GRANT DATABASE ROLE {{env_prefix}}ADMIN.DB_R TO ROLE {{env_prefix}}ETL;
---- WH
GRANT USAGE   ON WAREHOUSE {{env_prefix}}{{etl_wh}} TO ROLE {{env_prefix}}ETL;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}{{etl_wh}} TO ROLE {{env_prefix}}ETL;

--service account roles for data ingestion and any initial processing in LND and RAW.
{# --- LOADER --- #}
DEFINE ROLE {{env_prefix}}LOADER
    COMMENT = 'Data ingestion service - CRUD on Bronze only';

GRANT OWNERSHIP ON ROLE {{env_prefix}}LOADER TO ROLE USERADMIN;

---- DB Roles
GRANT DATABASE ROLE {{env_prefix}}BRONZE.DB_CRUD TO ROLE {{env_prefix}}LOADER;
---- DB Roles Read
GRANT DATABASE ROLE {{env_prefix}}ADMIN.DB_R TO ROLE {{env_prefix}}LOADER;
---- WH
GRANT USAGE   ON WAREHOUSE {{env_prefix}}{{load_wh}} TO ROLE {{env_prefix}}LOADER;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}{{load_wh}} TO ROLE {{env_prefix}}LOADER;

{# --- CONSUMER --- #}
DEFINE ROLE {{env_prefix}}CONSUMER
    COMMENT = 'Downstream consumer service - read on Silver and Gold';

GRANT OWNERSHIP ON ROLE {{env_prefix}}CONSUMER TO ROLE USERADMIN;

---- DB Roles
GRANT DATABASE ROLE {{env_prefix}}SILVER.DB_R TO ROLE {{env_prefix}}CONSUMER;
GRANT DATABASE ROLE {{env_prefix}}GOLD.DB_R   TO ROLE {{env_prefix}}CONSUMER;
---- WH
GRANT USAGE   ON WAREHOUSE {{env_prefix}}{{bi_wh}} TO ROLE {{env_prefix}}CONSUMER;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}{{bi_wh}} TO ROLE {{env_prefix}}CONSUMER;
