{% macro create_db(db_name, db_comment) %}
    DEFINE DATABASE {{db_name}}
        COMMENT = '{{db_comment}}';
    {{ grant_db_owner('DATABASE', db_name) }}
    {{ create_db_roles(db_name) }}
{% endmacro %}
