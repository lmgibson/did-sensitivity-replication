# Data

- `raw/spending/`: NASBO workbooks, state codes, and ACS income tables.
- `raw/enrollment/`: ACS B27016 aggregate tables for 2009–2017.
- `raw/shared/`: labor, ideology, population, and state lookup inputs.
- `reference/published_targets.csv`: independently transcribed Tables 1–4, with each cell's precision or p-value threshold.
- `derived/`: regenerated analytic panels in CSV/RDS and enrollment first differences.

Treat raw data as immutable. Source paths and SHA-256 checksums are recorded in [the import manifest](../staging/manifest.csv); its paths were updated when primary inputs moved here. Unused archival alternatives remain under `staging/original/data/`.

The full prepared spending panel is saved as RDS before fitting; the exported spending CSV reflects the 2010–2015 estimation window and includes both retained and excluded states. Individual model samples are in `outputs/samples/`. See the [audit](../docs/reference/replication-audit.md) for variable construction and sample restrictions.

The revenue-based Table 2 model has its own `derived/table_2_spending_panel.csv` and `.rds`, restricted to its 288 state/year observations and containing the explicitly named `revenue_per_capita` field alongside the preserved ACS `pc_inc`. Its membership and treatment flags are in `outputs/samples/spending_sensitivity_sample.csv`.

The run replaces files in `derived/`. Generated data are ignored by Git; regenerate them with `Rscript --vanilla scripts/run_replication.R`.
