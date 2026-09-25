# EV Battery Supply Chain Intelligence

**From Critical Minerals to Battery Manufacturing**

A data-driven intelligence system that maps the EV battery supply chain, quantifies geographic and trade concentration, and identifies structural exposure across process stages.

## Project Scope

- **Phase 1 (current):** Graphite + LFP battery chain
- **Phase 2:** Lithium, Nickel, Cobalt, Manganese + NMC
- **Phase 3:** Cross-chemistry comparison (LFP vs NMC)

## Core Questions

1. Where is supply concentrated?
2. Where does trade dependency exist?
3. How has concentration changed over time?
4. Which parts of the chain are structurally more exposed?
5. What evidence should a decision-maker examine before considering diversification?

## Architecture
USGS / IEA / UN Comtrade → Python (ETL) → PostgreSQL → Power BI

## Stack

- **Data sources:** USGS, IEA, UN Comtrade, industry reports
- **Storage:** PostgreSQL
- **ETL:** Python (pandas, SQLAlchemy)
- **Visualization:** Power BI + DAX
- **Documentation:** Markdown

## Repository Structure
├── data/ # Raw and processed data (raw is gitignored)
├── src/ # Python source (ingestion, cleaning, transformation, loading)
├── sql/ # DDL, reference data, analytical queries
├── notebooks/ # Exploratory analysis
├── powerbi/ # Dashboard files
├── docs/ # Project documentation
└── reports/ # Final analytical reports

## Documentation

- [Project Charter](docs/project_charter.md)
- [Design Decisions](docs/design_decisions.md)
- [Data Dictionary](docs/data_dictionary.md)
- [Methodology](docs/methodology.md)

## Environment

This project uses a shared conda environment (`data-project`) for Python. Project-specific dependencies are listed in `requirements.txt`.

```bash
pip install -r requirements.txt
