{% macro create_schema(catalog_name, schema_name, schema_comment) %}
    DEFINE SCHEMA {{ catalog_name }}.{{ schema_name }}
        COMMENT = '{{ schema_comment }}';
    {{ grant_db_owner('SCHEMA', catalog_name ~ '.' ~ schema_name) }}
{% endmacro %}
