# Mirror Statistics — Graphite (HS 250410)

## First Finding: 41% Discrepancy

For Germany ↔ China, HS 250410, 2023:

| Perspective | Quantity (tonnes) | Value (USD) | Valuation basis |
|---|---|---|---|
| Germany reported (Import) | 9,875.51 | 11,669,386 | CIF |
| China reported (Export)    | 6,893.27 | 6,875,968  | FOB |

**Discrepancy:** 41% (value), 30% (quantity)

## Interpretation

The 41% discrepancy is significantly larger than the typical
CIF/FOB differential (usually 5–15%). Possible causes:

1. **Valuation basis:** CIF vs FOB — accounts for part of the gap
2. **Timing:** customs recording periods may differ
3. **Re-export:** goods may transit through third countries
4. **Reporting thresholds or classification differences**

This is a documented analytical finding, not a data error.

## Implication for Supplier Dependency Analysis

The choice of perspective (import-reported vs export-reported)
can change dependency estimates by up to 30–40%.
Analyses must state which perspective is used.

## Storage Decision

Both perspectives are stored as separate observations in
`fact_trade`, distinguished by `source_id`:
- `UN_COMTRADE_REPORTED` — from reporter perspective
- `UN_COMTRADE_MIRROR` — from partner perspective