import sys
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import app


class ReportQuery:
    def __init__(self, data):
        self.data = data

    def __getattr__(self, _name):
        return lambda *_args, **_kwargs: self

    def execute(self):
        return type("Response", (), {"data": self.data})()


class ReportClient:
    def __init__(self, tables):
        self.tables = tables

    def table(self, name):
        return ReportQuery(self.tables[name])


class SalesWriteQuery:
    def __init__(self, client, table):
        self.client = client
        self.table_name = table
        self.payload = None
        self.single = False

    def __getattr__(self, _name):
        return lambda *_args, **_kwargs: self

    def insert(self, payload):
        self.payload = payload
        return self

    def maybe_single(self):
        self.single = True
        return self

    def execute(self):
        if self.payload is not None:
            self.client.inserted.append((self.table_name, self.payload))
            return type("Response", (), {"data": [self.payload]})()
        rows = self.client.tables.get(self.table_name, [])
        data = rows[0] if self.single and rows else None if self.single else rows
        return type("Response", (), {"data": data})()


class SalesWriteClient:
    def __init__(self, tables):
        self.tables = tables
        self.inserted = []

    def table(self, name):
        return SalesWriteQuery(self, name)


class SalesReportsTests(unittest.TestCase):
    def test_sales_header_requires_valid_reference_values_and_date(self):
        values, error = app.sales_header_values({
            "salesDate": "2026-03-15",
            "custNo": "C0001",
            "empNo": "E0001",
        })

        self.assertIsNone(error)
        self.assertEqual(values, {
            "salesdate": "2026-03-15",
            "custno": "C0001",
            "empno": "E0001",
        })
        self.assertIsNone(app.sales_header_values({
            "salesDate": "2026-02-30",
            "custNo": "C0001",
            "empNo": "E0001",
        })[0])

    def test_sale_detail_and_payment_amounts_reject_invalid_precision(self):
        self.assertEqual(
            app.sales_detail_values({"quantity": "2.50"})[0],
            {"quantity": "2.50"},
        )
        self.assertIsNotNone(app.sales_detail_values({"quantity": "0"})[1])
        self.assertIsNotNone(app.sales_detail_values({"quantity": "1.001"})[1])
        self.assertEqual(
            app.payment_values({"payDate": "2026-03-15", "amount": "12.35"})[0],
            {"paydate": "2026-03-15", "amount": "12.35"},
        )
        self.assertIsNotNone(
            app.payment_values({"payDate": "2026-03-15", "amount": "-1"})[1]
        )

    def test_report_filters_validate_range_and_top_n(self):
        report = next(item for item in app.REPORTS if item["slug"] == "top-sales")
        filters, error = app.parse_report_filters(report, {
            "fromDate": "2026-01-01",
            "toDate": "2026-03-31",
            "topN": "25",
        })

        self.assertIsNone(error)
        self.assertEqual(filters["topN"], 25)
        self.assertEqual(
            app.parse_report_filters(report, {
                "fromDate": "2026-04-01",
                "toDate": "2026-03-31",
                "topN": "10",
            })[1],
            "From date must be on or before To date.",
        )
        self.assertIsNotNone(app.parse_report_filters(report, {
            "fromDate": "2026-01-01",
            "toDate": "2026-03-31",
            "topN": "101",
        })[1])

    def test_report_rights_remain_report_specific(self):
        client = ReportClient({
            "user_permission": [
                {"right_code": "reports.topSales.view"},
            ],
        })
        profile = {"id": "user-1", "role": "user"}
        permissions = app.empty_permissions()
        permissions["Reports"]["view"] = True

        rights = app.report_rights_for_user(client, profile, permissions)

        self.assertEqual(rights, {"reports.topSales.view"})

    def test_transaction_number_advances_past_existing_records(self):
        self.assertEqual(
            app.next_number(
                [{"transno": "TR000009"}, {"transno": "TR000002"}],
                "TR",
            ),
            "TR000010",
        )

    def test_create_sale_uses_next_transaction_number_and_generated_fields(self):
        user_client = SalesWriteClient({
            "sales": [{"transno": "TR000225"}],
        })
        admin_client = SalesWriteClient({
            "customer_active": [{"custno": "C0001"}],
            "employee_active": [{"empno": "E0001"}],
        })
        access = (user_client, {}, {}, {}, None)
        test_client = app.app.test_client()
        with test_client.session_transaction() as session:
            session["csrf_token"] = "test-token"

        with (
            patch.object(app, "get_sales_access", return_value=access),
            patch.object(app, "get_admin_client", return_value=admin_client),
        ):
            response = test_client.post(
                "/api/sales",
                json={
                    "salesDate": "2026-03-15",
                    "custNo": "C0001",
                    "empNo": "E0001",
                },
                headers={"X-CSRF-Token": "test-token"},
            )

        self.assertEqual(response.status_code, 201)
        self.assertEqual(response.get_json()["transNo"], "TR000226")
        self.assertEqual(user_client.inserted[0][1]["transno"], "TR000226")
        self.assertNotIn("stamp", user_client.inserted[0][1])
        self.assertNotIn("status", user_client.inserted[0][1])

    def test_sales_mutations_require_csrf_token(self):
        response = app.app.test_client().post(
            "/api/sales",
            json={
                "salesDate": "2026-03-15",
                "custNo": "C0001",
                "empNo": "E0001",
            },
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn("could not be verified", response.get_json()["error"])

    def test_top_products_aggregates_quantity_and_amount_before_limiting(self):
        client = ReportClient({
            "sales_active": [
                {"transno": "TR000001", "salesdate": "2026-02-01", "custno": "C1"},
                {"transno": "TR000002", "salesdate": "2026-02-02", "custno": "C2"},
            ],
            "v_sale_line_amounts": [
                {"transno": "TR000001", "prodcode": "P1", "quantity": "2", "line_amount": "20.00"},
                {"transno": "TR000002", "prodcode": "P1", "quantity": "3", "line_amount": "30.00"},
                {"transno": "TR000001", "prodcode": "P2", "quantity": "1", "line_amount": "5.00"},
            ],
            "product": [
                {"prodcode": "P1", "description": "First", "unit": "ea"},
                {"prodcode": "P2", "description": "Second", "unit": "ea"},
            ],
            "customer": [
                {"custno": "C1", "custname": "Alpha"},
                {"custno": "C2", "custname": "Beta"},
            ],
        })
        report = next(item for item in app.REPORTS if item["slug"] == "top-products")

        columns, rows = app.report_columns_and_rows(client, report, {
            "fromDate": "2026-02-01",
            "toDate": "2026-02-28",
            "topN": 1,
        })

        self.assertEqual(columns[-1]["key"], "totalSales")
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["prodCode"], "P1")
        self.assertEqual(rows[0]["quantitySold"], "5.00")
        self.assertEqual(rows[0]["totalSales"], "50.00")

        customer_report = next(
            item for item in app.REPORTS if item["slug"] == "top-customers"
        )
        _columns, customers = app.report_columns_and_rows(
            client, customer_report, {
                "fromDate": "2026-02-01",
                "toDate": "2026-02-28",
                "topN": 2,
            }
        )
        self.assertEqual(customers[0]["custNo"], "C2")
        self.assertEqual(customers[0]["totalSales"], "30.00")
        self.assertEqual(customers[1]["totalSales"], "25.00")

    def test_sales_and_report_pages_render_for_authorized_users(self):
        profile = {
            "id": "user-1",
            "email": "user@example.test",
            "full_name": "Test User",
            "role": "user",
            "status": "approved",
        }
        permissions = app.empty_permissions()
        permissions["Sales"]["view"] = True
        permissions["Reports"]["view"] = True
        client = SimpleNamespace(
            auth=SimpleNamespace(
                get_user=lambda: SimpleNamespace(
                    user=SimpleNamespace(user_metadata={})
                )
            )
        )
        sales_actions = {
            "view": True, "create": True, "edit": True, "delete": True,
        }
        detail_actions = {
            "view": True, "create": True, "edit": True, "delete": True,
        }
        granted_reports = {"reports.topSales.view"}

        with (
            patch.object(app, "get_authenticated_client", return_value=client),
            patch.object(app, "get_current_profile", return_value=profile),
            patch.object(app, "profile_is_active", return_value=True),
            patch.object(app, "must_set_password", return_value=False),
            patch.object(app, "get_permissions_for_user", return_value=permissions),
            patch.object(
                app, "get_sales_actions",
                return_value=(sales_actions, detail_actions),
            ),
            patch.object(
                app, "report_rights_for_user", return_value=granted_reports
            ),
        ):
            test_client = app.app.test_client()
            sales_response = test_client.get("/sales")
            reports_response = test_client.get("/reports")
            report_response = test_client.get("/reports/top-sales")

        self.assertEqual(sales_response.status_code, 200)
        self.assertIn(b"Manage transactions", sales_response.data)
        self.assertEqual(reports_response.status_code, 200)
        self.assertIn(b"Top Sales", reports_response.data)
        self.assertNotIn(b"Top Customers", reports_response.data)
        self.assertEqual(report_response.status_code, 200)
        self.assertIn(b"Run Report", report_response.data)


if __name__ == "__main__":
    unittest.main()
