# ERP MAGIC-5 web app

Flask application using HTML templates, CSS, Supabase Auth, and a Supabase
PostgreSQL database.

## Requirements

- Python 3.10 or newer
- Access to the team's Supabase project (project URL and publishable key)
- A Supabase account with permission to access the project when applying
  database changes

`requirements.txt` installs Flask, itsdangerous, httpx, python-dotenv, supabase,
and supabase-auth. There is no separate database server or Docker setup for
local development.

## Local setup

From the repository root, enter the application directory and create a virtual
environment:

```powershell
cd my-web-app
py -m venv .venv
.\.venv\Scripts\Activate.ps1
py -m pip install -r requirements.txt
```

Create `my-web-app/.env` locally and set `SUPABASE_URL` and `SUPABASE_KEY`
using values provided by the project administrator. These identify the
Supabase project and its publishable key. Do not use a secret or service-role
key as `SUPABASE_KEY`. The app loads `.env` with `python-dotenv` and exits with
an error if either required value is missing. See the environment-variable
table below for optional settings. `.env.example` lists all supported names
without containing credentials; never commit `.env`.

Start the app from `my-web-app`:

```powershell
py app.py
```

Open [http://127.0.0.1:5000](http://127.0.0.1:5000).

## Database setup and migrations

The app connects directly to the team's Supabase project; it does not use a
local database or Flask/Alembic migration runner. The repository has no
Supabase CLI configuration or automated migration runner; the database
administrator applies the ordered SQL files through the Supabase Dashboard SQL
Editor.

Before using database-backed features, confirm with the database administrator
that the shared project is provisioned with the required schema, Row Level
Security (RLS) policies, and database triggers. The existing setup
documentation described a `profiles` table and a trigger that assigns new
profiles `status = 'pending'`, but the corresponding SQL migration is not
present here.
Do not treat this repository as containing or applying that migration.

The HOPE schema is split into timestamp-ordered migrations:

- `20261106002600_hope_base_tables.sql` creates the ten source operational
  tables plus `audit_log`. It stops on partial/conflicting relations and
  accepts a complete existing HOPE schema only when required source columns
  are present.
- `20261107000000_hope_sample_data.sql` inserts the 928 source sample rows;
  primary-key conflicts are ignored so missing rows can be added safely.
- `20261107000100_hope_audit_support.sql` adds the audit/soft-delete functions,
  columns, triggers, and active-row views. It preserves `audit_user()` exactly
  as supplied in `HopeDB_audit.sql`; S1-DBA-06 owns any later change to it.
- `20261107000200_s1_dba_03_access_control.sql` adds a role reference and
  blocked flag to the existing `profiles` table, plus normalized module,
  rights, and soft-deletable `user_permission` tables. It preserves Supabase
  Auth credentials and the app's existing JSON `user_permissions` contract;
  the legacy `profiles.role` and new role reference stay synchronized.
  It preflights case-insensitive duplicate profile emails before creating a
  unique email index, and backfills the new blocked flag from existing
  blocked/rejected statuses only when the column is first added. It defines
  dedicated stamp and truncate-guard trigger functions for `user_permission`,
  so it does not depend on the source HOPE audit helper functions. Its
  `user_permission` RLS policy allows authenticated users to read their own
  assignments; writes are performed by the trusted server-side service-role
  client. This is a schema/catalogue phase: it does not copy legacy
  `user_permissions.permissions` values into `user_permission` or replace
  existing `hope_can_access` logic or HOPE RLS policies. The catalogue uses
  `add` as the normalized create-action code; the later
  `20261109000000_hope_app_access.sql` helper maps application `create` checks
  to that code while retaining the legacy JSON fallback. A separate, reviewed
  cutover is required to backfill existing assignments and make normalized
  rights authoritative. The base seed contains 30 rights; the task migration
  later adds the guide's eight missing named rights while preserving the
  existing generic module-view rights.
- `20261107000300_s1_dba_04_password_reset_token.sql` adds a private
  `password_reset_token` table referencing `profiles(id)`, with a unique
  lowercase SHA-256 token hash, `reset`/`set_password` purpose, expiry, and
  nullable `used_at`. The current app still uses signed `itsdangerous` reset
  tokens and does not read or write this table; token-table integration is
  future work. When integrated, token consumption must atomically reject
  already-used or expired rows.
- `20261107000400_s1_dba_05_catalogue_seed.sql` reasserts the five modules,
  three default roles, and 30 baseline rights. It contains no member emails,
  passwords, or tokens.
- `20261108000000_s1_dba_06_audit_user.sql` makes `audit_user()` prefer the
  authenticated Supabase JWT user ID, then a transaction-local
  `app.username`, then the literal fallback `system`. Authenticated requests
  already carry the JWT; no application call is needed. The service-role
  rights-change logger continues writing its own explicit `actor_id` fields;
  this migration does not change that separate write contract. Do not set
  `app.username` in a separate pooled API call; any explicit setting must be
  transaction-local to the audited statement.
- `20261108000100_hope_operational_tables_preserve_audit.sql` creates the ten
  HOPE operational tables without changing `audit_log`. Use it when the
  project already has the application's `audit_log` table, whose schema is
  different from the source HOPE audit table. It stops on partial or
  conflicting HOPE operational schemas and enables RLS on the new tables
  without adding client access policies.
- `20261109000000_hope_app_access.sql` adds the app's soft-delete fields,
  active-row views, audit triggers compatible with the existing application
  `audit_log`, and row-level access policies. Approved users need the matching
  module/action permission; administrators have access to all HOPE records.
  Its `hope_can_access` helper reads normalized rights when present, maps
  application `create` checks to catalogue action `add`, and otherwise falls
  back to legacy JSON permissions. It also prevents users from changing their
  own profile role through the public API.
  Run `supabase/tests/s1_dba_06_audit_user.sql` in the SQL Editor after the
  migrations to test add/edit/soft-delete attribution and the fallback; it
  rolls back test rows.
- `20261110000000_s1_dba_07_price_history_rights.sql` adds the normalized
  price-history mutation rights and keeps the catalogue and HOPE access helper
  consistent with the app's effective-date price-history operations.
- `20261122000000_s3_dba_01_employee_current.sql` adds the active-only
  `v_employee_current` view, selecting each employee's latest non-deleted job
  history effective on or before today. It keeps employees with no job history
  and returns NULL job/department fields for them; future changes are ignored.
  Same-date history ties choose the greatest job code deterministically.
  Salary is intentionally excluded for the separate S3-DEV-08 permission.
  `supabase/tests/s3_dba_01_employee_current.sql` tests transfers, a future
  promotion, employees without history, and soft-deleted employees; it rolls
  back all test rows.
- `20261122000100_s3_dba_02_jobhistory_unique_effdate.sql` prevents active
  job-history rows from sharing an employee/effective-date pair, while allowing
  a soft-deleted row to remain archived. It reports existing duplicate pairs
  and preserves all rows; if active duplicates exist, it installs a trigger
  guard and defers the partial unique index until the duplicates have been
  reviewed and resolved. The effective-date and nonnegative-salary checks are
  added `NOT VALID` so pre-existing data cannot block deployment, while new
  writes are checked. After resolving any reported duplicates, rerun the
  migration to create the index.
  `supabase/tests/s3_dba_02_jobhistory_unique_effdate.sql` tests valid inserts,
  duplicate rejection, and rejecting a conflicting soft-delete restore; it
  rolls back all test rows.
- `20261122000200_s3_dba_03_profile_employee_link.sql` adds nullable
  `profiles.empno` referencing the `VARCHAR(5)` employee primary key. Existing
  profiles remain unlinked; no employee assignments are inferred. A unique
  index allows multiple NULL links but limits each employee to one profile.
  `ON DELETE SET NULL` clears only the optional link if an employee is
  physically removed; soft-deleting an employee does not affect the profile
  or its Supabase Auth login. The current profiles policy revokes direct
  authenticated updates, so linking is a privileged/admin database operation.
  `supabase/tests/s3_dba_03_profile_employee_link.sql` verifies a valid link,
  foreign-key and uniqueness rejection, and unchanged profile/Auth identity
  in a scratch/copy database; it rolls back all test rows.
- `20261122000300_s3_dba_04_child_delete_guards.sql` extends the employee
  soft-delete guard to block deletion while a profile is linked, with an
  explicit unlink-first error. Active job history or sales also block employee
  soft-delete; active job history blocks soft-deleting its department or job.
  Soft-deleted history/sales rows do not block these checks. Parent restore is
  allowed; the app's update guard requires delete permission and limits
  restores to administrators. Direct DELETE/TRUNCATE remains blocked by the
  existing hard-delete trigger.
- `20261122000400_s2_bld_01_customers_sprint1.sql` adds the eight guide rights
  absent from the existing 33-row catalogue: Add/Edit/Delete Job History and
  Top Products, Active Employees, All Employees, Employee Job History, and
  Top Sales. The five existing generic module-view rights are retained, so
  the resulting catalogue has 41 rows, of which 36 are the guide's named
  rights. The catalogue comparison found 28 guide rights already present,
  rather than the expected 33; no existing catalogue rows are removed.
  It adds `profiles.is_deleted` and `profiles.stamp`, a security-invoker
  `profiles_active` view, and a database guard against disabling or removing
  the last active Superadmin. New stamps use CREATED/EDITED/DELETED/RESTORED;
  existing stamp values are not rewritten. It also exposes a delete-right
  checked helper that tests `sales_active` before customer soft deletion;
  the existing child trigger remains the race-safe database guard.
  Apply this migration after the earlier access-control, operational-table,
  audit, and S3 migrations through the Supabase Dashboard SQL Editor. The
  repository has no automated migration runner.

  Foreign-key references and physical-delete actions:

  | Parent key | Referencing table/column | ON DELETE |
  | --- | --- | --- |
  | `employee.empno` | `jobhistory.empno` | NO ACTION |
  | `employee.empno` | `sales.empno` | NO ACTION |
  | `employee.empno` | `profiles.empno` | SET NULL |
  | `department.deptcode` | `jobhistory.deptcode` | NO ACTION |
  | `job.jobcode` | `jobhistory.jobcode` | NO ACTION |

  There are no direct department/job columns on employee; job and department
  assignments are represented by job-history rows. Run
  `supabase/tests/s3_dba_04_child_delete_guards.sql` only against a scratch or
  copied database that has an approved admin/superadmin profile with NULL
  `empno`; it lists the live FK and trigger definitions and tests active-child
  blocks, ignored archived children, linked-profile blocks, and restore
  behavior. The test rolls back all fixtures and the temporary profile link.

- `20261122000400_s2_dba_01_customer_product_active.sql` reasserts the
  app-consumed `customer_active` and `product_active` views with
  `security_invoker = true`; both expose the base-table columns but return
  only rows where `is_deleted = false`. These names match `RECORD_MODULES` in
  `app.py`. The migration emits the existing index catalog before and after
  its view definitions so operators can compare their actual schema.
  No new indexes are added: customer search (`custno`, `custname`, `address`,
  `payterm`) and product search (`prodcode`, `description`, `unit`) happen in
  Python after the app retrieves the active rows. The primary keys already
  index `customer.custno` and `product.prodcode`; an index on `is_deleted` or
  the name/description columns would not speed up these current queries.
  Existing base-table foreign keys to Customer/Product are
  `sales.custno`, `salesdetail.prodcode`, and `pricehist.prodcode`; the
  migration does not add indexes to those related tables without measured
  query evidence.
  Run `supabase/tests/s2_dba_01_customer_product_active.sql` only against a
  scratch/copy database as an approved admin/superadmin. It soft-deletes
  temporary Customer and Product rows, verifies they disappear from the
  active views while remaining in the base tables, lists the relevant
  indexes, then rolls back the fixtures.

- `20261122000500_s2_dba_02_price_as_of.sql` adds the reusable scalar function
  `public.price_as_of(p_prodcode VARCHAR, p_as_of_date DATE) RETURNS
  NUMERIC(10,2)`. It returns the latest non-deleted `pricehist.unitprice`
  whose `effdate` is on or before the supplied date, or `NULL` when none
  exists. A future-dated price is therefore ignored until its effective date.
  The existing primary key `(effdate, prodcode)` allows at most one row per
  product/date, making same-date price ties impossible; the test verifies the
  constraint rejects such a duplicate rather than inventing a precedence.
  `public.v_product_current_price` lists active products and their price as of
  `CURRENT_DATE` (NULL when no price is yet effective). The function and view
  are invoker-security objects with access granted to `authenticated`.
  The migration adds `pricehist_prodcode_effdate_idx` on
  `(prodcode, effdate DESC)` only when an equivalent valid B-tree index is
  absent; the primary key's `(effdate, prodcode)` index does not support a
  product-first lookup. Migration notices show the price-history index
  definitions before and after deployment.
  Run `supabase/tests/s2_dba_02_price_as_of.sql` in a scratch/copy database
  as a database owner. It checks no eligible price, the latest prior price,
  ignoring a future price, using it when its date arrives, the current-price
  view, and duplicate-date rejection; fixtures are rolled back.

- `20261122000600_s2_dba_03_validation_constraints.sql` enforces
  `customer.payterm IN ('COD', '30D', '45D')` using `pay_ck` and
  `product.unit IN ('pc', 'ea', 'mtr', 'pkg', 'ltr')` using `unit_ck`.
  The source schema and app already use these sets. The sample-data migration
  has 82 customer rows using `30D` (28), `45D` (30), and `COD` (24), and 57
  product rows using `ea` (37) and `pc` (20); `mtr`, `pkg`, and `ltr` are
  available in the schema/app but not present in the sample rows. The existing
  nullable behavior is preserved.
  The migration briefly locks both tables against concurrent writes, then
  scans every current row, including soft-deleted rows, before adding or
  validating a constraint. If it finds an unapproved non-NULL value, it raises
  an exception listing each affected primary key and value, and leaves the
  constraints unapplied so the records can be reviewed. It stops
  rather than silently duplicating a differently named check on the column.
  Idempotently keeps or validates the existing `pay_ck`/`unit_ck` checks,
  adding only a missing named check when no conflicting check exists.
  The supplied guide is not present in the repository; the Customer wireframe
  notes that guide wording “Net 30” differs from the built `30D` option. The
  allowed labels below follow the existing schema and app options confirmed
  for this task. No live-copy values have been checked in this environment.
  `supabase/tests/s2_dba_03_validation_constraints.sql` inserts every allowed
  value and verifies two invalid examples per column (`NET`, `60D`; `box`,
  `kg`) are rejected by the expected constraints, then rolls back.

- `supabase/tests/s2_dba_04_customer_product_delete_guards.sql` verifies the
  Customer/Product child-record deletion rules without modifying a migration.
  The existing `trg_check_children()` function checks active `sales.custno`
  rows before a Customer soft-delete, and active `salesdetail.prodcode` or
  `pricehist.prodcode` rows before a Product soft-delete. Soft-deleted child
  rows do not block the parent. Parents without children can be soft-deleted
  and restored; active-child restore is not tested because the blocked parent
  never enters the deleted state. `hope_protect_record_update()` continues to
  enforce delete permissions and admin-only restore through the application.
  Direct hard DELETE/TRUNCATE is blocked independently by the existing
  `customer_bd_block` and `product_bd_block` triggers.

  Physical foreign-key delete actions are `NO ACTION`: `sales.custno` points
  to `customer.custno`; `salesdetail.prodcode` and `pricehist.prodcode` point
  to `product.prodcode`. Thus physical parent deletion is not cascaded. The
  test prints the installed FK and trigger catalog, asserts the expected
  references and triggers, then exercises each active/archived child case,
  soft-delete, restore, and blocked direct DELETE in a rollback-only
  transaction. Run it only in a scratch/copy database as a database owner
  with an approved admin/superadmin profile. The SQL test has not been run
  against the live team database in this environment.

- `supabase/seeds/s3_dba_05_hr_demo_data.sql` adds the explicitly synthetic
  HR-only demo departments, jobs, employees, and history rows. It includes a
  promotion, transfer, future-dated job change, separated employee, soft-deleted
  employee, and employee with no history. Placeholder salary figures are
  synthetic and are not real compensation data. Run it after the schema
  migrations as an approved admin/superadmin; fixed demo keys use
  `ON CONFLICT DO NOTHING` and conflicting existing values cause the seed to
  fail and roll back rather than overwrite data. Re-running does not add
  duplicate rows.
  `supabase/tests/s3_dba_05_hr_demo_data.sql` reports demo row counts and
  current-view results, including the intentional behavior that separated
  employees remain visible and soft-deleted employees do not. Run the seed
  twice, then the test script, to verify idempotency and expected HR cases.

- `supabase/seeds/s2_dba_05_customer_product_demo_data.sql` adds clearly
  synthetic Customer, Product, and Price History fixtures with reserved demo
  keys `ZC501`-`ZC504` and `ZP5001`-`ZP5004`. It uses only example addresses,
  fake buyer names, and demo descriptions; no emails or real contacts.
  Payment terms use `COD`, `30D`, and `45D`; product units use `pc`, `mtr`,
  `ea`, and `pkg`, all allowed by S2-DBA-03. Each of the four demo products
  has four effective dates, including `2099-01-01`; the final product and
  its price rows are soft-deleted, as is Customer `ZC504`. Seed inserts use
  `ON CONFLICT DO NOTHING`, then validate exact fixture values/counts and
  abort the transaction on reserved-key conflicts. An approved admin or
  superadmin profile is required for the soft-delete triggers.
  Apply after the active views, `price_as_of`, and validation constraints.
  To verify reruns, apply the seed twice in a scratch database, then run
  `supabase/tests/s2_dba_05_customer_product_demo_data.sql`. The read-only
  script checks exact base/active/deleted counts, four price rows per product,
  current/future price results, and visibility through `customer_active`,
  `product_active`, `pricehist_active`, and `v_product_current_price`.
  The test also prints row counts and example query results; it does not
  modify the database. Database execution is still required to produce live
  output.

- `20261122000700_s2_dba_06_search_indexes.sql` adds partial indexes for
  selective administrator inactive-row filters on Customer and Product. The
  active list fetches return all active rows and substring search is performed
  in Python, so the migration does not add speculative name/description or
  active-row indexes. The throwaway generator and before/after `EXPLAIN`
  queries are in
  `supabase/tests/s2_dba_06_customer_product_index_benchmark.sql`; run them
  only on a scratch database. See
  [the S2-DBA-06 benchmark notes](docs/s2-dba-06-search-index-tuning.md) for
  measured plans and timings.
- `20261122000800_s3_dba_07_department_view_access.sql` aligns the department
  SELECT policy with the existing Human Resources module-view right; department
  add/edit/delete continue to use their resource-specific rights.
- `20261122000900_s4_bld_01_sales_header.sql` adds the Sales list's protected
  customer/salesperson option RPC and a permission-checked sale-creation RPC.
  New transaction numbers use an atomic sequence initialized from existing
  `TR` plus six-digit identifiers; the format is retained and concurrent
  requests cannot allocate the same number. Only active customers and eligible
  employees are offered, and the database rechecks those references when it
  creates the sale. Apply this migration after
  `20261109000000_hope_app_access.sql`. Sales View is required to load choices
  and list transactions; Sales Add is additionally required to create a sale.
- `20261122001000_s4_bld_02_sales_details.sql` adds the protected Sales Details
  read and line-item add/edit/soft-delete operations. Mutations require the
  matching Sales Details Add/Edit/Delete right and an active sale/product.
  Products without a non-deleted price effective on the sale date are excluded
  from selection. The displayed unit price and line total use
  `price_as_of(product, salesdate)`, matching the Sales balance views; the
  existing `salesdetail` schema does not store a separate price snapshot.
  Apply after the Sales header migration, the Sales rights catalogue seed, and
  `20261109000000_hope_app_access.sql` and
  `20261122000500_s2_dba_02_price_as_of.sql`.
- `20261122001100_s4_bld_03_sales_payments.sql` adds the transaction payment
  history and payment-recording RPCs. It requires the Sales balance views and
  HOPE app-access policies. Receipt numbers are assigned atomically in the
  existing `OR` plus six-digit format. Recording a payment requires Sales View
  and Sales Add; the existing balance calculation supports partial and excess
  payments. Payment amount and date are validated, and payment history shows
  the updated total, paid amount, balance, and receipt list. Apply after
  `20261122000800_s4_dba_01_02_sales_balance_views.sql`,
  `20261122000900_s4_bld_01_sales_header.sql`, and
  `20261122001000_s4_bld_02_sales_details.sql`.

Confirm the target project and review existing HOPE relations before applying
SQL. On a project with the application's different `audit_log` table, run
`20261108000100_hope_operational_tables_preserve_audit.sql` followed by the
sample-data migration. To use normalized rights for those tables, apply
`20261107000200_s1_dba_03_access_control.sql` and
`20261107000400_s1_dba_05_catalogue_seed.sql` before
`20261109000000_hope_app_access.sql`; that last migration installs/replaces
the app's named HOPE policies. Do not run
the base-table migration or the source HOPE audit-support migration until
they have been adapted for that audit schema. Otherwise, apply the migrations
in filename order. The base migration does not touch the `profiles` table or
Supabase Auth data used by login and registration. The repository does not
connect to or inspect the live database automatically.

Do not invent or rerun a migration based only on the description above; ask the
database administrator for the authoritative SQL if it is not available.

## Environment variables

| Variable | Required | Purpose |
| --- | --- | --- |
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_KEY` | Yes | Supabase publishable key used by the app |
| `FLASK_SECRET_KEY` | No for local development | Flask session and reset-token signing key; if omitted, a temporary key is generated at startup and sessions do not survive a restart |
| `SUPABASE_SERVICE_ROLE_KEY` | Only for password recovery | Server-only key used for administrator Auth operations |
| `MAIL_SERVER` | Only for password recovery | SMTP server hostname |
| `MAIL_DEFAULT_SENDER` | Only for password recovery unless `MAIL_USERNAME` is set | From address for password reset email |
| `MAIL_PORT` | No | SMTP port; defaults to `587` |
| `MAIL_USERNAME` | No | SMTP login and fallback sender address |
| `MAIL_PASSWORD` | No | SMTP password |
| `MAIL_USE_TLS` | No | Whether to use STARTTLS; defaults to `true` |
| `DATABASE_URL` | For database backup/restore | Direct PostgreSQL URL for the backup source |
| `RESTORE_DATABASE_URL` | For database restore | Direct URL for a separate, pre-created restore target |

Password recovery requires `SUPABASE_SERVICE_ROLE_KEY`, `MAIL_SERVER`, and a
sender address (`MAIL_DEFAULT_SENDER` or `MAIL_USERNAME`). Keep service-role
and SMTP credentials server-side only. Never commit `.env` or put secrets in
templates or browser-side code. `.env` and other environment files are ignored
by Git.

## HR query indexes

No additional HR index is proposed in S3-DBA-06. The HR module has Department,
Job, and Employee lists. They use the shared record-list API, which
fetches rows before applying search and filters in Python, so name indexes
would not accelerate that search. `get_current_profile` and
user-management record lookups filter `profiles.id`, whose primary key is
already indexed; the admin user list filters by role and orders by
`created_at`. Employee, department, and job codes are primary keys; S3-DBA-02
already created the partial unique `jobhistory(empno, effdate) WHERE NOT
is_deleted` index used by the current employee view. Do not add duplicate or
speculative indexes. The same index enforces one active Job History record
per employee and effective date. Measure future HR queries with
`EXPLAIN (ANALYZE, BUFFERS)` before and after any candidate index.

## PostgreSQL backup and restore

The local scripts use PostgreSQL's `pg_dump`, `pg_restore`, and `psql` command
line clients; there is no Docker dependency or migration runner. Install the
PostgreSQL client tools for your operating system and ensure all three
executables are on `PATH`. Python 3.10+ and the project requirements (including
`python-dotenv`) are also required. The Python scripts work on Windows, macOS,
and Linux.

Copy `.env.example` to `.env`. Set `DATABASE_URL` to a direct PostgreSQL
connection URL for the source database, including its database password and
`sslmode=require` for a remote Supabase connection. Set
`RESTORE_DATABASE_URL` to a different, already-created scratch/restore
database. Never use a Supabase publishable key or service-role key as the
database password; keep both URLs out of source control and chat.

From `my-web-app`, create a custom-format backup:

```powershell
py scripts\db_backup.py
```

On macOS/Linux, run `python3 scripts/db_backup.py`. Backups are written to
`my-web-app/backups/`, which is git-ignored; on non-Windows systems the script
sets backup file permissions to owner-only. Keep backup files in protected
storage and remove them when no longer needed.

Restore a listed backup into the separately configured target:

```powershell
py scripts\db_restore.py backups\hope-db-<timestamp>.dump
```

On macOS/Linux, run `python3 scripts/db_restore.py backups/hope-db-<timestamp>.dump`.
The script refuses to restore into the source database and checks whether the
target already contains user objects. For a non-empty target it stops unless
`--confirm-overwrite` is explicitly supplied. That flag allows
`pg_restore --clean` to replace matching objects from the archive; unrelated target
objects remain. The restore runs in one transaction, does not create/drop the
database, and requires a pre-created target and sufficient PostgreSQL
permissions. First verify the target URL and use a scratch database; do not
restore over the shared team database.

After restoring, compare every user-table row count against the still-unchanged
source:

```powershell
py scripts\db_compare.py
```

On macOS/Linux, run `python3 scripts/db_compare.py`. The command prints source
and restored counts for every table and exits with an error if any table is
missing or has a different count.

## Application notes

Registration is available at `/register`. The `POST /api/register` endpoint
accepts JSON or form data with `full_name`, `email`, and `password`. Supabase
Auth creates the account; the database is responsible for setting a new
profile's pending status.

The login flow uses Supabase Auth, which hashes passwords and stores only
access and refresh tokens in the Flask session. A profile with `status =
'rejected'` is treated as blocked. For administrator-created temporary-password
accounts, set the Auth user's `must_set_password` metadata to `true`; the user
is redirected to set a new password on first login.

Keep `.env` private and never put secret or service-role keys in templates or browser-side code. Use a publishable key with Row Level Security (RLS) policies for database access.

User Management is available to admins and superadmins at `/user-management`.
Admins manage regular user accounts and cannot see or change Superadmin
accounts. Superadmins can approve pending users, designate admins, and manage
other accounts; the last Superadmin cannot be removed or demoted, and the last
active Superadmin cannot be blocked.
Removing an account soft-deletes its profile and can be restored. New stamps
are recorded with the guide's action words and shown without rewriting legacy
ADD/EDIT/DELETE/RESTORE values.

Administrators can assign the guide's 36 named rights from the grouped Rights
dialog, including per-module selection and All/None controls. Existing generic
module-view rights remain available for navigation. Changes are stored in the
normalized `user_permission` assignments and the `right_catalog`, with the
legacy JSON `user_permissions` record kept synchronized for compatibility.
Admins and superadmins have implicit full access to all five modules. Apply
`20261107000200_s1_dba_03_access_control.sql` followed by
`20261107000400_s1_dba_05_catalogue_seed.sql` and the later task migration
after confirming the target project's profile schema; the app also requires compatible
`user_permissions` and `audit_log` tables. Rights changes are recorded in
`audit_log`; verify the deployed tables and policies if the app reports that
rights need database setup.

The base access-control and catalogue-seed migrations define 30 rights; the
separate price-history migration adds three price mutation rights, and the
S2-BLD-01 migration adds the eight guide rights found missing in the checked-in
catalogue.

Departments, Jobs, and Employees are available at `/human-resources`,
`/human-resources/jobs`, and `/human-resources/employees`; Customers and
Products are at `/customers` and `/products`. The HR lists share a record list
that provides search and administrator active/inactive/all filters.
Employees can additionally be filtered by gender and employment status;
Current includes employees without a separation date or with a separation
date on/after today's Asia/Manila date. Employee creation and editing use the
employee Add/Edit rights; employee numbers cannot be changed after creation.
Employee separation dates remain editable. Employee deletion uses the
employee Delete right and is soft-delete only; linked profiles must first be
unlinked, and active Job History/Sales records prevent deletion. Only
administrators can restore inactive Employees.
Employee profiles are available from the employee list and show personal
details with a chronological Job Timeline when the user has Job History View.
Employees with Job History View access have a per-employee Job History page
for effective-dated job/department promotions or transfers and salary. Job
History Add/Edit/Delete rights control those operations, which soft-delete
history records and reject duplicate active effective dates.
Department and Job lists provide permission-checked create/edit/soft-delete
operations and administrator-only restore. Department and Job mutations use
their resource-specific HR rights; deletion is refused while active
job-history records are linked. Customer deletion is refused while
`sales_active` contains a linked sale. Admin/Superadmin rows show
Active/Inactive and a stamp; Users see active rows only. The Department form
maps to `deptcode` and `deptname`; the Job form maps to `jobcode` and
`jobdesc`. The Customer form maps to `custno`, `custname`, `address`, and
`payterm`; the Product form maps to `prodcode`, `description`, and `unit`.
Product rows link to Price History, which supports dated price creation,
editing (including the effective date), soft deletion, and administrator
restore. The Products list displays the latest non-deleted price effective on
the current Asia/Manila business date; products without a price effective yet
show a dash. Apply
`20261110000000_s1_dba_07_price_history_rights.sql` after the access-control
and HOPE app-access migrations, then apply
`20261120000000_s1_dba_08_current_product_price.sql`. Product View controls
access to Price History; separate Price History Add/Edit/Delete rights control
mutations. Assign those rights through User Management; the migration does not
assign them automatically.
CRUD requests use the authenticated Supabase client so RLS remains in effect.
Employee, Department, and Job viewing use the Human Resources View right. Apply
`20261122000800_s3_dba_07_department_view_access.sql` after
`20261109000000_hope_app_access.sql` so their RLS policies match that view
permission. If the active view, table access, or policies are unavailable,
the UI reports that database setup is needed. Sales View users can search the
Sales list; users with Sales Add can create a sale using active Customer and
Salesperson choices. The transaction number is assigned by the database when
the header is saved. Apply
`20261122000900_s4_bld_01_sales_header.sql` before using Sales; Reports still
shows a Coming soon page. Apply
`20261122001000_s4_bld_02_sales_details.sql` to enable Sales line items; the
separate Sales Details View/Add/Edit/Delete rights govern detail visibility and
mutations. Assign those rights through User Management. Apply
`20261122001100_s4_bld_03_sales_payments.sql` to enable payment recording
against active transactions; the Sales Add right controls payment entry.

The new `blocked` column is not yet consulted by the login handler; existing
`status` checks remain in effect. The access-control migration leaves existing
`user_permissions` and `audit_log` tables untouched, so verify their deployed
columns and policies against the application contract.

Password recovery is available at `/forgot-password`. Reset links use an
`itsdangerous` signed token that expires after one hour; they are not yet
persisted in `password_reset_token`. To find expired and consumed database
tokens:

```sql
SELECT id, user_id, purpose, expires_at, used_at, created_at
FROM public.password_reset_token
WHERE used_at IS NOT NULL OR expires_at <= now()
ORDER BY expires_at;
```

The signed-in home page and sidebar expose only modules with View permission
for regular users. Admins and superadmins see all modules. Module workspaces
are server-guarded at `/customers`, `/products`, `/human-resources`, `/sales`,
and `/reports`. Use `GET /api/modules/<module>/<action>` for a server-side
permission check; API module slugs are `customer`, `product`,
`human-resources`, `sales`, and `reports`.
