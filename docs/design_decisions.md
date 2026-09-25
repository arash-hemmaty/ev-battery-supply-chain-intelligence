# Design Decisions — EV Battery Supply Chain Intelligence

This document records key architectural and analytical decisions. Each decision
is dated and justified, so future contributors (including our future selves)
can understand *why*.

## Project Charter (summary)

| Item | Decision |
|---|---|
| Title | EV Battery Supply Chain Intelligence |
| Phase 1 | Graphite + LFP |
| Phase 2 | Lithium, Nickel, Cobalt, Manganese + NMC |
| Phase 3 | Cross-chemistry comparison (LFP vs NMC) |
| Artifact language | English |
| Guiding principle | Data-driven, Source-traceable, Reproducible |

## Architecture

| # | Decision | Rationale |
|---|---|---|
| 1 | Stack: Python + PostgreSQL + DBeaver + Power BI | Industry-standard combination |
| 2 | Lightweight Star Schema | Balance simplicity and flexibility |
| 3 | Surrogate Key (PK) + Natural Key (UNIQUE) | Decoupled from source systems |
| 4 | SCD Type 1 in Phase 1; Type 2 possible later | Do not over-engineer |
| 5 | Different grains = Different fact tables | Kimball principle; avoid double counting |
| 6 | Three facts: production, trade, capacity | Not a single unified fact |
| 7 | One fact_trade with two FKs (exporter, importer) | Trade is a directed single flow |
| 8 | Company only in fact_capacity | Only where meaning is clear and data exists |
| 9 | Product + Material unified in Phase 1 | May split in Phase 2 |
| 10 | dim_source_term_mapping = harmonization core | Maps source terms to standard products |

## Data

| # | Decision | Rationale |
|---|---|---|
| 11 | NO synthetic data | Project integrity |
| 12 | Every number traceable to source_id | Auditability |
| 13 | source_id in fact grain | Each source is a separate observation |
| 14 | Fact = Observation, not absolute truth | User picks source |
| 15 | Latest available year per source | Data honesty |
| 16 | Both quantity and value stored in trade | Physical ≠ economic dependency |

## Analytical

| # | Decision | Rationale |
|---|---|---|
| 17 | We measure Exposure, not Risk | Risk requires event probability (out of scope) |
| 18 | Project 1 = baseline intelligence | Geopolitical scoring is Project 2 |
| 19 | HHI = concentration, not risk | Avoid misinterpretation |
| 20 | Supply sufficiency ≠ Supply security | Foundational principle |
| 21 | Five analytical layers | Clear role for each KPI |

## Technical (PostgreSQL)

| # | Decision | Rationale |
|---|---|---|
| 22 | COALESCE(company_id, 0) in UNIQUE constraints | Postgres NULL trick |
| 23 | CREATE UNIQUE INDEX instead of UNIQUE CONSTRAINT for expressions | SQL limitation |
| 24 | CHECK (exporter ≠ importer) in fact_trade | Prevent self-trade |
| 25 | BIGSERIAL for facts, SERIAL for dimensions | Different scale expectations |
| 26 | Index on FKs and date_id | Postgres FK is not auto-indexed |

## Workflow

| # | Rule | Rationale |
|---|---|---|
| 27 | One statement per DBeaver tab | Prevent cascading errors |
| 28 | Ctrl+Enter for one statement; Ctrl+A → Ctrl+Enter for a selection | Precise control |
| 29 | Verify with information_schema after DDL | Only ground truth |
| 30 | Orange warning in DBeaver = UI noise; red error = real | Distinguish warning from error |
| 31 | dim_date.is_latest must be updated every January | Maintenance rule |
| 32 | Shared conda env (data-project) | Avoid duplicate packages |
| 33 | requirements.txt lists project-specific packages only | Layered env |