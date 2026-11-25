# snowflake-blueprint-dcm

An open source blueprint for setting up a medallion architecture (Bronze, Silver, Gold) in
Snowflake with [DCM (Database Change Management) projects](https://docs.snowflake.com/en/developer-guide/dcm/overview).
Clone it, adjust the names and sizes to suit your organization, and deploy a working set of
databases, schemas, roles, and warehouses for each environment.

Released under the [MIT License](LICENSE): use it, change it, and redistribute it freely.

## What it builds

Each DCM target (environment) deploys the same set of objects. Every name is prefixed with the
target's `env_prefix` (`DEV_`, `TST_`, `PRD_`, or `<NAME>_` for a sandbox).

| Object type | Objects |
| --- | --- |
| Databases | `BRONZE`, `SILVER`, `GOLD`, `COMMON`, `ADMIN` |
| Schemas | Layer-specific schemas in each database (see [Schema Naming](#schema-naming)) |
| Database roles | `DB_CRUD` and `DB_R` in every database |
| Account roles (per environment) | `ETL`, `LOADER`, `CONSUMER` service roles |
| Account roles (shared) | Grants to `ANALYST`, `TESTER`, `DEVELOPER`, `DEVOPS` |
| Warehouses | `ETL_WH`, `LOAD_WH`, `ANALYST_WH`, `BI_WH`, `DEVELOPER_WH`, `DEPLOYMENT_WH`, `OPS_WH`, `AI_WH` |
| Stages | `BRONZE.STAGING.FILES` (internal stage for flat-file loads) |

For example, the DEV target creates `DEV_BRONZE`, `DEV_BRONZE.DB_R`, `DEV_ETL`, and `DEV_ETL_WH`.

## Notes on the blueprint

### Deployment Role Separation by Privilege Needed

You'll notice if you read the code a bit, that everything is owned by a DB_OWNER role but the actual IaC code runs under the DCM_DEPLOYER role (you'll see ownership grants to DB_OWNER in the code).  Note that the account-level privileges are stripped out of the DB_OWNER role, which owns the databases and has full control of everything in them (see [DB_OWNER](#db_owner) below).  The reason for that is to separate out the needed privileges to manage the databases and schemas and manage the overall platform which makes some of the administrative work divisible.  This also enables an organization to use the open source DCM project as an initial setup, but then move to the method where Platform IaC can be easily separated from Database IaC e.g. a repo for platform, and perhaps multiple repos for database oriented subject areas such as EDW, ODS, etc.  Simply put, Platform IaC can run under the DCM_DEPLOYER role, while database IaC can run under the DB_OWNER role with a simple change e.g. 

```{sql}
GRANT CREATE DATABASE ON ACCOUNT TO ROLE DB_OWNER;
```

### DB_OWNER

`DB_OWNER` is modeled on the `db_owner` fixed database role in SQL Server, which has full control
of a database: configuration, maintenance, object creation, security management, and even
dropping the database. Snowflake separates these privileges, so the blueprint assembles them:

- `DB_OWNER` **owns** each database, its schemas, and its database roles, so it can manage,
  grant on, and drop them.
- `DB_OWNER` is **granted** each database's `DB_CRUD` and `DB_R` roles, so it can create objects
  and read and change all data in every database it owns.

`DB_OWNER` has no account-level privileges. It can't create databases, warehouses, or roles
unless you grant that separately (see the `GRANT CREATE DATABASE` example above).

### Object ownership

| Object | Owner | Set by |
| --- | --- | --- |
| DCM projects and the `DCM_ADMIN` database | `DCM_DEPLOYER` | `manual/1.setup.sql` |
| Databases, schemas, database roles, and the `BRONZE.STAGING.FILES` stage | `DB_OWNER` | `grant_db_owner` macro |
| Account roles (`DCM_DEPLOYER`, `DB_OWNER`, `ETL`, `LOADER`, `CONSUMER`, and the shared roles) | `USERADMIN` | `manual/1.setup.sql`, `manual/2.pre_deploy.sql`, `roles.sql` |
| Warehouses | `DCM_DEPLOYER` | No ownership transfer |
| Tables, views, and other objects created after deployment | The role that creates them | Snowflake default |

`DCM_DEPLOYER` inherits both `DB_OWNER` and `USERADMIN`, so it can keep managing every object it
transferred on later deployments. Account roles are owned by `USERADMIN`, following Snowflake's
recommendation that `USERADMIN` own roles.

### Role hierarchy

```
ACCOUNTADMIN
├── DCM_DEPLOYER                 runs DCM plan/deploy (project_owner in manifest.yml)
│   ├── DB_OWNER
│   └── USERADMIN
└── SYSADMIN
    └── DB_OWNER                 owns and fully controls the databases
        ├── <DB>.DB_CRUD, <DB>.DB_R   (every database)
        └── ANALYST, TESTER, DEVELOPER, DEVOPS
```

Account roles don't inherit from each other. Each one receives only the database roles and
warehouses it needs, which keeps role assignment flexible.

### Access by role

`R` is `DB_R` (read) and `CRUD` is `DB_CRUD` (create, read, update, delete).

| Role | Environments | BRONZE | SILVER | GOLD | COMMON | ADMIN | Warehouses |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `ANALYST` | PRD | | R | R | R | | `ANALYST_WH`, `BI_WH` |
| `ANALYST` | DEV, TST, SBX | | | | | | `ANALYST_WH` |
| `TESTER` | All | R | R | R | R | R | `BI_WH` |
| `DEVELOPER` | DEV | CRUD | CRUD | CRUD | CRUD | CRUD | `DEVELOPER_WH` |
| `DEVELOPER` | TST, PRD | R | R | R | R | R | `DEVELOPER_WH` |
| `DEVELOPER` | SBX | | | | | | `DEVELOPER_WH` |
| `DEVOPS` | All | CRUD | CRUD | CRUD | CRUD | CRUD | `OPS_WH`, `DEPLOYMENT_WH` |
| `<env>ETL` | Own env | R | CRUD | CRUD | CRUD | R | `ETL_WH` |
| `<env>LOADER` | Own env | CRUD | | | | R | `LOAD_WH` |
| `<env>CONSUMER` | Own env | | R | R | | | `BI_WH` |

Warehouse grants are `USAGE` and `MONITOR` on the environment's warehouse (for example
`PRD_BI_WH`). `AI_WH` is created but not granted to any role yet.

The blueprint provides scaffolding: these grants are a starting point, and each organization
decides how its own roles map to the database roles. The shared roles (`ANALYST`, `TESTER`,
`DEVELOPER`, `DEVOPS`) exist once per account and receive grants from every environment. The service roles are created per environment (`DEV_ETL`,
`PRD_ETL`), so a service account can only reach its own environment.

### Database roles and inherited grants

The `create_db_roles` macro creates two database roles in every database and grants their
privileges with [inherited grants](https://docs.snowflake.com/en/user-guide/security-access-control-inherited-grants)
(`GRANT INHERITED ... ON ALL <objects> IN DATABASE`). One inherited grant covers every current
and future object of that type in the database, so there are no `ON FUTURE` grants to maintain,
and schema-level future grants can't override them. Inherited grants require
`FEATURE_RBAC_INHERITED_GRANTS`, which `manual/1.setup.sql` enables.

| Database role | Privileges |
| --- | --- |
| `DB_CRUD` | `MONITOR` on the database; `ALL PRIVILEGES` on schemas, tables, views, semantic views, materialized views, dynamic tables, external tables, file formats, streams, tasks, sequences, event tables, functions, procedures, and stages |
| `DB_R` | `MONITOR` on the database; `USAGE` on schemas; `SELECT, REFERENCES` on tables, views, semantic views, materialized views, and external tables; `SELECT` on streams and event tables; `SELECT, MONITOR` on dynamic tables; `USAGE` on functions, procedures, stages, and file formats; `READ` on stages |

`ALL PRIVILEGES` never includes `OWNERSHIP`. Grant database roles to account roles, never
object privileges directly.

## Database Naming

Database names are `<env_prefix><LAYER>`, for example `DEV_BRONZE` or `PRD_GOLD`. The layer names
are defined in `sources/definitions/databases.sql`:

| Database | Purpose |
| --- | --- |
| `BRONZE` | Raw landed data |
| `SILVER` | Cleansed and conformed data |
| `GOLD` | Business-ready models |
| `COMMON` | Shared reference data, functions, and procedures |
| `ADMIN` | Monitoring and admin utilities |

## Schema Naming

Schemas are defined in `sources/definitions/schemas.sql`. Names that include `SOURCE` or
`CONNECTOR` are templates: copy the line and replace `SOURCE` with the source system name and
`CONNECTOR` with the connector name (for example Fivetran or Talend).

### Bronze

| Schema | Naming format | Purpose |
| --- | --- | --- |
| `LND_SOURCE_CONNECTOR` | `LND_<source_system>_<connector>[_<connection_info>]` | Landing zone: data exactly as extracted from the source |
| `RAW_SOURCE` | `RAW_<source_system>[_<connection_info>]` | Minimally standardized data (typing, basic structure) |
| `ARC_SOURCE_CONNECTOR` | `ARC_<source_system>_<connector>[_<connection_info>]` | Archive: immutable, append-only copies for lineage, audit, and reprocessing |
| `STAGING` | | Holds the `FILES` internal stage for flat-file loads |

### Silver

The Silver layer follows dbt conventions:

| Schema | Purpose |
| --- | --- |
| `STG_SOURCE` | Staging models: the entry point into Silver from Bronze |
| `INT_SOURCE` | Intermediate models: joins, deduplication, key standardization, and business rules |
| `SNP_SOURCE` | dbt snapshots (SCD Type 2) |

### Gold

| Schema | Purpose |
| --- | --- |
| `FACT` | Fact tables |
| `DIM` | Dimension tables |
| `AGG` | Pre-aggregated tables for specific reporting and BI use cases |

### Common and Admin

- `COMMON`: `REFERENCE` (reference data) and `UDFS` (shared functions and procedures).
- `ADMIN`: `COST`, `MONITORING`, `ENVIRONMENT_SUPPORT`, `GENERAL_SUPPORT`, `LOAD_SUPPORT`, and
  `SECURITY_SUPPORT`.

## Directory structure

```
snowflake-blueprint-dcm/
  ├── manifest.yml                 generated by util/generate_manifest.py (git-ignored)
  ├── snowflake.yml                Snowflake CLI project file
  ├── manual/                      one-time scripts run by hand (not deployed by DCM)
  │   ├── 1.setup.sql              DCM_DEPLOYER, DB_OWNER, DCM_ADMIN, project objects
  │   └── 2.pre_deploy.sql         shared account roles: ANALYST, TESTER, DEVELOPER, DEVOPS
  ├── sources/
  │   ├── definitions/             DCM definitions, deployed to every target
  │   │   ├── databases.sql
  │   │   ├── schemas.sql
  │   │   ├── roles.sql
  │   │   └── warehouses.sql
  │   └── macros/                  Jinja macros used by the definitions
  │       ├── create_db_macro.sql          create_db: database + ownership + database roles
  │       ├── create_db_roles_macro.sql    create_db_roles: DB_CRUD and DB_R with inherited grants
  │       ├── create_schema_macro.sql      create_schema: schema + ownership
  │       ├── define_wh_macro.sql          define_warehouses: one warehouse per list entry
  │       └── grant_db_owner_macro.sql     grant_db_owner, grant_db_role_to_owner, grant_db_role_to_role
  ├── util/
  │   ├── generate_manifest.py     renders the manifest template
  │   └── templates/manifest.yaml.jinja
  ├── doc/                         supporting design documents
  ├── archive/                     earlier versions, kept for reference (not deployed)
  └── out/                         plan output from --save-output (git-ignored)
```

## Environments and configuration

`util/templates/manifest.yaml.jinja` defines four targets. Each one points at a DCM project object
in `DCM_ADMIN.PROJECTS` and a templating configuration:

| Target | Project object | `env_prefix` | Notes |
| --- | --- | --- | --- |
| `DEV` | `DCM_ADMIN.PROJECTS.DCM_DEV` | `DEV_` | Default target |
| `TST` | `DCM_ADMIN.PROJECTS.DCM_TST` | `TST_` | |
| `PRD` | `DCM_ADMIN.PROJECTS.DCM_PRD` | `PRD_` | Larger warehouses, 300-second auto-suspend |
| `SBX` | `DCM_ADMIN.PROJECTS.DCM_SBX_<NAME>` | `<NAME>_` | Both are passed at run time |

Warehouse names and sizes and `auto_suspend_secs` are template variables. Set defaults under
`templating.defaults` and override them per environment under `templating.configurations`.

## Initial build and build test (Windows)

Use these steps to test a build or run the first deployment. Run every command in PowerShell
from the project root, one at a time.

Prerequisites:

- The [Snowflake CLI](https://docs.snowflake.com/en/developer-guide/snowflake-cli/index) (`snow`)
  is installed, with a connection to the target account.
- Python with the `jinja2` package (`pip install jinja2`).
- For steps 2 and 3, a user who has the ACCOUNTADMIN, SECURITYADMIN, and USERADMIN roles.

### 1. Generate the manifest

`util/generate_manifest.py` renders `util/templates/manifest.yaml.jinja` and writes
`manifest.yml` to the project root, overwriting any existing file. Pass your Snowflake account
identifier:

```powershell
python util\generate_manifest.py <account_identifier>
```

`manifest.yml` is git-ignored because it contains your account identifier.

### 2. Run setup (one time per account)

`manual/1.setup.sql`:

- Enables `FEATURE_RBAC_INHERITED_GRANTS` on the account.
- Creates the `DCM_DEPLOYER` and `DB_OWNER` roles as USERADMIN and grants both to the current
  user.
- Rolls `DCM_DEPLOYER` up to ACCOUNTADMIN and `DB_OWNER` up to SYSADMIN, and grants `DB_OWNER`
  and `USERADMIN` to `DCM_DEPLOYER`.
- Grants `DCM_DEPLOYER` `CREATE DATABASE`, `CREATE WAREHOUSE`, `MANAGE GRANTS`,
  `EXECUTE TASK`, and `EXECUTE MANAGED TASK` on the account, instead of inheriting SYSADMIN
  and SECURITYADMIN.
- Creates the `DCM_ADMIN.PROJECTS` schema and the `DCM_DEV`, `DCM_TST`, and `DCM_PRD` project
  objects.

The script switches roles itself with `USE ROLE`, and every statement is safe to re-run.

```powershell
snow sql -f manual\1.setup.sql
```

### 3. Run pre-deploy

`manual/2.pre_deploy.sql` creates the account roles that all environments share (`ANALYST`,
`TESTER`, `DEVELOPER`, `DEVOPS`) as USERADMIN, then grants them to `DB_OWNER` as SECURITYADMIN.
Run it before the first plan, because `roles.sql` grants to these roles. It's safe to re-run.

```powershell
snow sql -f manual\2.pre_deploy.sql
```

### 4. Plan and deploy DEV, TST, and PRD

Always run as `DCM_DEPLOYER`, the manifest's `project_owner`.

1. Set the deploying role for the session:

   ```powershell
   $ROLE = "DCM_DEPLOYER"
   ```

2. Plan DEV, the default target. `--save-output` writes the plan to `out\`, and `--verbose`
   shows more detail:

   ```powershell
   snow dcm plan --target DEV --save-output --verbose --role $ROLE
   ```

3. Plan TST and PRD:

   ```powershell
   snow dcm plan --target TST --save-output --role $ROLE
   snow dcm plan --target PRD --save-output --role $ROLE
   ```

4. Review the plan output in `out\plan_result.json` and the rendered SQL in `out\rendered\`.
   For a build test, stop here.

5. For a real build, deploy each target after you've reviewed its plan:

   ```powershell
   snow dcm deploy --target DEV --role $ROLE
   snow dcm deploy --target TST --role $ROLE
   snow dcm deploy --target PRD --role $ROLE
   ```

### 5. Plan and deploy a sandbox

A sandbox is a personal copy of the project. It uses the `SBX` target and its own project object,
and every object is prefixed with the sandbox name (for example `JSMITH_BRONZE`). Steps 1 to 3
must already have been run.

1. Set the sandbox name, project, and role for the session. Use only upper-case letters, digits,
   and underscores in the name. Always run as `DCM_DEPLOYER`: the CLI doesn't switch roles for
   you, and running as ACCOUNTADMIN makes ACCOUNTADMIN the owner of the project and of any object
   without an explicit `GRANT OWNERSHIP`.

   ```powershell
   $NAME    = "JSMITH"
   $PROJECT = "DCM_ADMIN.PROJECTS.DCM_SBX_${NAME}"
   $ROLE    = "DCM_DEPLOYER"
   ```

2. Create the sandbox's project object (safe to re-run), then confirm that it exists and that
   its owner is `DCM_DEPLOYER`:

   ```powershell
   snow dcm create $PROJECT --target SBX --if-not-exists --role $ROLE
   snow sql -q "SHOW DCM PROJECTS LIKE 'DCM_SBX_${NAME}' IN SCHEMA DCM_ADMIN.PROJECTS" --role $ROLE
   ```

3. Plan the sandbox. In the output, check that `role_name` is `DCM_DEPLOYER` and that there are
   no `ALTER ROLE ACCOUNTADMIN` entries:

   ```powershell
   snow dcm plan $PROJECT --target SBX -D "env_prefix='${NAME}_'" --save-output --role $ROLE
   ```

4. Review the plan. For a build test, stop here.

   ```powershell
   Get-Content .\out\plan_result.json
   ```

5. Deploy the sandbox:

   ```powershell
   snow dcm deploy $PROJECT --target SBX -D "env_prefix='${NAME}_'" --role $ROLE
   ```

6. Check what was created:

   ```powershell
   snow sql -q "SHOW SCHEMAS IN DATABASE ${NAME}_BRONZE" --role $ROLE
   snow sql -q "SHOW DATABASE ROLES IN DATABASE ${NAME}_BRONZE" --role $ROLE
   ```

   To test a second sandbox, repeat steps 1 to 6 with a different name, then confirm that the
   first sandbox's objects are unchanged. Always pair the same `$NAME` with the same `$PROJECT`.

7. Tear down the sandbox when you're finished. **This is destructive:** it permanently drops the
   sandbox's databases (such as `${NAME}_BRONZE`) and their data. Check the flags first, then
   purge the managed objects and drop the project object:

   ```powershell
   snow dcm purge --help
   snow dcm purge $PROJECT --target SBX --role $ROLE
   snow dcm drop $PROJECT --role $ROLE
   ```

## Customizing the blueprint

- **Add a database:** add a `create_db` line to `databases.sql`. It creates the database, its
  `DB_CRUD` and `DB_R` roles, and the ownership grants. Then grant the new database roles to
  account roles in `roles.sql`.
- **Add a schema:** add a `create_schema` line to `schemas.sql`. No grants are needed: the
  database roles' inherited grants cover new schemas and their objects automatically.
- **Add a warehouse:** add a name and size variable to the manifest template, an entry to the list
  in `warehouses.sql`, and `USAGE`/`MONITOR` grants in `roles.sql`. `roles.sql` refers to
  warehouses by their template variables (for example `{{env_prefix}}{{bi_wh}}`), so renaming a
  warehouse in the manifest also updates its grants.
- **Add a role:** add a `DEFINE ROLE` with a `GRANT OWNERSHIP ... TO ROLE USERADMIN` to
  `roles.sql` for a per-environment role, or a `CREATE ROLE IF NOT EXISTS` to
  `manual/2.pre_deploy.sql` for a role shared across environments.

Comments are inserted into single-quoted SQL strings, so don't use apostrophes in database,
schema, or warehouse comments.

## Scripts outside DCM

Some Snowflake objects can't or shouldn't be managed by DCM. Those scripts live at the project
root, outside `sources/`, so DCM never uploads or runs them:

- `manual/`: one-time scripts run by hand by a DBA, such as creating the account-level SSO
  security integration. These are never part of a CI/CD process.
- `always/`: idempotent scripts run on **every** deployment, for objects DCM can't `DEFINE`
  (for example `CREATE NOTIFICATION INTEGRATION IF NOT EXISTS ...`). Every script must be safe
  to re-run: use `CREATE ... IF NOT EXISTS`, `CREATE OR ALTER`, or `ALTER ... SET`. The name
  follows schemachange's "always" script type, which runs on every deployment. Create the folder
  when you add the first script.

Scripts in these folders run with `snow sql`, not `snow dcm`, so they don't read
`manifest.yml`. To use Jinja variables, enable templating and pass the variables explicitly,
for example `--enable-templating JINJA -D "env_prefix=DEV_"`.

### Script run order

Unlike DCM definitions, these scripts have no dependency sorting, so the run order has to be
set explicitly. Use both of the following:

1. **Number the files** in run order with a two-digit prefix: `01_`, `02_`, `03_`. The order
   is visible in a directory listing, and gaps (`10_`, `20_`, `30_`) leave room to insert a
   script later without renaming the others.
2. **Add a `main.sql`** in each folder that lists the scripts in run order with `!source`.
   This is the recommended entry point: the run order is written down in one place, and
   everything runs on a single connection with one command.

```
always/
  ├── main.sql
  ├── 01_do_this.sql
  └── 02_do_that.sql
```

```sql
-- always/main.sql: runs every script in this folder, in order
!source 01_do_this.sql
!source 02_do_that.sql
```

Run `main.sql` from inside its folder. A relative `!source` path is resolved from the
current working directory, not from the folder containing `main.sql`, so running it from the
project root fails with `Could not read: 01_do_this.sql`:

```powershell
Push-Location .\always
snow sql -f main.sql --enable-templating JINJA -D "env_prefix=DEV_" --role DCM_DEPLOYER
Pop-Location
```

When you add a script, give it the next number and add a matching `!source` line to
`main.sql`. A numbered file that isn't listed in `main.sql` won't run. Variables passed with
`-D` are applied to every sourced file.

## General notes

- DCM reads every file under `sources/definitions/` regardless of folder nesting, so you can
  organize definitions into subfolders. Name folders with the base object name (`BRONZE`, not
  `DEV_BRONZE`) and keep `{{ env_prefix }}` in the SQL, with fully qualified object names in
  every statement.
- Anything outside `sources/` (such as `archive/` and `doc/`) isn't uploaded or deployed.

## License

[MIT](LICENSE)
