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
  It adds a case-insensitive unique email index and backfills the new blocked
  flag from existing blocked/rejected statuses only when the column is first
  added. The catalogue includes the 30 rights documented in the checked-in
  design notes; six rights unspecified by the sprint plan remain deferred.
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
  It also prevents users from changing their own profile role through the
  public API.
  Run `supabase/tests/s1_dba_06_audit_user.sql` in the SQL Editor after the
  migrations to test add/edit/soft-delete attribution and the fallback; it
  rolls back test rows.

Confirm the target project and review existing HOPE relations before applying
SQL. On a project with the application's different `audit_log` table, run
`20261108000100_hope_operational_tables_preserve_audit.sql` followed by the
sample-data migration, then `20261109000000_hope_app_access.sql`. Do not run
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
Product, Human Resources, Sales, and Reports from the Rights dialog. Admins and
superadmins have implicit full access to all five modules. User rights are read
from the active `user_permission` assignments and the `right_catalog`, with the
legacy JSON `user_permissions` record kept synchronized for compatibility.
Rights changes are recorded in `audit_log`; verify the deployed tables and
policies if the app reports that rights need database setup.

The checked-in catalogue currently has 30 rights. It does not yet include
Product Price Add/Edit/Delete; Job History Add/Edit/Delete; or the Reports
rights Top Products, Active Employees, All Employees, Employee Job History,
and Top Sales. These require a DB Admin catalogue update; the app does not edit
the database schema or seed data.

Customers are available at `/customers`. The shared record list reads
`customer_active` for active rows and uses the existing `is_deleted`, `stamp`,
and audit triggers for administrator status, restore, and record history.
CRUD requests use the authenticated Supabase client so RLS remains in effect.
If the active view, table access, or policies are unavailable, the UI reports
that database setup is needed. Products, Human Resources, Sales, and Reports
currently show a Coming soon page.

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
