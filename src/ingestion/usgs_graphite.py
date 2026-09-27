"""
USGS Graphite Ingestion

Reads the USGS Mineral Commodity Summaries graphite CSV and loads
world mine production into fact_production.

Source: USGS Mineral Commodity Summaries 2025 — Graphite (Natural)
CSV: data/raw/usgs/graphite_world_production.csv
"""

from pathlib import Path

import pandas as pd
from sqlalchemy import text

from src.db import PROJECT_ROOT, get_engine


# ------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------
CSV_PATH = PROJECT_ROOT / "data" / "raw" / "usgs" / "graphite_world_production.csv"

# Static references — we look these up dynamically from the database
PRODUCT_CODE = "NAT_GRAPHITE"
STAGE_CODE = "GRAPHITE_MINING"
UNIT_CODE = "T"
SOURCE_CODE = "USGS_MCS"


# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------
def _lookup_id(conn, sql: str, **params) -> int:
    """Execute a lookup query and return the single integer result."""
    result = conn.execute(text(sql), params).scalar()
    if result is None:
        raise RuntimeError(f"Lookup failed for: {sql} with {params}")
    return result


def _resolve_reference_ids(conn) -> dict:
    """Resolve all static reference IDs from dimension tables."""
    return {
        "product_id": _lookup_id(
            conn,
            "SELECT product_material_id FROM ev.dim_product_material WHERE code = :code",
            code=PRODUCT_CODE,
        ),
        "stage_id": _lookup_id(
            conn,
            "SELECT stage_id FROM ev.dim_stage WHERE stage_code = :code",
            code=STAGE_CODE,
        ),
        "unit_id": _lookup_id(
            conn,
            "SELECT unit_id FROM ev.dim_unit WHERE unit_code = :code",
            code=UNIT_CODE,
        ),
        "source_id": _lookup_id(
            conn,
            "SELECT source_id FROM ev.dim_source WHERE source_code = :code",
            code=SOURCE_CODE,
        ),
    }


def _load_country_lookup(conn) -> dict:
    """Load country_name -> country_id mapping from dim_country."""
    rows = conn.execute(text(
        "SELECT country_name, country_id FROM ev.dim_country"
    )).fetchall()
    return {name: cid for name, cid in rows}


def _load_date_lookup(conn) -> dict:
    """Load year -> date_id mapping from dim_date."""
    rows = conn.execute(text(
        "SELECT year, date_id FROM ev.dim_date"
    )).fetchall()
    return {year: did for year, did in rows}


# ------------------------------------------------------------------
# Main ingestion
# ------------------------------------------------------------------
def ingest() -> None:
    """Read CSV, validate, and upsert into fact_production."""
    print(f"[read] {CSV_PATH}")
    df = pd.read_csv(CSV_PATH)
    print(f"[read] {len(df)} rows loaded from CSV")

    # Validate columns
    expected_cols = {"country_name", "year", "production_tonnes", "is_estimated"}
    if not expected_cols.issubset(df.columns):
        raise ValueError(f"CSV missing columns. Expected: {expected_cols}")

    engine = get_engine()

    with engine.begin() as conn:
        # Resolve references
        refs = _resolve_reference_ids(conn)
        countries = _load_country_lookup(conn)
        dates = _load_date_lookup(conn)

        print(f"[ref] product_id={refs['product_id']}, stage_id={refs['stage_id']}, "
              f"unit_id={refs['unit_id']}, source_id={refs['source_id']}")
        print(f"[ref] {len(countries)} countries, {len(dates)} years available")

        inserted = 0
        updated = 0
        skipped = 0

        for _, row in df.iterrows():
            country_name = row["country_name"].strip()
            year = int(row["year"])
            quantity = float(row["production_tonnes"])
            is_est = bool(row["is_estimated"])

            # Validate country
            if country_name not in countries:
                print(f"[skip] Country not found: {country_name}")
                skipped += 1
                continue

            # Validate year
            if year not in dates:
                print(f"[skip] Year not found: {year}")
                skipped += 1
                continue

            note = "USGS estimate" if is_est else None

            # UPSERT into fact_production
            sql = text("""
                INSERT INTO ev.fact_production
                    (country_id, product_material_id, stage_id, date_id,
                     unit_id, source_id, quantity, notes)
                VALUES
                    (:country_id, :product_id, :stage_id, :date_id,
                     :unit_id, :source_id, :quantity, :notes)
                ON CONFLICT (country_id, product_material_id, stage_id, date_id, source_id)
                DO UPDATE SET
                    quantity = EXCLUDED.quantity,
                    notes = EXCLUDED.notes
                RETURNING (xmax = 0) AS inserted_flag
            """)

            result = conn.execute(sql, {
                "country_id": countries[country_name],
                "product_id": refs["product_id"],
                "stage_id": refs["stage_id"],
                "date_id": dates[year],
                "unit_id": refs["unit_id"],
                "source_id": refs["source_id"],
                "quantity": quantity,
                "notes": note,
            }).scalar()

            if result:  # xmax=0 means a fresh insert
                inserted += 1
            else:
                updated += 1

        print(f"\n[done] Inserted: {inserted}, Updated: {updated}, Skipped: {skipped}")


# ------------------------------------------------------------------
# Entry point
# ------------------------------------------------------------------
if __name__ == "__main__":
    ingest()