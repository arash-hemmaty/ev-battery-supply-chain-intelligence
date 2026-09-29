-- ============================================================
-- Data Quality Audit
-- ============================================================
-- Run AFTER ingestion. These queries are diagnostic, not
-- analytical. They identify coverage gaps, anomalies, and
-- potential issues before visualization.
-- ============================================================

-- ============================================================
-- A. COVERAGE
-- ============================================================

-- A1. Which reporters have data?
SELECT
    c.country_code,
    c.country_name AS reporter,
    COUNT(DISTINCT ft.partner_country_id) AS distinct_partners,
    COUNT(DISTINCT d.year) AS distinct_years,
    MIN(d.year) AS first_year,
    MAX(d.year) AS last_year,
    COUNT(*) AS rows
FROM ev.fact_trade ft
JOIN ev.dim_country c ON c.country_id = ft.reporter_country_id
JOIN ev.dim_date    d ON d.date_id    = ft.date_id
WHERE ft.source_id = (SELECT source_id FROM ev.dim_source WHERE source_code='UN_COMTRADE_REPORTED')
GROUP BY c.country_code, c.country_name
ORDER BY c.country_name;


-- A2. Coverage matrix by year (REPORTED only)
SELECT
    c.country_code AS reporter,
    d.year,
    COUNT(*) AS observations
FROM ev.fact_trade ft
JOIN ev.dim_country c ON c.country_id = ft.reporter_country_id
JOIN ev.dim_date    d ON d.date_id    = ft.date_id
WHERE ft.source_id = (SELECT source_id FROM ev.dim_source WHERE source_code='UN_COMTRADE_REPORTED')
GROUP BY c.country_code, d.year
ORDER BY c.country_code, d.year;


-- ============================================================
-- B. MIRROR PAIRING
-- ============================================================

-- B1. Do all reporter flows have a corresponding mirror?
--      (Should be near-100% if getBilateralData works)
SELECT
    COUNT(*) AS reporter_rows,
    COUNT(*) FILTER (WHERE EXISTS (
        SELECT 1 FROM ev.fact_trade m
        WHERE m.source_id = (SELECT source_id FROM ev.dim_source WHERE source_code='UN_COMTRADE_MIRROR')
          AND m.reporter_country_id = ft.partner_country_id
          AND m.partner_country_id  = ft.reporter_country_id
          AND m.hs_code             = ft.hs_code
          AND m.date_id             = ft.date_id
    )) AS with_mirror,
    COUNT(*) FILTER (WHERE NOT EXISTS (
        SELECT 1 FROM ev.fact_trade m
        WHERE m.source_id = (SELECT source_id FROM ev.dim_source WHERE source_code='UN_COMTRADE_MIRROR')
          AND m.reporter_country_id = ft.partner_country_id
          AND m.partner_country_id  = ft.reporter_country_id
          AND m.hs_code             = ft.hs_code
          AND m.date_id             = ft.date_id
    )) AS without_mirror
FROM ev.fact_trade ft
WHERE ft.source_id = (SELECT source_id FROM ev.dim_source WHERE source_code='UN_COMTRADE_REPORTED');


-- ============================================================
-- C. NULLS AND ZEROS
-- ============================================================

-- C1. Rows with NULL quantity or value (expected: some in reporter rows)
SELECT
    s.source_code,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE ft.trade_quantity IS NULL) AS null_quantity,
    COUNT(*) FILTER (WHERE ft.trade_value_usd IS NULL) AS null_value,
    COUNT(*) FILTER (WHERE ft.trade_quantity IS NULL AND ft.trade_value_usd IS NULL) AS both_null
FROM ev.fact_trade ft
JOIN ev.dim_source s ON s.source_id = ft.source_id
GROUP BY s.source_code;


-- C2. Suspiciously small quantities (< 1 tonne)
SELECT COUNT(*) AS suspicious_rows
FROM ev.fact_trade
WHERE trade_quantity IS NOT NULL AND trade_quantity < 1;


-- ============================================================
-- D. CLASSIFICATION SANITY
-- ============================================================

-- D1. Are there any HS codes other than 250410 / 250490?
SELECT hs_code, hs_revision, COUNT(*) AS rows
FROM ev.fact_trade
GROUP BY hs_code, hs_revision
ORDER BY rows DESC;


-- D2. Are all flows valid (M or X)?
SELECT flow_code, COUNT(*) AS rows
FROM ev.fact_trade
GROUP BY flow_code;


-- ============================================================
-- E. DUPLICATES
-- ============================================================

-- E1. Any duplicate (should return 0 rows)
SELECT
    reporter_country_id, partner_country_id, flow_code,
    product_material_id, date_id, hs_code, hs_revision, source_id,
    COUNT(*) AS cnt
FROM ev.fact_trade
GROUP BY reporter_country_id, partner_country_id, flow_code,
         product_material_id, date_id, hs_code, hs_revision, source_id
HAVING COUNT(*) > 1;
-- ============================================================
-- F. DOCUMENTED FINDINGS
-- ============================================================
-- The following are known, documented characteristics of the
-- current dataset. They are NOT errors. They inform interpretation.
-- ============================================================

-- F1. NULL quantity rows (5 rows, all Vietnam → China)
-- Interpretation: country reported value but not weight.
-- Action: retained; excluded from quantity-based analyses only.
SELECT 'F1: 5 NULL quantity rows (Vietnam → China, 2017-2020)' AS finding;


-- F2. Suspiciously small quantities (< 1 tonne, 76 rows)
-- Interpretation: likely R&D samples, laboratory-scale shipments,
-- or reporting anomalies. Unit values reach 10^6 USD/tonne, far
-- above market prices (~$1,000-2,000/tonne).
-- Action: retained; flagged as unit-value outliers in Power BI;
-- excluded from price-per-tonne analyses.
SELECT 'F2: 76 rows with quantity < 1 tonne (unit-value outliers)' AS finding;


-- F3. Coverage gaps
-- USA, India, Taiwan: 0 rows (do not report graphite to Comtrade
--   or report under different HS)
-- Vietnam: data ends 2023 (reporting stopped)
-- Hungary: only 2 suppliers, 14 rows over 10 years
-- Action: documented; may be filled via China-as-reporter in Phase 2.
SELECT 'F3: coverage gaps documented (USA/India/Taiwan/Vietnam)' AS finding;


-- F4. Mirror coverage
-- 497 reporter rows, 353 have mirror (71%), 144 without (29%)
-- Action: dependency analysis uses reporter perspective for
-- completeness; mirror analysis limited to paired subset.
SELECT 'F4: mirror pairing at 71% (144 rows unpaired)' AS finding;


-- F5. No duplicates
-- E1 returned 0 rows. Uniqueness enforced by constraint.
SELECT 'F5: no duplicate observations' AS finding;