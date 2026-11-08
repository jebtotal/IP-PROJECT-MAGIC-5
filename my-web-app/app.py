

import os
import secrets
import smtplib
from email.message import EmailMessage
from collections.abc import Mapping

import httpx
from dotenv import load_dotenv
from flask import Flask, jsonify, redirect, render_template, request, session, url_for
from itsdangerous import BadSignature, SignatureExpired, URLSafeTimedSerializer
from postgrest.exceptions import APIError
from supabase import create_client
from supabase_auth.errors import AuthError, AuthRetryableError

load_dotenv()

url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_KEY")
service_role_key = os.getenv("SUPABASE_SERVICE_ROLE_KEY")

if not url or not key:
    raise RuntimeError("SUPABASE_URL and SUPABASE_KEY must be set in .env")

app = Flask(__name__)
app.secret_key = os.getenv("FLASK_SECRET_KEY") or secrets.token_urlsafe(32)
reset_token_serializer = URLSafeTimedSerializer(app.secret_key)
RESET_TOKEN_MAX_AGE = 3600
RIGHTS_MODULES = (
    "Customer",
    "Product",
    "Human Resources",
    "Sales",
    "Reports",
)
RIGHTS_ACTIONS = ("view", "create", "edit", "delete")
MODULE_SLUGS = {
    "Customer": "customer",
    "Product": "product",
    "Human Resources": "human-resources",
    "Sales": "sales",
    "Reports": "reports",
}
WORKSPACE_MODULES = (
    {
        "name": "Customer",
        "slug": "customers",
        "permission": "Customer",
        "icon": "fa-address-book",
    },
    {
        "name": "Product",
        "slug": "products",
        "permission": "Product",
        "icon": "fa-boxes-stacked",
    },
    {
        "name": "Human Resources",
        "slug": "human-resources",
        "permission": "Human Resources",
        "icon": "fa-id-card",
    },
    {"name": "Sales", "slug": "sales", "permission": "Sales", "icon": "fa-cart-shopping"},
    {"name": "Reports", "slug": "reports", "permission": "Reports", "icon": "fa-chart-column"},
)
RECORD_MODULES = {
    "customers": {
        "name": "Customers",
        "singular": "Customer",
        "permission": "Customer",
        "table": "customer",
        "active_view": "customer_active",
        "key": "custno",
        "key_field": "custNo",
        "display_field": "custName",
        "fields": (
            {
                "name": "custNo",
                "column": "custno",
                "label": "Customer No",
                "maxlength": 5,
                "required": True,
            },
            {
                "name": "custName",
                "column": "custname",
                "label": "Customer Name",
                "maxlength": 20,
                "required": True,
            },
            {
                "name": "address",
                "column": "address",
                "label": "Address",
                "maxlength": 50,
                "required": False,
            },
            {
                "name": "payTerms",
                "column": "payterm",
                "label": "Payment Terms",
                "maxlength": 3,
                "required": True,
                "options": ("COD", "30D", "45D"),
            },
        ),
    },
}


def get_supabase_client():
    return create_client(url, key)


def get_admin_client():
    if not service_role_key:
        raise RuntimeError("SUPABASE_SERVICE_ROLE_KEY must be set for administration")
    return create_client(url, service_role_key)


def send_password_reset_email(email, reset_url):
    server = os.getenv("MAIL_SERVER")
    username = os.getenv("MAIL_USERNAME")
    password = os.getenv("MAIL_PASSWORD")
    sender = os.getenv("MAIL_DEFAULT_SENDER") or username
    if not server or not sender:
        raise RuntimeError("MAIL_SERVER and MAIL_DEFAULT_SENDER must be configured")

    message = EmailMessage()
    message["Subject"] = "Reset your ERP MAGIC-5 password"
    message["From"] = sender
    message["To"] = email
    message.set_content(
        "Use this link to reset your ERP MAGIC-5 password. "
        f"The link expires in one hour:\n\n{reset_url}\n"
    )

    port = int(os.getenv("MAIL_PORT", "587"))
    use_tls = os.getenv("MAIL_USE_TLS", "true").lower() == "true"
    with smtplib.SMTP(server, port, timeout=15) as smtp:
        if use_tls:
            smtp.starttls()
        if username and password:
            smtp.login(username, password)
        smtp.send_message(message)


def get_reset_user(email):
    users = get_admin_client().auth.admin.list_users()
    return next((user for user in users if user.email == email), None)


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
        .select("id, email, full_name, status, role, created_at")
        .eq("id", user.id)
        .single()
        .execute()
    )
    return response.data


def get_management_profile():
    client = get_authenticated_client()
    if client is None:
        return None, None
    profile = get_current_profile(client)
    if profile is None or profile.get("role") not in {"admin", "superadmin"}:
        return client, None
    return client, profile


def get_user_payload():
    payload = request.get_json(silent=True) if request.is_json else request.form
    return payload if isinstance(payload, Mapping) else None


def empty_permissions():
    return {
        module: {action: False for action in RIGHTS_ACTIONS}
        for module in RIGHTS_MODULES
    }


def validate_permissions(value):
    if not isinstance(value, Mapping) or set(value) != set(RIGHTS_MODULES):
        return None
    permissions = empty_permissions()
    for module in RIGHTS_MODULES:
        module_permissions = value[module]
        if not isinstance(module_permissions, Mapping) or set(module_permissions) != set(
            RIGHTS_ACTIONS
        ):
            return None
        if not all(isinstance(module_permissions[action], bool) for action in RIGHTS_ACTIONS):
            return None
        permissions[module] = dict(module_permissions)
    return permissions


def write_audit_log(admin_client, actor_id, target_user_id, old_rights, new_rights):
    admin_client.table("audit_log").insert(
        {
            "table_name": "user_permission",
            "action": "EDIT",
            "record_key": str(target_user_id),
            "old_values": {"rights": sorted(old_rights)},
            "new_values": {"rights": sorted(new_rights)},
            "action_by": str(actor_id),
        }
    ).execute()


def get_permissions_for_user(client, profile):
    if profile["role"] in {"admin", "superadmin"}:
        return {
            module: {action: True for action in RIGHTS_ACTIONS}
            for module in RIGHTS_MODULES
        }
    try:
        normalized = (
            client.table("user_permission")
            .select("right_code")
            .eq("user_id", profile["id"])
            .eq("is_deleted", False)
            .execute()
        )
    except APIError as error:
        if error.code not in {"PGRST205", "42P01"}:
            raise
    else:
        if normalized is not None and normalized.data:
            catalog = client.table("right_catalog").select(
                "right_code, module_code, action"
            ).execute()
            return rights_to_permissions(catalog.data, normalized.data)

    response = (
        client.table("user_permissions")
        .select("permissions")
        .eq("user_id", profile["id"])
        .maybe_single()
        .execute()
    )
    response_data = response.data if response is not None else None
    return (
        validate_permissions(response_data["permissions"])
        if response_data
        else empty_permissions()
    )


def rights_to_permissions(catalog, assignments):
    module_names = {
        "customers": "Customer",
        "products": "Product",
        "hr": "Human Resources",
        "sales": "Sales",
        "reports": "Reports",
    }
    permissions = empty_permissions()
    granted = {row["right_code"] for row in assignments}
    for right in catalog:
        if right["right_code"] not in granted:
            continue
        module = module_names.get(right["module_code"])
        if module is None:
            continue
        action = right["action"]
        permissions[module][action if action == "view" else {
            "add": "create",
            "edit": "edit",
            "delete": "delete",
        }[action]] = True
    return permissions


def permissions_to_rights(catalog, permissions):
    selected = []
    for right in catalog:
        module = {
            "customers": "Customer",
            "products": "Product",
            "hr": "Human Resources",
            "sales": "Sales",
            "reports": "Reports",
        }.get(right["module_code"])
        if module is None:
            continue
        action = right["action"]
        permission_action = "create" if action == "add" else action
        if permissions[module].get(permission_action) is True:
            selected.append(right["right_code"])
    return selected


def has_permission(permissions, module, action):
    return (
        module in RIGHTS_MODULES
        and action in RIGHTS_ACTIONS
        and permissions.get(module, {}).get(action) is True
    )


def module_cards(permissions):
    return [
        {
            "name": module,
            "slug": next(item["slug"] for item in WORKSPACE_MODULES if item["permission"] == module),
            "api_slug": MODULE_SLUGS[module],
            "icon": next(item["icon"] for item in WORKSPACE_MODULES if item["permission"] == module),
            "actions": permissions[module],
        }
        for module in RIGHTS_MODULES
        if has_permission(permissions, module, "view")
    ]


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
    try:
        permissions = get_permissions_for_user(client, profile)
    except (APIError, httpx.HTTPError, KeyError, TypeError):
        app.logger.exception("Workspace permissions could not be loaded")
        permissions = empty_permissions()
        permission_error = "Modules are unavailable until permissions are configured."
    else:
        permission_error = None
    return render_template(
        "index.html",
        profile=profile,
        module_cards=module_cards(permissions),
        sidebar_modules=module_cards(permissions),
        permission_error=permission_error,
    )


@app.get("/api/modules/<module>/<action>")
def api_check_module_permission(module, action):
    client = get_authenticated_client()
    if client is None:
        return jsonify(error="You must be logged in."), 401
    profile = get_current_profile(client)
    if profile is None or profile.get("status") in {"blocked", "rejected", "pending"}:
        return jsonify(error="Profile not found."), 403
    module_name = next(
        (name for name, slug in MODULE_SLUGS.items() if slug == module),
        None,
    )
    if module_name is None or action not in RIGHTS_ACTIONS:
        return jsonify(error="Unknown module or action."), 400
    try:
        permissions = get_permissions_for_user(client, profile)
    except (APIError, httpx.HTTPError, KeyError, TypeError):
        app.logger.exception("Module permission check failed")
        return jsonify(error="Permissions could not be checked."), 503
    if not has_permission(permissions, module_name, action):
        return jsonify(error="You do not have permission for this action."), 403
    return jsonify(allowed=True)


@app.get("/customers")
@app.get("/products")
@app.get("/human-resources")
@app.get("/sales")
@app.get("/reports")
def module_workspace():
    client = get_authenticated_client()
    if client is None:
        return redirect(url_for("login"))
    profile = get_current_profile(client)
    if profile is None:
        session.clear()
        return redirect(url_for("login"))
    if profile.get("status") in {"blocked", "rejected", "pending"}:
        session.clear()
        return redirect(url_for("login"))
    if must_set_password(client.auth.get_user().user):
        return redirect(url_for("set_password"))

    slug = request.path.strip("/")
    module = next((item for item in WORKSPACE_MODULES if item["slug"] == slug), None)
    if module is None:
        return redirect(url_for("index"))
    try:
        permissions = get_permissions_for_user(client, profile)
    except (APIError, httpx.HTTPError, KeyError, TypeError):
        app.logger.exception("Module workspace permissions could not be loaded")
        return render_template(
            "module_workspace.html",
            profile=profile,
            module=module,
            allowed=False,
            permission_error=True,
            sidebar_modules=[],
        ), 503

    allowed = has_permission(permissions, module["permission"], "view")
    if allowed and slug == "customers":
        record_config = RECORD_MODULES["customers"]
        return render_template(
            "record_list.html",
            profile=profile,
            module=module,
            record_config=record_config,
            is_admin=profile["role"] in {"admin", "superadmin"},
            sidebar_modules=module_cards(permissions),
        )
    return render_template(
        "module_workspace.html",
        profile=profile,
        module=module,
        allowed=allowed,
        permission_error=False,
        sidebar_modules=module_cards(permissions),
    ), 200 if allowed else 403


@app.get("/user-management")
def user_management():
    client, profile = get_management_profile()
    if client is None:
        return redirect(url_for("login"))
    if profile is None:
        return redirect(url_for("index"))
    try:
        sidebar_modules = module_cards(get_permissions_for_user(client, profile))
    except (APIError, httpx.HTTPError, KeyError, TypeError):
        app.logger.exception("Sidebar permissions could not be loaded")
        sidebar_modules = []
    return render_template(
        "user_management.html",
        profile=profile,
        is_superadmin=profile["role"] == "superadmin",
        sidebar_modules=sidebar_modules,
    )


def get_record_access(module_slug, action):
    client = get_authenticated_client()
    if client is None:
        return None, None, None, (jsonify(error="You must be logged in."), 401)
    profile = get_current_profile(client)
    if profile is None or profile.get("status") in {"blocked", "rejected", "pending"}:
        return None, None, None, (jsonify(error="This account is not active."), 403)
    config = RECORD_MODULES.get(module_slug)
    if config is None:
        return None, None, None, (jsonify(error="Unknown module."), 404)
    try:
        permissions = get_permissions_for_user(client, profile)
    except (APIError, httpx.HTTPError):
        app.logger.exception("Record permissions could not be loaded")
        return None, None, None, (
            jsonify(error="Module access needs database setup or could not be checked."),
            503,
        )
    if not has_permission(permissions, config["permission"], "view"):
        return None, None, None, (
            jsonify(error="View access is required for this module."),
            403,
        )
    if not has_permission(permissions, config["permission"], action):
        return None, None, None, (
            jsonify(error="You do not have permission for this action."),
            403,
        )
    return client, profile, config, None


def record_error_response(error, config):
    app.logger.exception("Record request could not be completed")
    if isinstance(error, (APIError, RuntimeError)):
        return jsonify(error=f"{config['name']} data needs database setup or is blocked by access policies."), 503
    return jsonify(error=f"{config['name']} request could not be completed. Please try again."), 502


def record_form_values(config, payload, editing=False):
    if not isinstance(payload, Mapping):
        return None, f"Submit {config['name'].lower()} details."
    valid_names = {field["name"] for field in config["fields"]}
    if editing:
        valid_names.remove(config["key_field"])
    if set(payload) != valid_names:
        return None, f"{config['singular']} details are incomplete or contain unsupported fields."
    values = {}
    for field in config["fields"]:
        name = field["name"]
        if editing and name == config["key_field"]:
            continue
        value = payload.get(name)
        if not isinstance(value, str):
            return None, f"{field['label']} is required."
        value = value.strip()
        if field["required"] and not value:
            return None, f"{field['label']} is required."
        if len(value) > field["maxlength"]:
            return None, f"{field['label']} must be {field['maxlength']} characters or fewer."
        if field.get("options") and value not in field["options"]:
            return None, f"Choose valid {field['label'].lower()}."
        values[field["column"]] = value or None
    return values, None


@app.get("/api/records/<module_slug>")
def api_list_records(module_slug):
    client, profile, config, error = get_record_access(module_slug, "view")
    if error:
        return error

    requested_status = request.args.get("status", "active")
    if requested_status not in {"active", "inactive", "all"}:
        return jsonify(error="Choose Active, Inactive, or All."), 400
    is_admin = profile["role"] in {"admin", "superadmin"}
    status_filter = requested_status if is_admin else "active"
    business_columns = [field["column"] for field in config["fields"]]
    admin_columns = business_columns + ["is_deleted", "stamp"]
    try:
        active = client.table(config["active_view"]).select(
            ", ".join(admin_columns if is_admin else business_columns)
        ).execute()
        active_rows = active.data or []
        inactive_rows = []
        if is_admin:
            inactive = (
                client.table(config["table"])
                .select(", ".join(admin_columns))
                .eq("is_deleted", True)
                .execute()
            )
            inactive_rows = inactive.data or []
        counts = {"active": len(active_rows), "inactive": len(inactive_rows)}
        counts["all"] = counts["active"] + counts["inactive"]
        rows = (
            active_rows if status_filter == "active"
            else inactive_rows if status_filter == "inactive"
            else active_rows + inactive_rows
        )
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, config)

    search = request.args.get("search", "").strip().casefold()
    if search:
        rows = [
            row for row in rows
            if any(search in str(row.get(column) or "").casefold() for column in business_columns)
        ]
    records = []
    for row in rows:
        record = {
            field["name"]: row.get(field["column"])
            for field in config["fields"]
        }
        if is_admin:
            record.update(
                isDeleted=row.get("is_deleted") is True,
                stamp=row.get("stamp"),
            )
        records.append(record)
    try:
        permissions = get_permissions_for_user(client, profile)
    except (APIError, httpx.HTTPError):
        app.logger.exception("Record action permissions could not be loaded")
        return jsonify(error="Module access needs database setup or could not be checked."), 503
    actions = permissions[config["permission"]]
    return jsonify(
        records=records,
        counts=counts if is_admin else None,
        is_admin=is_admin,
        actions={
            "create": actions["create"],
            "edit": actions["edit"],
            "delete": actions["delete"],
        },
    )


@app.post("/api/records/<module_slug>")
def api_create_record(module_slug):
    client, profile, config, error = get_record_access(module_slug, "create")
    if error:
        return error
    values, validation_error = record_form_values(config, get_user_payload())
    if validation_error:
        return jsonify(error=validation_error), 400
    try:
        response = client.table(config["table"]).insert(values).execute()
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, config)
    return jsonify(message=f"{config['singular']} added.", record=response.data[0] if response.data else None), 201


@app.patch("/api/records/<module_slug>/<record_id>")
def api_edit_record(module_slug, record_id):
    client, profile, config, error = get_record_access(module_slug, "edit")
    if error:
        return error
    values, validation_error = record_form_values(config, get_user_payload(), editing=True)
    if validation_error:
        return jsonify(error=validation_error), 400
    try:
        current = (
            client.table(config["table"])
            .select("is_deleted")
            .eq(config["key"], record_id)
            .maybe_single()
            .execute()
        )
        if current.data is None:
            return jsonify(error=f"{config['singular']} not found."), 404
        if current.data.get("is_deleted"):
            return jsonify(error=f"Restore this {config['singular'].lower()} before editing."), 409
        response = (
            client.table(config["table"])
            .update(values)
            .eq(config["key"], record_id)
            .eq("is_deleted", False)
            .execute()
        )
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, config)
    return jsonify(message=f"{config['singular']} updated.", record=response.data[0] if response.data else None)


@app.patch("/api/records/<module_slug>/<record_id>/delete")
def api_delete_record(module_slug, record_id):
    client, profile, config, error = get_record_access(module_slug, "delete")
    if error:
        return error
    try:
        response = (
            client.table(config["table"])
            .update({"is_deleted": True})
            .eq(config["key"], record_id)
            .eq("is_deleted", False)
            .execute()
        )
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, config)
    if not response.data:
        return jsonify(error=f"{config['singular']} not found or already inactive."), 404
    return jsonify(message=f"{config['singular']} moved to Inactive.")


@app.patch("/api/records/<module_slug>/<record_id>/restore")
def api_restore_record(module_slug, record_id):
    client, profile, config, error = get_record_access(module_slug, "delete")
    if error:
        return error
    if profile["role"] not in {"admin", "superadmin"}:
        return jsonify(error="Only administrators can restore inactive records."), 403
    try:
        response = (
            client.table(config["table"])
            .update({"is_deleted": False})
            .eq(config["key"], record_id)
            .eq("is_deleted", True)
            .execute()
        )
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, config)
    if not response.data:
        return jsonify(error=f"Inactive {config['singular'].lower()} not found."), 404
    return jsonify(message=f"{config['singular']} restored.")


@app.get("/api/users")
def api_users():
    client, profile = get_management_profile()
    if client is None:
        return jsonify(error="You must be logged in."), 401
    if profile is None:
        return jsonify(error="Administrator access is required."), 403

    try:
        query = get_admin_client().table("profiles").select(
            "id, email, full_name, status, role, created_at"
        )
        query = query.in_("role", ["admin", "user"])
        response = query.order("created_at", desc=True).execute()
    except (RuntimeError, httpx.HTTPError):
        app.logger.exception("User list could not be loaded")
        return jsonify(error="Users could not be loaded. Please try again."), 502

    return jsonify(users=response.data)


@app.post("/api/users")
def api_add_user():
    client, profile = get_management_profile()
    if client is None:
        return jsonify(error="You must be logged in."), 401
    if profile is None:
        return jsonify(error="Administrator access is required."), 403

    payload = get_user_payload()
    full_name = payload.get("full_name") if payload else None
    email = payload.get("email") if payload else None
    password = payload.get("password") if payload else None
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
        admin_client = get_admin_client()
        response = admin_client.auth.admin.create_user(
            {
                "email": email,
                "password": password,
                "email_confirm": True,
                "user_metadata": {
                    "full_name": full_name,
                    "must_set_password": True,
                },
            }
        )
        if response.user is None:
            return jsonify(error="User could not be created."), 502
        profile_response = admin_client.table("profiles").update(
            {"full_name": full_name, "role": "user", "status": "approved"}
        ).eq("id", response.user.id).execute()
        if not profile_response.data:
            admin_client.auth.admin.delete_user(response.user.id)
            return jsonify(error="User profile could not be created."), 502
    except (AuthError, httpx.HTTPError):
        app.logger.exception("Administrator user creation failed")
        return jsonify(error="User could not be created. Check the email and try again."), 400
    except RuntimeError:
        app.logger.exception("Administrator user creation is not configured")
        return jsonify(error="User management is not configured on the server."), 503

    return jsonify(message="User added successfully."), 201


@app.patch("/api/users/<user_id>")
def api_edit_user(user_id):
    client, profile = get_management_profile()
    if client is None:
        return jsonify(error="You must be logged in."), 401
    if profile is None:
        return jsonify(error="Administrator access is required."), 403

    payload = get_user_payload()
    full_name = payload.get("full_name") if payload else None
    if not isinstance(full_name, str):
        return jsonify(error="Name is required."), 400
    full_name = full_name.strip()
    if not full_name or len(full_name) > 120:
        return jsonify(error="Enter a name between 1 and 120 characters."), 400

    try:
        target = (
            get_admin_client()
            .table("profiles")
            .select("id, role")
            .eq("id", user_id)
            .maybe_single()
            .execute()
        )
        if target.data is None or (
            profile["role"] == "admin" and target.data["role"] != "user"
        ) or target.data["role"] == "superadmin":
            return jsonify(error="User not found."), 404
        update_query = get_admin_client().table("profiles").update(
            {"full_name": full_name}
        ).eq("id", user_id)
        if profile["role"] == "admin":
            update_query = update_query.eq("role", "user")
        update_query.execute()
    except (RuntimeError, httpx.HTTPError):
        app.logger.exception("Administrator user edit failed")
        return jsonify(error="User could not be updated. Please try again."), 502

    return jsonify(message="User updated successfully.")


@app.patch("/api/users/<user_id>/status")
def api_update_user_status(user_id):
    client, profile = get_management_profile()
    if client is None:
        return jsonify(error="You must be logged in."), 401
    if profile is None:
        return jsonify(error="Administrator access is required."), 403

    payload = get_user_payload()
    status = payload.get("status") if payload else None
    if status not in {"approved", "blocked"}:
        return jsonify(error="Status must be approved or blocked."), 400

    try:
        target = (
            get_admin_client()
            .table("profiles")
            .select("id, role, status")
            .eq("id", user_id)
            .maybe_single()
            .execute()
        )
        if target.data is None or (
            profile["role"] == "admin" and target.data["role"] != "user"
        ) or target.data["role"] == "superadmin":
            return jsonify(error="User not found."), 404
        if (
            profile["role"] == "admin"
            and target.data["status"] == "pending"
            and status == "approved"
        ):
            return jsonify(error="Only a superadmin can approve pending users."), 403
        update_query = get_admin_client().table("profiles").update(
            {"status": status}
        ).eq("id", user_id)
        if profile["role"] == "admin":
            update_query = update_query.eq("role", "user")
        update_query.execute()
    except (RuntimeError, httpx.HTTPError):
        app.logger.exception("Administrator user status update failed")
        return jsonify(error="User status could not be updated. Please try again."), 502

    return jsonify(message="User status updated.")


@app.patch("/api/users/<user_id>/role")
def api_update_user_role(user_id):
    client, profile = get_management_profile()
    if client is None:
        return jsonify(error="You must be logged in."), 401
    if profile is None:
        return jsonify(error="Administrator access is required."), 403
    if profile["role"] != "superadmin":
        return jsonify(error="Superadmin access is required."), 403

    payload = get_user_payload()
    role = payload.get("role") if payload else None
    if role not in {"admin", "user"}:
        return jsonify(error="Role must be admin or user."), 400

    try:
        target = (
            get_admin_client()
            .table("profiles")
            .select("id, role")
            .eq("id", user_id)
            .maybe_single()
            .execute()
        )
        if target.data is None or target.data["role"] == "superadmin":
            return jsonify(error="Superadmin accounts cannot be changed here."), 403
        get_admin_client().table("profiles").update(
            {"role": role}
        ).eq("id", user_id).neq("role", "superadmin").execute()
    except (RuntimeError, httpx.HTTPError):
        app.logger.exception("Superadmin role update failed")
        return jsonify(error="User role could not be updated. Please try again."), 502

    return jsonify(message="User role updated.")


@app.delete("/api/users/<user_id>")
def api_remove_user(user_id):
    client, profile = get_management_profile()
    if client is None:
        return jsonify(error="You must be logged in."), 401
    if profile is None:
        return jsonify(error="Administrator access is required."), 403
    if profile["role"] != "superadmin":
        return jsonify(error="Superadmin access is required."), 403

    try:
        target = (
            get_admin_client()
            .table("profiles")
            .select("id, role")
            .eq("id", user_id)
            .maybe_single()
            .execute()
        )
        if target.data is None:
            return jsonify(error="User not found."), 404
        if target.data["role"] == "superadmin":
            return jsonify(error="Superadmin accounts cannot be removed."), 403
        get_admin_client().auth.admin.delete_user(user_id)
    except (RuntimeError, AuthError, httpx.HTTPError):
        app.logger.exception("Superadmin user removal failed")
        return jsonify(error="User could not be removed. Please try again."), 502

    return jsonify(message="User removed.")


def get_rights_target(profile, user_id):
    target = (
        get_admin_client()
        .table("profiles")
        .select("id, role")
        .eq("id", user_id)
        .maybe_single()
        .execute()
    )
    if target.data is None:
        return None
    if target.data["role"] == "superadmin":
        return None
    if profile["role"] == "admin" and target.data["role"] != "user":
        return None
    return target.data


@app.get("/api/users/<user_id>/permissions")
def api_get_user_permissions(user_id):
    client, profile = get_management_profile()
    if client is None:
        return jsonify(error="You must be logged in."), 401
    if profile is None:
        return jsonify(error="Administrator access is required."), 403

    try:
        if get_rights_target(profile, user_id) is None:
            return jsonify(error="User not found."), 404
        admin_client = get_admin_client()
        catalog_response = admin_client.table("right_catalog").select(
            "right_code, module_code, resource_code, action"
        ).execute()
        assignment_response = (
            admin_client.table("user_permission")
            .select("right_code")
            .eq("user_id", user_id)
            .eq("is_deleted", False)
            .execute()
        )
    except (RuntimeError, APIError, httpx.HTTPError):
        app.logger.exception("User permissions could not be loaded")
        return jsonify(error="Rights catalogue needs database setup or could not be loaded."), 503

    catalog = catalog_response.data or []
    selected = [row["right_code"] for row in assignment_response.data or []]
    if not selected:
        legacy = (
            admin_client.table("user_permissions")
            .select("permissions")
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        legacy_data = legacy.data if legacy is not None else None
        legacy_permissions = (
            validate_permissions(legacy_data["permissions"]) if legacy_data else None
        )
        if legacy_permissions:
            selected = permissions_to_rights(catalog, legacy_permissions)
    return jsonify(catalog=catalog, selected=selected)


@app.patch("/api/users/<user_id>/permissions")
def api_update_user_permissions(user_id):
    client, profile = get_management_profile()
    if client is None:
        return jsonify(error="You must be logged in."), 401
    if profile is None:
        return jsonify(error="Administrator access is required."), 403

    payload = get_user_payload()
    selected = payload.get("rights") if payload else None
    if not isinstance(selected, list) or not all(
        isinstance(right, str) for right in selected
    ) or len(selected) != len(set(selected)):
        return jsonify(error="Invalid rights payload."), 400

    try:
        target = get_rights_target(profile, user_id)
        if target is None:
            return jsonify(error="User not found."), 404
        admin_client = get_admin_client()
        catalog_response = admin_client.table("right_catalog").select(
            "right_code, module_code, resource_code, action"
        ).execute()
        catalog = catalog_response.data or []
        known_rights = {right["right_code"] for right in catalog}
        if not set(selected).issubset(known_rights):
            return jsonify(error="Rights include entries not in the database catalogue."), 400
        current = admin_client.table("user_permission").select(
            "right_code, is_deleted"
        ).eq("user_id", user_id).execute()
        active_rights = {
            row["right_code"] for row in current.data or [] if not row["is_deleted"]
        }
        to_soft_delete = active_rights.difference(selected)
        if to_soft_delete:
            admin_client.table("user_permission").update(
                {"is_deleted": True}
            ).eq("user_id", user_id).in_("right_code", list(to_soft_delete)).execute()
        if selected:
            admin_client.table("user_permission").upsert(
                [
                    {"user_id": user_id, "right_code": right_code, "is_deleted": False}
                    for right_code in selected
                ]
            ).execute()
        # Keep the original JSON contract synchronized for deployments that still read it.
        permissions = rights_to_permissions(
            catalog, [{"right_code": right_code} for right_code in selected]
        )
        admin_client.table("user_permissions").upsert(
            {"user_id": user_id, "permissions": permissions, "updated_by": profile["id"]}
        ).execute()
        write_audit_log(admin_client, profile["id"], user_id, active_rights, selected)
    except (RuntimeError, APIError, httpx.HTTPError):
        app.logger.exception("User permissions update failed")
        return jsonify(error="Rights need database setup or could not be updated."), 503

    return jsonify(message="Rights updated.", rights=selected)


@app.get("/login")
def login():
    if get_authenticated_client() is not None:
        return redirect(url_for("index"))
    return render_template("login.html")


@app.get("/forgot-password")
def forgot_password():
    return render_template("forgot_password.html")


@app.post("/api/forgot-password")
def api_forgot_password():
    payload = request.get_json(silent=True) if request.is_json else request.form
    email = payload.get("email") if isinstance(payload, Mapping) else None
    if not isinstance(email, str):
        return jsonify(error="Email is required."), 400

    email = email.strip().lower()
    if not email or "@" not in email or any(character.isspace() for character in email):
        return jsonify(error="Enter a valid email address."), 400

    try:
        user = get_reset_user(email)
        if user is not None:
            token = reset_token_serializer.dumps({"user_id": user.id, "email": email})
            reset_url = url_for("reset_password", token=token, _external=True)
            send_password_reset_email(email, reset_url)
    except (RuntimeError, ValueError, smtplib.SMTPException):
        app.logger.exception("Password reset email could not be sent")
        return jsonify(error="Password reset service is unavailable. Please try again later."), 502
    except (AuthError, httpx.HTTPError):
        app.logger.exception("Supabase password reset lookup failed")
        return jsonify(error="Password reset service is unavailable. Please try again later."), 502

    return jsonify(
        message="If an account exists for that email, a password reset link is on its way."
    )


@app.get("/reset-password")
def reset_password():
    return render_template("reset_password.html", token=request.args.get("token", ""))


@app.post("/api/reset-password")
def api_reset_password():
    payload = request.get_json(silent=True) if request.is_json else request.form
    token = payload.get("token") if isinstance(payload, Mapping) else None
    password = payload.get("password") if isinstance(payload, Mapping) else None
    confirmation = payload.get("confirmation") if isinstance(payload, Mapping) else None
    if not all(isinstance(value, str) and value for value in (token, password, confirmation)):
        return jsonify(error="Reset token, password, and confirmation are required."), 400
    if len(password) < 8:
        return jsonify(error="Password must be at least 8 characters."), 400
    if password != confirmation:
        return jsonify(error="Passwords do not match."), 400

    try:
        data = reset_token_serializer.loads(token, max_age=RESET_TOKEN_MAX_AGE)
    except SignatureExpired:
        return jsonify(error="This reset link has expired. Request a new one."), 400
    except BadSignature:
        return jsonify(error="This reset link is invalid. Request a new one."), 400

    try:
        user = get_reset_user(data["email"])
        if user is None or user.id != data["user_id"]:
            return jsonify(error="This reset link is invalid. Request a new one."), 400
        get_admin_client().auth.admin.update_user_by_id(user.id, {"password": password})
    except (KeyError, TypeError):
        return jsonify(error="This reset link is invalid. Request a new one."), 400
    except (RuntimeError, AuthError, httpx.HTTPError):
        app.logger.exception("Supabase password reset failed")
        return jsonify(error="Password could not be reset. Please try again."), 502

    return jsonify(message="Password reset. You can now log in.", redirect=url_for("login"))


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
        if profile["status"] == "pending":
            client.auth.sign_out()
            return jsonify(error="Your account is pending administrator approval."), 403
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
                    "data": {
                        "full_name": full_name,
                        "must_set_password": False,
                        "status": "pending",
                    }
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

    try:
        get_admin_client().table("profiles").update(
            {"full_name": full_name, "status": "pending"}
        ).eq("id", response.user.id).execute()
    except (RuntimeError, httpx.HTTPError):
        app.logger.exception("New registration profile status could not be set to pending")
        return (
            jsonify(
                error="Registration completed, but the account could not be placed in the approval queue."
            ),
            502,
        )

    return (
        jsonify(
            message="Registration completed. Your account is pending administrator approval.",
            status="pending",
        ),
        201,
    )


if __name__ == "__main__":
    app.run(debug=os.getenv("FLASK_DEBUG", "").lower() == "true")
