import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch


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
