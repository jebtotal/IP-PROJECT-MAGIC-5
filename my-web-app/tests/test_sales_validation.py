import base64
import os
from pathlib import Path
import sys
import unittest
from types import SimpleNamespace
from unittest.mock import MagicMock, patch


APP_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(APP_DIR))
os.environ.setdefault("SUPABASE_URL", "https://example.supabase.co")
os.environ.setdefault("SUPABASE_KEY", "test-publishable-key")

import app as web_app


class SalesDetailValidationTests(unittest.TestCase):
    def test_quantity_and_product_are_normalized(self):
        values, error = web_app.parse_sale_detail(
            {"productCode": "  PR0001 ", "quantity": "12.50"}
        )

        self.assertIsNone(error)
        self.assertEqual(
            values,
            {"product_code": "PR0001", "quantity": "12.50"},
        )

    def test_zero_quantity_is_rejected(self):
        values, error = web_app.parse_sale_detail(
            {"productCode": "PR0001", "quantity": "0"}
        )

        self.assertIsNone(values)
        self.assertIn("greater than zero", error)

    def test_quantity_with_more_than_two_decimal_places_is_rejected(self):
        values, error = web_app.parse_sale_detail(
            {"productCode": "PR0001", "quantity": "1.001"}
        )

        self.assertIsNone(values)
        self.assertIn("two decimal places", error)

    def test_quantity_outside_database_precision_is_rejected(self):
        values, error = web_app.parse_sale_detail(
            {"productCode": "PR0001", "quantity": "100000000"}
        )

        self.assertIsNone(values)
        self.assertIn("eight integer digits", error)

    def test_unsupported_fields_and_invalid_product_are_rejected(self):
        values, error = web_app.parse_sale_detail(
            {"productCode": "PR0001", "quantity": "1", "unitPrice": "10"}
        )
        self.assertIsNone(values)
        self.assertIn("product and quantity", error)

        values, error = web_app.parse_sale_detail(
            {"productCode": "TOOLONG7", "quantity": "1"}
        )
        self.assertIsNone(values)
        self.assertIn("valid product", error)


class SalesPaymentValidationTests(unittest.TestCase):
    def test_payment_date_and_amount_are_normalized(self):
        values, error = web_app.parse_sale_payment(
            {"paymentDate": "2026-11-22", "amount": "1250.50"}
        )

        self.assertIsNone(error)
        self.assertEqual(
            values,
            {"payment_date": "2026-11-22", "amount": "1250.50"},
        )

    def test_invalid_date_and_nonpositive_amount_are_rejected(self):
        values, error = web_app.parse_sale_payment(
            {"paymentDate": "2026-02-30", "amount": "1.00"}
        )
        self.assertIsNone(values)
        self.assertIn("valid payment date", error)

        values, error = web_app.parse_sale_payment(
            {"paymentDate": "2026-11-22", "amount": "0"}
        )
        self.assertIsNone(values)
        self.assertIn("greater than zero", error)

    def test_amount_precision_and_numeric_range_are_enforced(self):
        for amount in ("1.001", "100000000", "NaN", "Infinity"):
            with self.subTest(amount=amount):
                values, error = web_app.parse_sale_payment(
                    {"paymentDate": "2026-11-22", "amount": amount}
                )
                self.assertIsNone(values)
                self.assertIn("two decimal places", error)

    def test_unexpected_fields_and_boolean_amount_are_rejected(self):
        values, error = web_app.parse_sale_payment(
            {"paymentDate": "2026-11-22", "amount": "5", "receiptNo": "OR000001"}
        )
        self.assertIsNone(values)
        self.assertIn("payment date and amount", error)

        values, error = web_app.parse_sale_payment(
            {"paymentDate": "2026-11-22", "amount": True}
        )
        self.assertIsNone(values)
        self.assertIn("valid payment amount", error)


class SalesStatusRouteTests(unittest.TestCase):
    class RpcClient:
        def __init__(self):
            self.calls = []

        def rpc(self, name, params):
            self.calls.append((name, params))
            return self

        def execute(self):
            return type("Response", (), {"data": True})()

    def request_with_csrf(self, client, path):
        with client.session_transaction() as session:
            session["csrf_token"] = "test-token"
        return client.patch(path, headers={"X-CSRF-Token": "test-token"})

    def test_delete_uses_permission_checked_soft_delete_rpc(self):
        rpc_client = self.RpcClient()
        with patch.object(
            web_app,
            "get_record_access",
            return_value=(rpc_client, {"role": "user"}, {}, {"delete": True}, None),
        ):
            response = self.request_with_csrf(
                web_app.app.test_client(),
                "/api/sales/TR000001/delete",
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            rpc_client.calls,
            [(
                "hope_set_sale_deleted",
                {"p_transno": "TR000001", "p_is_deleted": True},
            )],
        )

    def test_non_admin_cannot_restore_sale(self):
        rpc_client = self.RpcClient()
        with patch.object(
            web_app,
            "get_record_access",
            return_value=(rpc_client, {"role": "user"}, {}, {"delete": True}, None),
        ):
            response = self.request_with_csrf(
                web_app.app.test_client(),
                "/api/sales/TR000001/restore",
            )

        self.assertEqual(response.status_code, 403)
        self.assertEqual(rpc_client.calls, [])

    def test_admin_restore_uses_permission_checked_soft_delete_rpc(self):
        rpc_client = self.RpcClient()
        with patch.object(
            web_app,
            "get_record_access",
            return_value=(rpc_client, {"role": "admin"}, {}, {"delete": True}, None),
        ):
            response = self.request_with_csrf(
                web_app.app.test_client(),
                "/api/sales/TR000001/restore",
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            rpc_client.calls,
            [(
                "hope_set_sale_deleted",
                {"p_transno": "TR000001", "p_is_deleted": False},
            )],
        )


class AuditLogAccessTests(unittest.TestCase):
    class RpcClient:
        def __init__(self, data):
            self.data = data
            self.calls = []

        def rpc(self, name, params):
            self.calls.append((name, params))
            return self

        def execute(self):
            return type("Response", (), {"data": self.data})()

    def test_audit_filters_validate_page_and_search_length(self):
        filters, error = web_app.parse_audit_log_filters(
            {"page": "2", "search": " sales "}
        )
        self.assertIsNone(error)
        self.assertEqual(filters, {
            "search": "sales",
            "page": 2,
            "page_size": 50,
            "offset": 50,
        })

        for args in (
            {"page": "0"},
            {"page": "20002"},
            {"page": "invalid"},
            {"search": "x" * 201},
        ):
            with self.subTest(args=args):
                filters, error = web_app.parse_audit_log_filters(args)
                self.assertIsNone(filters)
                self.assertIsNotNone(error)

    def test_non_superadmin_cannot_open_audit_api(self):
        with patch.object(
            web_app,
            "get_management_profile",
            return_value=(object(), {"role": "admin"}),
        ):
            response = web_app.app.test_client().get("/api/audit-log")

        self.assertEqual(response.status_code, 403)

    def test_profile_lookup_failure_returns_json_error(self):
        with patch.object(
            web_app,
            "get_management_profile",
            side_effect=RuntimeError("profile lookup failed"),
        ):
            response = web_app.app.test_client().get("/api/audit-log")

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.mimetype, "application/json")
        self.assertIn("access could not be checked", response.json["error"])

    def test_superadmin_audit_api_uses_paginated_read_rpc(self):
        rpc_client = self.RpcClient({"rows": [{"event_type": "hope.sales.ADD"}], "total": 1})
        with patch.object(
            web_app,
            "get_management_profile",
            return_value=(rpc_client, {"role": "superadmin"}),
        ):
            response = web_app.app.test_client().get(
                "/api/audit-log?page=2&search=sales"
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["rows"], [{"event_type": "hope.sales.ADD"}])
        self.assertEqual(rpc_client.calls, [(
            "hope_read_audit_log",
            {"p_search": "sales", "p_limit": 50, "p_offset": 50},
        )])

    def test_audit_migration_supports_profiles_without_is_deleted(self):
        migration = (
            APP_DIR
            / "supabase"
            / "migrations"
            / "20261122001400_s1_bld_09_audit_log_viewer.sql"
        ).read_text(encoding="utf-8")

        self.assertNotIn("'profiles', 'is_deleted'", migration)
        self.assertNotIn("profile.is_deleted", migration)
        self.assertIn(
            "COALESCE((to_jsonb(profile) ->> 'is_deleted')::BOOLEAN, FALSE)",
            migration,
        )


class ProfileCompatibilityTests(unittest.TestCase):
    def test_current_profile_lookup_does_not_require_optional_is_deleted(self):
        client = MagicMock()
        client.table.return_value.select.return_value.eq.return_value.maybe_single.return_value.execute.return_value.data = {
            "id": "user-id",
            "email": "superadmin@example.test",
            "full_name": "Superadmin",
            "status": "approved",
            "role": "superadmin",
            "blocked": False,
        }

        with web_app.app.test_request_context("/api/records/employees"):
            web_app.session["user_id"] = "user-id"
            profile = web_app.get_current_profile(client)

        self.assertEqual(profile["role"], "superadmin")
        client.auth.get_user.assert_not_called()
        selected_columns = client.table.return_value.select.call_args.args[0]
        self.assertNotIn("is_deleted", selected_columns)
        self.assertNotIn("stamp", selected_columns)
        self.assertTrue(web_app.profile_is_active(profile))

    def test_missing_profile_record_returns_no_profile_instead_of_database_setup_error(self):
        with (
            patch.object(web_app, "get_authenticated_client", return_value=object()),
            patch.object(
                web_app,
                "get_current_profile",
                return_value=None,
            ),
        ):
            response = web_app.app.test_client().get("/api/records/employees")

        self.assertEqual(response.status_code, 403)
        self.assertIn("No application profile", response.json["error"])


class SupabaseSessionRefreshTests(unittest.TestCase):
    def test_refreshed_supabase_tokens_are_saved_to_flask_session(self):
        auth_client = MagicMock()
        auth_client.auth.refresh_session.return_value = SimpleNamespace(
            session=SimpleNamespace(
                access_token="renewed-access",
                refresh_token="renewed-refresh",
                expires_at=4_000_000_000,
                user=None,
            )
        )

        with web_app.app.test_request_context("/api/records/employees"):
            web_app.session["access_token"] = "old-access"
            web_app.session["refresh_token"] = "rotated-refresh"
            web_app.session["access_token_expires_at"] = 0
            with patch.object(web_app, "get_supabase_client", return_value=auth_client):
                client = web_app.get_authenticated_client()

            self.assertIs(client, auth_client)
            auth_client.auth.refresh_session.assert_called_once_with("rotated-refresh")
            self.assertEqual(web_app.session["access_token"], "renewed-access")
            self.assertEqual(web_app.session["refresh_token"], "renewed-refresh")
            self.assertEqual(
                web_app.session["access_token_expires_at"],
                4_000_000_000,
            )
            auth_client.postgrest.auth.assert_called_once_with("renewed-access")

    def test_unexpired_session_uses_local_bearer_token_without_auth_network_call(self):
        auth_client = MagicMock()

        with web_app.app.test_request_context("/api/records/employees"):
            web_app.session["access_token"] = "valid-access"
            web_app.session["refresh_token"] = "refresh-token"
            web_app.session["access_token_expires_at"] = web_app.time.time() + 3600
            with patch.object(web_app, "get_supabase_client", return_value=auth_client):
                client = web_app.get_authenticated_client()

        self.assertIs(client, auth_client)
        auth_client.auth.set_session.assert_not_called()
        auth_client.auth.refresh_session.assert_not_called()
        auth_client.postgrest.auth.assert_called_once_with("valid-access")

    def test_existing_session_uses_expiry_hint_without_auth_network_call(self):
        auth_client = MagicMock()
        expires_at = int(web_app.time.time() + 3600)
        payload = base64.urlsafe_b64encode(
            f'{{"exp":{expires_at}}}'.encode()
        ).decode().rstrip("=")
        access_token = f"header.{payload}.signature"

        with web_app.app.test_request_context("/api/records/employees"):
            web_app.session["access_token"] = access_token
            web_app.session["refresh_token"] = "refresh-token"
            with patch.object(web_app, "get_supabase_client", return_value=auth_client):
                client = web_app.get_authenticated_client()

            self.assertEqual(
                web_app.session["access_token_expires_at"],
                expires_at,
            )

        self.assertIs(client, auth_client)
        auth_client.auth.set_session.assert_not_called()
        auth_client.auth.refresh_session.assert_not_called()
        auth_client.postgrest.auth.assert_called_once_with(access_token)

    def test_expiry_hint_rejects_malformed_or_non_numeric_expiration(self):
        tokens = [
            "malformed",
            "header.e30.signature",
            "header."
            + base64.urlsafe_b64encode(b"[]").decode().rstrip("=")
            + ".signature",
            "header."
            + base64.urlsafe_b64encode(b'{"exp":true}').decode().rstrip("=")
            + ".signature",
            "header."
            + base64.urlsafe_b64encode(b'{"exp":"tomorrow"}').decode().rstrip("=")
            + ".signature",
        ]
        for token in tokens:
            with self.subTest(token=token):
                self.assertIsNone(web_app.access_token_expiry_hint(token))

    def test_transient_auth_refresh_error_preserves_existing_session(self):
        auth_client = MagicMock()
        auth_client.auth.set_session.side_effect = web_app.AuthRetryableError(
            "Auth service temporarily unavailable",
            503,
        )

        with web_app.app.test_request_context("/api/records/employees"):
            web_app.session["access_token"] = "expired-access"
            web_app.session["refresh_token"] = "refresh-token"
            with patch.object(web_app, "get_supabase_client", return_value=auth_client):
                with self.assertRaises(web_app.AuthRetryableError):
                    web_app.get_authenticated_client()

            self.assertEqual(web_app.session["access_token"], "expired-access")
            self.assertEqual(web_app.session["refresh_token"], "refresh-token")

    def test_transient_auth_refresh_returns_retryable_api_error(self):
        with patch.object(
            web_app,
            "get_authenticated_client",
            side_effect=web_app.AuthRetryableError(
                "Auth service temporarily unavailable",
                503,
            ),
        ):
            response = web_app.app.test_client().get("/api/records/employees")

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.mimetype, "application/json")
        self.assertIn("Try again shortly", response.json["error"])
        self.assertNotIn("Sign in again", response.json["error"])

    def test_page_auth_timeout_returns_retryable_503_not_internal_error(self):
        with patch.object(
            web_app,
            "get_authenticated_client",
            side_effect=web_app.AuthRetryableError("Auth timeout", 503),
        ):
            response = web_app.app.test_client().get("/products")

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.mimetype, "text/html")
        self.assertIn(b"Service temporarily unavailable", response.data)
        self.assertIn(b"Try again", response.data)

    def test_audit_compatibility_migration_replaces_legacy_triggers_without_schema_changes(self):
        migration = (
            APP_DIR
            / "supabase"
            / "migrations"
            / "20261122001500_s1_dba_10_hope_audit_trigger_compat.sql"
        ).read_text(encoding="utf-8")

        self.assertIn("DROP TRIGGER IF EXISTS %I ON public.%I", migration)
        self.assertIn("r.table_name || '_aiu_audit'", migration)
        self.assertIn(
            "CREATE TRIGGER hope_20_audit_change AFTER INSERT OR UPDATE",
            migration,
        )
        self.assertNotIn("audit_log (table_name", migration)
        self.assertNotIn("ADD COLUMN", migration)


class RecordFormAndResponseTests(unittest.TestCase):
    def test_employee_form_marks_one_character_identifier_as_minimum(self):
        config = web_app.RECORD_MODULES["employees"]
        payload = {
            "empNo": "E",
            "lastName": "",
            "firstName": "",
            "gender": "",
            "birthDate": "",
            "hireDate": "",
            "sepDate": "",
        }

        values, error = web_app.record_form_values(config, payload)

        self.assertIsNone(error)
        self.assertEqual(values["empno"], "E")
        self.assertIsNone(values["lastname"])
        self.assertIsNone(values["gender"])
        self.assertIsNone(values["sepdate"])

        payload["empNo"] = " "
        values, error = web_app.record_form_values(config, payload)
        self.assertIsNone(values)
        self.assertIn("Employee No is required", error)

    def test_record_errors_distinguish_database_policy_denials(self):
        with web_app.app.test_request_context():
            try:
                raise web_app.APIError({
                    "message": "new row violates row-level security policy",
                    "code": "42501",
                })
            except web_app.APIError as error:
                response, status = web_app.record_error_response(
                    error,
                    web_app.RECORD_MODULES["departments"],
                )

        self.assertEqual(status, 403)
        self.assertIn("database policy", response.get_json()["error"])
        self.assertIn("Row Level Security", response.get_json()["error"])

    def test_unexpected_api_errors_return_json_instead_of_html(self):
        with patch.object(
            web_app,
            "get_record_access",
            side_effect=ValueError("unexpected failure"),
        ):
            response = web_app.app.test_client().get("/api/records/departments")

        self.assertEqual(response.status_code, 500)
        self.assertEqual(response.mimetype, "application/json")
        self.assertIn("could not complete", response.json["error"])

    def test_api_http_errors_are_json_without_changing_page_404s(self):
        client = web_app.app.test_client()

        api_response = client.get("/api/unknown-endpoint")
        page_response = client.get("/unknown-page")

        self.assertEqual(api_response.status_code, 404)
        self.assertEqual(api_response.mimetype, "application/json")
        self.assertEqual(page_response.status_code, 404)
        self.assertEqual(page_response.mimetype, "text/html")

    def test_expired_record_session_returns_json_unauthorized(self):
        with (
            patch.object(web_app, "get_authenticated_client", return_value=object()),
            patch.object(
                web_app,
                "get_current_profile",
                side_effect=web_app.AuthError("Session expired", None),
            ),
        ):
            response = web_app.app.test_client().get("/api/records/departments")

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.mimetype, "application/json")
        self.assertIn("session expired", response.json["error"])

    def test_employee_separated_filter_includes_any_gender(self):
        rows = [
            {
                "empno": "E0001",
                "lastname": "Past",
                "firstname": "Separated",
                "gender": "F",
                "birthdate": None,
                "hiredate": None,
                "sepdate": "2020-01-01",
                "is_deleted": False,
                "stamp": "ADD system",
            },
            {
                "empno": "E0002",
                "lastname": "Current",
                "firstname": "Employee",
                "gender": "M",
                "birthdate": None,
                "hiredate": None,
                "sepdate": None,
                "is_deleted": False,
                "stamp": "ADD system",
            },
        ]
        client = MagicMock()
        client.table.side_effect = lambda name: ProductDatabaseRouteTests.TableQuery(
            rows if name == "employee_active" else []
        )
        with (
            patch.object(
                web_app,
                "get_record_access",
                return_value=(
                    client,
                    {"role": "admin"},
                    web_app.RECORD_MODULES["employees"],
                    {"view": True, "create": True, "edit": True, "delete": True},
                    None,
                ),
            ),
            patch.object(web_app, "get_job_history_rights", return_value=set()),
        ):
            response = web_app.app.test_client().get(
                "/api/records/employees?status=active&gender=all&employment=separated"
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            [record["empNo"] for record in response.json["records"]],
            ["E0001"],
        )


class ProductDatabaseRouteTests(unittest.TestCase):
    class TableQuery:
        def __init__(self, rows):
            self.rows = rows

        def select(self, _columns):
            return self

        def order(self, *_args, **_kwargs):
            return self

        def eq(self, *_args, **_kwargs):
            return self

        def execute(self):
            return SimpleNamespace(data=self.rows)

    def test_product_list_uses_available_current_price_view(self):
        table_calls = []
        rows_by_table = {
            "product_active": [{
                "prodcode": "PR0001",
                "description": "Widget",
                "unit": "ea",
                "is_deleted": False,
                "stamp": "ADD system",
            }],
            "product": [],
            "v_product_current_price": [{
                "prodcode": "PR0001",
                "unitprice": "12.50",
            }],
        }
        client = MagicMock()
        client.table.side_effect = lambda name: (
            table_calls.append(name)
            or self.TableQuery(rows_by_table.get(name, []))
        )
        with patch.object(
            web_app,
            "get_record_access",
            return_value=(
                client,
                {"role": "admin"},
                web_app.RECORD_MODULES["products"],
                {"view": True, "create": True, "edit": True, "delete": True},
                None,
            ),
        ):
            response = web_app.app.test_client().get("/api/records/products")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json["records"][0]["currentPrice"], "12.50")
        self.assertIn("v_product_current_price", table_calls)
        self.assertNotIn("pricehist_current", table_calls)


class LoginErrorTests(unittest.TestCase):
    def test_only_sign_in_auth_error_is_reported_as_invalid_credentials(self):
        client = MagicMock()
        client.auth.sign_in_with_password.side_effect = web_app.AuthError(
            "Invalid login credentials",
            None,
        )
        with patch.object(web_app, "get_supabase_client", return_value=client):
            response = web_app.app.test_client().post(
                "/api/login",
                json={"email": "user@example.test", "password": "correct-password"},
            )

        self.assertEqual(response.status_code, 401)
        self.assertEqual(response.json["error"], "Invalid email or password.")
        client.auth.set_session.assert_not_called()

    def test_session_auth_error_is_not_reported_as_invalid_credentials(self):
        client = MagicMock()
        client.auth.sign_in_with_password.return_value = SimpleNamespace(
            session=SimpleNamespace(
                access_token="test-access-token",
                refresh_token="test-refresh-token",
            ),
            user=SimpleNamespace(id="user-id"),
        )
        with (
            patch.object(web_app, "get_supabase_client", return_value=client),
            patch.object(
                web_app,
                "get_current_profile",
                side_effect=web_app.AuthError("Session token rejected", None),
            ),
        ):
            response = web_app.app.test_client().post(
                "/api/login",
                json={"email": "user@example.test", "password": "correct-password"},
            )

        self.assertEqual(response.status_code, 502)
        self.assertIn("Authentication succeeded", response.json["error"])
        self.assertNotEqual(response.json["error"], "Invalid email or password.")


class ReportFilterTests(unittest.TestCase):
    def test_top_reports_require_valid_date_range_and_bounded_top_n(self):
        filters, error = web_app.parse_report_filters(
            "top_sales",
            {
                "startDate": "2026-11-01",
                "endDate": "2026-11-22",
                "topN": "25",
            },
        )

        self.assertIsNone(error)
        self.assertEqual(
            filters,
            {
                "start_date": "2026-11-01",
                "end_date": "2026-11-22",
                "top_n": 25,
                "employee_no": None,
            },
        )

    def test_invalid_date_order_and_top_n_are_rejected(self):
        for query in (
            {"startDate": "2026-11-23", "endDate": "2026-11-22", "topN": "10"},
            {"startDate": "2026-11-01", "endDate": "2026-11-22", "topN": "101"},
            {"startDate": "2026-11-01", "endDate": "2026-11-22", "topN": "1.5"},
        ):
            with self.subTest(query=query):
                filters, error = web_app.parse_report_filters("top_sales", query)
                self.assertIsNone(filters)
                self.assertIsNotNone(error)

    def test_employee_job_history_allows_initial_options_load(self):
        filters, error = web_app.parse_report_filters("employee_job_history", {})
        self.assertIsNone(error)
        self.assertIsNone(filters["employee_no"])

        filters, error = web_app.parse_report_filters(
            "employee_job_history", {"employeeNo": "E0001"}
        )
        self.assertIsNone(error)
        self.assertEqual(filters["employee_no"], "E0001")

    def test_report_specific_right_does_not_grant_module_view(self):
        permissions = web_app.rights_to_permissions(
            [{"right_code": "reports.topSales.view", "module_code": "reports",
              "resource_code": "top_sales", "action": "view"}],
            [{"right_code": "reports.topSales.view"}],
        )
        self.assertFalse(permissions["Reports"]["view"])

        permissions = web_app.rights_to_permissions(
            [{"right_code": "reports.view", "module_code": "reports",
              "resource_code": "reports", "action": "view"}],
            [{"right_code": "reports.view"}],
        )
        self.assertTrue(permissions["Reports"]["view"])


if __name__ == "__main__":
    unittest.main()
