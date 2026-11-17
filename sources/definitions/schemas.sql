--Naming convention should be:
--<naming_format_schema_data_layer> ::= { LND }_{ source_system_name }_{ connector_name } [ _ ] [ physical_source_connection_information | logical_source_connection_information ]
{{ create_schema(env_prefix ~ 'BRONZE', 'LND_SOURCE_CONNECTOR', 'Landing zone/stage - data exactly as extracted from the source, untouched, often still source-shaped.   This is a template schema only with SOURCE being replaced by the actual source name and CONNECTOR replace by the actual connector name e.g. Fivetran, Talend, ect.') }}

--<naming_format_schema_data_layer> ::= { RAW }_{ source_system_name } [ _ ] [ physical_source_connection_information | logical_source_connection_information ]
{{ create_schema(env_prefix ~ 'BRONZE', 'RAW_SOURCE', 'Data thats been minimally standardized (typing, basic structure).  This is a template schema only with SOURCE being replaced by the actual source name.') }}

{{ create_schema(env_prefix ~ 'BRONZE', 'STAGING', '') }}

-- Internal stage for flat-file loads
DEFINE STAGE {{env_prefix}}BRONZE.STAGING.FILES
    COMMENT = 'Landing area for flat files';

-- Internal sub-layer for archive
--<naming_format_schema_data_layer> ::= { ARC}_{ source_system_name }_{ connector_name } [ _ ] [ physical_source_connection_information | logical_source_connection_information ]
{{ create_schema(env_prefix ~ 'BRONZE', 'ARC_SOURCE_CONNECTOR', 'Archive/history zone - immutable, append-only copies retained for lineage/audit/reprocessing purposes.  This is a template schema only with SOURCE being replaced by the actual source name.') }}

-- ---------------------------------------------------------
--dbt oriented silver layer

{{ create_schema(env_prefix ~ 'SILVER', 'STG_SOURCE', 'Staging models form the entry point into the silver layer from bronze.  This is a template schema only with SOURCE being replaced by the actual source name.') }}
{{ create_schema(env_prefix ~ 'SILVER', 'INT_SOURCE', 'Intermediate models consume one or more staging models and apply the business logic required to conform data across sources: joins, deduplication, key standardization, and derived business rules.  This is a template schema only with SOURCE being replaced by the actual source name.') }}
{{ create_schema(env_prefix ~ 'SILVER', 'SNP_SOURCE', 'Snapshots are a first-class dbt feature used to capture slowly changing dimensions (SCD Type 2) from mutable upstream sources.') }}

-- ---------------------------------------------------------

{{ create_schema(env_prefix ~ 'GOLD', 'FACT', 'Fact tables are stored here for easy reference.') }}
{{ create_schema(env_prefix ~ 'GOLD', 'DIM', 'Dimension tables are stored here for easy reference.') }}
{{ create_schema(env_prefix ~ 'GOLD', 'AGG', 'Pre-aggregated tables are stored here and used for specific reporting/BI use cases.') }}

-- ---------------------------------------------------------

{{ create_schema(env_prefix ~ 'COMMON', 'REFERENCE', 'Common reference data.') }}
{{ create_schema(env_prefix ~ 'COMMON', 'UDFS', 'Common area for functions and procedures.') }}

-- ---------------------------------------------------------

{{ create_schema(env_prefix ~ 'ADMIN', 'COST', '') }}
{{ create_schema(env_prefix ~ 'ADMIN', 'MONITORING', '') }}
{{ create_schema(env_prefix ~ 'ADMIN', 'ENVIRONMENT_SUPPORT', '') }}
{{ create_schema(env_prefix ~ 'ADMIN', 'GENERAL_SUPPORT', '') }}
{{ create_schema(env_prefix ~ 'ADMIN', 'LOAD_SUPPORT', '') }}
{{ create_schema(env_prefix ~ 'ADMIN', 'SECURITY_SUPPORT', '') }}
