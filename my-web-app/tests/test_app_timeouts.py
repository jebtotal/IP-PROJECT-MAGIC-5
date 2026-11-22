import sys
import unittest
from pathlib import Path
from unittest.mock import patch

import httpx


sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import app


class SupabaseTimeoutTests(unittest.TestCase):
    def setUp(self):
        self.client = app.app.test_client()

    def test_user_management_timeout_returns_retryable_page(self):
        with (
            patch.object(
                app,
                "get_management_profile",
                side_effect=httpx.ReadTimeout("timeout"),
            ),
            patch.object(app.app.logger, "warning") as warning,
        ):
            response = self.client.get("/user-management")

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.headers["Retry-After"], "3")
        self.assertIn(b"Service temporarily unavailable", response.data)
        warning.assert_called_once()

    def test_users_api_timeout_returns_retryable_json(self):
        with (
            patch.object(
                app,
                "get_management_profile",
                side_effect=httpx.ReadTimeout("timeout"),
            ),
            patch.object(app.app.logger, "warning") as warning,
        ):
            response = self.client.get("/api/users")

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.headers["Retry-After"], "3")
        self.assertIn("could not reach Supabase", response.get_json()["error"])
        warning.assert_called_once()


if __name__ == "__main__":
    unittest.main()
