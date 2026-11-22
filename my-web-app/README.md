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
table below for optional settings. Never commit `.env`.

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
  rights authoritative. The catalogue includes the 30 rights documented in
  the checked-in design notes; six rights unspecified by the sprint plan
  remain deferred.
- `20261107000300_s1_dba_04_password_reset_token.sql` adds a private
  `password_reset_token` table referencing `profiles(id)`, with a unique
  lowercase SHA-256 token hash, `reset`/`set_password` purpose, expiry, and
  nullable `used_at`. The current app still uses signed `itsdangerous` reset
  tokens and does not read or write this table; token-table integration is
  future work. When integrated, token consumption must atomically reject
  already-used or expired rows.
- `20261107000400_s1_dba_05_catalogue_seed.sql` reasserts the five modules,
  three default roles, and 30 rights currently documented in the checked-in
  design notes. The six unspecified rights and five superadmin account records
  are deferred; this seed contains no member emails, passwords, or tokens.
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

Password recovery requires `SUPABASE_SERVICE_ROLE_KEY`, `MAIL_SERVER`, and a
sender address (`MAIL_DEFAULT_SENDER` or `MAIL_USERNAME`). Keep service-role
and SMTP credentials server-side only. Never commit `.env` or put secrets in
templates or browser-side code. `.env` and other environment files are ignored
by Git.

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
Admins manage regular users only. Superadmins can approve pending users and
designate admins; superadmin accounts cannot be blocked, demoted, or removed
through the application.

Administrators can assign View, Create, Edit, and Delete rights for Customer,
Product, Human Resources, Sales, and Reports from the Rights dialog. Changes
are stored in the normalized `user_permission` assignments and the
`right_catalog`, with the legacy JSON `user_permissions` record kept
synchronized for compatibility. Admins and superadmins have implicit full
access to all five modules. Apply
`20261107000200_s1_dba_03_access_control.sql` followed by
`20261107000400_s1_dba_05_catalogue_seed.sql` after confirming the target
project's profile schema; the app also requires compatible
`user_permissions` and `audit_log` tables. Rights changes are recorded in
`audit_log`; verify the deployed tables and policies if the app reports that
rights need database setup.

The base access-control and catalogue-seed migrations define 30 rights; the
separate price-history migration adds its three mutation rights. Job History
Add/Edit/Delete and the Reports rights Top Products, Active Employees, All
Employees, Employee Job History, and Top Sales remain deferred; these require
a future DB Admin catalogue update.

Customers and Products are available at `/customers` and `/products`. Their
shared record list provides search, administrator active/inactive/all filters,
permission-checked create/edit/soft-delete operations, and administrator-only
restore. The Customer form maps to `custno`, `custname`, `address`, and
`payterm`; the Product form maps to `prodcode`, `description`, and `unit`.
Product rows link to Price History, which supports dated price creation,
editing (including the effective date), soft deletion, and administrator
restore. Product View controls access to the history; the separate Price
History Add/Edit/Delete rights control mutations. Apply
`20261110000000_s1_dba_07_price_history_rights.sql` after the access-control
and HOPE app-access migrations, then assign the new rights through User
Management. No rights are automatically assigned by that migration.
CRUD requests use the authenticated Supabase client so RLS remains in effect.
If the active view, table access, or policies are unavailable, the UI reports
that database setup is needed. Human Resources, Sales, and Reports currently
show a Coming soon page.

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
