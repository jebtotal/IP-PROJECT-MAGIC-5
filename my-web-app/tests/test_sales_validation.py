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


if __name__ == "__main__":
    unittest.main()
