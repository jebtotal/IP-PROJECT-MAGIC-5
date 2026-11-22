"""Shared PostgreSQL connection helpers for the local database scripts."""

from dataclasses import dataclass
import os
from pathlib import Path
from urllib.parse import parse_qs, unquote, urlsplit

from dotenv import load_dotenv


APP_DIR = Path(__file__).resolve().parents[1]
BACKUP_DIR = APP_DIR / "backups"
load_dotenv(APP_DIR / ".env")

_CONNECTION_PARAMETERS = {
    "sslmode": "PGSSLMODE",
    "connect_timeout": "PGCONNECT_TIMEOUT",
    "application_name": "PGAPPNAME",
    "target_session_attrs": "PGTARGETSESSIONATTRS",
    "gssencmode": "PGGSSENCMODE",
    "sslrootcert": "PGSSLROOTCERT",
    "sslcert": "PGSSLCERT",
    "sslkey": "PGSSLKEY",
}
_SSL_MODES = {"disable", "allow", "prefer", "require", "verify-ca", "verify-full"}


@dataclass(frozen=True)
class DatabaseConnection:
    host: str
    port: int
    username: str
    password: str
    database: str
    parameters: dict[str, str]

    @property
    def identity(self) -> tuple[str, int, str]:
        return self.host.rstrip(".").casefold(), self.port, self.database


def parse_database_url(value: str, variable_name: str) -> DatabaseConnection:
    try:
        parsed = urlsplit(value)
        if parsed.scheme not in {"postgres", "postgresql"}:
            raise ValueError
        host = parsed.hostname
        port = parsed.port or 5432
        username = unquote(parsed.username or "")
        password = unquote(parsed.password or "")
        database = unquote(parsed.path.lstrip("/"))
    except ValueError as error:
        raise ValueError(
            f"{variable_name} must be a valid PostgreSQL connection URL."
        ) from error

    if not host or not username or not password or not database or "/" in database:
        raise ValueError(
            f"{variable_name} must include a PostgreSQL host, username, password, and database."
        )

    try:
        query = parse_qs(parsed.query, keep_blank_values=True, strict_parsing=True)
    except ValueError as error:
        raise ValueError(
            f"{variable_name} contains unsupported or malformed connection parameters."
        ) from error
    unknown_parameters = set(query) - set(_CONNECTION_PARAMETERS)
    if unknown_parameters or any(len(values) != 1 for values in query.values()):
        raise ValueError(
            f"{variable_name} contains unsupported or repeated connection parameters."
        )

    parameters = {name: values[0] for name, values in query.items()}
    sslmode = parameters.setdefault("sslmode", "require")
    if sslmode not in _SSL_MODES:
        raise ValueError(f"{variable_name} has an invalid sslmode.")
    if "connect_timeout" in parameters:
        try:
            if int(parameters["connect_timeout"]) < 1:
                raise ValueError
        except ValueError as error:
            raise ValueError(
                f"{variable_name} connect_timeout must be a positive integer."
            ) from error

    return DatabaseConnection(host, port, username, password, database, parameters)


def load_database_url(variable_name: str) -> DatabaseConnection:
    value = os.environ.get(variable_name, "").strip()
    if not value:
        raise ValueError(
            f"Set {variable_name} in my-web-app/.env before running this script."
        )
    return parse_database_url(value, variable_name)


def connection_server_arguments(connection: DatabaseConnection) -> list[str]:
    return [
        "--host",
        connection.host,
        "--port",
        str(connection.port),
        "--username",
        connection.username,
    ]


def connection_arguments(connection: DatabaseConnection) -> list[str]:
    return [
        *connection_server_arguments(connection),
        "--dbname",
        connection.database,
    ]


def connection_environment(connection: DatabaseConnection) -> dict[str, str]:
    environment = os.environ.copy()
    environment["PGPASSWORD"] = connection.password
    for parameter, value in connection.parameters.items():
        environment[_CONNECTION_PARAMETERS[parameter]] = value
    return environment


def require_distinct_databases(
    source: DatabaseConnection, target: DatabaseConnection
) -> None:
    if source.identity == target.identity:
        raise ValueError(
            "The restore target resolves to the same host and database as DATABASE_URL."
        )


def require_overwrite_confirmation(
    target_has_objects: bool, confirmed: bool
) -> None:
    if target_has_objects and not confirmed:
        raise ValueError(
            "Restore target contains database objects. Re-run with "
            "--confirm-overwrite only after verifying the target."
        )
