import os
from functools import lru_cache

from dotenv import load_dotenv
from flask import Flask, render_template
from supabase import Client, create_client

load_dotenv()

app = Flask(__name__)


@lru_cache(maxsize=1)
def get_supabase_client() -> Client:
    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_KEY")

    if not url or not key:
        raise RuntimeError(
            "Missing Supabase configuration. Set SUPABASE_URL and SUPABASE_KEY in .env."
        )

    return create_client(url, key)


@app.get("/")
def home():
    return render_template("index.html")


if __name__ == "__main__":
    app.run(debug=True)
