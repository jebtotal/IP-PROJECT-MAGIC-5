

import os
import secrets
import smtplib
import hmac
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal, InvalidOperation
from email.message import EmailMessage
from collections.abc import Mapping

import httpx
from dotenv import load_dotenv
from flask import Flask, abort, jsonify, redirect, render_template, request, session, url_for
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
MANILA_TIMEZONE = timezone(timedelta(hours=8))
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
REPORTS = {
    "products_master": {
        "right": "reports.productsMaster.view",
        "resource": "products_master",
        "name": "Product Master List",
        "filters": (),
    },
    "active_employees": {
        "right": "reports.activeEmployees.view",
        "resource": "active_employees",
        "name": "Active Employees",
        "filters": (),
    },
    "all_employees": {
        "right": "reports.allEmployees.view",
        "resource": "all_employees",
        "name": "All Employees",
        "filters": (),
    },
    "employee_job_history": {
        "right": "reports.employeeJobHistory.view",
        "resource": "employee_job_history",
        "name": "Employee Job History",
        "filters": ("employee",),
    },
    "top_customers": {
        "right": "reports.topCustomers.view",
        "resource": "top_customers",
        "name": "Top Customers",
        "filters": ("date_range", "top_n"),
    },
    "top_products": {
        "right": "reports.topProducts.view",
        "resource": "top_products",
        "name": "Top Products",
        "filters": ("date_range", "top_n"),
    },
    "top_sales": {
        "right": "reports.topSales.view",
        "resource": "top_sales",
        "name": "Top Sales",
        "filters": ("date_range", "top_n"),
    },
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
    "employees": {
        "module_slug": "employees",
        "name": "Employees",
        "singular": "Employee",
        "permission": "Human Resources",
        "rights_module": "hr",
        "rights_resource": "employees",
        "rights_view_resource": "hr",
        "table": "employee",
        "active_view": "employee_active",
        "key": "empno",
        "key_field": "empNo",
        "display_field": "lastName",
        "allowed_actions": ("view", "create", "edit", "delete"),
        "filters": (
            {
                "name": "gender",
                "label": "Gender",
                "options": (
                    {"value": "all", "label": "All genders"},
                    {"value": "F", "label": "Female"},
                    {"value": "M", "label": "Male"},
                ),
            },
            {
                "name": "employment",
                "label": "Employment",
                "options": (
                    {"value": "all", "label": "All employees"},
                    {"value": "current", "label": "Current"},
                    {"value": "separated", "label": "Separated"},
                ),
            },
        ),
        "fields": (
            {
                "name": "empNo",
                "column": "empno",
                "label": "Employee No",
                "maxlength": 5,
                "required": True,
            },
            {
                "name": "lastName",
                "column": "lastname",
                "label": "Last Name",
                "maxlength": 15,
                "required": False,
            },
            {
                "name": "firstName",
                "column": "firstname",
                "label": "First Name",
                "maxlength": 15,
                "required": False,
            },
            {
                "name": "gender",
                "column": "gender",
                "label": "Gender",
                "maxlength": 1,
                "required": False,
                "options": (
                    {"value": "F", "label": "Female"},
                    {"value": "M", "label": "Male"},
                ),
            },
            {
                "name": "birthDate",
                "column": "birthdate",
                "label": "Birth Date",
                "maxlength": 10,
                "required": False,
                "type": "date",
            },
            {
                "name": "hireDate",
                "column": "hiredate",
                "label": "Hire Date",
                "maxlength": 10,
                "required": False,
                "type": "date",
            },
            {
                "name": "sepDate",
                "column": "sepdate",
                "label": "Separation Date",
                "maxlength": 10,
                "required": False,
                "type": "date",
            },
        ),
    },
    "jobs": {
        "module_slug": "jobs",
        "name": "Jobs",
        "singular": "Job",
        "permission": "Human Resources",
        "rights_module": "hr",
        "rights_resource": "jobs",
        "rights_view_resource": "hr",
        "table": "job",
        "active_view": "job_active",
        "key": "jobcode",
        "key_field": "jobCode",
        "display_field": "jobDesc",
        "fields": (
            {
                "name": "jobCode",
                "column": "jobcode",
                "label": "Job Code",
                "maxlength": 4,
                "required": True,
            },
            {
                "name": "jobDesc",
                "column": "jobdesc",
                "label": "Job Description",
                "maxlength": 20,
                "required": True,
            },
        ),
    },
    "departments": {
        "module_slug": "departments",
        "name": "Departments",
        "singular": "Department",
        "permission": "Human Resources",
        "rights_module": "hr",
        "rights_resource": "departments",
        "rights_view_resource": "hr",
        "table": "department",
        "active_view": "department_active",
        "key": "deptcode",
        "key_field": "deptCode",
        "display_field": "deptName",
        "fields": (
            {
                "name": "deptCode",
                "column": "deptcode",
                "label": "Department Code",
                "maxlength": 3,
                "required": True,
            },
            {
                "name": "deptName",
                "column": "deptname",
                "label": "Department Name",
                "maxlength": 20,
                "required": True,
            },
        ),
    },
    "customers": {
        "module_slug": "customers",
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
    "products": {
        "module_slug": "products",
        "name": "Products",
        "singular": "Product",
        "permission": "Product",
        "table": "product",
        "active_view": "product_active",
        "key": "prodcode",
        "key_field": "prodCode",
        "display_field": "description",
        "fields": (
            {
                "name": "prodCode",
                "column": "prodcode",
                "label": "Product Code",
                "maxlength": 6,
                "required": True,
            },
            {
                "name": "description",
                "column": "description",
                "label": "Description",
                "maxlength": 30,
                "required": False,
            },
            {
                "name": "unit",
                "column": "unit",
                "label": "Unit",
                "maxlength": 3,
                "required": False,
                "options": ("pc", "ea", "mtr", "pkg", "ltr"),
            },
        ),
    },
    "sales": {
        "module_slug": "sales",
        "name": "Sales",
        "singular": "Sale",
        "permission": "Sales",
        "rights_module": "sales",
        "rights_resource": "sales",
        "rights_view_resource": "sales",
        "table": "sales",
        "active_view": "sales_active",
        "key": "transno",
        "key_field": "transNo",
        "display_field": "transNo",
        "allowed_actions": ("view", "create"),
        "fields": (
            {
                "name": "transNo",
                "column": "transno",
                "label": "Transaction No",
                "maxlength": 8,
                "required": True,
            },
            {
                "name": "salesDate",
                "column": "salesdate",
                "label": "Sale Date",
                "maxlength": 10,
                "required": True,
                "type": "date",
            },
            {
                "name": "custNo",
                "column": "custno",
                "label": "Customer",
                "maxlength": 5,
                "required": True,
            },
            {
                "name": "empNo",
                "column": "empno",
                "label": "Salesperson",
                "maxlength": 5,
                "required": True,
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


@app.context_processor
def inject_csrf_token():
    if "csrf_token" not in session:
        session["csrf_token"] = secrets.token_urlsafe(32)
    return {"csrf_token": session["csrf_token"]}


@app.before_request
def validate_api_csrf_token():
    protected_paths = (
        request.path.startswith("/api/records/")
        or request.path.startswith("/api/products/")
        or request.path.startswith("/api/hr/")
        or request.path.startswith("/api/users")
        or request.path.startswith("/api/sales")
        or request.path in {"/api/logout", "/logout"}
    )
    if request.method not in {"POST", "PATCH", "DELETE"} or not protected_paths:
        return None

    expected = session.get("csrf_token")
    supplied = request.headers.get("X-CSRF-Token") or request.form.get("csrf_token")
    if (
        not isinstance(expected, str)
        or not isinstance(supplied, str)
        or not hmac.compare_digest(expected, supplied)
    ):
        return jsonify(error="This request could not be verified. Reload the page and try again."), 400
    return None


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
        .select("id, email, full_name, status, role, blocked, is_deleted, stamp, created_at")
        .eq("id", user.id)
        .single()
        .execute()
    )
    return response.data


def profile_is_active(profile):
    return (
        profile is not None
        and profile.get("status") not in {"blocked", "rejected", "pending"}
        and profile.get("blocked") is not True
        and profile.get("is_deleted") is not True
    )


def make_stamp(action, actor):
    actor_name = str(actor.get("email") or actor.get("id") or "system")[:24]
    timestamp = datetime.now(MANILA_TIMEZONE).strftime("%Y-%m-%d %I:%M %p")
    return f"{action} {actor_name} {timestamp}"[:60]


def display_stamp(stamp):
    if not isinstance(stamp, str):
        return stamp
    parts = stamp.split(" ", 1)
    action_labels = {
        "ADD": "CREATED",
        "EDIT": "EDITED",
        "DELETE": "DELETED",
        "RESTORE": "RESTORED",
    }
    if parts[0] in action_labels:
        return f"{action_labels[parts[0]]} {parts[1]}" if len(parts) == 2 else action_labels[parts[0]]
    return stamp


def employee_is_current(separation_date, today=None):
    if not separation_date:
        return True
    if isinstance(separation_date, datetime):
        separation_date = separation_date.date()
    if isinstance(separation_date, date):
        return separation_date >= (today or datetime.now(MANILA_TIMEZONE).date())
    try:
        parsed_date = date.fromisoformat(str(separation_date)[:10])
    except ValueError:
        return False
    return parsed_date >= (today or datetime.now(MANILA_TIMEZONE).date())


def get_management_profile():
    client = get_authenticated_client()
    if client is None:
        return None, None
    profile = get_current_profile(client)
    if not profile_is_active(profile) or profile.get("role") not in {"admin", "superadmin"}:
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


def write_audit_log(
    admin_client,
    actor_id,
    target_user_id,
    old_rights,
    new_rights,
    event_type="user_permission.EDIT",
):
    admin_client.table("audit_log").insert(
        {
            "actor_id": str(actor_id),
            "event_type": event_type,
            "old_values": {
                "user_id": str(target_user_id),
                "rights": sorted(old_rights),
            },
            "new_values": {
                "user_id": str(target_user_id),
                "rights": sorted(new_rights),
            },
        }
    ).execute()


def write_profile_audit_log(admin_client, actor_id, target_user_id, event_type, old_values, new_values):
    admin_client.table("audit_log").insert(
        {
            "actor_id": str(actor_id),
            "event_type": event_type,
            "old_values": old_values,
            "new_values": new_values,
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
        if right.get("resource_code") in {
            report["resource"] for report in REPORTS.values()
        }:
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
        if right.get("resource_code") in {
            report["resource"] for report in REPORTS.values()
        }:
            continue
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


def legacy_right_catalog():
    module_codes = {
        "Customer": "customers",
        "Product": "products",
        "Human Resources": "hr",
        "Sales": "sales",
        "Reports": "reports",
    }
    return [
        {
            "right_code": f"{module_code}.{'add' if action == 'create' else action}",
            "module_code": module_code,
            "resource_code": module_code,
            "action": "add" if action == "create" else action,
        }
        for module, module_code in module_codes.items()
        for action in RIGHTS_ACTIONS
    ]


def is_missing_rights_table(error):
    return error.code == "PGRST205" and any(
        f"public.{table}" in str(error)
        for table in ("right_catalog", "user_permission")
    )


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
    if not profile_is_active(profile):
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
    if not profile_is_active(profile):
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
@app.get("/human-resources/jobs")
@app.get("/human-resources/employees")
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
    if not profile_is_active(profile):
        session.clear()
        return redirect(url_for("login"))
    if must_set_password(client.auth.get_user().user):
        return redirect(url_for("set_password"))

    path_parts = request.path.strip("/").split("/")
    slug = path_parts[0]
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
    if allowed and slug == "sales":
        return render_template(
            "sales_list.html",
            profile=profile,
            module=module,
            is_admin=profile["role"] in {"admin", "superadmin"},
            today=datetime.now(MANILA_TIMEZONE).date().isoformat(),
            sidebar_modules=module_cards(permissions),
        )
    if allowed and slug == "reports":
        try:
            report_rights = get_report_rights(client, profile)
        except (APIError, httpx.HTTPError, RuntimeError, KeyError, TypeError):
            app.logger.exception("Report rights could not be loaded")
            return render_template(
                "reports.html",
                profile=profile,
                module=module,
                report_rights=[],
                today=datetime.now(MANILA_TIMEZONE).date().isoformat(),
                permission_error=True,
                sidebar_modules=module_cards(permissions),
            ), 503
        return render_template(
            "reports.html",
            profile=profile,
            module=module,
            report_rights=report_rights,
            today=datetime.now(MANILA_TIMEZONE).date().isoformat(),
            permission_error=False,
            sidebar_modules=module_cards(permissions),
        )
    record_slug = (
        path_parts[1] if len(path_parts) > 1 else "departments"
    ) if slug == "human-resources" else slug
    if allowed and record_slug in RECORD_MODULES:
        record_config = RECORD_MODULES[record_slug]
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


@app.get("/human-resources/employees/<employee_no>/job-history")
def employee_job_history(employee_no):
    client, profile, context, _actions, error = get_employee_job_history_access(
        employee_no, "view"
    )
    if error:
        if error[1] == 401:
            return redirect(url_for("login"))
        if error[1] == 403:
            return redirect(url_for("index"))
        return error
    try:
        permissions = get_permissions_for_user(client, profile)
        jobs = (
            client.table("job_active")
            .select("jobcode, jobdesc")
            .order("jobcode")
            .execute()
            .data or []
        )
        departments = (
            client.table("department_active")
            .select("deptcode, deptname")
            .order("deptcode")
            .execute()
            .data or []
        )
    except (APIError, httpx.HTTPError, RuntimeError, KeyError, TypeError):
        app.logger.exception("Job history form options could not be loaded")
        return jsonify(error="Job History, Job, or Department data needs database setup or could not be loaded."), 503
    is_admin = profile["role"] in {"admin", "superadmin"}
    actions = {
        action: is_admin or JOB_HISTORY_RIGHTS[action] in context["rights"]
        for action in ("create", "edit", "delete")
    }
    return render_template(
        "job_history.html",
        profile=profile,
        employee=context["employee"],
        jobs=jobs,
        departments=departments,
        is_admin=is_admin,
        actions=actions,
        sidebar_modules=module_cards(permissions),
    )


@app.get("/human-resources/employees/<employee_no>")
def employee_profile(employee_no):
    client, profile, _config, _actions, error = get_record_access(
        "employees", "view"
    )
    if error:
        if error[1] == 401:
            return redirect(url_for("login"))
        if error[1] == 403:
            return redirect(url_for("index"))
        return error

    is_admin = profile["role"] in {"admin", "superadmin"}
    employee_columns = (
        "empno, lastname, firstname, gender, birthdate, hiredate, sepdate, is_deleted, stamp"
        if is_admin
        else "empno, lastname, firstname, gender, birthdate, hiredate, sepdate"
    )
    try:
        employee = (
            client.table("employee" if is_admin else "employee_active")
            .select(employee_columns)
            .eq("empno", employee_no)
            .maybe_single()
            .execute()
            .data
        )
        if employee is None:
            abort(404)

        history_rights = get_job_history_rights(client, profile)
        history = []
        can_view_history = JOB_HISTORY_RIGHTS["view"] in history_rights
        if can_view_history and not employee.get("is_deleted"):
            history = (
                client.table("jobhistory_active")
                .select("jobcode, deptcode, effdate, salary")
                .eq("empno", employee_no)
                .order("effdate", desc=True)
                .execute()
                .data or []
            )
            jobs = (
                client.table("job_active")
                .select("jobcode, jobdesc")
                .execute()
                .data or []
            )
            departments = (
                client.table("department_active")
                .select("deptcode, deptname")
                .execute()
                .data or []
            )
    except (APIError, httpx.HTTPError, RuntimeError, KeyError, TypeError):
        app.logger.exception("Employee profile could not be loaded")
        return jsonify(error="Employee profile data needs database setup or could not be loaded."), 503

    today = datetime.now(MANILA_TIMEZONE).date()
    current_history = None
    for row in history:
        try:
            effective_date = date.fromisoformat(str(row.get("effdate"))[:10])
        except ValueError:
            continue
        if effective_date <= today:
            current_history = row
            break
    job_labels = {
        row["jobcode"]: row.get("jobdesc")
        for row in jobs
    } if can_view_history and not employee.get("is_deleted") else {}
    department_labels = {
        row["deptcode"]: row.get("deptname")
        for row in departments
    } if can_view_history and not employee.get("is_deleted") else {}
    timeline = []
    for row in history:
        try:
            effective_date = date.fromisoformat(str(row.get("effdate"))[:10])
        except ValueError:
            continue
        timeline.append({
            "effDate": row.get("effdate"),
            "jobCode": row.get("jobcode"),
            "jobTitle": job_labels.get(row.get("jobcode")),
            "deptCode": row.get("deptcode"),
            "departmentName": department_labels.get(row.get("deptcode")),
            "salary": row.get("salary"),
            "status": (
                "Upcoming" if effective_date > today
                else "Current" if row is current_history and employee_is_current(employee.get("sepdate"))
                else "Previous"
            ),
        })

    try:
        permissions = get_permissions_for_user(client, profile)
    except (APIError, httpx.HTTPError, KeyError, TypeError):
        app.logger.exception("Employee profile permissions could not be loaded")
        return jsonify(error="Employee profile permissions could not be checked."), 503
    return render_template(
        "employee_profile.html",
        profile=profile,
        employee=employee,
        timeline=timeline,
        can_view_history=can_view_history,
        is_current=employee_is_current(employee.get("sepdate")),
        is_admin=is_admin,
        sidebar_modules=module_cards(permissions),
    )


@app.get("/api/hr/employees/<employee_no>/job-history")
def api_list_employee_job_history(employee_no):
    client, profile, context, _actions, error = get_employee_job_history_access(
        employee_no, "view"
    )
    if error:
        return error
    requested_status = request.args.get("status", "active")
    if requested_status not in {"active", "inactive", "all"}:
        return jsonify(error="Choose Active, Inactive, or All."), 400
    is_admin = profile["role"] in {"admin", "superadmin"}
    status_filter = requested_status if is_admin else "active"
    columns = "empno, jobcode, deptcode, effdate, salary"
    admin_columns = f"{columns}, is_deleted, stamp"
    try:
        active_rows = (
            client.table("jobhistory_active")
            .select(admin_columns if is_admin else columns)
            .eq("empno", employee_no)
            .order("effdate", desc=True)
            .execute()
            .data or []
        )
        inactive_rows = []
        if is_admin:
            inactive_rows = (
                client.table("jobhistory")
                .select(admin_columns)
                .eq("empno", employee_no)
                .eq("is_deleted", True)
                .order("effdate", desc=True)
                .execute()
                .data or []
            )
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, {"name": "Job History"})
    counts = {
        "active": len(active_rows),
        "inactive": len(inactive_rows),
        "all": len(active_rows) + len(inactive_rows),
    }
    rows = (
        active_rows if status_filter == "active"
        else inactive_rows if status_filter == "inactive"
        else active_rows + inactive_rows
    )
    search = request.args.get("search", "").strip().casefold()
    if search:
        rows = [
            row for row in rows
            if any(
                search in str(row.get(column) or "").casefold()
                for column in ("jobcode", "deptcode", "effdate", "salary")
            )
        ]
    return jsonify(
        employee={
            "empNo": context["employee"]["empno"],
            "name": " ".join(
                part for part in (
                    context["employee"].get("firstname"),
                    context["employee"].get("lastname"),
                ) if part
            ),
        },
        records=[job_history_response_record(row, is_admin) for row in rows],
        counts=counts if is_admin else None,
        is_admin=is_admin,
        actions={
            action: is_admin or JOB_HISTORY_RIGHTS[action] in context["rights"]
            for action in ("create", "edit", "delete")
        },
    )


@app.post("/api/hr/employees/<employee_no>/job-history")
def api_create_employee_job_history(employee_no):
    client, profile, _context, _actions, error = get_employee_job_history_access(
        employee_no, "create"
    )
    if error:
        return error
    values, validation_error = job_history_form_values(get_user_payload())
    if validation_error:
        return jsonify(error=validation_error), 400
    relation_error = validate_job_history_relations(client, values)
    if relation_error:
        return relation_error
    values["empno"] = employee_no
    try:
        response = client.table("jobhistory").insert(values).execute()
    except APIError as error:
        if error.code == "23503":
            return jsonify(error="Choose an active Job and, if provided, Department."), 400
        if error.code in {"23505", "P0001"}:
            return jsonify(error="An active job-history record already exists for that effective date."), 409
        return record_error_response(error, {"name": "Job History"})
    except (httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, {"name": "Job History"})
    if not response.data:
        return jsonify(error="Job History could not be created."), 502
    return jsonify(
        message="Job history added.",
        record=job_history_response_record(
            response.data[0], profile["role"] in {"admin", "superadmin"}
        ),
    ), 201


@app.patch("/api/hr/employees/<employee_no>/job-history/<effective_date>")
def api_edit_employee_job_history(employee_no, effective_date):
    client, profile, _context, _actions, error = get_employee_job_history_access(
        employee_no, "edit"
    )
    if error:
        return error
    if not is_iso_date(effective_date):
        return jsonify(error="Enter a valid effective date."), 400
    values, validation_error = job_history_form_values(get_user_payload())
    if validation_error:
        return jsonify(error=validation_error), 400
    relation_error = validate_job_history_relations(client, values)
    if relation_error:
        return relation_error
    try:
        current = (
            client.table("jobhistory")
            .select("is_deleted")
            .eq("empno", employee_no)
            .eq("effdate", effective_date)
            .eq("is_deleted", False)
            .maybe_single()
            .execute()
        )
        if current.data is None:
            return jsonify(error="Active job-history record not found."), 404
        response = (
            client.table("jobhistory")
            .update(values)
            .eq("empno", employee_no)
            .eq("effdate", effective_date)
            .eq("is_deleted", False)
            .execute()
        )
    except APIError as error:
        if error.code == "23503":
            return jsonify(error="Choose an active Job and, if provided, Department."), 400
        if error.code in {"23505", "P0001"}:
            return jsonify(error="An active job-history record already exists for that effective date."), 409
        return record_error_response(error, {"name": "Job History"})
    except (httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, {"name": "Job History"})
    if not response.data:
        return jsonify(error="Active job-history record not found."), 404
    return jsonify(
        message="Job history updated.",
        record=job_history_response_record(
            response.data[0], profile["role"] in {"admin", "superadmin"}
        ),
    )


@app.patch("/api/hr/employees/<employee_no>/job-history/<effective_date>/delete")
def api_delete_employee_job_history(employee_no, effective_date):
    client, _profile, _context, _actions, error = get_employee_job_history_access(
        employee_no, "delete"
    )
    if error:
        return error
    if not is_iso_date(effective_date):
        return jsonify(error="Enter a valid effective date."), 400
    try:
        response = (
            client.table("jobhistory")
            .update({"is_deleted": True})
            .eq("empno", employee_no)
            .eq("effdate", effective_date)
            .eq("is_deleted", False)
            .execute()
        )
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, {"name": "Job History"})
    if not response.data:
        return jsonify(error="Active job-history record not found."), 404
    return jsonify(message="Job history moved to Inactive.")


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
        return None, None, None, None, (jsonify(error="You must be logged in."), 401)
    profile = get_current_profile(client)
    if not profile_is_active(profile):
        return None, None, None, None, (jsonify(error="This account is not active."), 403)
    config = RECORD_MODULES.get(module_slug)
    if config is None:
        return None, None, None, None, (jsonify(error="Unknown module."), 404)
    if action not in config.get("allowed_actions", RIGHTS_ACTIONS):
        return None, None, None, None, (
            jsonify(error=f"{action.title()} is not available for {config['name'].lower()} records."),
            403,
        )
    try:
        permissions = get_permissions_for_user(client, profile)
        actions = get_record_actions(client, profile, config, permissions)
    except (APIError, httpx.HTTPError):
        app.logger.exception("Record permissions could not be loaded")
        return None, None, None, None, (
            jsonify(error="Module access needs database setup or could not be checked."),
            503,
        )
    if not actions["view"]:
        return None, None, None, None, (
            jsonify(error="View access is required for this module."),
            403,
        )
    if not actions[action]:
        return None, None, None, None, (
            jsonify(error="You do not have permission for this action."),
            403,
        )
    return client, profile, config, actions, None


def get_record_actions(client, profile, config, permissions):
    if profile["role"] in {"admin", "superadmin"}:
        return {action: True for action in RIGHTS_ACTIONS}

    rights_module = config.get("rights_module")
    rights_resource = config.get("rights_resource")
    if not rights_module or not rights_resource:
        return {
            action: has_permission(permissions, config["permission"], action)
            for action in RIGHTS_ACTIONS
        }

    try:
        assignments = (
            client.table("user_permission")
            .select("right_code")
            .eq("user_id", profile["id"])
            .eq("is_deleted", False)
            .execute()
        )
    except APIError as error:
        if error.code not in {"PGRST205", "42P01"}:
            raise
        assignments = None

    if assignments is None or not assignments.data:
        return {
            action: has_permission(permissions, config["permission"], action)
            for action in RIGHTS_ACTIONS
        }

    right_codes = [row["right_code"] for row in assignments.data]
    catalog = (
        client.table("right_catalog")
        .select("right_code, resource_code, action")
        .eq("module_code", rights_module)
        .in_("right_code", right_codes)
        .execute()
    )
    granted = {
        (row["resource_code"], row["action"])
        for row in catalog.data or []
    }
    return {
        action: (
            config.get("rights_view_resource", rights_resource)
            if action == "view"
            else rights_resource,
            "add" if action == "create" else action,
        ) in granted
        for action in RIGHTS_ACTIONS
    }


def parse_sale_header(payload):
    if not isinstance(payload, Mapping) or set(payload) != {
        "salesDate", "customerNo", "employeeNo"
    }:
        return None, "Enter a sale date, customer, and salesperson."
    sale_date = payload.get("salesDate")
    if not isinstance(sale_date, str):
        return None, "Enter a valid sale date."
    try:
        parsed_date = date.fromisoformat(sale_date)
    except ValueError:
        return None, "Enter a valid sale date."
    if parsed_date.isoformat() != sale_date:
        return None, "Enter a valid sale date."
    customer_no = payload.get("customerNo")
    employee_no = payload.get("employeeNo")
    if not isinstance(customer_no, str) or not customer_no.strip() or len(customer_no.strip()) > 5:
        return None, "Choose a valid customer."
    if not isinstance(employee_no, str) or not employee_no.strip() or len(employee_no.strip()) > 5:
        return None, "Choose a valid salesperson."
    return {
        "salesdate": parsed_date.isoformat(),
        "custno": customer_no.strip(),
        "empno": employee_no.strip(),
    }, None


def parse_sale_detail(payload):
    expected_fields = {"productCode", "quantity"}
    if not isinstance(payload, Mapping) or set(payload) != expected_fields:
        return None, "Enter a product and quantity."
    product_code = payload.get("productCode")
    if (
        not isinstance(product_code, str)
        or not product_code.strip()
        or len(product_code.strip()) > 6
    ):
        return None, "Choose a valid product."
    quantity = payload.get("quantity")
    if not isinstance(quantity, (str, int, float, Decimal)) or isinstance(quantity, bool):
        return None, "Enter a valid quantity."
    try:
        parsed_quantity = Decimal(str(quantity))
    except InvalidOperation:
        return None, "Enter a valid quantity."
    if (
        not parsed_quantity.is_finite()
        or parsed_quantity <= 0
        or parsed_quantity.as_tuple().exponent < -2
        or parsed_quantity >= Decimal("100000000")
    ):
        return None, (
            "Quantity must be greater than zero, fit within eight integer digits, "
            "and have at most two decimal places."
        )
    return {
        "product_code": product_code.strip(),
        "quantity": format(parsed_quantity, "f"),
    }, None


def parse_sale_payment(payload):
    if not isinstance(payload, Mapping) or set(payload) != {"paymentDate", "amount"}:
        return None, "Enter a payment date and amount."
    payment_date = payload.get("paymentDate")
    if not isinstance(payment_date, str):
        return None, "Enter a valid payment date."
    try:
        parsed_date = date.fromisoformat(payment_date)
    except ValueError:
        return None, "Enter a valid payment date."
    if parsed_date.isoformat() != payment_date:
        return None, "Enter a valid payment date."

    amount = payload.get("amount")
    if not isinstance(amount, (str, int, float, Decimal)) or isinstance(amount, bool):
        return None, "Enter a valid payment amount."
    try:
        parsed_amount = Decimal(str(amount))
    except InvalidOperation:
        return None, "Enter a valid payment amount."
    if (
        not parsed_amount.is_finite()
        or parsed_amount <= 0
        or parsed_amount.as_tuple().exponent < -2
        or parsed_amount >= Decimal("100000000")
    ):
        return None, (
            "Payment must be greater than zero, fit within eight integer digits, "
            "and have at most two decimal places."
        )
    return {
        "payment_date": parsed_date.isoformat(),
        "amount": format(parsed_amount, "f"),
    }, None


def sales_detail_error_response(error):
    if isinstance(error, APIError):
        if error.code == "42501":
            return jsonify(error="You do not have permission for this Sales Detail action."), 403
        if error.code == "22023":
            message = str(error).lower()
            if "price" in message:
                return jsonify(error="No active price is available for this product on the sale date."), 400
            return jsonify(error="Choose an active product and enter a valid quantity."), 400
        if error.code == "23505":
            return jsonify(error="This product is already on the sale. Edit its existing line instead."), 409
        if error.code == "P0002":
            return jsonify(error="The sale or line item is no longer active."), 404
    return record_error_response(error, {"name": "Sales detail"})


def sales_payment_error_response(error):
    if isinstance(error, APIError):
        if error.code == "42501":
            return jsonify(error="Sales View and Add permissions are required to record a payment."), 403
        if error.code == "22023":
            return jsonify(error="Enter a valid payment date and amount for an active sale."), 400
        if error.code == "P0002":
            return jsonify(error="The active sale could not be found."), 404
        if error.code == "P0001" and "receipt number" in str(error).lower():
            return jsonify(error="A receipt number could not be allocated. Contact an administrator."), 503
    return record_error_response(error, {"name": "Sales payment"})


def get_report_rights(client, profile):
    if profile["role"] in {"admin", "superadmin"}:
        return list(REPORTS)
    right_codes = [report["right"] for report in REPORTS.values()]
    assignments = (
        client.table("user_permission")
        .select("right_code")
        .eq("user_id", profile["id"])
        .eq("is_deleted", False)
        .in_("right_code", right_codes)
        .execute()
    )
    granted = {row["right_code"] for row in assignments.data or []}
    return [
        slug for slug, report in REPORTS.items()
        if report["right"] in granted
    ]


def parse_report_filters(report_slug, query):
    filters = {"start_date": None, "end_date": None, "top_n": 10, "employee_no": None}
    report = REPORTS[report_slug]
    if "date_range" in report["filters"]:
        start_value = query.get("startDate")
        end_value = query.get("endDate")
        try:
            start_date = date.fromisoformat(start_value or "")
            end_date = date.fromisoformat(end_value or "")
        except ValueError:
            return None, "Enter a valid start and end date."
        if start_date.isoformat() != start_value or end_date.isoformat() != end_value:
            return None, "Enter a valid start and end date."
        if end_date < start_date:
            return None, "End date must be on or after the start date."
        filters["start_date"] = start_date.isoformat()
        filters["end_date"] = end_date.isoformat()
        raw_top_n = query.get("topN", "10")
        if not raw_top_n.isdecimal():
            return None, "Top N must be a whole number between 1 and 100."
        top_n = int(raw_top_n)
        if not 1 <= top_n <= 100:
            return None, "Top N must be a whole number between 1 and 100."
        filters["top_n"] = top_n
    if "employee" in report["filters"]:
        employee_no = query.get("employeeNo", "").strip()
        if len(employee_no) > 5:
            return None, "Choose a valid employee."
        filters["employee_no"] = employee_no or None
    return filters, None


def get_report_access(report_slug):
    client = get_authenticated_client()
    if client is None:
        return None, None, None, (jsonify(error="You must be logged in."), 401)
    profile = get_current_profile(client)
    if not profile_is_active(profile):
        return None, None, None, (jsonify(error="This account is not active."), 403)
    report = REPORTS.get(report_slug)
    if report is None:
        return None, None, None, (jsonify(error="Unknown report."), 404)
    try:
        permissions = get_permissions_for_user(client, profile)
        if not has_permission(permissions, "Reports", "view"):
            return None, None, None, (jsonify(error="Reports View access is required."), 403)
        granted_reports = get_report_rights(client, profile)
    except (APIError, httpx.HTTPError, RuntimeError, KeyError, TypeError):
        app.logger.exception("Report permissions could not be loaded")
        return None, None, None, (
            jsonify(error="Report permissions need database setup or could not be checked."),
            503,
        )
    if report_slug not in granted_reports:
        return None, None, None, (jsonify(error="You do not have permission to view this report."), 403)
    return client, profile, report, None


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
        options = field.get("options", ())
        option_values = {
            option["value"] if isinstance(option, Mapping) else option
            for option in options
        }
        if options and value and value not in option_values:
            return None, f"Choose valid {field['label'].lower()}."
        if value and field.get("type") == "date":
            try:
                parsed_date = date.fromisoformat(value)
            except ValueError:
                return None, f"Enter a valid {field['label'].lower()}."
            if parsed_date.isoformat() != value:
                return None, f"Enter a valid {field['label'].lower()}."
        values[field["column"]] = value or None
    return values, None


def record_response_record(row, config, is_admin):
    record = {
        field["name"]: row.get(field["column"])
        for field in config["fields"]
    }
    if is_admin:
        record.update(
            isDeleted=row.get("is_deleted") is True,
            stamp=display_stamp(row.get("stamp")),
        )
    return record


PRICE_HISTORY_RIGHTS = {
    "create": "products.priceHistory.add",
    "edit": "products.priceHistory.edit",
    "delete": "products.priceHistory.delete",
}
JOB_HISTORY_RIGHTS = {
    "view": "hr.jobHistory.view",
    "create": "hr.jobHistory.add",
    "edit": "hr.jobHistory.edit",
    "delete": "hr.jobHistory.delete",
}


def get_job_history_rights(client, profile):
    if profile["role"] in {"admin", "superadmin"}:
        return set(JOB_HISTORY_RIGHTS.values())
    assignments = (
        client.table("user_permission")
        .select("right_code")
        .eq("user_id", profile["id"])
        .eq("is_deleted", False)
        .in_("right_code", list(JOB_HISTORY_RIGHTS.values()))
        .execute()
    )
    return {row["right_code"] for row in assignments.data or []}


def get_employee_job_history_access(employee_no, action):
    client = get_authenticated_client()
    if client is None:
        return None, None, None, None, (jsonify(error="You must be logged in."), 401)
    profile = get_current_profile(client)
    if not profile_is_active(profile):
        return None, None, None, None, (jsonify(error="This account is not active."), 403)
    if action not in JOB_HISTORY_RIGHTS:
        return None, None, None, None, (jsonify(error="Unknown job history action."), 400)
    try:
        employee = (
            client.table("employee")
            .select("empno, lastname, firstname, is_deleted")
            .eq("empno", employee_no)
            .maybe_single()
            .execute()
            .data
        )
        if employee is None:
            return None, None, None, None, (jsonify(error="Employee not found."), 404)
        rights = get_job_history_rights(client, profile)
    except (APIError, httpx.HTTPError, RuntimeError, KeyError, TypeError) as error:
        app.logger.exception("Job history access could not be checked")
        return None, None, None, None, (
            jsonify(error="Job History rights or employee data need database setup or could not be checked."),
            503,
        )
    if JOB_HISTORY_RIGHTS["view"] not in rights:
        return None, None, None, None, (
            jsonify(error="Job History view permission is required."),
            403,
        )
    if action != "view" and JOB_HISTORY_RIGHTS[action] not in rights:
        return None, None, None, None, (
            jsonify(error=f"Job History {action} permission is required."),
            403,
        )
    if action != "view" and employee.get("is_deleted"):
        return None, None, None, None, (
            jsonify(error="Restore this employee before changing job history."),
            409,
        )
    return client, profile, {"employee": employee, "rights": rights}, None, None


def job_history_form_values(payload):
    fields = {"effDate", "jobCode", "deptCode", "salary"}
    if not isinstance(payload, Mapping) or set(payload) != fields:
        return None, "Enter an effective date, job, department, and salary."
    effective_date = payload.get("effDate")
    if not isinstance(effective_date, str):
        return None, "Enter a valid effective date."
    try:
        parsed_date = date.fromisoformat(effective_date)
    except ValueError:
        return None, "Enter a valid effective date."
    if parsed_date.isoformat() != effective_date:
        return None, "Enter a valid effective date."
    job_code = payload.get("jobCode")
    department_code = payload.get("deptCode")
    if not isinstance(job_code, str) or not job_code.strip() or len(job_code.strip()) > 4:
        return None, "Choose a valid job."
    if not isinstance(department_code, str) or len(department_code.strip()) > 4:
        return None, "Choose a valid department."
    raw_salary = payload.get("salary")
    if not isinstance(raw_salary, str):
        return None, "Enter a valid salary."
    try:
        salary = Decimal(raw_salary)
    except InvalidOperation:
        return None, "Enter a valid salary."
    if (
        not salary.is_finite()
        or salary < 0
        or salary.as_tuple().exponent < -2
        or salary > Decimal("99999999.99")
    ):
        return None, "Salary must be zero or more and have at most 2 decimal places."
    return {
        "effdate": parsed_date.isoformat(),
        "jobcode": job_code.strip(),
        "deptcode": department_code.strip() or None,
        "salary": format(salary.quantize(Decimal("0.01")), "f"),
    }, None


def validate_job_history_relations(client, values):
    try:
        job = (
            client.table("job_active")
            .select("jobcode")
            .eq("jobcode", values["jobcode"])
            .maybe_single()
            .execute()
        )
        if job.data is None:
            return jsonify(error="Choose an active Job."), 400
        if values["deptcode"]:
            department = (
                client.table("department_active")
                .select("deptcode")
                .eq("deptcode", values["deptcode"])
                .maybe_single()
                .execute()
            )
            if department.data is None:
                return jsonify(error="Choose an active Department."), 400
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        app.logger.exception("Job history Job/Department choices could not be verified")
        return jsonify(error="Job and Department choices could not be verified."), 503
    return None


def job_history_response_record(row, is_admin):
    record = {
        "empNo": row.get("empno"),
        "jobCode": row.get("jobcode"),
        "effDate": row.get("effdate"),
        "salary": row.get("salary"),
        "deptCode": row.get("deptcode"),
    }
    if is_admin:
        record.update(
            isDeleted=row.get("is_deleted") is True,
            stamp=display_stamp(row.get("stamp")),
        )
    return record


def get_price_history_access(product_code, action):
    client = get_authenticated_client()
    if client is None:
        return None, None, None, (
            jsonify(error="You must be logged in."),
            401,
        )
    profile = get_current_profile(client)
    if not profile_is_active(profile):
        return None, None, None, (
            jsonify(error="This account is not active."),
            403,
        )

    is_admin = profile["role"] in {"admin", "superadmin"}
    rights = set()
    try:
        permissions = get_permissions_for_user(client, profile)
        if not is_admin and not permissions["Product"]["view"]:
            return None, None, None, (
                jsonify(error="Product view access is required."),
                403,
            )
        if not is_admin:
            response = (
                client.table("user_permission")
                .select("right_code")
                .eq("user_id", profile["id"])
                .eq("is_deleted", False)
                .in_("right_code", list(PRICE_HISTORY_RIGHTS.values()))
                .execute()
            )
            rights = {row["right_code"] for row in response.data or []}
    except (APIError, httpx.HTTPError):
        app.logger.exception("Price history permissions could not be loaded")
        return None, None, None, (
            jsonify(error="Price History rights need database setup or could not be checked."),
            503,
        )

    if not is_admin and action in PRICE_HISTORY_RIGHTS:
        if PRICE_HISTORY_RIGHTS[action] not in rights:
            return None, None, None, (
                jsonify(error=f"Price History {action} permission is required."),
                403,
            )

    try:
        product = (
            client.table("product")
            .select("prodcode, description, unit, is_deleted")
            .eq("prodcode", product_code)
            .maybe_single()
            .execute()
        )
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return None, None, None, record_error_response(
            error, {"name": "Price History"}
        )
    if product.data is None:
        return None, None, None, (
            jsonify(error="Product not found."),
            404,
        )
    if action in {"create", "edit", "delete"} and product.data.get("is_deleted"):
        return None, None, None, (
            jsonify(error="Restore this product before changing its price history."),
            409,
        )
    return client, profile, {"product": product.data, "rights": rights}, None


def price_history_form_values(payload):
    if not isinstance(payload, Mapping) or set(payload) != {"effDate", "unitPrice"}:
        return None, "Enter an effective date and unit price."
    effective_date = payload.get("effDate")
    if not isinstance(effective_date, str):
        return None, "Enter a valid effective date."
    try:
        parsed_date = date.fromisoformat(effective_date)
    except ValueError:
        return None, "Enter a valid effective date."
    if parsed_date.isoformat() != effective_date:
        return None, "Enter a valid effective date."

    raw_price = payload.get("unitPrice")
    if not isinstance(raw_price, str):
        return None, "Enter a valid unit price."
    try:
        unit_price = Decimal(raw_price)
    except InvalidOperation:
        return None, "Enter a valid unit price."
    if (
        not unit_price.is_finite()
        or unit_price <= 0
        or unit_price.as_tuple().exponent < -2
        or unit_price > Decimal("99999999.99")
    ):
        return None, "Unit price must be greater than zero and have at most 2 decimal places."
    return {
        "effdate": parsed_date.isoformat(),
        "unitprice": format(unit_price.quantize(Decimal("0.01")), "f"),
    }, None


def is_iso_date(value):
    if not isinstance(value, str):
        return False
    try:
        return date.fromisoformat(value).isoformat() == value
    except ValueError:
        return False


def price_history_response_record(row, is_admin):
    record = {
        "prodCode": row.get("prodcode"),
        "effDate": row.get("effdate"),
        "unitPrice": row.get("unitprice"),
    }
    if is_admin:
        record.update(
            isDeleted=row.get("is_deleted") is True,
            stamp=display_stamp(row.get("stamp")),
        )
    return record


@app.get("/products/<product_code>/price-history")
def product_price_history(product_code):
    client, profile, context, error = get_price_history_access(product_code, "view")
    if error:
        if error[1] == 401:
            return redirect(url_for("login"))
        if error[1] == 403:
            return redirect(url_for("index"))
        return error

    permissions = get_permissions_for_user(client, profile)
    is_admin = profile["role"] in {"admin", "superadmin"}
    actions = {
        action: is_admin or PRICE_HISTORY_RIGHTS[action] in context["rights"]
        for action in PRICE_HISTORY_RIGHTS
    }
    return render_template(
        "price_history.html",
        profile=profile,
        product=context["product"],
        is_admin=is_admin,
        actions=actions,
        sidebar_modules=module_cards(permissions),
    )


@app.get("/api/products/<product_code>/price-history")
def api_list_price_history(product_code):
    client, profile, context, error = get_price_history_access(product_code, "view")
    if error:
        return error
    requested_status = request.args.get("status", "active")
    if requested_status not in {"active", "inactive", "all"}:
        return jsonify(error="Choose Active, Inactive, or All."), 400
    is_admin = profile["role"] in {"admin", "superadmin"}
    status_filter = requested_status if is_admin else "active"
    columns = "prodcode, effdate, unitprice"
    admin_columns = f"{columns}, is_deleted, stamp"
    try:
        active = (
            client.table("pricehist_active")
            .select(admin_columns if is_admin else columns)
            .eq("prodcode", product_code)
            .order("effdate", desc=True)
            .execute()
        )
        active_rows = active.data or []
        inactive_rows = []
        if is_admin:
            inactive = (
                client.table("pricehist")
                .select(admin_columns)
                .eq("prodcode", product_code)
                .eq("is_deleted", True)
                .order("effdate", desc=True)
                .execute()
            )
            inactive_rows = inactive.data or []
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, {"name": "Price History"})

    search = request.args.get("search", "").strip().casefold()
    rows = active_rows + inactive_rows if status_filter == "all" else (
        inactive_rows if status_filter == "inactive" else active_rows
    )
    if search:
        rows = [
            row for row in rows
            if search in str(row.get("effdate") or "").casefold()
            or search in str(row.get("unitprice") or "").casefold()
        ]
    counts = {
        "active": len(active_rows),
        "inactive": len(inactive_rows),
        "all": len(active_rows) + len(inactive_rows),
    }
    actions = {
        action: is_admin or PRICE_HISTORY_RIGHTS[action] in context["rights"]
        for action in PRICE_HISTORY_RIGHTS
    }
    return jsonify(
        product=context["product"],
        records=[price_history_response_record(row, is_admin) for row in rows],
        counts=counts if is_admin else None,
        is_admin=is_admin,
        actions=actions,
    )


@app.post("/api/products/<product_code>/price-history")
def api_create_price_history(product_code):
    client, profile, _context, error = get_price_history_access(product_code, "create")
    if error:
        return error
    values, validation_error = price_history_form_values(get_user_payload())
    if validation_error:
        return jsonify(error=validation_error), 400
    values["prodcode"] = product_code
    try:
        response = client.table("pricehist").insert(values).execute()
    except APIError as error:
        if error.code == "23505":
            return jsonify(error="A price already exists for that effective date."), 409
        return record_error_response(error, {"name": "Price History"})
    except (httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, {"name": "Price History"})
    return jsonify(
        message="Price added.",
        record=price_history_response_record(
            response.data[0], profile["role"] in {"admin", "superadmin"}
        )
        if response.data else None,
    ), 201


@app.patch("/api/products/<product_code>/price-history/<effective_date>")
def api_edit_price_history(product_code, effective_date):
    client, profile, _context, error = get_price_history_access(product_code, "edit")
    if error:
        return error
    if not is_iso_date(effective_date):
        return jsonify(error="Enter a valid effective date."), 400
    values, validation_error = price_history_form_values(get_user_payload())
    if validation_error:
        return jsonify(error=validation_error), 400
    try:
        current = (
            client.table("pricehist")
            .select("is_deleted")
            .eq("prodcode", product_code)
            .eq("effdate", effective_date)
            .maybe_single()
            .execute()
        )
        if current.data is None:
            return jsonify(error="Price history entry not found."), 404
        if current.data.get("is_deleted"):
            return jsonify(error="Restore this price history entry before editing."), 409
        response = (
            client.table("pricehist")
            .update(values)
            .eq("prodcode", product_code)
            .eq("effdate", effective_date)
            .eq("is_deleted", False)
            .execute()
        )
    except APIError as error:
        if error.code == "23505":
            return jsonify(error="A price already exists for that effective date."), 409
        return record_error_response(error, {"name": "Price History"})
    except (httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, {"name": "Price History"})
    return jsonify(
        message="Price updated.",
        record=price_history_response_record(
            response.data[0], profile["role"] in {"admin", "superadmin"}
        )
        if response.data else None,
    )


@app.patch("/api/products/<product_code>/price-history/<effective_date>/delete")
def api_delete_price_history(product_code, effective_date):
    client, _profile, _context, error = get_price_history_access(product_code, "delete")
    if error:
        return error
    if not is_iso_date(effective_date):
        return jsonify(error="Enter a valid effective date."), 400
    try:
        response = (
            client.table("pricehist")
            .update({"is_deleted": True})
            .eq("prodcode", product_code)
            .eq("effdate", effective_date)
            .eq("is_deleted", False)
            .execute()
        )
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, {"name": "Price History"})
    if not response.data:
        return jsonify(error="Price history entry not found or already inactive."), 404
    return jsonify(message="Price history entry moved to Inactive.")


@app.patch("/api/products/<product_code>/price-history/<effective_date>/restore")
def api_restore_price_history(product_code, effective_date):
    client, profile, _context, error = get_price_history_access(product_code, "delete")
    if error:
        return error
    if not is_iso_date(effective_date):
        return jsonify(error="Enter a valid effective date."), 400
    if profile["role"] not in {"admin", "superadmin"}:
        return jsonify(error="Only administrators can restore inactive price history."), 403
    try:
        response = (
            client.table("pricehist")
            .update({"is_deleted": False})
            .eq("prodcode", product_code)
            .eq("effdate", effective_date)
            .eq("is_deleted", True)
            .execute()
        )
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, {"name": "Price History"})
    if not response.data:
        return jsonify(error="Inactive price history entry not found."), 404
    return jsonify(message="Price history entry restored.")


@app.get("/api/records/<module_slug>")
def api_list_records(module_slug):
    client, profile, config, actions, error = get_record_access(module_slug, "view")
    if error:
        return error

    requested_status = request.args.get("status", "active")
    if requested_status not in {"active", "inactive", "all"}:
        return jsonify(error="Choose Active, Inactive, or All."), 400
    employee_gender = request.args.get("gender", "all")
    employee_status = request.args.get("employment", "all")
    if module_slug == "employees":
        if employee_gender not in {"all", "F", "M"}:
            return jsonify(error="Choose a valid gender filter."), 400
        if employee_status not in {"all", "current", "separated"}:
            return jsonify(error="Choose a valid employment filter."), 400

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
        current_prices = {}
        if module_slug == "products":
            product_codes = list({row["prodcode"] for row in rows})
            if product_codes:
                price_response = (
                    client.table("pricehist_current")
                    .select("prodcode, effdate, unitprice")
                    .in_("prodcode", product_codes)
                    .execute()
                )
                current_prices = {
                    row["prodcode"]: {
                        "unitPrice": row["unitprice"],
                        "effectiveDate": row["effdate"],
                    }
                    for row in price_response.data or []
                }
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, config)

    search = request.args.get("search", "").strip().casefold()
    if search:
        rows = [
            row for row in rows
            if any(search in str(row.get(column) or "").casefold() for column in business_columns)
        ]
    if module_slug == "employees":
        if employee_gender != "all":
            rows = [row for row in rows if row.get("gender") == employee_gender]
        if employee_status != "all":
            is_current = employee_status == "current"
            rows = [
                row for row in rows
                if employee_is_current(row.get("sepdate")) is is_current
            ]
    records = [
        record_response_record(row, config, is_admin)
        for row in rows
    ]
    if module_slug == "products":
        try:
            prices = (
                client.table("v_product_current_price")
                .select("prodcode, unitprice")
                .execute()
            )
            price_map = {
                row["prodcode"]: row["unitprice"]
                for row in (prices.data or [])
            }
        except (APIError, httpx.HTTPError, RuntimeError, KeyError, TypeError):
            price_map = {}
        for record in records:
            record["currentPrice"] = price_map.get(record.get("prodCode"))
    response_actions = {
        action: (
            actions[action]
            and action in config.get("allowed_actions", RIGHTS_ACTIONS)
        )
        for action in ("create", "edit", "delete")
    }
    if module_slug == "employees":
        try:
            history_rights = get_job_history_rights(client, profile)
        except (APIError, httpx.HTTPError, RuntimeError, KeyError, TypeError):
            app.logger.exception("Employee Job History rights could not be loaded")
            return jsonify(error="Job History permissions need database setup or could not be checked."), 503
        response_actions["jobHistoryView"] = (
            JOB_HISTORY_RIGHTS["view"] in history_rights
        )
        response_actions["profileView"] = True
    return jsonify(
        records=records,
        counts=counts if is_admin else None,
        is_admin=is_admin,
        actions=response_actions,
    )


@app.get("/api/sales/options")
def api_sales_options():
    client, _profile, _config, _actions, error = get_record_access("sales", "view")
    if error:
        return error
    try:
        response = client.rpc("hope_sales_form_options").execute()
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, {"name": "Sales"})
    options = response.data
    if not isinstance(options, Mapping):
        app.logger.error("Sales form options RPC returned an invalid response")
        return jsonify(error="Sales form choices could not be loaded."), 502
    return jsonify(
        customers=options.get("customers", []),
        salespeople=options.get("salespeople", []),
    )


@app.get("/api/reports/<report_slug>")
def api_run_report(report_slug):
    client, _profile, _report, error = get_report_access(report_slug)
    if error:
        return error
    filters, validation_error = parse_report_filters(report_slug, request.args)
    if validation_error:
        return jsonify(error=validation_error), 400
    try:
        response = client.rpc(
            "hope_run_report",
            {
                "p_report": report_slug,
                "p_start_date": filters["start_date"],
                "p_end_date": filters["end_date"],
                "p_top_n": filters["top_n"],
                "p_empno": filters["employee_no"],
            },
        ).execute()
    except APIError as error:
        if error.code == "42501":
            return jsonify(error="You do not have permission to view this report."), 403
        if error.code == "P0002":
            return jsonify(error="Choose an active employee."), 404
        return record_error_response(error, {"name": "Report"})
    except (httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, {"name": "Report"})
    if not isinstance(response.data, Mapping) or not isinstance(response.data.get("rows"), list):
        app.logger.error("Report RPC returned an invalid response for %s", report_slug)
        return jsonify(error="Report data could not be loaded."), 502
    return jsonify(
        report=report_slug,
        title=REPORTS[report_slug]["name"],
        rows=response.data["rows"],
        employeeOptions=response.data.get("employeeOptions", []),
    )


@app.get("/api/sales")
def api_list_sales():
    client, profile, config, actions, error = get_record_access("sales", "view")
    if error:
        return error
    requested_status = request.args.get("status", "active")
    if requested_status not in {"active", "inactive", "all"}:
        return jsonify(error="Choose Active, Inactive, or All."), 400
    is_admin = profile["role"] in {"admin", "superadmin"}
    status_filter = requested_status if is_admin else "active"
    fields = config["fields"]
    business_columns = [field["column"] for field in fields]
    admin_columns = ", ".join(business_columns + ["is_deleted", "stamp"])
    try:
        active_rows = (
            client.table("sales_active")
            .select(", ".join(business_columns))
            .order("salesdate", desc=True)
            .execute()
            .data or []
        )
        inactive_rows = []
        if is_admin:
            inactive_rows = (
                client.table("sales")
                .select(admin_columns)
                .eq("is_deleted", True)
                .order("salesdate", desc=True)
                .execute()
                .data or []
            )
        options_response = client.rpc("hope_sales_form_options").execute()
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, config)
    options = options_response.data
    if not isinstance(options, Mapping):
        app.logger.error("Sales form options RPC returned an invalid response")
        return jsonify(error="Sales list choices could not be loaded."), 502
    customer_names = {
        row["customerNo"]: row.get("customerName")
        for row in options.get("customers", [])
    }
    salesperson_names = {
        row["employeeNo"]: row.get("fullName")
        for row in options.get("salespeople", [])
    }
    counts = {
        "active": len(active_rows),
        "inactive": len(inactive_rows),
        "all": len(active_rows) + len(inactive_rows),
    }
    rows = (
        active_rows if status_filter == "active"
        else inactive_rows if status_filter == "inactive"
        else active_rows + inactive_rows
    )
    search = request.args.get("search", "").strip().casefold()
    if search:
        rows = [
            row for row in rows
            if search in str(row.get("transno") or "").casefold()
            or search in str(row.get("salesdate") or "").casefold()
            or search in str(customer_names.get(row.get("custno")) or "").casefold()
            or search in str(salesperson_names.get(row.get("empno")) or "").casefold()
            or search in str(row.get("custno") or "").casefold()
            or search in str(row.get("empno") or "").casefold()
        ]
    records = []
    for row in rows:
        record = record_response_record(row, config, is_admin)
        record["customerName"] = customer_names.get(row.get("custno"))
        record["salespersonName"] = salesperson_names.get(row.get("empno"))
        records.append(record)
    return jsonify(
        records=records,
        counts=counts if is_admin else None,
        is_admin=is_admin,
        actions={
            "create": actions["create"],
            "edit": False,
            "delete": False,
            "saleDetails": options.get("saleDetailActions"),
        },
    )


@app.post("/api/sales")
def api_create_sale():
    client, _profile, _config, _actions, error = get_record_access("sales", "create")
    if error:
        return error
    values, validation_error = parse_sale_header(get_user_payload())
    if validation_error:
        return jsonify(error=validation_error), 400
    try:
        response = client.rpc(
            "hope_create_sale",
            {
                "p_salesdate": values["salesdate"],
                "p_custno": values["custno"],
                "p_empno": values["empno"],
            },
        ).execute()
    except APIError as error:
        if error.code == "42501":
            return jsonify(error="Sales Add permission is required."), 403
        if error.code == "22023":
            return jsonify(error="Choose an active customer and salesperson."), 400
        if error.code == "P0001" and "transaction number" in str(error).lower():
            return jsonify(error="A transaction number could not be allocated. Contact an administrator."), 503
        return record_error_response(error, {"name": "Sales"})
    except (httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, {"name": "Sales"})
    data = response.data
    transaction_no = (
        data[0].get("transno")
        if isinstance(data, list) and data and isinstance(data[0], Mapping)
        else data.get("transno")
        if isinstance(data, Mapping)
        else data
        if isinstance(data, str)
        else None
    )
    if not isinstance(transaction_no, str):
        app.logger.error("Sale creation RPC returned no transaction number")
        return jsonify(error="Sale could not be created."), 502
    return jsonify(
        message=f"Sale {transaction_no} created.",
        transactionNo=transaction_no,
    ), 201


@app.get("/api/sales/<trans_no>/details")
def api_sale_details(trans_no):
    client, _profile, _config, _actions, error = get_record_access("sales", "view")
    if error:
        return error
    try:
        response = client.rpc(
            "hope_sales_details_data",
            {"p_transno": trans_no},
        ).execute()
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return sales_detail_error_response(error)
    if not isinstance(response.data, Mapping):
        app.logger.error("Sales detail data RPC returned an invalid response")
        return jsonify(error="Sale details could not be loaded."), 502
    return jsonify(response.data)


@app.post("/api/sales/<trans_no>/details")
def api_add_sale_detail(trans_no):
    client, _profile, _config, _actions, error = get_record_access("sales", "view")
    if error:
        return error
    values, validation_error = parse_sale_detail(get_user_payload())
    if validation_error:
        return jsonify(error=validation_error), 400
    try:
        client.rpc(
            "hope_add_sale_detail",
            {
                "p_transno": trans_no,
                "p_product_code": values["product_code"],
                "p_quantity": values["quantity"],
            },
        ).execute()
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return sales_detail_error_response(error)
    return jsonify(message="Sale line added."), 201


@app.patch("/api/sales/<trans_no>/details/<product_code>")
def api_edit_sale_detail(trans_no, product_code):
    client, _profile, _config, _actions, error = get_record_access("sales", "view")
    if error:
        return error
    values, validation_error = parse_sale_detail(get_user_payload())
    if validation_error:
        return jsonify(error=validation_error), 400
    try:
        client.rpc(
            "hope_edit_sale_detail",
            {
                "p_transno": trans_no,
                "p_old_product_code": product_code,
                "p_product_code": values["product_code"],
                "p_quantity": values["quantity"],
            },
        ).execute()
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return sales_detail_error_response(error)
    return jsonify(message="Sale line updated.")


@app.delete("/api/sales/<trans_no>/details/<product_code>")
def api_delete_sale_detail(trans_no, product_code):
    client, _profile, _config, _actions, error = get_record_access("sales", "view")
    if error:
        return error
    try:
        client.rpc(
            "hope_delete_sale_detail",
            {
                "p_transno": trans_no,
                "p_product_code": product_code,
            },
        ).execute()
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return sales_detail_error_response(error)
    return jsonify(message="Sale line deleted.")


@app.get("/api/sales/<trans_no>/payments")
def api_sale_payments(trans_no):
    client, _profile, _config, _actions, error = get_record_access("sales", "view")
    if error:
        return error
    try:
        response = client.rpc(
            "hope_sales_payments_data",
            {"p_transno": trans_no},
        ).execute()
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return sales_payment_error_response(error)
    if not isinstance(response.data, Mapping):
        app.logger.error("Sales payment data RPC returned an invalid response")
        return jsonify(error="Sale payments could not be loaded."), 502
    return jsonify(response.data)


@app.post("/api/sales/<trans_no>/payments")
def api_add_sale_payment(trans_no):
    client, _profile, _config, _actions, error = get_record_access("sales", "create")
    if error:
        return error
    values, validation_error = parse_sale_payment(get_user_payload())
    if validation_error:
        return jsonify(error=validation_error), 400
    try:
        response = client.rpc(
            "hope_create_sale_payment",
            {
                "p_transno": trans_no,
                "p_paydate": values["payment_date"],
                "p_amount": values["amount"],
            },
        ).execute()
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return sales_payment_error_response(error)
    data = response.data
    receipt_no = (
        data[0].get("orno")
        if isinstance(data, list) and data and isinstance(data[0], Mapping)
        else data.get("orno")
        if isinstance(data, Mapping)
        else data
        if isinstance(data, str)
        else None
    )
    if not isinstance(receipt_no, str):
        app.logger.error("Sale payment RPC returned no receipt number")
        return jsonify(error="Payment could not be recorded."), 502
    return jsonify(
        message=f"Payment recorded as {receipt_no}.",
        receiptNo=receipt_no,
    ), 201


@app.post("/api/records/<module_slug>")
def api_create_record(module_slug):
    client, profile, config, _actions, error = get_record_access(module_slug, "create")
    if error:
        return error
    values, validation_error = record_form_values(config, get_user_payload())
    if validation_error:
        return jsonify(error=validation_error), 400
    try:
        response = client.table(config["table"]).insert(values).execute()
    except (APIError, httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, config)
    return jsonify(
        message=f"{config['singular']} added.",
        record=record_response_record(
            response.data[0],
            config,
            profile["role"] in {"admin", "superadmin"},
        ) if response.data else None,
    ), 201


@app.patch("/api/records/<module_slug>/<record_id>")
def api_edit_record(module_slug, record_id):
    client, profile, config, _actions, error = get_record_access(module_slug, "edit")
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
    return jsonify(
        message=f"{config['singular']} updated.",
        record=record_response_record(
            response.data[0],
            config,
            profile["role"] in {"admin", "superadmin"},
        ) if response.data else None,
    )


@app.patch("/api/records/<module_slug>/<record_id>/delete")
def api_delete_record(module_slug, record_id):
    client, profile, config, _actions, error = get_record_access(module_slug, "delete")
    if error:
        return error
    try:
        if module_slug == "customers":
            sales_check = client.rpc(
                "hope_customer_has_active_sales",
                {"p_custno": record_id},
            ).execute()
            if sales_check.data is True:
                return jsonify(
                    error="This customer cannot be deleted while active sales are linked."
                ), 409
        if module_slug == "products":
            active_prices = (
                client.table("pricehist_active")
                .select("prodcode")
                .eq("prodcode", record_id)
                .execute()
            )
            if active_prices.data:
                return jsonify(
                    error="This product cannot be deleted while active prices are linked."
                ), 409
            active_sales = (
                client.table("salesdetail_active")
                .select("prodcode")
                .eq("prodcode", record_id)
                .execute()
            )
            if active_sales.data:
                return jsonify(
                    error="This product cannot be deleted while active sale lines are linked."
                ), 409
        response = (
            client.table(config["table"])
            .update({"is_deleted": True})
            .eq(config["key"], record_id)
            .eq("is_deleted", False)
            .execute()
        )
    except APIError as error:
        if module_slug == "employees" and error.code in {"P0001", "23514"}:
            if "linked user profile" in str(error).lower():
                return jsonify(
                    error="This employee cannot be deleted while a user profile is linked. Unlink the profile first."
                ), 409
            if "cannot delete employee" in str(error).lower():
                return jsonify(
                    error="This employee cannot be deleted while active Job History or Sales records are linked."
                ), 409
        if (
            module_slug == "customers"
            and error.code in {"P0001", "23514"}
            and "Cannot delete customer" in str(error)
        ):
            return jsonify(
                error="This customer cannot be deleted while active sales are linked."
            ), 409
        if (
            module_slug == "departments"
            and error.code == "P0001"
            and "Cannot delete department row:" in str(error)
        ):
            return jsonify(
                error="This department cannot be deleted while active job history is linked."
            ), 409
        if (
            module_slug == "jobs"
            and error.code == "P0001"
            and "Cannot delete job row:" in str(error)
        ):
            return jsonify(
                error="This job cannot be deleted while active job history is linked."
            ), 409
        return record_error_response(error, config)
    except (httpx.HTTPError, RuntimeError) as error:
        return record_error_response(error, config)
    if not response.data:
        return jsonify(error=f"{config['singular']} not found or already inactive."), 404
    return jsonify(message=f"{config['singular']} moved to Inactive.")


@app.patch("/api/records/<module_slug>/<record_id>/restore")
def api_restore_record(module_slug, record_id):
    client, profile, config, _actions, error = get_record_access(module_slug, "delete")
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

    requested_status = request.args.get("status", "active")
    if requested_status not in {"active", "inactive", "all"}:
        return jsonify(error="Choose Active, Inactive, or All."), 400
    columns = "id, email, full_name, status, role, blocked, is_deleted, stamp, created_at"
    try:
        admin_client = get_admin_client()
        active_query = admin_client.table("profiles_active").select(columns)
        inactive_query = (
            admin_client.table("profiles")
            .select(columns)
            .eq("is_deleted", True)
        )
        if profile["role"] == "admin":
            active_query = active_query.in_("role", ["admin", "user"])
            inactive_query = inactive_query.in_("role", ["admin", "user"])
        active_rows = active_query.order("created_at", desc=True).execute().data or []
        inactive_rows = inactive_query.order("created_at", desc=True).execute().data or []
    except (RuntimeError, APIError, httpx.HTTPError):
        app.logger.exception("User list could not be loaded")
        return jsonify(error="Users could not be loaded. Please try again."), 502

    counts = {
        "active": len(active_rows),
        "inactive": len(inactive_rows),
        "all": len(active_rows) + len(inactive_rows),
    }
    if requested_status == "active":
        rows = active_rows
    elif requested_status == "inactive":
        rows = inactive_rows
    else:
        rows = active_rows + inactive_rows

    search = request.args.get("search", "").strip().casefold()
    if search:
        rows = [
            row for row in rows
            if search in str(row.get("full_name") or "").casefold()
            or search in str(row.get("email") or "").casefold()
            or search in str(row.get("role") or "").casefold()
        ]

    active_superadmins = [
        row for row in active_rows
        if row.get("role") == "superadmin"
        and not row.get("blocked")
        and row.get("status") == "approved"
    ]
    undeleted_superadmins = [
        row for row in active_rows
        if row.get("role") == "superadmin"
    ]
    users = []
    for row in rows:
        user = dict(row)
        user["status"] = (
            "blocked"
            if user.get("blocked") or user.get("status") == "blocked"
            else user.get("status")
        )
        user["isLastSuperadmin"] = (
            user.get("role") == "superadmin"
            and not user.get("is_deleted")
            and user.get("status") == "approved"
            and len(active_superadmins) == 1
        )
        user["isOnlySuperadmin"] = (
            user.get("role") == "superadmin"
            and not user.get("is_deleted")
            and len(undeleted_superadmins) == 1
        )
        user["isDeleted"] = user.get("is_deleted") is True
        user["stamp"] = display_stamp(user.get("stamp"))
        users.append(user)
    return jsonify(users=users, counts=counts, is_admin=True)


def get_managed_user(admin_client, profile, user_id, include_deleted=False):
    query = (
        admin_client.table("profiles")
        .select("id, email, full_name, status, role, blocked, is_deleted, stamp")
        .eq("id", user_id)
    )
    if profile["role"] == "admin":
        query = query.eq("role", "user")
    if not include_deleted:
        query = query.eq("is_deleted", False)
    return query.maybe_single().execute().data


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
            {
                "full_name": full_name,
                "role": "user",
                "status": "approved",
                "blocked": False,
                "is_deleted": False,
                "stamp": make_stamp("CREATED", profile),
            }
        ).eq("id", response.user.id).execute()
        if not profile_response.data:
            admin_client.auth.admin.delete_user(response.user.id)
            return jsonify(error="User profile could not be created."), 502
        write_profile_audit_log(
            admin_client,
            profile["id"],
            response.user.id,
            "profile.CREATED",
            {},
            {
                "email": email,
                "full_name": full_name,
                "role": "user",
                "status": "approved",
            },
        )
    except AuthError:
        app.logger.exception("Administrator user creation failed")
        return jsonify(error="User could not be created. Check the email and try again."), 400
    except APIError:
        app.logger.exception("Administrator user profile or audit entry could not be saved")
        return jsonify(error="User setup or audit logging failed. Contact an administrator."), 502
    except httpx.HTTPError:
        app.logger.exception("Administrator user creation request failed")
        return jsonify(error="User could not be created. Please try again."), 502
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
        admin_client = get_admin_client()
        target = get_managed_user(admin_client, profile, user_id)
        if target is None:
            return jsonify(error="User not found."), 404
        update_query = admin_client.table("profiles").update(
            {"full_name": full_name, "stamp": make_stamp("EDITED", profile)}
        ).eq("id", user_id).eq("is_deleted", False)
        if profile["role"] == "admin":
            update_query = update_query.eq("role", "user")
        if not update_query.execute().data:
            return jsonify(error="User not found."), 404
        write_profile_audit_log(
            admin_client,
            profile["id"],
            user_id,
            "profile.EDITED",
            {"full_name": target.get("full_name")},
            {"full_name": full_name},
        )
    except (RuntimeError, APIError, httpx.HTTPError):
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
    requested_status = payload.get("status") if payload else None
    if requested_status not in {"approved", "blocked"}:
        return jsonify(error="Status must be approved or blocked."), 400

    try:
        admin_client = get_admin_client()
        target = get_managed_user(admin_client, profile, user_id)
        if target is None:
            return jsonify(error="User not found."), 404
        if (
            profile["role"] != "superadmin"
            and target["status"] == "pending"
            and requested_status == "approved"
        ):
            return jsonify(error="Only a superadmin can approve pending users."), 403

        updates = {"stamp": make_stamp("EDITED", profile)}
        if requested_status == "blocked":
            updates["blocked"] = True
            event_type = "profile.BLOCKED"
        else:
            updates["blocked"] = False
            if target["status"] in {"pending", "blocked", "rejected"}:
                updates["status"] = "approved"
            event_type = (
                "profile.APPROVED"
                if target["status"] == "pending"
                else "profile.UNBLOCKED"
            )
        update_query = (
            admin_client.table("profiles")
            .update(updates)
            .eq("id", user_id)
            .eq("is_deleted", False)
        )
        if profile["role"] == "admin":
            update_query = update_query.eq("role", "user")
        if not update_query.execute().data:
            return jsonify(error="User not found."), 404
        old_values = {"status": target["status"], "blocked": target["blocked"]}
        new_values = {
            "status": updates.get("status", target["status"]),
            "blocked": updates["blocked"],
        }
        write_profile_audit_log(
            admin_client,
            profile["id"],
            user_id,
            event_type,
            old_values,
            new_values,
        )
    except APIError as error:
        if error.code == "23514" and "last superadmin" in str(error).casefold():
            return jsonify(error="The last active Superadmin cannot be blocked or removed."), 409
        app.logger.exception("Administrator user status update failed")
        return jsonify(error="User status could not be updated. Please try again."), 502
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
        admin_client = get_admin_client()
        target = get_managed_user(admin_client, profile, user_id)
        if target is None:
            return jsonify(error="User not found."), 404
        if target["role"] == "superadmin":
            return jsonify(error="Superadmin accounts cannot be demoted."), 403
        updated = (
            admin_client.table("profiles")
            .update({"role": role, "stamp": make_stamp("EDITED", profile)})
            .eq("id", user_id)
            .eq("is_deleted", False)
            .neq("role", "superadmin")
            .execute()
        )
        if not updated.data:
            return jsonify(error="User not found."), 404
        write_profile_audit_log(
            admin_client,
            profile["id"],
            user_id,
            "profile.ROLE_EDITED",
            {"role": target["role"]},
            {"role": role},
        )
    except (RuntimeError, APIError, httpx.HTTPError):
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
        admin_client = get_admin_client()
        target = get_managed_user(admin_client, profile, user_id)
        if target is None:
            return jsonify(error="User not found."), 404
        updated = (
            admin_client.table("profiles")
            .update(
                {
                    "is_deleted": True,
                    "stamp": make_stamp("DELETED", profile),
                }
            )
            .eq("id", user_id)
            .eq("is_deleted", False)
            .execute()
        )
        if not updated.data:
            return jsonify(error="User not found or already inactive."), 404
        write_profile_audit_log(
            admin_client,
            profile["id"],
            user_id,
            "profile.DELETED",
            {"is_deleted": False},
            {"is_deleted": True},
        )
    except APIError as error:
        if error.code == "23514" and "last superadmin" in str(error).casefold():
            return jsonify(error="The last Superadmin cannot be removed or disabled."), 409
        app.logger.exception("Superadmin user removal failed")
        return jsonify(error="User could not be removed. Please try again."), 502
    except (RuntimeError, httpx.HTTPError):
        app.logger.exception("Superadmin user removal failed")
        return jsonify(error="User could not be removed. Please try again."), 502

    return jsonify(message="User moved to Inactive.")


@app.patch("/api/users/<user_id>/restore")
def api_restore_user(user_id):
    client, profile = get_management_profile()
    if client is None:
        return jsonify(error="You must be logged in."), 401
    if profile is None:
        return jsonify(error="Administrator access is required."), 403

    try:
        admin_client = get_admin_client()
        target = get_managed_user(admin_client, profile, user_id, include_deleted=True)
        if target is None or not target["is_deleted"]:
            return jsonify(error="Inactive user not found."), 404
        updated = (
            admin_client.table("profiles")
            .update(
                {
                    "is_deleted": False,
                    "stamp": make_stamp("RESTORED", profile),
                }
            )
            .eq("id", user_id)
            .eq("is_deleted", True)
            .execute()
        )
        if not updated.data:
            return jsonify(error="Inactive user not found."), 404
        write_profile_audit_log(
            admin_client,
            profile["id"],
            user_id,
            "profile.RESTORED",
            {"is_deleted": True},
            {"is_deleted": False},
        )
    except (RuntimeError, APIError, httpx.HTTPError):
        app.logger.exception("Administrator user restore failed")
        return jsonify(error="User could not be restored. Please try again."), 502

    return jsonify(message="User restored.")


def get_rights_target(profile, user_id):
    target = (
        get_admin_client()
        .table("profiles")
        .select("id, role, is_deleted")
        .eq("id", user_id)
        .maybe_single()
        .execute()
    )
    if target.data is None or target.data["is_deleted"]:
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
        try:
            catalog_response = admin_client.table("right_catalog").select(
                "right_code, module_code, resource_code, action"
            ).order("module_code").order("right_code").execute()
            assignment_response = (
                admin_client.table("user_permission")
                .select("right_code")
                .eq("user_id", user_id)
                .eq("is_deleted", False)
                .execute()
            )
        except APIError as error:
            if not is_missing_rights_table(error):
                raise
            catalog = legacy_right_catalog()
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
            selected = (
                permissions_to_rights(catalog, legacy_permissions)
                if legacy_permissions
                else []
            )
            return jsonify(catalog=catalog, selected=selected)
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
        legacy_mode = False
        try:
            catalog_response = admin_client.table("right_catalog").select(
                "right_code, module_code, resource_code, action"
            ).order("module_code").order("right_code").execute()
            catalog = catalog_response.data or []
            current = admin_client.table("user_permission").select(
                "right_code, is_deleted, stamp"
            ).eq("user_id", user_id).execute()
        except APIError as error:
            if not is_missing_rights_table(error):
                raise
            catalog = legacy_right_catalog()
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
            active_rights = (
                set(permissions_to_rights(catalog, legacy_permissions))
                if legacy_permissions
                else set()
            )
            legacy_mode = True
        known_rights = {right["right_code"] for right in catalog}
        if not set(selected).issubset(known_rights):
            return jsonify(error="Rights include entries not in the database catalogue."), 400
        permissions = rights_to_permissions(
            catalog, [{"right_code": right_code} for right_code in selected]
        )
        if legacy_mode:
            admin_client.table("user_permissions").upsert(
                {"user_id": user_id, "permissions": permissions}
            ).execute()
        else:
            current_rows = current.data or []
            current_by_code = {row["right_code"]: row for row in current_rows}
            active_rights = {
                right_code
                for right_code, row in current_by_code.items()
                if not row["is_deleted"]
            }
            to_soft_delete = active_rights.difference(selected)
            if to_soft_delete:
                admin_client.table("user_permission").update(
                    {
                        "is_deleted": True,
                        "stamp": make_stamp("DELETED", profile),
                    }
                ).eq("user_id", user_id).in_("right_code", list(to_soft_delete)).execute()
            to_restore_or_create = set(selected).difference(active_rights)
            if to_restore_or_create:
                admin_client.table("user_permission").upsert(
                    [
                        {
                            "user_id": user_id,
                            "right_code": right_code,
                            "is_deleted": False,
                            "stamp": make_stamp(
                                "RESTORED" if right_code in current_by_code else "CREATED",
                                profile,
                            ),
                        }
                        for right_code in to_restore_or_create
                    ]
                ).execute()
            # Keep the original JSON contract synchronized for deployments that still read it.
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
        if (
            profile["status"] in {"blocked", "rejected"}
            or profile.get("blocked") is True
            or profile.get("is_deleted") is True
        ):
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
    if not profile_is_active(profile):
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
    profile = get_current_profile(client)
    if not profile_is_active(profile):
        session.clear()
        return jsonify(error="This account is not active."), 403

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
