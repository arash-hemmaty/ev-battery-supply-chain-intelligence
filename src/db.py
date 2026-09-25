"""
Database connection module.

Provides a single engine for the EV battery supply chain database.
All ETL scripts import from here.
"""

import os
from pathlib import Path

from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Engine


# Load .env from project root
PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")


def _build_db_url() -> str:
    """Build PostgreSQL connection URL from environment variables."""
    user = os.getenv("DB_USER")
    password = os.getenv("DB_PASSWORD")
    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "5432")
    name = os.getenv("DB_NAME")

    missing = [k for k, v in {
        "DB_USER": user, "DB_PASSWORD": password, "DB_NAME": name
    }.items() if not v]
    if missing:
        raise RuntimeError(f"Missing environment variables: {', '.join(missing)}")

    return f"postgresql+psycopg2://{user}:{password}@{host}:{port}/{name}"


def get_engine() -> Engine:
    """Return a SQLAlchemy engine for the project database."""
    return create_engine(_build_db_url(), pool_pre_ping=True)


def test_connection() -> None:
    """Quick sanity check: connect and query the current database."""
    engine = get_engine()
    with engine.connect() as conn:
        result = conn.execute(text("SELECT current_database(), version();"))
        row = result.fetchone()
        print(f"Connected to: {row[0]}")
        print(f"Server: {row[1][:60]}...")


if __name__ == "__main__":
    test_connection()