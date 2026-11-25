{% macro grant_db_owner(object_type, object_fqn) %}
    GRANT OWNERSHIP ON {{ object_type }} {{ object_fqn }} TO ROLE DB_OWNER;
{% endmacro %}

{% macro grant_db_role_to_owner(catalog_name, db_role_name) %}
    GRANT DATABASE ROLE {{ catalog_name }}.{{ db_role_name }} TO ROLE DB_OWNER;
{% endmacro %}

{% macro grant_db_role_to_role(catalog_name, db_role_name, account_role_name) %}
    GRANT DATABASE ROLE {{ catalog_name }}.{{ db_role_name }} TO ROLE {{ account_role_name }};
{% endmacro %}