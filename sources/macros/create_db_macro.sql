{% macro create_db(db_name, db_comment) %}
    DEFINE DATABASE {{db_name}}
        COMMENT = '{{db_comment}}';

    GRANT OWNERSHIP ON DATABASE {{db_name}} TO ROLE DB_OWNER;

    -- DB_R / DB_CRUD database roles (sources/macros/db_roles_macro.sql)
    {{ create_db_roles(db_name) }}
{% endmacro %}
