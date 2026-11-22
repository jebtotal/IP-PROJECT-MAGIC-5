"""Compare all user-table row counts between source and restore databases."""

import argparse
import shutil
import subprocess
import sys

from db_common import (
    connection_arguments,
    connection_environment,
    load_database_url,
    require_distinct_databases,
)


_TABLE_COUNTS_SQL = r"""
SELECT format(
    'SELECT %L, count(*)::bigint FROM %I.%I;',
    namespace.nspname || '.' || relation.relname,
    namespace.nspname,
    relation.relname
)
  FROM pg_class AS relation
  JOIN pg_namespace AS namespace ON namespace.oid = relation.relnamespace
 WHERE relation.relkind IN ('r', 'p')
   AND NOT relation.relispartition
   AND namespace.nspname NOT IN ('pg_catalog', 'information_schema')
   AND namespace.nspname NOT LIKE 'pg_toast%'
 ORDER BY namespace.nspname, relation.relname
\gexec
"""


def parse_table_counts(output: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    for line in output.splitlines():
        if not line:
            continue
        fields = line.split("\t")
        if len(fields) != 2 or not fields[1].isdigit() or fields[0] in counts:
            raise ValueError("psql returned an invalid or duplicate table count row.")
        counts[fields[0]] = int(fields[1])
    return counts


def get_table_counts(psql: str, database) -> dict[str, int]:
    command = [
        psql,
        "-X",
        "--no-password",
        "--quiet",
        "--tuples-only",
        "--no-align",
        "--field-separator=" + "\t",
        *connection_arguments(database),
    ]
    result = subprocess.run(
        command,
        input=_TABLE_COUNTS_SQL,
        env=connection_environment(database),
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        if result.stderr:
            print(result.stderr, file=sys.stderr, end="")
        raise RuntimeError(f"psql row-count query failed (exit code {result.returncode}).")
    return parse_table_counts(result.stdout)


def main() -> int:
    argparse.ArgumentParser(
        description="Compare all user-table counts between DATABASE_URL and RESTORE_DATABASE_URL."
    ).parse_args()

    try:
        source = load_database_url("DATABASE_URL")
        target = load_database_url("RESTORE_DATABASE_URL")
        require_distinct_databases(source, target)
    except ValueError as error:
        raise SystemExit(str(error)) from error

    psql = shutil.which("psql")
    if psql is None:
        raise SystemExit("psql was not found on PATH. Install PostgreSQL client tools first.")

    try:
        source_counts = get_table_counts(psql, source)
        target_counts = get_table_counts(psql, target)
    except (RuntimeError, ValueError) as error:
        raise SystemExit(str(error)) from error

    print("table\tsource_rows\trestored_rows\tresult")
    differences = False
    for table_name in sorted(source_counts.keys() | target_counts.keys()):
        source_count = source_counts.get(table_name)
        target_count = target_counts.get(table_name)
        matches = source_count == target_count
        differences = differences or not matches
        print(
            f"{table_name}\t"
            f"{source_count if source_count is not None else 'MISSING'}\t"
            f"{target_count if target_count is not None else 'MISSING'}\t"
            f"{'MATCH' if matches else 'DIFFERENT'}"
        )

    if differences:
        raise SystemExit("Source and restore table row counts differ.")
    print(f"PASS: row counts match for all {len(source_counts)} user tables.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
