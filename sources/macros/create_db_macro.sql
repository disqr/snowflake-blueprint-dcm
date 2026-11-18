{% macro create_db(catalog_name, catalog_comment) %}
    DEFINE DATABASE {{catalog_name}}
        COMMENT = '{{catalog_comment}}';
    {{ grant_db_owner('DATABASE', catalog_name) }}
    {{ create_db_roles(catalog_name) }}
{% endmacro %}
