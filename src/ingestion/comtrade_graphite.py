"""
UN Comtrade — Graphite Trade Ingestion
Endpoint: /tools/v1/getBilateralData

Fetches bilateral trade data for natural graphite (HS 250410, 250490)
between a set of reporters and a set of graphite suppliers.

Note: The API endpoint is genuinely bilateral — one call per
(reporter, partner) pair. We loop over all combinations.

For each API response, stores TWO observations in fact_trade:
  1. Reporter perspective  (source_id = UN_COMTRADE_REPORTED)
  2. Mirror perspective    (source_id = UN_COMTRADE_MIRROR)

Both perspectives are retained, per Trade Data Contract v1.1.
They are NEVER silently merged.
"""

import os
import time
from typing import Optional

import requests
from dotenv import load_dotenv
from sqlalchemy import text

from src.db import PROJECT_ROOT, get_engine


# ------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------
load_dotenv(PROJECT_ROOT / ".env")

API_BASE = "https://comtradeapi.un.org/tools/v1"
API_KEY = os.getenv("COMTRADE_API_KEY")

# Reporters: countries whose imports we want to analyze
REPORTERS = {
    276: "Germany",
    392: "Japan",
    410: "South Korea",
    840: "United States",
    704: "Vietnam",
    356: "India",
}

# Partners: major natural graphite suppliers
PARTNER_M49_CODES = [
    156,   # China
    76,    # Brazil
    508,   # Mozambique
    450,   # Madagascar
    356,   # India
    124,   # Canada
    484,   # Mexico
    144,   # Sri Lanka
    578,   # Norway
    704,   # Vietnam
]

HS_CODES = ["250410", "250490"]
YEARS = list(range(2015, 2027))   # 2015..2026

PRODUCT_CODE = "GRAPHITE_TRADE_NATURAL"
UNIT_CODE = "T"
HS_REVISION = "HS2022"


# ------------------------------------------------------------------
# API client
# ------------------------------------------------------------------
def fetch_bilateral(reporter_m49: int, partner_m49: int) -> dict:
    """
    Call getBilateralData for ONE (reporter, partner) pair.
    Includes all years and both HS codes.
    """
    url = f"{API_BASE}/getBilateralData/C/A/HS"
    params = {
        "reporterCode": str(reporter_m49),
        "partnerCode": str(partner_m49),
        "period": ",".join(str(y) for y in YEARS),
        "cmdCode": ",".join(HS_CODES),
        "flowCode": "M",
        "includeDesc": "true",
        "subscription-key": API_KEY,
    }
    resp = requests.get(url, params=params, timeout=60)
    resp.raise_for_status()
    return resp.json()


# ------------------------------------------------------------------
# Reference lookups
# ------------------------------------------------------------------
def _lookup_id(conn, sql: str, **params) -> Optional[int]:
    return conn.execute(text(sql), params).scalar()


def resolve_references(conn) -> dict:
    return {
        "product_id": _lookup_id(
            conn,
            "SELECT product_material_id FROM ev.dim_product_material WHERE code = :c",
            c=PRODUCT_CODE,
        ),
        "unit_id": _lookup_id(
            conn,
            "SELECT unit_id FROM ev.dim_unit WHERE unit_code = :c",
            c=UNIT_CODE,
        ),
        "source_reported": _lookup_id(
            conn,
            "SELECT source_id FROM ev.dim_source WHERE source_code = 'UN_COMTRADE_REPORTED'",
        ),
        "source_mirror": _lookup_id(
            conn,
            "SELECT source_id FROM ev.dim_source WHERE source_code = 'UN_COMTRADE_MIRROR'",
        ),
    }


def load_lookups(conn) -> dict:
    countries = dict(conn.execute(text(
        "SELECT m49_code, country_id FROM ev.dim_country WHERE m49_code IS NOT NULL"
    )).fetchall())
    dates = dict(conn.execute(text(
        "SELECT year, date_id FROM ev.dim_date"
    )).fetchall())
    return {"countries": countries, "dates": dates}


# ------------------------------------------------------------------
# Transformation
# ------------------------------------------------------------------
def _norm(v):
    """Normalize API values: 0, None, or non-numeric → None. Positive → float."""
    if v is None:
        return None
    try:
        f = float(v)
    except (TypeError, ValueError):
        return None
    if f <= 0:
        return None
    return f


def _kg_to_tonnes(kg):
    v = _norm(kg)
    if v is None:
        return None
    return round(v / 1000.0, 4)


def build_fact_rows(api_row: dict, reporter_m49: int) -> list:
    """Convert one API row into up to TWO fact_trade rows."""
    partner_m49 = api_row.get("partnerCode")
    period = int(api_row["period"])
    hs_code = api_row["cmdCode"]

    rep_qty = _kg_to_tonnes(api_row.get("netWgt"))
    rep_val = _norm(api_row.get("primaryValue"))

    mir_qty = _kg_to_tonnes(api_row.get("mirrorNetWgt"))
    mir_val = _norm(api_row.get("mirrorPrimaryValue"))

    rows = []

    # --- Reporter perspective ---
    rows.append({
        "reporter_country_id": reporter_m49,
        "partner_country_id":  partner_m49,
        "flow_code":           "M",
        "exporter_country_id": partner_m49,
        "importer_country_id": reporter_m49,
        "hs_code":             hs_code,
        "hs_revision":         HS_REVISION,
        "date_year":           period,
        "trade_quantity":      rep_qty,
        "trade_value_usd":     rep_val,
        "valuation_basis":     "CIF",
        "is_reported":         api_row.get("isReported"),
        "is_quantity_estimated": api_row.get("isNetWgtEstimated"),
        "legacy_estimation_flag": api_row.get("legacyEstimationFlag"),
        "source_key":          "source_reported",
        "notes":               "Reporter perspective (country-reported import).",
    })

    # --- Mirror perspective ---
    if mir_qty is not None or mir_val is not None:
        rows.append({
            "reporter_country_id": partner_m49,
            "partner_country_id":  reporter_m49,
            "flow_code":           "X",
            "exporter_country_id": partner_m49,
            "importer_country_id": reporter_m49,
            "hs_code":             hs_code,
            "hs_revision":         HS_REVISION,
            "date_year":           period,
            "trade_quantity":      mir_qty,
            "trade_value_usd":     mir_val,
            "valuation_basis":     "FOB",
            "is_reported":         None,
            "is_quantity_estimated": None,
            "legacy_estimation_flag": None,
            "source_key":          "source_mirror",
            "notes":               "Mirror perspective (partner-reported export).",
        })

    return rows


# ------------------------------------------------------------------
# UPSERT
# ------------------------------------------------------------------
UPSERT_SQL = text("""
    INSERT INTO ev.fact_trade
        (reporter_country_id, partner_country_id, flow_code,
         exporter_country_id, importer_country_id,
         hs_code, hs_revision, product_material_id,
         date_id, unit_id, source_id,
         trade_quantity, trade_value_usd, valuation_basis,
         is_reported, is_quantity_estimated, legacy_estimation_flag,
         notes)
    VALUES
        (:reporter_id, :partner_id, :flow_code,
         :exporter_id, :importer_id,
         :hs_code, :hs_revision, :product_id,
         :date_id, :unit_id, :source_id,
         :quantity, :value, :valuation_basis,
         :is_reported, :is_qty_est, :legacy_flag,
         :notes)
    ON CONFLICT (reporter_country_id, partner_country_id, flow_code,
                 product_material_id, date_id, hs_code, hs_revision, source_id)
    DO UPDATE SET
        trade_quantity        = EXCLUDED.trade_quantity,
        trade_value_usd       = EXCLUDED.trade_value_usd,
        valuation_basis       = EXCLUDED.valuation_basis,
        is_reported           = EXCLUDED.is_reported,
        is_quantity_estimated = EXCLUDED.is_quantity_estimated,
        legacy_estimation_flag= EXCLUDED.legacy_estimation_flag,
        notes                 = EXCLUDED.notes
    RETURNING (xmax = 0) AS inserted_flag
""")


# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------
def ingest():
    if not API_KEY:
        raise RuntimeError("COMTRADE_API_KEY missing in .env")

    engine = get_engine()
    inserted = updated = skipped = 0
    api_calls = 0

    with engine.begin() as conn:
        refs = resolve_references(conn)
        lk = load_lookups(conn)

        print(f"[ref] product_id={refs['product_id']}  unit_id={refs['unit_id']}")
        print(f"[ref] sources: reported={refs['source_reported']}  mirror={refs['source_mirror']}")
        print(f"[ref] {len(lk['countries'])} countries, {len(lk['dates'])} years\n")

        for reporter_m49 in REPORTERS:
            for partner_m49 in PARTNER_M49_CODES:
                if reporter_m49 == partner_m49:
                    continue

                try:
                    api_data = fetch_bilateral(reporter_m49, partner_m49)
                    api_calls += 1
                except Exception as e:
                    print(f"[error] {reporter_m49}→{partner_m49}: {e}")
                    continue

                rows = api_data.get("data", [])
                if rows:
                    print(f"[api] {REPORTERS[reporter_m49]:<12} → partner {partner_m49}: {len(rows)} rows")

                for api_row in rows:
                    fact_rows = build_fact_rows(api_row, reporter_m49)

                    for r in fact_rows:
                        if r["reporter_country_id"] not in lk["countries"]:
                            skipped += 1
                            continue
                        if r["partner_country_id"] not in lk["countries"]:
                            skipped += 1
                            continue

                        year = r.pop("date_year")
                        if year not in lk["dates"]:
                            skipped += 1
                            continue

                        source_id = refs[r.pop("source_key")]

                        params = {
                            "reporter_id":   lk["countries"][r["reporter_country_id"]],
                            "partner_id":    lk["countries"][r["partner_country_id"]],
                            "exporter_id":   lk["countries"][r["exporter_country_id"]],
                            "importer_id":   lk["countries"][r["importer_country_id"]],
                            "flow_code":     r["flow_code"],
                            "hs_code":       r["hs_code"],
                            "hs_revision":   r["hs_revision"],
                            "product_id":    refs["product_id"],
                            "date_id":       lk["dates"][year],
                            "unit_id":       refs["unit_id"],
                            "source_id":     source_id,
                            "quantity":      r["trade_quantity"],
                            "value":         r["trade_value_usd"],
                            "valuation_basis": r["valuation_basis"],
                            "is_reported":   r["is_reported"],
                            "is_qty_est":    r["is_quantity_estimated"],
                            "legacy_flag":   r["legacy_estimation_flag"],
                            "notes":         r["notes"],
                        }

                        if params["quantity"] is None and params["value"] is None:
                            skipped += 1
                            continue

                        is_insert = conn.execute(UPSERT_SQL, params).scalar()
                        if is_insert:
                            inserted += 1
                        else:
                            updated += 1

                time.sleep(0.5)   # polite delay between partner calls

            time.sleep(1)   # longer delay between reporters

    print(f"\n[api calls] {api_calls}")
    print(f"[done] Inserted: {inserted}  Updated: {updated}  Skipped: {skipped}")


if __name__ == "__main__":
    ingest()