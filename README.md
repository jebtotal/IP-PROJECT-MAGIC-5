# Hope, Inc. ERP — MAGIC-5

An Information Management group project building a small-business ERP with
Flask, Supabase Auth, and a Supabase PostgreSQL database.

The application brings customer, product, human-resources, sales, reporting,
and user-access workflows together behind role- and permission-aware screens.
It is a course project under active development, not a production-hardened ERP.

## Features

- **Authentication:** registration, login, account approval, first-login
  password setup, and password recovery.
- **Customers:** customer records with payment terms, search, soft deletion,
  and administrator restore.
- **Products:** product records and effective-dated price history; the
  current-price display uses the latest price effective for the business date.
- **Human Resources:** employees, departments, jobs, employee profiles, and
  effective-dated job history.
- **Sales:** auto-numbered sale headers, customer/employee selection, product
  detail lines priced for the sale date, payments, totals, and outstanding
  balances.
- **Reports:** Top Customers, Product Master List, Top Products, Active
  Employees, All Employees, Employee Job History, and Top Sales. Report access
  is assigned individually; reports can be printed or saved through the
  browser's print dialog.
- **User Management:** administrators manage user accounts and assign
  module/action rights; Superadmins manage administrator access.
- **Audit and access controls:** permission-checked operations, database
  row-level security, soft-delete status, and system-generated stamps.

Administrators and Superadmins have broad access. Regular Users see only
modules and actions granted to them. Database policies remain the enforcement
boundary; hiding a button is not a substitute for server-side authorization.

## Run locally on Windows

Requirements: Python 3.10 or newer and access to the project's Supabase
instance. There is no local database or Docker setup for the web app.

From the repository root, open PowerShell and run:

```powershell
Set-Location .\my-web-app
py -m venv .venv
.\.venv\Scripts\Activate.ps1
py -m pip install -r requirements.txt
Copy-Item .env.example .env
```

Edit the `.env` file you just created inside `my-web-app` and set at least:

```dotenv
SUPABASE_URL=your-project-url
SUPABASE_KEY=your-publishable-key
FLASK_SECRET_KEY=your-generated-private-value
```

Generate a private session key in PowerShell with:

```powershell
py -c "import secrets; print(secrets.token_urlsafe(32))"
```

Paste the generated value into `FLASK_SECRET_KEY`. Use the Supabase
**publishable key** for `SUPABASE_KEY`, never the service-role key. The
server-side `SUPABASE_SERVICE_ROLE_KEY` is also needed for report queries,
Sales reference/price/balance reads, and certain administrator operations.
Password recovery additionally needs the `MAIL_*` SMTP settings. Keep all
credentials private; never commit `.env` or place secret keys in browser code.

Start the app from `my-web-app`:

```powershell
py app.py
```

Open [http://127.0.0.1:5000](http://127.0.0.1:5000). Stop the development
server with **Ctrl+C** in the terminal.

If PowerShell blocks virtual-environment activation, run the environment's
Python directly instead:

```powershell
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe app.py
```

## Supabase setup

The app connects to the configured Supabase project. It does not apply schema
migrations automatically. Before using database-backed features, confirm that
the database has the required tables, views, triggers, grants, and row-level
security policies.

Sales totals and balances rely on the existing sales-balance views migration;
effective-dated pricing relies on the existing price-as-of migration. Database
administrators should review the ordered migration and compatibility notes in
[the web-app README](./my-web-app/README.md) before applying SQL. Do not apply
migrations to the shared database without the database administrator's review.

## Tests

From `my-web-app`, run:

```powershell
py -m unittest discover -s tests -v
```

## Project documentation

The [web-app README](./my-web-app/README.md) contains detailed local
configuration, Supabase migration, environment-variable, and database
backup/restore notes.

## Team

| Role | Member |
| --- | --- |
| Scrum Master | Jahreb Total |
| Developer | Dan Weslet Cabellero |
| DB Admin | Sedric Pineda |
| UI/UX Designer | Bea Bocobo |
| Tester | Kent Genesis Makiramdam |

## Purpose

This project applies information-management, database-integration, software
development, and team-collaboration concepts by building an integrated ERP
application.
