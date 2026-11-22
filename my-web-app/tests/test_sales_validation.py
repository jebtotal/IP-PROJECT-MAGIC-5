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


if __name__ == "__main__":
    unittest.main()
