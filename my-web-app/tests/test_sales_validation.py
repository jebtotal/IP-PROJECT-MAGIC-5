import os
from pathlib import Path
import sys
import unittest


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
