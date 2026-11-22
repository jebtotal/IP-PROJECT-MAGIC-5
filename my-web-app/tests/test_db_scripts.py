from contextlib import redirect_stdout
from io import StringIO
import sys
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


SCRIPTS_DIR = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS_DIR))

import db_common
import db_compare
import db_backup
import db_restore


class DatabaseConnectionTests(unittest.TestCase):
    def test_database_url_decodes_credentials_and_defaults_to_ssl(self):
        connection = db_common.parse_database_url(
            "postgresql://dbadmin:p%40ss%3Aword@db.example:6543/hope"
            "?connect_timeout=8",
            "DATABASE_URL",
        )

        self.assertEqual(connection.username, "dbadmin")
        self.assertEqual(connection.password, "p@ss:word")
        self.assertEqual(connection.port, 6543)
        self.assertEqual(connection.database, "hope")
        self.assertEqual(connection.parameters["sslmode"], "require")

    def test_connection_arguments_do_not_include_password(self):
        connection = db_common.parse_database_url(
            "postgresql://dbadmin:private-value@db.example/hope",
            "DATABASE_URL",
        )

        self.assertNotIn(connection.password, db_common.connection_arguments(connection))
        self.assertEqual(
            db_common.connection_environment(connection)["PGPASSWORD"],
            connection.password,
        )

    def test_unsupported_parameters_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "unsupported or repeated"):
            db_common.parse_database_url(
                "postgresql://dbadmin:secret@db.example/hope?options=unsafe",
                "DATABASE_URL",
            )

    def test_restore_cannot_target_source_database(self):
        source = db_common.parse_database_url(
            "postgresql://admin:secret@DB.example/hope", "DATABASE_URL"
        )
        target = db_common.parse_database_url(
            "postgresql://restore:other@db.example:5432/hope", "RESTORE_DATABASE_URL"
        )

        with self.assertRaisesRegex(ValueError, "same host and database"):
            db_common.require_distinct_databases(source, target)

    def test_nonempty_restore_requires_confirmation_flag(self):
        with self.assertRaisesRegex(ValueError, "--confirm-overwrite"):
            db_common.require_overwrite_confirmation(True, False)

        db_common.require_overwrite_confirmation(True, True)
        db_common.require_overwrite_confirmation(False, False)


class DatabaseScriptTests(unittest.TestCase):
    def test_row_counts_parse_and_reject_duplicates(self):
        self.assertEqual(
            db_compare.parse_table_counts("public.employee\t4\npublic.job\t3\n"),
            {"public.employee": 4, "public.job": 3},
        )
        with self.assertRaisesRegex(ValueError, "duplicate"):
            db_compare.parse_table_counts("public.employee\t4\npublic.employee\t4\n")

    def test_restore_accepts_only_custom_archives_inside_ignored_backup_folder(self):
        with self.subTest("valid backup"):
            with patch.object(db_restore, "BACKUP_DIR", Path(__file__).parent):
                backup = Path(__file__).with_name("valid.dump")
                backup.write_bytes(b"PGDMPtest")
                try:
                    self.assertEqual(db_restore.resolve_archive(backup), backup.resolve())
                finally:
                    backup.unlink()

        with self.subTest("invalid format"):
            with patch.object(db_restore, "BACKUP_DIR", Path(__file__).parent):
                backup = Path(__file__).with_name("invalid.dump")
                backup.write_bytes(b"not a dump")
                try:
                    with self.assertRaisesRegex(ValueError, "custom-format"):
                        db_restore.resolve_archive(backup)
                finally:
                    backup.unlink()

    def test_external_archive_path_is_rejected(self):
        with patch.object(db_restore, "BACKUP_DIR", Path(__file__).parent):
            with self.assertRaisesRegex(ValueError, "inside"):
                db_restore.resolve_archive(Path(sys.executable))

    def test_backup_writes_custom_archive_without_password_in_arguments(self):
        database = db_common.parse_database_url(
            "postgresql://dbadmin:private-value@db.example/hope", "DATABASE_URL"
        )
        with tempfile.TemporaryDirectory() as directory:
            backup_dir = Path(directory)

            def fake_pg_dump(command, env, check):
                archive_path = Path(command[command.index("--file") + 1])
                archive_path.write_bytes(b"PGDMPtest")
                self.assertEqual(env["PGPASSWORD"], database.password)
                self.assertNotIn(database.password, command)
                return subprocess.CompletedProcess(command, 0)

            output = StringIO()
            with (
                patch.object(db_backup, "BACKUP_DIR", backup_dir),
                patch.object(db_backup, "load_database_url", return_value=database),
                patch.object(db_backup.shutil, "which", return_value="pg_dump"),
                patch.object(db_backup.subprocess, "run", side_effect=fake_pg_dump),
                patch.object(sys, "argv", ["db_backup"]),
                redirect_stdout(output),
            ):
                self.assertEqual(db_backup.main(), 0)

            created = list(backup_dir.glob("*.dump"))
            self.assertEqual(len(created), 1)
            self.assertEqual(created[0].read_bytes(), b"PGDMPtest")
            self.assertIn("Backup created:", output.getvalue())

    def test_restore_refuses_nonempty_target_without_confirmation(self):
        source = db_common.parse_database_url(
            "postgresql://admin:source-secret@source.example/source", "DATABASE_URL"
        )
        target = db_common.parse_database_url(
            "postgresql://admin:target-secret@target.example/target",
            "RESTORE_DATABASE_URL",
        )
        with tempfile.TemporaryDirectory() as directory:
            backup_dir = Path(directory)
            archive = backup_dir / "test.dump"
            archive.write_bytes(b"PGDMPtest")
            with (
                patch.object(db_restore, "BACKUP_DIR", backup_dir),
                patch.object(
                    db_restore,
                    "load_database_url",
                    side_effect=[source, target],
                ),
                patch.object(db_restore.shutil, "which", return_value="pg_tool"),
                patch.object(db_restore, "target_has_objects", return_value=True),
                patch.object(db_restore.subprocess, "run") as run,
                patch.object(sys, "argv", ["db_restore", str(archive)]),
            ):
                with self.assertRaisesRegex(SystemExit, "--confirm-overwrite"):
                    db_restore.main()
                run.assert_not_called()

    def test_confirmed_restore_uses_clean_atomic_restore_without_url_password(self):
        source = db_common.parse_database_url(
            "postgresql://admin:source-secret@source.example/source", "DATABASE_URL"
        )
        target = db_common.parse_database_url(
            "postgresql://admin:target-secret@target.example/target",
            "RESTORE_DATABASE_URL",
        )
        with tempfile.TemporaryDirectory() as directory:
            backup_dir = Path(directory)
            archive = backup_dir / "test.dump"
            archive.write_bytes(b"PGDMPtest")
            output = StringIO()
            with (
                patch.object(db_restore, "BACKUP_DIR", backup_dir),
                patch.object(
                    db_restore,
                    "load_database_url",
                    side_effect=[source, target],
                ),
                patch.object(
                    db_restore.shutil,
                    "which",
                    side_effect=lambda tool: tool,
                ),
                patch.object(db_restore, "target_has_objects", return_value=True),
                patch.object(
                    db_restore.subprocess,
                    "run",
                    return_value=subprocess.CompletedProcess([], 0),
                ) as run,
                patch.object(
                    sys,
                    "argv",
                    ["db_restore", str(archive), "--confirm-overwrite"],
                ),
                redirect_stdout(output),
            ):
                self.assertEqual(db_restore.main(), 0)

            command = run.call_args.args[0]
            self.assertIn("--clean", command)
            self.assertIn("--single-transaction", command)
            self.assertNotIn(target.password, command)
            self.assertEqual(run.call_args.kwargs["env"]["PGPASSWORD"], target.password)
            self.assertIn("Warning:", output.getvalue())


if __name__ == "__main__":
    unittest.main()
