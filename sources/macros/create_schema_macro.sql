{% macro create_schema(db_name, schema_name, schema_comment) %}
    DEFINE SCHEMA {{ db_name }}.{{ schema_name }}
        COMMENT = '{{ schema_comment }}';
    {{ grant_db_owner('SCHEMA', db_name ~ '.' ~ schema_name) }}
{% endmacro %}
