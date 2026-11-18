{% macro grant_db_owner(object_type, object_fqn) %}
    GRANT OWNERSHIP ON {{ object_type }} {{ object_fqn }} TO ROLE DB_OWNER;
{% endmacro %}
