{# ----------------------------------------------------------------
   create_db_roles_macro.sql
   Creates the DB_CRUD and DB_R database roles for a given
   database, owned by DB_OWNER and granted to DB_OWNER
   ---------------------------------------------------------------- #}

{% macro create_db_roles(catalog_name) %}

    --Uses inherited grants: each grant covers all current and future objects of a type
    --in the database, so no separate ON FUTURE grants are needed. Unlike future grants,
    --database-level inherited grants are not overridden by schema-level grants.
    --Requires FEATURE_RBAC_INHERITED_GRANTS = 'ENABLED' on the account.
    --Database roles receive USAGE on their parent database automatically at creation.
    DEFINE DATABASE ROLE {{catalog_name}}.DB_CRUD COMMENT = 'Database role that grants the ability to create objects and all privileges to create, read, update, and delete data rows in tables and other objects in the database.';
    DEFINE DATABASE ROLE {{catalog_name}}.DB_R COMMENT = 'Database role with privileges to read (SELECT) data rows in tables and other objects in the database.';

    -- Ownership to DB_OWNER (DCM_DEPLOYER inherits DB_OWNER, so DCM can still manage them).
    -- Both roles are also granted to DB_OWNER, so DB_OWNER has full control of the
    -- database and its data, like db_owner in SQL Server.
    {{ grant_db_owner('DATABASE ROLE', catalog_name ~ '.DB_CRUD') }}
    {{ grant_db_role_to_owner(catalog_name, 'DB_CRUD') }}
    {{ grant_db_owner('DATABASE ROLE', catalog_name ~ '.DB_R') }}
    {{ grant_db_role_to_owner(catalog_name, 'DB_R') }}

    -- CRUD
    GRANT MONITOR ON DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_CRUD;
    GRANT INHERITED ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_CRUD;

    {% set crud_objects = ['TABLES','VIEWS','SEMANTIC VIEWS','MATERIALIZED VIEWS','DYNAMIC TABLES','EXTERNAL TABLES',
                           'FILE FORMATS','STREAMS','TASKS','SEQUENCES','EVENT TABLES',
                           'FUNCTIONS','PROCEDURES','STAGES'] %}
    {% for obj in crud_objects %}
        GRANT INHERITED ALL PRIVILEGES ON ALL {{obj}} IN DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_CRUD;
    {% endfor %}

    -- READ
    GRANT MONITOR ON DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_R;
    GRANT INHERITED USAGE ON ALL SCHEMAS IN DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_R;
    {% set object_list = [('SELECT, REFERENCES', ['TABLES','VIEWS', 'SEMANTIC VIEWS', 'MATERIALIZED VIEWS','EXTERNAL TABLES']),
    ('SELECT' , ['STREAMS','EVENT TABLES']),
    ('SELECT, MONITOR',['DYNAMIC TABLES']),
    ('USAGE',['FUNCTIONS','PROCEDURES','STAGES','FILE FORMATS']),
    ('READ',['STAGES'])]%}
    {% for privilege, objects in object_list %}
    --Privilege: {{privilege}}
        {% for obj in objects %}
            GRANT INHERITED {{privilege}} ON ALL {{obj}} IN DATABASE {{catalog_name}} TO DATABASE ROLE {{catalog_name}}.DB_R;
        {% endfor %}
    {% endfor %}
{% endmacro %}
