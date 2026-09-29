-- ============================================================
-- Country Dependency View
-- ============================================================
-- Grain: (importer, year, hs_code)
-- This is the primary analytical view for supplier dependency.
-- Feeds Power BI page 3.
-- ============================================================

CREATE OR REPLACE VIEW ev.v_country_dependency AS
WITH base AS (
    -- supplier-level rows with rank
    SELECT
        v.importer_country_id,
        v.exporter_country_id,
        v.date_id,
        v.hs_code,
        v.qty_t,
        v.total_qty_t,
        v.share_pct,
        ROW_NUMBER() OVER (
            PARTITION BY v.importer_country_id, v.date_id, v.hs_code
            ORDER BY v.share_pct DESC
        ) AS rank
    FROM ev.v_supplier_share v
),
per_year AS (
    SELECT
        importer_country_id,
        date_id,
        hs_code,
        COUNT(*) AS supplier_count,
        SUM(POWER(share_pct/100.0, 2)) * 10000 AS hhi,
        MAX(share_pct) AS top1_share_pct,
        SUM(share_pct) FILTER (WHERE rank <= 3) AS top3_share_pct,
        SUM(share_pct) FILTER (WHERE rank <= 5) AS top5_share_pct,
        SUM(share_pct) FILTER (
            WHERE exporter_country_id = (
                SELECT country_id FROM ev.dim_country WHERE country_code = 'CHN'
            )
        ) AS china_share_pct,
        MAX(total_qty_t) AS total_imports_t
    FROM base
    GROUP BY importer_country_id, date_id, hs_code
)
SELECT
    ic.country_code                                   AS importer_code,
    ic.country_name                                   AS importer_name,
    d.year                                            AS year,
    py.hs_code                                        AS hs_code,
    ROUND(py.total_imports_t::numeric, 2)             AS total_imports_t,
    py.supplier_count                                 AS supplier_count,
    ROUND(py.hhi::numeric, 2)                         AS hhi,
    ROUND(py.top1_share_pct::numeric, 2)              AS top1_share_pct,
    ROUND(py.top3_share_pct::numeric, 2)              AS top3_share_pct,
    ROUND(py.top5_share_pct::numeric, 2)              AS top5_share_pct,
    ROUND((100.0 - py.top1_share_pct)::numeric, 2)    AS n1_coverage_pct,
    ROUND(py.china_share_pct::numeric, 2)             AS china_share_pct,
    ROUND(
        (py.hhi - LAG(py.hhi) OVER (
            PARTITION BY py.importer_country_id, py.hs_code
            ORDER BY d.year
        ))::numeric, 2
    )                                                 AS hhi_yoy_change
FROM per_year py
JOIN ev.dim_country ic ON ic.country_id = py.importer_country_id
JOIN ev.dim_date    d  ON d.date_id    = py.date_id;