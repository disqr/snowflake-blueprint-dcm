{# ----------------------------------------------------------------
   db_roles_macro_v2.sql
   Creates DB_CRUD / DB_R database roles for a given
   database
   ---------------------------------------------------------------- #}

{% macro create_db_roles(catalog_name) %}

    --Uses inherited grants: each grant covers all current and future objects of a type
    --in the database, so no separate ON FUTURE grants are needed. Unlike future grants,
    --database-level inherited grants are not overridden by schema-level grants.
    --Requires FEATURE_RBAC_INHERITED_GRANTS = 'ENABLED' on the account.
    --Database roles receive USAGE on their parent database automatically at creation.
    DEFINE DATABASE ROLE {{catalog_name}}.DB_CRUD COMMENT = 'Database role with that grants the ability to create objects and all privileges to create, read, update, and delete data rows in tables and other objects in the database.';
    DEFINE DATABASE ROLE {{catalog_name}}.DB_R COMMENT = 'Database role with privileges to read (SELECT) data rows in tables and other objects in the database.';

    -- Ownership to DB_OWNER (DCM_DEPLOYER inherits DB_OWNER, so DCM can still manage them)
    {{ grant_db_owner('DATABASE ROLE', catalog_name ~ '.DB_CRUD') }}
    {{ grant_db_owner('DATABASE ROLE', catalog_name ~ '.DB_R') }}

    -- CRUD
    GRANT MONITOR ON DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_CRUD;
    GRANT INHERITED ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_CRUD;

    {% set crud_objects = ['TABLES','VIEWS','MATERIALIZED VIEWS','DYNAMIC TABLES','EXTERNAL TABLES',
                           'FILE FORMATS','STREAMS','TASKS','SEQUENCES','EVENT TABLES',
                           'FUNCTIONS','PROCEDURES','STAGES'] %}
    {% for obj in crud_objects %}
        GRANT INHERITED ALL PRIVILEGES ON ALL {{obj}} IN DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_CRUD;
    {% endfor %}

    -- READ
    GRANT MONITOR ON DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_R;
    GRANT INHERITED USAGE ON ALL SCHEMAS IN DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_R;

    {% set read_select_ref = ['TABLES','VIEWS','MATERIALIZED VIEWS','EXTERNAL TABLES'] %}
    {% set read_select_only = ['DYNAMIC TABLES','STREAMS','EVENT TABLES'] %}
    {% set read_usage  = ['FUNCTIONS','PROCEDURES','FILE FORMATS'] %}
    {% for obj in read_select_ref %}
        GRANT INHERITED SELECT, REFERENCES ON ALL {{obj}} IN DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_R;
    {% endfor %}
    {% for obj in read_select_only %}
        GRANT INHERITED SELECT ON ALL {{obj}} IN DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_R;
    {% endfor %}
    {% for obj in read_usage %}
        GRANT INHERITED USAGE ON ALL {{obj}} IN DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_R;
    {% endfor %}
    GRANT INHERITED READ ON ALL STAGES IN DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_R;
{% endmacro %}
