"""Create a private custom-format PostgreSQL backup in my-web-app/backups."""

import argparse
from datetime import datetime, timezone
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import uuid

from db_common import (
    BACKUP_DIR,
    connection_arguments,
    connection_environment,
    load_database_url,
)


def main() -> int:
    argparse.ArgumentParser(
        description="Back up DATABASE_URL into the git-ignored backups folder."
    ).parse_args()

    try:
        database = load_database_url("DATABASE_URL")
    except ValueError as error:
        raise SystemExit(str(error)) from error

    pg_dump = shutil.which("pg_dump")
    if pg_dump is None:
        raise SystemExit(
            "pg_dump was not found on PATH. Install PostgreSQL client tools first."
        )

    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    destination = BACKUP_DIR / f"hope-db-{timestamp}-{uuid.uuid4().hex[:8]}.dump"
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=".hope-db-", suffix=".dump.partial", dir=BACKUP_DIR
    )
    os.close(descriptor)
    temporary = Path(temporary_name)

    command = [
        pg_dump,
        "--format=custom",
        "--no-owner",
        "--no-acl",
        "--no-password",
        "--file",
        str(temporary),
        *connection_arguments(database),
    ]
    try:
        result = subprocess.run(
            command,
            env=connection_environment(database),
            check=False,
        )
        if result.returncode != 0:
            raise SystemExit(f"pg_dump failed with exit code {result.returncode}.")
        if not temporary.is_file() or temporary.stat().st_size == 0:
            raise SystemExit("pg_dump returned success but created an empty backup.")

        if os.name != "nt":
            temporary.chmod(0o600)
        temporary.rename(destination)
    finally:
        temporary.unlink(missing_ok=True)

    print(f"Backup created: {destination}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
