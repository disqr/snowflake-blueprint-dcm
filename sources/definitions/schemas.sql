--Naming convention should be:
--<naming_format_schema_data_layer> ::= { LND }_{ source_system_name }_{ connector_name } [ _ ] [ physical_source_connection_information | logical_source_connection_information ]
DEFINE SCHEMA {{env_prefix}}BRONZE.LND_SOURCE_CONNECTOR
    COMMENT = 'Landing zone/stage - data exactly as extracted from the source, untouched, often still source-shaped.';

--<naming_format_schema_data_layer> ::= { RAW }_{ source_system_name } [ _ ] [ physical_source_connection_information | logical_source_connection_information ]
DEFINE SCHEMA {{env_prefix}}BRONZE.RAW_SOURCE
    COMMENT = 'Data thats been minimally standardized (typing, basic structure).';

DEFINE SCHEMA {{env_prefix}}BRONZE.STAGING;

-- Internal stage for flat-file loads
DEFINE STAGE {{env_prefix}}BRONZE.STAGING.FILES
    COMMENT = 'Landing area for flat files';

-- Internal sub-layer for archive
--<naming_format_schema_data_layer> ::= { ARC}_{ source_system_name }_{ connector_name } [ _ ] [ physical_source_connection_information | logical_source_connection_information ]
DEFINE SCHEMA {{env_prefix}}BRONZE.ARC_SOURCE_CONNECTOR
    COMMENT = 'Archive/history zone - immutable, append-only copies retained for lineage/audit/reprocessing purposes.';

-- ---------------------------------------------------------
--dbt oriented silver layer

DEFINE SCHEMA {{env_prefix}}SILVER.STG_SOURCE
    COMMENT = 'Staging models form the entry point into the silver layer from bronze.  This is a template schema only with SOURCE being replaced by the actual source name.';
DEFINE SCHEMA {{env_prefix}}SILVER.INT_SOURCE
    COMMENT = 'Intermediate models consume one or more staging models and apply the business logic required to conform data across sources: joins, deduplication, key standardization, and derived business rules.
    This is a template schema only with SOURCE being replaced by the actual source name.';
DEFINE SCHEMA {{env_prefix}}SILVER.SNP_SOURCE
    COMMENT = 'Snapshots are a first-class dbt feature used to capture slowly changing dimensions (SCD Type 2) from mutable upstream sources.';

-- ---------------------------------------------------------

DEFINE SCHEMA {{env_prefix}}GOLD.FACT
    COMMENT = 'Fact tables are stored here for easy reference.';
DEFINE SCHEMA {{env_prefix}}GOLD.DIM
    COMMENT = 'Dimension tables are stored here for easy reference.';
DEFINE SCHEMA {{env_prefix}}GOLD.AGG
    COMMENT = 'Pre-aggregated tables are stored here and used for specific reporting/BI use cases.';


-- ---------------------------------------------------------

DEFINE SCHEMA {{env_prefix}}COMMON.REFERENCE;
DEFINE SCHEMA {{env_prefix}}COMMON.UDFS;

-- ---------------------------------------------------------

DEFINE SCHEMA {{env_prefix}}ADMIN.COST;
DEFINE SCHEMA {{env_prefix}}ADMIN.MONITORING;
DEFINE SCHEMA {{env_prefix}}ADMIN.ENVIRONMENT_SUPPORT;
DEFINE SCHEMA {{env_prefix}}ADMIN.GENERAL_SUPPORT;
DEFINE SCHEMA {{env_prefix}}ADMIN.LOAD_SUPPORT;
DEFINE SCHEMA {{env_prefix}}ADMIN.SECURITY_SUPPORT;

-- ---------------------------------------------------------
-- GRANT OWNERSHIP on all schemas to DB_OWNER role
-- ---------------------------------------------------------

-- BRONZE schemas
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}BRONZE.LND_SOURCE_CONNECTOR TO ROLE DB_OWNER;
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}BRONZE.RAW_SOURCE TO ROLE DB_OWNER;
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}BRONZE.STAGING TO ROLE DB_OWNER;
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}BRONZE.ARC_SOURCE_CONNECTOR TO ROLE DB_OWNER;

-- SILVER schemas
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}SILVER.STG_SOURCE TO ROLE DB_OWNER;
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}SILVER.INT_SOURCE TO ROLE DB_OWNER;
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}SILVER.SNP_SOURCE TO ROLE DB_OWNER;

-- GOLD schemas
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}GOLD.FACT TO ROLE DB_OWNER;
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}GOLD.DIM TO ROLE DB_OWNER;
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}GOLD.AGG TO ROLE DB_OWNER;

-- COMMON schemas
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}COMMON.REFERENCE TO ROLE DB_OWNER;
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}COMMON.UDFS TO ROLE DB_OWNER;

-- ADMIN schemas
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}ADMIN.COST TO ROLE DB_OWNER;
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}ADMIN.MONITORING TO ROLE DB_OWNER;
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}ADMIN.ENVIRONMENT_SUPPORT TO ROLE DB_OWNER;
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}ADMIN.GENERAL_SUPPORT TO ROLE DB_OWNER;
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}ADMIN.LOAD_SUPPORT TO ROLE DB_OWNER;
GRANT OWNERSHIP ON SCHEMA {{env_prefix}}ADMIN.SECURITY_SUPPORT TO ROLE DB_OWNER;

