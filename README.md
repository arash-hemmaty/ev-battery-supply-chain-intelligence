# EV Battery Supply Chain Intelligence

**Graphite Phase | Production, Trade Dependency, Concentration & Data Reliability**

An end-to-end analytics project investigating natural graphite production and international trade using public data. The project combines data ingestion, relational data modeling, SQL analytics, data-quality investigation, and a four-page Power BI report.

The objective is not to produce a generic dashboard. It is to examine how production concentration, supplier dependency, and reporting differences affect the way we measure a supply chain.

> **Scope note:** This is a selected analytical dataset, not an exhaustive representation of every global graphite trade flow. Concentration and dependency findings must be interpreted within the relevant country, year, HS classification, reporting perspective, and data coverage.

## Project at a Glance

| Item | Current scope |
|---|---|
| Trade observations | 1,584 |
| Production observations | 38 |
| Active trade reporters | 13 |
| Partner countries in selected extraction | 10 |
| Trade classifications | HS 250410 and HS 250490 |
| Trade years queried | 2015-2026; coverage varies by year and reporter |
| Production years | 2023-2024 |
| Dashboard | Four-page Power BI report |

## Key Findings

The following findings describe the selected dataset and its analytical filters. They should not be interpreted as universal measures of national supply-chain risk.

1. **Production concentration:** China accounted for 77.88% of global natural graphite production in 2024 in the assembled USGS-based production dataset.

2. **Supplier exposure:** A selected South Korea trade view showed a 98.95% supplier share attributed to China. The figure must be read in the context of the corresponding report filters and coverage.

3. **High observed concentration:** A selected Hungary trade slice produced an HHI of 10,000, indicating complete supplier concentration within that analytical slice.

4. **Germany concentration trend:** The analyzed Germany HHI series moved from 6,824 in 2015 to 2,730 in 2019, then increased to 3,341 in 2025.

5. **Classification matters:** For Germany, China represented 36.93% of the selected HS 250410 supplier share, compared with 99.99% for HS 250490 in the analyzed view.

6. **Mirror statistics:** A documented Germany-China comparison for HS 250410 in 2023 showed a 30% quantity discrepancy and a 41% trade-value discrepancy between exporter- and importer-reported perspectives. A discrepancy alone does not establish which report is correct or explain its cause.

**Interpretation principle:** HHI measures supplier concentration, not risk by itself. Supplier share, import volume, reporting coverage, trade classification, and data quality all affect the interpretation.

## Explore the Power BI Report

The report is organized around four analytical questions.

### 1. Executive Intelligence

**Question:** What does the selected graphite supply-chain dataset look like?

A high-level view of production concentration, trade coverage, supplier concentration, and the main findings.

![Executive Intelligence dashboard](assets/screenshots/01-executive-intelligence.png)

### 2. Trade Dependency

**Question:** How does supplier dependency vary across importing countries?

Compares supplier shares, leading suppliers, import profiles, and concentration indicators within the selected trade data.

![Trade Dependency dashboard](assets/screenshots/02-trade-dependency.png)

### 3. Concentration Evolution

**Question:** How has supplier concentration changed over time?

Examines HHI trends, leading supplier shares, and differences between trade classifications where the data support comparison.

![Concentration Evolution dashboard](assets/screenshots/03-concentration-evolution.png)

### 4. Data Reliability & Mirror Statistics

**Question:** How confidently can reported trade data be used to measure dependency?

Compares exporter- and importer-reported observations, highlights mirror discrepancies, and documents country-code harmonization issues.

![Data Reliability and Mirror Statistics dashboard](assets/screenshots/04-data-reliability-mirror-statistics.png)

## Data Sources and Classification

### USGS

The production dataset was assembled from the USGS *Mineral Commodity Summaries 2025* graphite statistics. It contains 38 country-year observations covering 19 countries in 2023 and 2024.

- [USGS Graphite Statistics and Information](https://www.usgs.gov/centers/national-minerals-information-center/graphite-statistics-and-information)

### UN Comtrade

Trade observations were collected through UN Comtrade for a selected set of reporters, partners, years, and natural graphite HS codes.

- [UN Comtrade Plus](https://comtradeplus.un.org/)

The extraction retains exporter- and importer-reported perspectives for mirror comparisons. The selected coverage should not be described as a complete global trade matrix.

### HS Classification

| HS code | Description used in this project |
|---|---|
| 250410 | Natural graphite in powder or flakes |
| 250490 | Other natural graphite |

These codes distinguish trade classifications, not individual graphite processing stages. Trade records under these codes should not be assigned to specific processing stages without additional evidence.

## Analytical Methods

- **Production share:** A country's reported production divided by the corresponding global production total in the assembled dataset.
- **Supplier share:** A supplier's share of the selected importer's observed supplier distribution.
- **Top-1 share:** The share attributed to the largest supplier within the chosen analytical context.
- **Herfindahl-Hirschman Index (HHI):** The sum of squared supplier shares expressed in percentage points, ranging up to 10,000 when a single supplier accounts for the entire measured distribution.
- **Concentration trend:** Changes in HHI and supplier shares over time, subject to comparable data coverage.
- **Mirror statistics:** Comparisons of exporter- and importer-reported observations for matched trade contexts. Differences may reflect several factors, and their underlying causes cannot be inferred from the discrepancy alone.
- **Data harmonization:** Investigation of country-code differences that can otherwise create apparent gaps in retrieved data.

The importer-reported perspective is used as the primary analytical choice for supplier dependency in this project. It is a methodological choice, not a claim that one reporting perspective is always correct.

## Technical Architecture

```text
USGS production data       UN Comtrade API
          |                      |
          v                      v
       Python ingestion and transformation
                      |
                      v
                  PostgreSQL
                      |
                      v
            SQL analytical views
                      |
                      v
              Power BI + DAX
                      |
                      v
       Four-page analytical report
```

### Technology Stack

- **Data ingestion and transformation:** Python, pandas
- **Database:** PostgreSQL
- **Database connectivity:** SQLAlchemy and psycopg2
- **Analytics:** SQL views and validation queries
- **Visualization:** Power BI and DAX
- **Source data:** USGS and UN Comtrade

## Repository Structure

```text
.
├── data/
│   └── raw/
│       └── usgs/
├── docs/
│   ├── project_charter.md
│   ├── design_decisions.md
│   ├── trade_data_contract.md
│   └── mirror_statistics.md
├── powerbi/
│   ├── ev_battery_supply_chain_intelligence.pbix
│   └── theme_supply_chain.json
├── sql/
│   ├── ddl/
│   ├── reference/
│   └── analytics/
├── src/
│   ├── ingestion/
│   ├── cleaning/
│   ├── transformation/
│   └── loading/
├── assets/
│   └── screenshots/
├── reports/
├── notebooks/
├── requirements.txt
└── README.md
```

## Documentation

- [Project Charter](docs/project_charter.md)
- [Design Decisions](docs/design_decisions.md)
- [Trade Data Contract](docs/trade_data_contract.md)
- [Mirror Statistics](docs/mirror_statistics.md)

## Running the Project

1. Clone the repository and install the Python dependencies listed in `requirements.txt`.
2. Configure PostgreSQL and API access using your own local environment settings.
3. Review the SQL DDL, reference-data, and analytics scripts before executing them in the intended order.
4. Open `powerbi/ev_battery_supply_chain_intelligence.pbix` using Power BI Desktop.

The PBIX report may require your own PostgreSQL connection configuration to refresh. Database credentials and local `.env` files are not part of the intended public setup.

```bash
pip install -r requirements.txt
```

## Limitations and Responsible Interpretation

- The trade extraction covers a selected subset of reporters and partners; it is not a complete global census.
- Coverage varies by country, partner, year, HS code, and reporting perspective.
- A missing observation must not automatically be interpreted as zero trade.
- Production, trade, processing capacity, and battery demand are distinct measures and are not interchangeable.
- HS 250410 and HS 250490 do not identify individual processing stages.
- High HHI or high supplier share alone does not establish the probability or severity of a disruption.
- Mirror discrepancies do not, by themselves, identify the correct reporter or prove the reason for a difference.

## Roadmap

This project is the intelligence baseline for a broader three-project portfolio:

1. **Intelligence:** Understand production concentration, trade dependency, and data reliability.
2. **Geopolitical Exposure:** Examine how geographic and policy-related disruptions can affect supply exposure.
3. **Resilience and Diversification:** Evaluate scenarios and potential responses to supply-chain disruptions.

The current repository implements the graphite-focused intelligence phase. Future phases are planned extensions, not completed capabilities of this report.
