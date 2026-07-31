{# ----------------------------------------------------------------
   db_roles_macro_v2.sql
   Creates DB_CRUD / DB_R database roles for a given
   database
   ---------------------------------------------------------------- #}

{% macro create_db_roles(db_name) %}

    --The problem with this setup of course is that granting future privileges at the database level will be broken if then subsequent to this future privileges are then granted at the schema level.  
    --In that case, the future privileges at the database level would need to be re-granted to pick up the new schema-level future grants.  
    --This is a known limitation of Snowflake's privilege model and is something to be aware of when designing your role and privilege strategy.  
    DEFINE DATABASE ROLE {{db_name}}.DB_CRUD COMMENT = 'Database role with that grants the ability to create objects and all privileges to create, read, update, and delete data rows in tables and other objects in the database.';
    DEFINE DATABASE ROLE {{db_name}}.DB_R COMMENT = 'Database role with privileges to read (SELECT) data rows in tables and other objects in the database.';

    -- CRUD
    GRANT MONITOR ON DATABASE {{db_name}} TO DATABASE ROLE {{db_name}}.DB_CRUD;
    GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE {{db_name}} TO DATABASE ROLE {{db_name}}.DB_CRUD;
    GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE {{db_name}} TO DATABASE ROLE {{db_name}}.DB_CRUD;

    {% set crud_objects = ['TABLES','VIEWS','MATERIALIZED VIEWS','DYNAMIC TABLES','EXTERNAL TABLES',
                           'FILE FORMATS','STREAMS','TASKS','SEQUENCES','EVENT TABLES',
                           'FUNCTIONS','PROCEDURES','PIPES'] %}
    {% for scope in ['ALL','FUTURE'] %}
      {% for obj in crud_objects %}
        GRANT ALL PRIVILEGES ON {{scope}} {{obj}} IN DATABASE {{db_name}} TO DATABASE ROLE {{db_name}}.DB_CRUD;
      {% endfor %}
    {% endfor %}

    -- READ
    GRANT MONITOR ON DATABASE {{db_name}} TO DATABASE ROLE {{db_name}}.DB_R;
    GRANT USAGE ON ALL SCHEMAS IN DATABASE {{db_name}} TO DATABASE ROLE {{db_name}}.DB_R;
    GRANT USAGE ON FUTURE SCHEMAS IN DATABASE {{db_name}} TO DATABASE ROLE {{db_name}}.DB_R;

    {% set read_select_ref = ['TABLES','VIEWS','MATERIALIZED VIEWS','EXTERNAL TABLES'] %}
    {% set read_select_only = ['DYNAMIC TABLES','STREAMS','EVENT TABLES'] %}
    {% set read_usage  = ['FUNCTIONS','PROCEDURES','FILE FORMATS'] %}
    {% for scope in ['ALL','FUTURE'] %}
      {% for obj in read_select_ref %}
        GRANT SELECT, REFERENCES ON {{scope}} {{obj}} IN DATABASE {{db_name}} TO DATABASE ROLE {{db_name}}.DB_R;
      {% endfor %}
      {% for obj in read_select_only %}
        GRANT SELECT ON {{scope}} {{obj}} IN DATABASE {{db_name}} TO DATABASE ROLE {{db_name}}.DB_R;
      {% endfor %}
      {% for obj in read_usage %}
        GRANT USAGE ON {{scope}} {{obj}} IN DATABASE {{db_name}} TO DATABASE ROLE {{db_name}}.DB_R;
      {% endfor %}
    {% endfor %}
    {% for scope in ['ALL','FUTURE'] %}
        GRANT READ ON {{scope}} STAGES IN DATABASE {{db_name}} TO DATABASE ROLE {{db_name}}.DB_R;
    {% endfor %}
    {% for scope in ['ALL','FUTURE'] %}
        GRANT READ ON {{scope}} STAGES IN DATABASE {{db_name}} TO DATABASE ROLE {{db_name}}.DB_CRUD;
    {% endfor %}
{% endmacro %}

