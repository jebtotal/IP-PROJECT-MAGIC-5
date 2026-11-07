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

Copy `.env.example` to `.env` and replace the placeholders with values provided
by the project administrator:

```powershell
Copy-Item .env.example .env
```

At minimum, set `SUPABASE_URL` and `SUPABASE_KEY`. These identify the Supabase
project and its publishable key. Do not use a secret or service-role key as
`SUPABASE_KEY`. The app loads `.env` with `python-dotenv` and exits with an
error if either required value is missing.

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

Apply the files in filename order, only after confirming the target project and
reviewing existing HOPE relations. The base migration does not touch the
`profiles` table or Supabase Auth data used by login and registration. The
repository does not connect to or inspect the live database automatically.

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
templates or browser-side code. `.env` is ignored by Git; use
`.env.example` only for placeholders.

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
are stored in `user_permissions` and recorded in `audit_log`. Apply the
corresponding Supabase schema for those tables after the profiles migration.

Password recovery is available at `/forgot-password`. Reset links use an
`itsdangerous` signed token that expires after one hour.

The signed-in home page exposes only modules with View permission. Use
`GET /api/modules/<module>/<action>` for a server-side permission check before
module actions; module slugs are `customer`, `product`, `human-resources`,
`sales`, and `reports`.
