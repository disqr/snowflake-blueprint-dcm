-- ===================================================================
--  PRE-DEPLOY: Shared Account-Level Roles
--  These roles are shared across all environments in the account.
--  Using CREATE ROLE IF NOT EXISTS ensures idempotent execution
--  regardless of how many times or for how many environments this runs.
--  
--  NOTE: This file uses standard SQL (not DCM DEFINE syntax).
--        Jinja templating is NOT supported in companion scripts.
-- ===================================================================
use role USERADMIN;

-- ANALYST: Read-only access to production curated layers.
CREATE ROLE IF NOT EXISTS ANALYST
    COMMENT = 'Read-only access to production curated layers (Gold, Silver, Common)';

-- TESTER: Read-only access to test all layers.
CREATE ROLE IF NOT EXISTS TESTER
    COMMENT = 'Read-only access to test all layers (Gold, Silver, Bronze, Common)';

--- DEVELOPER: Crud access to dev and test environments to make chanes
CREATE ROLE IF NOT EXISTS DEVELOPER
    COMMENT = 'Developer - CRUD on Development Bronze, Silver, Gold, Common, read access on all others.';

-- DEVOPS: Production environment management.
CREATE ROLE IF NOT EXISTS DEVOPS
    COMMENT = 'Ability to manage production environment.';

USE ROLE SECURITYADMIN;

GRANT ROLE ANALYST TO ROLE DB_OWNER;
GRANT ROLE TESTER TO ROLE DB_OWNER;
GRANT ROLE DEVELOPER TO ROLE DB_OWNER;
GRANT ROLE DEVOPS TO ROLE DB_OWNER;