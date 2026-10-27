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

Copy `.env.example` to `.env` and set your Supabase project URL and publishable key. Then run the site:

```powershell
py app.py
```

Open [http://127.0.0.1:5000](http://127.0.0.1:5000).

Use `get_supabase_client()` in `app.py` to initialize the Supabase Python client when a route needs database access. It raises a clear error if configuration is missing. Keep `.env` private and never put secret or service-role keys in templates or browser-side code. Use a publishable key with Row Level Security (RLS) policies for database access.
