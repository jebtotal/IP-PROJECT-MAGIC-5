

import os
import secrets
from collections.abc import Mapping

import httpx
from dotenv import load_dotenv
from flask import Flask, jsonify, redirect, render_template, request, session, url_for
from supabase import create_client
from supabase_auth.errors import AuthError, AuthRetryableError

load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_KEY")

if not url or not key:
    raise RuntimeError("SUPABASE_URL and SUPABASE_KEY must be set in .env")

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY") or secrets.token_urlsafe(32)


def get_supabase_client():
    return create_client(url, key)


def get_authenticated_client():
    access_token = session.get("access_token")
    refresh_token = session.get("refresh_token")
    if not access_token or not refresh_token:
        return None

    client = get_supabase_client()
    try:
        client.auth.set_session(access_token, refresh_token)
    except AuthError:
        session.clear()
        return None
    return client


def get_current_profile(client):
    user = client.auth.get_user().user
    if user is None:
        return None
    response = (
        client.table("profiles")
        .select("id, email, full_name, status")
        .eq("id", user.id)
        .single()
        .execute()
    )
    return response.data


def must_set_password(user):
    metadata = user.user_metadata or {}
    return metadata.get("must_set_password") is True

@app.get("/")
def index():
    client = get_authenticated_client()
    if client is None:
        return render_template("index.html")

    profile = get_current_profile(client)
    if profile is None:
        session.clear()
        return redirect(url_for("login"))
    if must_set_password(client.auth.get_user().user):
        return redirect(url_for("set_password"))
    return render_template("index.html", profile=profile)


@app.get("/login")
def login():
    if get_authenticated_client() is not None:
        return redirect(url_for("index"))
    return render_template("login.html")


@app.post("/api/login")
def api_login():
    payload = request.get_json(silent=True) if request.is_json else request.form
    if not isinstance(payload, Mapping):
        return jsonify(error="Submit login details as JSON or form data."), 400

    email = payload.get("email")
    password = payload.get("password")
    if not all(isinstance(value, str) for value in (email, password)):
        return jsonify(error="Email and password are required."), 400

    email = email.strip().lower()
    if not email or not password:
        return jsonify(error="Email and password are required."), 400

    client = get_supabase_client()
    try:
        response = client.auth.sign_in_with_password(
            {"email": email, "password": password}
        )
        if response.session is None or response.user is None:
            return jsonify(error="Login could not be completed."), 401

        client.auth.set_session(
            response.session.access_token, response.session.refresh_token
        )
        profile = get_current_profile(client)
        if profile is None:
            client.auth.sign_out()
            return jsonify(error="Your account profile is unavailable."), 403
        if profile["status"] in {"blocked", "rejected"}:
            client.auth.sign_out()
            return jsonify(error="This account is blocked. Contact an administrator."), 403
    except AuthRetryableError:
        app.logger.exception("Supabase login service is temporarily unavailable")
        return jsonify(error="Login service is unavailable. Please try again later."), 502
    except (AuthError, httpx.HTTPError):
        return jsonify(error="Invalid email or password."), 401

    session.clear()
    session["access_token"] = response.session.access_token
    session["refresh_token"] = response.session.refresh_token
    session["user_id"] = response.user.id
    require_password = must_set_password(response.user)
    return jsonify(
        message="Login successful.",
        must_set_password=require_password,
        redirect=url_for("set_password" if require_password else "index"),
    )


@app.post("/api/logout")
def api_logout():
    client = get_authenticated_client()
    if client is not None:
        try:
            client.auth.sign_out()
        except (AuthError, httpx.HTTPError):
            app.logger.exception("Supabase logout failed")
    session.clear()
    return jsonify(message="Logged out.")


@app.route("/logout", methods=["GET", "POST"])
def logout():
    api_logout()
    return redirect(url_for("index"))


@app.get("/set-password")
def set_password():
    client = get_authenticated_client()
    if client is None:
        return redirect(url_for("login"))
    profile = get_current_profile(client)
    if profile is None:
        session.clear()
        return redirect(url_for("login"))
    if not must_set_password(client.auth.get_user().user):
        return redirect(url_for("index"))
    return render_template("set_password.html")


@app.post("/api/set-password")
def api_set_password():
    client = get_authenticated_client()
    if client is None:
        return jsonify(error="You must be logged in."), 401

    payload = request.get_json(silent=True) if request.is_json else request.form
    password = payload.get("password") if isinstance(payload, Mapping) else None
    confirmation = (
        payload.get("confirmation") if isinstance(payload, Mapping) else None
    )
    if not isinstance(password, str) or not isinstance(confirmation, str):
        return jsonify(error="Password and confirmation are required."), 400
    if len(password) < 8:
        return jsonify(error="Password must be at least 8 characters."), 400
    if password != confirmation:
        return jsonify(error="Passwords do not match."), 400

    try:
        client.auth.update_user(
            {"password": password, "data": {"must_set_password": False}}
        )
        user = client.auth.get_user().user
        if user is None:
            return jsonify(error="Your session is no longer valid."), 401
    except AuthRetryableError:
        app.logger.exception("Supabase password update service is temporarily unavailable")
        return jsonify(error="Password service is unavailable. Please try again later."), 502
    except (AuthError, httpx.HTTPError):
        app.logger.exception("Supabase password update failed")
        return jsonify(error="Password could not be updated. Please try again."), 502

    return jsonify(message="Password updated.", redirect=url_for("index"))


@app.get("/register")
def register():
    return render_template("register.html")

@app.post("/api/register")
def api_register():
    payload = request.get_json(silent=True) if request.is_json else request.form
    if not isinstance(payload, Mapping):
        return jsonify(error="Submit registration details as JSON or form data."), 400

    full_name = payload.get("full_name")
    email = payload.get("email")
    password = payload.get("password")

    if not all(isinstance(value, str) for value in (full_name, email, password)):
        return jsonify(error="Name, email, and password are required."), 400

    full_name = full_name.strip()
    email = email.strip().lower()
    if not full_name or len(full_name) > 120:
        return jsonify(error="Enter a name between 1 and 120 characters."), 400
    if not email or "@" not in email or any(character.isspace() for character in email):
        return jsonify(error="Enter a valid email address."), 400
    if len(password) < 8:
        return jsonify(error="Password must be at least 8 characters."), 400

    try:
        response = get_supabase_client().auth.sign_up(
            {
                "email": email,
                "password": password,
                "options": {
                    "data": {"full_name": full_name, "must_set_password": False}
                },
            }
        )
        """pwede nyo toh baguhin yung sinasabi netong supabase. kung trip nyo lang"""
    except AuthRetryableError:
        app.logger.exception("Supabase registration service is temporarily unavailable")
        return (
            jsonify(error="Registration service is unavailable. Please try again later."),
            502,
        )
    except AuthError as error:
        if "rate limit" in str(error).lower():
            return (
                jsonify(
                    error=(
                        "Supabase email rate limit reached. Wait before trying again, "
                        "or disable email confirmation in Supabase Auth settings."
                    )
                ),
                429,
            )
        app.logger.exception("Supabase rejected registration")
        return (
            jsonify(
                error="Supabase rejected the registration. Check the details and try again."
            ),
            400,
        )
    except httpx.HTTPError:
        app.logger.exception("Supabase registration request failed")
        return (
            jsonify(error="Registration service is unavailable. Please try again later."),
            502,
        )

    if response.user is None:
        app.logger.error("Supabase signup returned no user for a registration request")
        return jsonify(error="Registration could not be completed. Please try again."), 502

    return (
        jsonify(
            message="Registration submitted. Your account is pending approval.",
            status="pending",
        ),
        201,
    )


if __name__ == "__main__":
    app.run(debug=os.getenv("FLASK_DEBUG", "").lower() == "true")
