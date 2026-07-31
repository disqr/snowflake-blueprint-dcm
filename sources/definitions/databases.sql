
DEFINE DATABASE {{env_prefix}}BRONZE
    COMMENT = 'Raw landing zone';

DEFINE DATABASE {{env_prefix}}SILVER
    COMMENT = 'Cleansed and conformed data';

DEFINE DATABASE {{env_prefix}}GOLD
    COMMENT = 'Business-ready models';

DEFINE DATABASE {{env_prefix}}COMMON
    COMMENT = 'Shared reference data';

DEFINE DATABASE {{env_prefix}}ADMIN
    COMMENT = 'Monitoring, and admin utilities';

GRANT OWNERSHIP ON DATABASE {{env_prefix}}BRONZE TO ROLE DB_OWNER;
GRANT OWNERSHIP ON DATABASE {{env_prefix}}SILVER TO ROLE DB_OWNER;
GRANT OWNERSHIP ON DATABASE {{env_prefix}}GOLD TO ROLE DB_OWNER;
GRANT OWNERSHIP ON DATABASE {{env_prefix}}COMMON TO ROLE DB_OWNER;
GRANT OWNERSHIP ON DATABASE {{env_prefix}}ADMIN TO ROLE DB_OWNER;
