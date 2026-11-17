/*
    DCM_DEPLOYER ROLE
    Usage:  role used by DCM to create objects and
            manage permissions. 
    Inherits SYSADMIN + SECURITYADMIN so it can create infrastructure
    (databases, warehouses) and manage role grants in a single context.
*/

-- 1. Create DCM_DEPLOYER
USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS DCM_DEPLOYER;
SET curr_user = (SELECT CURRENT_USER());
GRANT ROLE DCM_DEPLOYER TO USER IDENTIFIER($curr_user);

-- DCM_DEPLOYER inherits SYSADMIN (create databases, warehouses, schema objects)
-- and SECURITYADMIN (create roles, manage grants)
-- Why?  you cannot include USE ROLE <rolename>; in a DCM definition file, so you cannot flip around to different roles in the definition files.
--  DCM scripts use declarative DEFINE statements, not imperative session commands. USE ROLE is a session-level command that changes context, 
--  and DCM doesn't support it in definition files.
GRANT ROLE SYSADMIN       TO ROLE DCM_DEPLOYER;
GRANT ROLE SECURITYADMIN  TO ROLE DCM_DEPLOYER;

-- DCM_DEPLOYER rolls up to ACCOUNTADMIN
GRANT ROLE DCM_DEPLOYER TO ROLE ACCOUNTADMIN;

USE ROLE ACCOUNTADMIN;

-- Account-level privileges (requires ACCOUNTADMIN to grant)
GRANT CREATE WAREHOUSE     ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT CREATE ROLE          ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT CREATE DATABASE      ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT MANAGE GRANTS        ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT EXECUTE MANAGED TASK ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT EXECUTE TASK         ON ACCOUNT TO ROLE DCM_DEPLOYER;

-- 2. DCM Project container DB + schema
USE ROLE DCM_DEPLOYER;

CREATE DATABASE IF NOT EXISTS DCM_ADMIN;
CREATE SCHEMA IF NOT EXISTS DCM_ADMIN.PROJECTS;

-- 3. DCM Project objectS (referenced by manifest target)
CREATE OR REPLACE DCM PROJECT DCM_ADMIN.PROJECTS.DCM_DEV;
    COMMENT = 'DEV environment';

CREATE OR REPLACE DCM PROJECT DCM_ADMIN.PROJECTS.DCM_TEST;
    COMMENT = 'Test environment';

CREATE OR REPLACE DCM PROJECT ADMIN.PROJECTS.DCM_PROD
    COMMENT = 'PROD environment';
