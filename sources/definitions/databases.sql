
{{ create_db(env_prefix ~ 'BRONZE', 'Bronze layer - raw landed data') }}
{{ create_db(env_prefix ~ 'SILVER', 'Silver layer - Cleansed and conformed data') }}
{{ create_db(env_prefix ~ 'GOLD', 'Gold layer - Business-ready models') }}
{{ create_db(env_prefix ~ 'COMMON', 'Common layer - shared reference data') }}
{{ create_db(env_prefix ~ 'ADMIN', 'Admin layer - Monitoring, and admin utilities') }}
