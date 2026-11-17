/*
    One-time setup for the BRONZE DCM project. Run manually before the first
    `snow dcm plan` / `snow dcm deploy`.

    Creates:
      - DCM_DEPLOYER role: owns the DCM projects (project_owner in manifest.yml)
        and is the role DCM uses to create objects and manage grants.
        Uses explicit account-level grants (least privilege) rather than
        inheriting SYSADMIN / SECURITYADMIN.
      - DB_OWNER role: owns all the databases and schemas.  Rolls up to SYSADMIN.  Has no grants other than
        ownership of the objects so that it can drop an created objects in the databases it owns.
      - DCM_ADMIN.PROJECTS: container for the DCM project objects.
      - DCM_DEV / DCM_TST / DCM_PRD project objects, one per manifest target.

    Prerequisites:
      - Run as a user with SECURITYADMIN and ACCOUNTADMIN.
      - FEATURE_RBAC_INHERITED_GRANTS enabled on the account (required by
        the GRANT INHERITED statements in database_roles.sql).
      - DB_OWNER account role exists (definition files transfer ownership to it).
*/

-- 1. Create DCM_DEPLOYER and DB_OWNER roles.
USE ROLE SECURITYADMIN;

CREATE ROLE IF NOT EXISTS DCM_DEPLOYER;
SET curr_user = (SELECT CURRENT_USER());
GRANT ROLE DCM_DEPLOYER TO USER IDENTIFIER($curr_user);

CREATE ROLE IF NOT EXISTS DB_OWNER;
SET curr_user = (SELECT CURRENT_USER());
GRANT ROLE DB_OWNER TO USER IDENTIFIER($curr_user);

-- DCM_DEPLOYER needs every privilege for a deployment in one role, because
-- definition files can't contain USE ROLE (DCM is declarative; session commands
-- aren't supported). Inheriting SYSADMIN + SECURITYADMIN would work but grants
-- far more than needed; the explicit account-level grants in step 2 cover
-- CREATE DATABASE / WAREHOUSE / ROLE and MANAGE GRANTS instead.
-- GRANT ROLE SYSADMIN       TO ROLE DCM_DEPLOYER;
-- GRANT ROLE SECURITYADMIN  TO ROLE DCM_DEPLOYER;

-- DCM_DEPLOYER rolls up to ACCOUNTADMIN
GRANT ROLE DCM_DEPLOYER TO ROLE ACCOUNTADMIN;

--DB_OWNER rolls up to SYSADMIN.
GRANT ROLE DB_OWNER TO ROLE SYSADMIN;

-- Definition files transfer ownership of the database, schema, and database roles
-- to DB_OWNER. DCM_DEPLOYER must inherit DB_OWNER to keep managing those objects
-- on later deployments; without this, DCM loses ownership and deploys fail.
GRANT ROLE DB_OWNER TO ROLE DCM_DEPLOYER;

USE ROLE ACCOUNTADMIN;

-- 2. Account-level privileges (requires ACCOUNTADMIN to grant)
GRANT CREATE WAREHOUSE     ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT CREATE ROLE          ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT CREATE DATABASE      ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT MANAGE GRANTS        ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT EXECUTE MANAGED TASK ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT EXECUTE TASK         ON ACCOUNT TO ROLE DCM_DEPLOYER;

-- 3. DCM project container DB + schema
USE ROLE DCM_DEPLOYER;

CREATE DATABASE IF NOT EXISTS DCM_ADMIN;
CREATE SCHEMA IF NOT EXISTS DCM_ADMIN.PROJECTS;

-- 4. DCM project objects (one per manifest target)
CREATE DCM PROJECT IF NOT EXISTS DCM_ADMIN.PROJECTS.DCM_DEV
    COMMENT = 'Development environment';

CREATE DCM PROJECT IF NOT EXISTS DCM_ADMIN.PROJECTS.DCM_TST
    COMMENT = 'Test environment';

CREATE DCM PROJECT IF NOT EXISTS DCM_ADMIN.PROJECTS.DCM_PRD
    COMMENT = 'Production environment';
