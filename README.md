# snowflake-blueprint-dcm
A blueprint to set up a medallion architecture in Snowflake using DCM.

## Notes on the blueprint

### Deployment Role Separation by Privilege Needed

You'll notice if you read the code a bit, that everything is owned by a DB_OWNER role but the actual IaC code runs under the DCM_DEPLOYER role (you'll see ownership grants to DB_OWNER in the code).  Note that the higher level privileges are stripped out of the DB_OWNER role which simply owns the database and schemas.  The reason for that is to separate out the needed privileges to manage the databases and schemas and manage the overall platform which makes some of the administrative work divisible.  This also enables an organization to use the open source DCM project as an initial setup, but then move to the method where Platform IaC can be easily separated from Database IaC e.g. a repo for platform, and perhaps multiple repos for database oriented subject areas such as EDW, ODS, etc.  Simply put, Platform IaC can run under the DCM_DEPLOYER role, while database IaC can run under the DB_OWNER role with a simple change e.g. 

```{sql}
GRANT CREATE DATABASE ON ACCOUNT TO ROLE DB_OWNER;
```

## Database Naming

## Schema Naming

### Bronze

### Initial build and build test (Windows)

Use these steps to test a build or run the first deployment of the DCM project from a Windows
machine. Run every command in PowerShell from the project root, and run them one at a time.
Don't run `do-not-run-test.ps1` or `do-not-run-test-sbx.ps1` as scripts: they're step lists
to copy from, and the commands are repeated below.

Prerequisites:

- The Snowflake CLI (`snow`) is installed and has a connection to the target account.
- Python with the `jinja2` package (`pip install jinja2`).
- For steps 2 and 3, a user who has both the SECURITYADMIN and ACCOUNTADMIN roles.

#### 1. Generate the manifest

`util/generate_manifest.py` renders `util/templates/manifest.yaml.jinja` and writes
`manifest.yml` to the project root, overwriting any existing file. Pass the Snowflake account
identifier:

```{ps1}
python util\generate_manifest.py <account_identifier>
```

#### 2. Run setup (one time per account)

`manual/1.setup.sql` creates the `DCM_DEPLOYER` and `DB_OWNER` roles, grants
`DCM_DEPLOYER` its account-level privileges, and creates the `DCM_ADMIN.PROJECTS` schema with
the `DCM_DEV`, `DCM_TST`, and `DCM_PRD` project objects. The script switches roles itself with
`USE ROLE`, and every statement is safe to re-run.  It also turns opts in to inherited grants and 
container-level MANAGE GRANTS.  Inherited grants are used are used for the database role grants in this project.

```{ps1}
snow sql -f manual\1.setup.sql
```

#### 3. Run pre-deploy

`manual/2.pre_deploy.sql` creates the account-level roles that all environments share
(`ANALYST`, `TESTER`, `DEVELOPER`, `DEVOPS`) and grants them to `DB_OWNER`. It runs as
SECURITYADMIN and is safe to re-run.

```{ps1}
snow sql -f manual\2.pre_deploy.sql
```

#### 4. Plan and deploy the DEV, TST, and PRD environments

These steps come from `do-not-run-test.ps1`. Always run as `DCM_DEPLOYER`, the manifest's
`project_owner`.

1. Set the deploying role for the session:

   ```{ps1}
   $ROLE = "DCM_DEPLOYER"
   ```

2. Plan DEV, which is the default target. `--save-output` writes the plan to `out\`, and
   `--verbose` shows more detail:

   ```{ps1}
   snow dcm plan --target DEV --save-output --verbose --role $ROLE
   ```

    Or non-verbose

   ```{ps1}
   snow dcm plan --target DEV --save-output --role $ROLE
   ```

3. Plan TST and PRD:

   ```{ps1}
   snow dcm plan --target TST  --save-output --role $ROLE
   snow dcm plan --target PRD  --save-output --role $ROLE
   ```

4. Review the plan output. For a build test, stop here.

5. For a real build, deploy each target after you've reviewed its plan:

   ```{ps1}
   snow dcm deploy --target DEV --role $ROLE
   snow dcm deploy --target TST --role $ROLE
   snow dcm deploy --target PRD --role $ROLE
   ```

#### 5. Plan and deploy a sandbox

These steps come from `do-not-run-test-sbx.ps1`. A sandbox is a personal copy of the project,
using the `SBX` target and its own project object, with its objects prefixed by the sandbox
name (for example `JMORAN_BRONZE`). Steps 1 to 3 above must already have been run.

1. Set the sandbox name, project, and role for the session. Use upper-case letters, digits,
   and underscores only in the name. Always run as `DCM_DEPLOYER`: the CLI doesn't switch roles
   for you, and running as ACCOUNTADMIN makes ACCOUNTADMIN the owner of the project and of any
   object without an explicit `GRANT OWNERSHIP`.

   ```{ps1}
   $NAME    = "{SBX Developer Name}"
   $PROJECT = "DCM_ADMIN.PROJECTS.DCM_SBX_${NAME}"
   $ROLE    = "DCM_DEPLOYER"
   ```

2. Create the sandbox's DCM project object (safe to re-run), then confirm that it exists and
   that its owner is `DCM_DEPLOYER`:

   ```{ps1}
   snow dcm create $PROJECT --target SBX --if-not-exists --role $ROLE
   snow sql -q "SHOW DCM PROJECTS LIKE 'DCM_SBX_${NAME}' IN SCHEMA DCM_ADMIN.PROJECTS" --role $ROLE
   ```

3. Plan the sandbox and save the results to `out\`. In the output, check that `role_name` is
   `DCM_DEPLOYER` and that there are no `ALTER ROLE ACCOUNTADMIN` entries:

   ```{ps1}
   snow dcm plan $PROJECT --target SBX -D "env_prefix='${NAME}_'" --save-output --role $ROLE
   ```

4. Review the plan. For a build test, stop here.

   ```{ps1}
   Get-Content .\out\plan\plan_result.json
   ```

5. Deploy the sandbox:

   ```{ps1}
   snow dcm deploy $PROJECT --target SBX -D "env_prefix='${NAME}_'" --role $ROLE
   ```

6. Check what was created:

   ```{ps1}
   snow sql -q "SHOW SCHEMAS IN DATABASE ${NAME}_BRONZE" --role $ROLE
   snow sql -q "SHOW DATABASE ROLES IN DATABASE ${NAME}_BRONZE" --role $ROLE
   ```

To test a second sandbox, repeat steps 1 to 6 with a different name (for example
`$NAME = "DRSMITH"`), then confirm that the first sandbox's objects are unchanged. Always pair
the same `$NAME` with the same `$PROJECT`.

7. Tear down the sandbox when you're finished. **This is destructive:** it permanently drops
   the sandbox's databases (such as `${NAME}_BRONZE`) and their data. Check the flags first,
   then purge the managed objects and drop the project object:

   ```{ps1}
   snow dcm purge --help
   snow dcm purge $PROJECT --target SBX --role $ROLE
   snow dcm drop $PROJECT --role $ROLE
   ```

### Scripts outside DCM

Some Snowflake objects can't or shouldn't be managed by DCM. Those scripts live at the project
root, outside `sources/`, so DCM never uploads or runs them:

- `manual/`: one-time scripts run by hand by a DBA, such as creating the account-level SSO
  security integration. These are never part of a CI/CD process.
- `always/`: idempotent scripts run on **every** deployment, for objects DCM can't `DEFINE`
  (for example `CREATE NOTIFICATION INTEGRATION IF NOT EXISTS ...`). Every script must be safe
  to re-run: use `CREATE ... IF NOT EXISTS`, `CREATE OR ALTER`, or `ALTER ... SET`. The name
  follows schemachange's "always" script type, which runs on every deployment.

Scripts in these folders run with `snow sql`, not `snow dcm`, so they don't read
`manifest.yml`. Pass any variables explicitly, for example
`--enable-templating JINJA -D "env_prefix=DEV_"` (see General Notes).

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

```{ps1}
Push-Location .\always
snow sql -f main.sql --enable-templating JINJA -D "env_prefix=DEV_" --role DCM_DEPLOYER
Pop-Location
```

When you add a script, give it the next number and add a matching `!source` line to
`main.sql`. A numbered file that isn't listed in `main.sql` won't run. Variables passed with
`-D` are applied to every sourced file.

Folder names are for organization only; DCM reads every file under `sources/definitions/`
regardless of nesting. Each statement still uses a fully qualified object name, with
`{{ env_prefix }}` in the SQL rather than in folder names. Name folders with the base object
name (`BRONZE`, not `DEV_BRONZE`). Anything outside `sources/` (such as `archive/`) isn't
uploaded or deployed.

