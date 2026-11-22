"""Restore a custom-format PostgreSQL backup into a pre-created database."""

import argparse
from pathlib import Path
import shutil
import subprocess
import sys

from db_common import (
    BACKUP_DIR,
    connection_arguments,
    connection_environment,
    connection_server_arguments,
    load_database_url,
    require_distinct_databases,
    require_overwrite_confirmation,
)


_DATABASE_HAS_OBJECTS_SQL = """
SELECT EXISTS (
    SELECT 1
      FROM pg_class AS relation
      JOIN pg_namespace AS namespace ON namespace.oid = relation.relnamespace
     WHERE namespace.nspname NOT IN ('pg_catalog', 'information_schema')
       AND namespace.nspname NOT LIKE 'pg_toast%'
       AND relation.relkind IN ('r', 'p', 'v', 'm', 'S', 'f')
    UNION ALL
    SELECT 1
      FROM pg_proc AS routine
      JOIN pg_namespace AS namespace ON namespace.oid = routine.pronamespace
     WHERE namespace.nspname NOT IN ('pg_catalog', 'information_schema')
       AND namespace.nspname NOT LIKE 'pg_toast%'
       AND routine.prokind IN ('f', 'p')
    UNION ALL
    SELECT 1
      FROM pg_type AS type
      JOIN pg_namespace AS namespace ON namespace.oid = type.typnamespace
     WHERE namespace.nspname NOT IN ('pg_catalog', 'information_schema')
       AND namespace.nspname NOT LIKE 'pg_toast%'
       AND type.typtype IN ('b', 'c', 'd', 'e', 'r')
)::text;
"""


def resolve_archive(argument: Path) -> Path:
    candidate = argument if argument.is_absolute() else Path.cwd() / argument
    if not candidate.exists():
        candidate = BACKUP_DIR / argument
    try:
        resolved = candidate.resolve(strict=True)
        resolved.relative_to(BACKUP_DIR.resolve())
    except (OSError, ValueError) as error:
        raise ValueError(
            f"Choose a backup file located inside {BACKUP_DIR}."
        ) from error

    if not resolved.is_file() or resolved.suffix.lower() != ".dump":
        raise ValueError("The selected backup must be a .dump file.")
    with resolved.open("rb") as backup_file:
        if backup_file.read(5) != b"PGDMP":
            raise ValueError("The selected file is not a PostgreSQL custom-format backup.")
    return resolved


def target_has_objects(psql: str, target) -> bool:
    command = [
        psql,
        "-X",
        "--no-password",
        "--tuples-only",
        "--no-align",
        "--quiet",
        "--set=ON_ERROR_STOP=1",
        "--command",
        _DATABASE_HAS_OBJECTS_SQL,
        *connection_arguments(target),
    ]
    result = subprocess.run(
        command,
        env=connection_environment(target),
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        if result.stderr:
            print(result.stderr, file=sys.stderr, end="")
        raise RuntimeError(
            f"Could not inspect restore target (psql exit code {result.returncode})."
        )
    value = result.stdout.strip().casefold()
    if value not in {"t", "true", "f", "false"}:
        raise RuntimeError("psql returned an unexpected result while inspecting the target.")
    return value in {"t", "true"}


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Restore a private PostgreSQL .dump into a pre-created database."
    )
    parser.add_argument(
        "backup",
        type=Path,
        help="Backup filename in my-web-app/backups (or its full path)",
    )
    parser.add_argument(
        "--confirm-overwrite",
        action="store_true",
        help="Allow pg_restore to replace objects already present in the target.",
    )
    arguments = parser.parse_args()

    try:
        archive = resolve_archive(arguments.backup)
        source = load_database_url("DATABASE_URL")
        target = load_database_url("RESTORE_DATABASE_URL")
        require_distinct_databases(source, target)
    except ValueError as error:
        raise SystemExit(str(error)) from error

    pg_restore = shutil.which("pg_restore")
    psql = shutil.which("psql")
    if pg_restore is None or psql is None:
        raise SystemExit(
            "pg_restore and psql were not found on PATH. Install PostgreSQL client tools first."
        )

    try:
        has_objects = target_has_objects(psql, target)
        require_overwrite_confirmation(has_objects, arguments.confirm_overwrite)
    except (RuntimeError, ValueError) as error:
        raise SystemExit(str(error)) from error

    if has_objects:
        print(
            "Warning: --clean will replace matching objects from the archive; "
            "unrelated target objects remain."
        )

    command = [
        pg_restore,
        "--format=custom",
        "--no-owner",
        "--no-acl",
        "--no-password",
        "--exit-on-error",
        "--single-transaction",
        "--clean",
        "--if-exists",
        "--dbname",
        target.database,
        *connection_server_arguments(target),
        str(archive),
    ]
    result = subprocess.run(
        command,
        env=connection_environment(target),
        check=False,
    )
    if result.returncode != 0:
        raise SystemExit(f"pg_restore failed with exit code {result.returncode}.")

    print(f"Restore completed into database {target.database} on {target.host}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
