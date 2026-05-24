# Credit Card Fraud Analytics — SQL Data Warehouse & Detection Engine

A PostgreSQL-based analytical project that models 590K credit card transactions 
into a star schema and builds a rule-based fraud detection engine — entirely in SQL.

![ER Diagram](docs/er_diagram.png)

## Overview

This project analyzes the IEEE-CIS Fraud Detection dataset (590,540 transactions, 
Dec 2017–Jun 2018) to answer a core business question: **where does fraud 
concentrate, and can we detect it with rule-based logic?**

The work is structured as a dimensional data warehouse plus five analytical phases, 
culminating in a fraud detection engine with measured precision, recall, and 
cost-benefit performance.

## Key Findings

- **Overall fraud rate:** 3.5% by count
- **Highest-risk segment:** Card-Not-Present + Credit + free webmail + high value — 
  a **26.3% fraud rate**, 7.5× the baseline
- **Concentration:** Two segments (CNP and Web Purchase, both with free webmail) 
  contain ~66% of all fraud
- **Detection engine:** 21.9% recall at threshold 10, generating **$245,722 in net 
  benefit** under a conservative cost model
- **Notable null result:** Transaction velocity — usually the strongest fraud signal — 
  proved unusable here because the dataset's anonymization makes card IDs represent 
  clusters, not individual cards

## Tech Stack

- **PostgreSQL** — data warehouse, all transformation and analysis
- **Python** (pandas, SQLAlchemy) — connectivity and visualization only
- **Jupyter** — analytical notebooks
- **matplotlib / seaborn** — charts

## Architecture

Raw CSV → Python column-slimming → PostgreSQL staging → dimensional ETL → star schema → analysis

All cleaning, transformation, and analytical logic lives in SQL. Python handles only 
CSV pre-processing, database connectivity, and visualization — mirroring production 
analytics workflows where SQL is the system of record.

## Analytical Phases

1. **Fraud Landscape** — baseline rates by product, card network, card type, amount
2. **Temporal Patterns** — hour-of-day, day-of-week, weekly trends
3. **Velocity Analytics** — per-card transaction velocity (and why it failed here)
4. **Segmentation** — multi-dimensional risk profiling with NTILE, CUBE
5. **Rule Engine** — detection rules with precision/recall and cost-benefit analysis

## SQL Techniques Demonstrated

`FILTER` clause · `GROUPING SETS` · `CUBE` · `NTILE` · `PERCENTILE_CONT` · 
`RANGE BETWEEN INTERVAL` window frames · CTEs · star-schema dimensional modeling · 
role-playing dimensions · point-in-time transformations

## How to Run

1. Download the [IEEE-CIS dataset](https://www.kaggle.com/competitions/ieee-fraud-detection/data)
2. Run `scripts/python/01_preprocess_csv.py` to generate slim CSVs
3. Execute `sql/01` through `sql/09` in order to build and populate the warehouse
4. Open notebooks in `notebooks/` to reproduce the analysis

Database credentials are loaded from a `.env` file (see `.env.example`).

## Repository Structure

\`\`\`
├── sql/                 # DDL, ETL, and analysis queries (numbered in order)
├── notebooks/           # Five analytical phase notebooks
├── scripts/python/      # CSV pre-processing
├── docs/                # ER diagram, findings report
└── visuals/             # Exported charts
\`\`\`