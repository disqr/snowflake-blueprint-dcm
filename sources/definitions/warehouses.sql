{%- set warehouses = [
    {'name': etl_wh,        'size': etl_wh_size,        'comment': 'ETL warehouse'},
    {'name': load_wh,       'size': load_wh_size,       'comment': 'Data Ingestion'},
    {'name': analyst_wh,    'size': analyst_wh_size,     'comment': 'Analyst Reads'},
    {'name': bi_wh,         'size': bi_wh_size,          'comment': 'BI queries and dashboarding'},
    {'name': developer_wh,  'size': developer_wh_size,   'comment': 'Dev and exploration'},
    {'name': deployment_wh, 'size': deployment_wh_size,  'comment': 'Deployments'},
    {'name': ops_wh,        'size': ops_wh_size,         'comment': 'Operations'},
    {'name': ai_wh,         'size': ai_wh_size,          'comment': 'AI'}
] -%}

{{ define_warehouses(warehouses, env_prefix, auto_suspend_secs) }}


