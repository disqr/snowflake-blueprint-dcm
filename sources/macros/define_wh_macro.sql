
{% macro define_warehouses(warehouses, env_prefix, auto_suspend_secs) %}
{% for wh in warehouses %}
DEFINE WAREHOUSE {{env_prefix}}{{ wh.name }}
    WAREHOUSE_SIZE            = '{{ wh.size }}'
    AUTO_SUSPEND              = {{ auto_suspend_secs }}
    AUTO_RESUME               = TRUE
    INITIALLY_SUSPENDED       = TRUE
    COMMENT                   = '{{ wh.comment }}';
{% endfor %}
{% endmacro %}