CREATE OR REPLACE VIEW ev.v_supplier_concentration_trend AS
SELECT
    ic.country_name AS importer_name,
    ic.country_code AS importer_code,
    d.year,
    v.hs_code,
    v.supplier_count,
    v.hhi,
    v.top1_share_pct,
    -- YoY change in HHI
    v.hhi - LAG(v.hhi) OVER (
        PARTITION BY v.importer_country_id, v.hs_code
        ORDER BY d.year
    ) AS hhi_yoy_change,
    -- Decade change (2015 baseline)
    v.hhi - FIRST_VALUE(v.hhi) OVER (
        PARTITION BY v.importer_country_id, v.hs_code
        ORDER BY d.year
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS hhi_change_vs_first_year
FROM ev.v_supplier_concentration v
JOIN ev.dim_country ic ON ic.country_id = v.importer_country_id
JOIN ev.dim_date    d  ON d.date_id    = v.date_id
WHERE v.hs_code = '250410';