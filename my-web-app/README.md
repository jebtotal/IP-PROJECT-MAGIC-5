# ERP MAGIC-5 web app

A Flask website starter using HTML templates, CSS, and Supabase.

## Requirements

- Python 3.10 or newer
- A Supabase project

## Getting started

From the `my-web-app` directory, create and activate a virtual environment:

```powershell
py -m venv .venv
.\.venv\Scripts\Activate.ps1
```

Install dependencies:

```powershell
py -m pip install -r requirements.txt
```

Create a `.env` file and set your Supabase project URL and publishable key:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-publishable-key
FLASK_SECRET_KEY=optional-long-random-secret
```

Apply the SQL migration in `supabase/migrations` to your Supabase project before accepting registrations. It creates a `profiles` table with Row Level Security and a database trigger that creates every new profile with `status = 'pending'`.

Then run the site:

```powershell
py app.py
```

Open [http://127.0.0.1:5000](http://127.0.0.1:5000).

Open [http://127.0.0.1:5000/register](http://127.0.0.1:5000/register) to submit a registration. The `POST /api/register` endpoint accepts JSON or form data with `full_name`, `email`, and `password`. Supabase Auth creates the account; the database trigger ensures the pending status is set by the database rather than trusted from the form.

The login flow uses Supabase Auth, which hashes passwords and stores only access
and refresh tokens in the Flask session. A profile with `status = 'rejected'`
is treated as blocked by the app. For administrator-created temporary-password
accounts, set the Auth user's `must_set_password` metadata to `true`; the user
is redirected to set a new password on first login. `FLASK_SECRET_KEY` is
optional for local development; if omitted, sessions reset when the app restarts.

Apply the user roles migration before opening `/user-management`. Admins can add,
edit, block, and unblock regular users. The API filters to `role = 'user'`, so
superadmin accounts are not exposed in the user list.

Password recovery is available at `/forgot-password`. Configure
`SUPABASE_SERVICE_ROLE_KEY` on the server, plus `MAIL_SERVER`,
`MAIL_DEFAULT_SENDER`, and the optional `MAIL_PORT`, `MAIL_USERNAME`,
`MAIL_PASSWORD`, and `MAIL_USE_TLS` settings. Reset links use an
`itsdangerous` signed token that expires after one hour. Never expose the
service-role key in browser code or commit it to `.env`.

Keep `.env` private and never put secret or service-role keys in templates or browser-side code. Use a publishable key with Row Level Security (RLS) policies for database access.
