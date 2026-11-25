/*
    One-time setup for the medallion DCM project. Run manually before the first
    `snow dcm plan` / `snow dcm deploy`. Every statement is safe to re-run.

    Creates:
      - DCM_DEPLOYER role: owns the DCM projects (project_owner in manifest.yml)
        and is the role DCM uses to create objects and manage grants.
        Uses explicit account-level grants (least privilege) rather than
        inheriting SYSADMIN / SECURITYADMIN.
      - DB_OWNER role: owns the databases, schemas, and database roles, and holds
        each database's DB_CRUD and DB_R roles, so it has full control of every
        database it owns (like db_owner in SQL Server). It has no account-level
        privileges. Rolls up to SYSADMIN.
      - DCM_ADMIN.PROJECTS: container for the DCM project objects.
      - DCM_DEV / DCM_TST / DCM_PRD project objects, one per manifest target.

    Prerequisites:
      - Run as a user with ACCOUNTADMIN, SECURITYADMIN, and USERADMIN.
*/

-- 0. The database roles use inherited grants (GRANT INHERITED in create_db_roles_macro.sql).
USE ROLE ACCOUNTADMIN;
ALTER ACCOUNT SET FEATURE_RBAC_INHERITED_GRANTS = 'ENABLED';

-- 1. Create DCM_DEPLOYER and DB_OWNER roles, owned by USERADMIN.
USE ROLE USERADMIN;

CREATE ROLE IF NOT EXISTS DCM_DEPLOYER;
CREATE ROLE IF NOT EXISTS DB_OWNER;

USE ROLE SECURITYADMIN;

SET curr_user = (SELECT CURRENT_USER());
GRANT ROLE DCM_DEPLOYER TO USER IDENTIFIER($curr_user);
GRANT ROLE DB_OWNER TO USER IDENTIFIER($curr_user);

-- DCM_DEPLOYER needs every privilege for a deployment in one role, because
-- definition files can't contain USE ROLE (DCM is declarative; session commands
-- aren't supported). Inheriting SYSADMIN + SECURITYADMIN would work but grants
-- far more than needed; the explicit account-level grants in step 2 cover
-- CREATE DATABASE / WAREHOUSE and MANAGE GRANTS instead (CREATE ROLE comes
-- from USERADMIN in step 2.A).
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
--GRANT CREATE ROLE          ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT CREATE DATABASE      ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT MANAGE GRANTS        ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT EXECUTE MANAGED TASK ON ACCOUNT TO ROLE DCM_DEPLOYER;
GRANT EXECUTE TASK         ON ACCOUNT TO ROLE DCM_DEPLOYER;

-- 2.A. roles.sql creates roles and transfers their ownership to USERADMIN.
-- Inheriting USERADMIN gives DCM_DEPLOYER CREATE ROLE and lets it keep
-- managing those roles after the transfer.
GRANT ROLE USERADMIN TO ROLE DCM_DEPLOYER;

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
