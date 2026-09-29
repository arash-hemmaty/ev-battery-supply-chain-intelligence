-- ============================================================
-- Analytical Views — Trade Concentration
-- ============================================================
-- Run AFTER all ingestion scripts.
-- These views are read-only and used by Power BI / analytical queries.
-- ============================================================

-- Supplier share: % of each supplier in an importer's total
CREATE OR REPLACE VIEW ev.v_supplier_share AS
WITH imports AS (
    SELECT
        ft.importer_country_id,
        ft.exporter_country_id,
        ft.hs_code,
        ft.date_id,
        SUM(ft.trade_quantity) AS qty_t
    FROM ev.fact_trade ft
    WHERE ft.flow_code = 'M'
      AND ft.source_id = (SELECT source_id FROM ev.dim_source WHERE source_code='UN_COMTRADE_REPORTED')
      AND ft.trade_quantity IS NOT NULL
    GROUP BY ft.importer_country_id, ft.exporter_country_id, ft.hs_code, ft.date_id
),
totals AS (
    SELECT
        importer_country_id, hs_code, date_id,
        SUM(qty_t) AS total_qty_t
    FROM imports
    GROUP BY importer_country_id, hs_code, date_id
)
SELECT
    i.importer_country_id,
    i.exporter_country_id,
    i.hs_code,
    i.date_id,
    i.qty_t,
    t.total_qty_t,
    ROUND(100.0 * i.qty_t / t.total_qty_t, 2) AS share_pct
FROM imports i
JOIN totals t USING (importer_country_id, hs_code, date_id);


-- Supplier concentration: HHI + Top-1 share + supplier count
CREATE OR REPLACE VIEW ev.v_supplier_concentration AS
WITH shares AS (
    SELECT * FROM ev.v_supplier_share
)
SELECT
    importer_country_id,
    hs_code,
    date_id,
    COUNT(*) AS supplier_count,
    ROUND(SUM(POWER(share_pct/100.0, 2)) * 10000, 2) AS hhi,
    MAX(share_pct) AS top1_share_pct
FROM shares
GROUP BY importer_country_id, hs_code, date_id;