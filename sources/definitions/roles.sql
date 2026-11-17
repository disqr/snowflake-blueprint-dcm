-- ===================================================================
--  CUSTOM ROLES
--  Note that role hierarchies are avoided here for simplicity and to provide maximum flexibility in role assignment.
--  In most cases, account level roles are only granted database-level roles as needed, and do not inherit from other account-level roles.
-- ===================================================================

-- ===================================================================
--  SHARED ACCOUNT-LEVEL ROLES (grants only)
--  Role creation is handled in pre_deploy.sql using CREATE ROLE IF NOT EXISTS.
--  Only environment-specific grants to these roles are defined here.
-- ===================================================================

{# --- DB_OWNER: env-specific grants --- #}
--Granting CREATE DATABASE to DB_OWNER allows it to create databases and own them, which is necessary for the role to function as intended.
-- (CREATE DATABASE grant is in pre_deploy.sql)

-- ===================================================================
--  CUSTOM ROLES
-- ===================================================================

{# --- ANALYST: env-specific grants --- #}
---- DB Roles Read
{% if env_prefix == "PRD_" %}
-- Analysts have access to prod only.
GRANT DATABASE ROLE {{env_prefix}}SILVER.DB_R TO ROLE ANALYST;
GRANT DATABASE ROLE {{env_prefix}}GOLD.DB_R TO ROLE ANALYST;
GRANT DATABASE ROLE {{env_prefix}}COMMON.DB_R TO ROLE ANALYST;
GRANT USAGE   ON WAREHOUSE {{env_prefix}}BI_WH      TO ROLE ANALYST;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}BI_WH      TO ROLE ANALYST;
{% endif %}
---- WH
GRANT USAGE   ON WAREHOUSE {{env_prefix}}ANALYST_WH TO ROLE ANALYST;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}ANALYST_WH TO ROLE ANALYST;

{# --- TESTER: env-specific grants --- #}
---- DB Roles Read
GRANT DATABASE ROLE {{env_prefix}}BRONZE.DB_R TO ROLE TESTER;
GRANT DATABASE ROLE {{env_prefix}}SILVER.DB_R TO ROLE TESTER;
GRANT DATABASE ROLE {{env_prefix}}GOLD.DB_R TO ROLE TESTER;
GRANT DATABASE ROLE {{env_prefix}}COMMON.DB_R TO ROLE TESTER;
GRANT DATABASE ROLE {{env_prefix}}ADMIN.DB_R  TO ROLE TESTER;
---- WH
GRANT USAGE   ON WAREHOUSE {{env_prefix}}BI_WH      TO ROLE TESTER;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}BI_WH      TO ROLE TESTER;

{# --- DEVELOPER env-specific grants --- #}
---- DB Roles
{% if env_prefix == "DEV_" %}
    ---- DB Roles Crud
    GRANT DATABASE ROLE {{env_prefix}}BRONZE.DB_CRUD TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}SILVER.DB_CRUD TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}GOLD.DB_CRUD   TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}COMMON.DB_CRUD TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}ADMIN.DB_CRUD  TO ROLE DEVELOPER;
{% elif env_prefix == "PRD_" or env_prefix == "TST_" %}
    ---- DB Roles Read
    GRANT DATABASE ROLE {{env_prefix}}BRONZE.DB_R TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}SILVER.DB_R TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}GOLD.DB_R   TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}COMMON.DB_R TO ROLE DEVELOPER;
    GRANT DATABASE ROLE {{env_prefix}}ADMIN.DB_R  TO ROLE DEVELOPER;
{% endif %}
---- WH
GRANT USAGE   ON WAREHOUSE {{env_prefix}}DEVELOPER_WH TO ROLE DEVELOPER;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}DEVELOPER_WH TO ROLE DEVELOPER;

{# --- DEVOPS: env-specific grants --- #}

---- DB Roles Crud
GRANT DATABASE ROLE {{env_prefix}}BRONZE.DB_CRUD TO ROLE DEVOPS;
GRANT DATABASE ROLE {{env_prefix}}SILVER.DB_CRUD TO ROLE DEVOPS;
GRANT DATABASE ROLE {{env_prefix}}GOLD.DB_CRUD   TO ROLE DEVOPS;
GRANT DATABASE ROLE {{env_prefix}}COMMON.DB_CRUD TO ROLE DEVOPS;
GRANT DATABASE ROLE {{env_prefix}}ADMIN.DB_CRUD  TO ROLE DEVOPS;
---- WH
GRANT USAGE   ON WAREHOUSE {{env_prefix}}OPS_WH        TO ROLE DEVOPS;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}OPS_WH        TO ROLE DEVOPS;
GRANT USAGE   ON WAREHOUSE {{env_prefix}}DEPLOYMENT_WH TO ROLE DEVOPS;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}DEPLOYMENT_WH TO ROLE DEVOPS;

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
GRANT USAGE   ON WAREHOUSE {{env_prefix}}ETL_WH TO ROLE {{env_prefix}}ETL;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}ETL_WH TO ROLE {{env_prefix}}ETL;

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
GRANT USAGE   ON WAREHOUSE {{env_prefix}}LOAD_WH TO ROLE {{env_prefix}}LOADER;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}LOAD_WH TO ROLE {{env_prefix}}LOADER;

{# --- CONSUMER --- #}
DEFINE ROLE {{env_prefix}}CONSUMER
    COMMENT = 'Downstream consumer service - read on Silver and Gold';

GRANT OWNERSHIP ON ROLE {{env_prefix}}CONSUMER TO ROLE USERADMIN;

---- DB Roles
GRANT DATABASE ROLE {{env_prefix}}SILVER.DB_R TO ROLE {{env_prefix}}CONSUMER;
GRANT DATABASE ROLE {{env_prefix}}GOLD.DB_R   TO ROLE {{env_prefix}}CONSUMER;
---- WH
GRANT USAGE   ON WAREHOUSE {{env_prefix}}BI_WH TO ROLE {{env_prefix}}CONSUMER;
GRANT MONITOR ON WAREHOUSE {{env_prefix}}BI_WH TO ROLE {{env_prefix}}CONSUMER;
