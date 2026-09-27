# Trade Data Contract v1.0

**Project:** EV Battery Supply Chain Intelligence
**Domain:** Natural Graphite (Phase 1)
**Source:** UN Comtrade
**Status:** Locked pending validation against live API

---

## 1. Classification

| Field | Decision |
|---|---|
| Classification system | HS (Harmonized System) |
| Analytical level | HS 6-digit |
| Graphite HS codes | 250410 (powder/flakes), 250490 (other) |
| HS revision | Stored explicitly per observation; not assumed |
| Excluded codes | HS 3801 (artificial graphite) — separate product family |

**Note:** The claim "2504 codes unchanged across HS revisions" is NOT
asserted. Each observation carries its own hs_revision. Verification
against UNSD correspondence tables will be performed before any
cross-revision claim is made.

---

## 2. Product Semantics

Trade classification ≠ Production stage classification.

| Layer | Field | Meaning |
|---|---|---|
| Raw (source) | hs_code, hs_revision | As reported by customs |
| Analytical | product_material_id = `GRAPHITE_TRADE_NATURAL` | Our standardization |

**Do not** map trade observations to stage-specific products
(NAT_GRAPHITE, GRAPHITE_CONC, SPHERICAL_GR, etc.). Trade data
does not carry stage-level granularity.

---

## 3. Reporting Perspective

Two perspectives exist for every trade flow:

| Perspective | flow_code | Reporter role | Partner role |
|---|---|---|---|
| Export-reported | 'X' | Exporter | Importer |
| Import-reported | 'M' | Importer | Exporter |

**Both perspectives are stored** as separate observations.
`reporter_country_id`, `partner_country_id`, `flow_code` are stored
as the raw observation. `exporter_country_id` and
`importer_country_id` are derived and enforced consistent via CHECK.

**Never silently merge mirror flows.** They serve different analytical
purposes.

---

## 4. Analytical Usage

| Analysis | Perspective used | Rationale |
|---|---|---|
| Supplier dependency | Import-reported | Dependency is a downstream concern |
| Export concentration | Export-reported | Supply-side concentration |
| Mirror-statistics review | Both, side-by-side | Data quality and methodology |

This is a **methodological choice**, not a hierarchy of truth.
Export perspective remains available for all analyses.

---

## 5. Quantity

| Field | Source | Unit |
|---|---|---|
| Preferred | `netWgt` | kg → converted to metric tonnes |
| Fallback | `qty` | validated against `qtyUnitAbbr` |
| Missing | NULL | never 0 |

**Rationale:** UNSD documents that some countries do not report net
weight for all commodities. Missing quantity is a data-availability
fact, not an absence of trade.

---

## 6. Trade Value

| Field | Unit | Valuation basis |
|---|---|---|
| trade_value_usd | USD | Import = CIF-type; Export = FOB-type |

**Valuation basis is stored** so that mirror-statistics discrepancies
can be partially attributed to CIF/FOB asymmetry rather than treated
as data errors.

---

## 7. Known Limitations

1. Trade data aggregates all forms of natural graphite.
2. Mirror statistics: reporter values may differ from partner values.
3. Some (country, year, HS) combinations have missing quantity.
4. HS 3801 (artificial graphite) is NOT included.
5. Cross-revision comparability requires UNSD correspondence verification.

---

## 8. Validation Rules

- `reporter_country_id <> partner_country_id`
- `flow_code IN ('M','X')`
- `hs_code IN ('250410','250490')`
- `hs_revision` present for every observation
- `trade_quantity IS NULL OR trade_quantity > 0`
- `trade_value_usd IS NULL OR trade_value_usd > 0`
- Reporter and partner both exist in `dim_country`

---

## 9. Out of Scope for v1.0

- HS 3801 (artificial graphite)
- Sub-annual frequencies (monthly, quarterly)
- Transport mode
- Second-hand / re-export flows
- Cross-revision time-series harmonization

---

## 10. v1.1 — Additions after Live API Validation

### Data Quality Flags

Every Comtrade observation carries three quality indicators that are
preserved as part of the observation:

| Comtrade field | Stored as | Meaning |
|---|---|---|
| `isReported` | `is_reported` | True if reported by the country; false if estimated by UNSD |
| `isNetWgtEstimated` | `is_quantity_estimated` | True if net weight is estimated |
| `legacyEstimationFlag` | `legacy_estimation_flag` | Legacy estimation method code |

These flags are **never** used to silently filter data. They are stored as
first-class properties of the observation.

### Partner code 0 (World)

`partnerCode = 0` represents the World aggregate, not a bilateral flow.
These rows are **never** ingested into `fact_trade`. They may be used
only for sanity checks (e.g., summing bilateral flows and comparing
with the World total).

### Country Mapping

Comtrade uses UN M49 numeric codes (`reporterCode`, `partnerCode`).
Mapping to `dim_country` requires `m49_code`, a column added in v1.1.

### Descriptive Fields

Preview-mode API returns `null` for `reporterDesc`, `partnerDesc`, and
`cmdDesc`. These are **not** relied upon. Country names come from
`dim_country`; product names come from `dim_product_material`.

### Quantity Unit

`qtyUnitCode = 8` indicates kilograms. Conversion to metric tonnes is
performed before insertion. `unit_id = T` in `fact_trade`.

### Valuation

- Export flows: `fobvalue` used; `valuation_basis = 'FOB'`
- Import flows: `cifvalue` used; `valuation_basis = 'CIF'`
- `primaryValue` used as fallback when the specific value is null