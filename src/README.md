# Source code

The entry point `scripts/run_replication.R` calls `targets::tar_make()`. The central `_targets.R` file loads function definitions and declares the dependency graph. Loading a source module does not read data, fit models, or write files.

| Module | Responsibility |
| --- | --- |
| `data/read_covariates.R` | Shared labor and ideology imports, with distinct fiscal/calendar LFP aggregation |
| `data/prepare_spending_panel.R` | Return the prepared spending panel |
| `data/prepare_enrollment_panel.R` | Return the prepared enrollment panel |
| `analysis/fit_spending_models.R` | Fit Table 1 spending models and preserve the original ACS-based Table 2 diagnostic |
| `analysis/fit_spending_sensitivity.R` | Fit the source-supported revenue-per-capita Table 2 model and calculate full-precision and reporting-path bounds |
| `analysis/export_spending_reconciliation.R` | Export reporting reconstruction, ACS diagnostics, explicit specifications, Table 2 model data and sample |
| `analysis/fit_enrollment_models.R` | Construct differences and fit enrollment models; return Tables 3–4 and the legacy missing-data diagnostic |
| `analysis/export_replication_results.R` | Export explicitly supplied analysis results |
| `validation/validate_replication.R` | Compare published targets, validate scientific consistency, and export comparisons |
| `analysis/diagnose_spending_bounds.R` | Return exploratory specification checks; excluded from the main workflow |
| `workflow_files.R` | Declare input groups and write tracked output files |
| `run_replication.R` | Uncached orchestration for independent regression checks and debugging |

`prepare_spending()` and `prepare_enrollment()` accept a raw-data directory. `fit_spending()`, `fit_spending_sensitivity()`, and `fit_enrollment()` take their prepared panels explicitly. `run_replication()` accepts raw-data, derived-data, output, and reference-target paths; defaults reproduce this repository's analysis. It remains uncached so regression checks execute every calculation independently of the workflow store. Its default `table2_specification = "revenue"` matches the targets workflow; `"acs"` explicitly replays the original recovery baseline for exact regression testing.

Legacy analytic column names are retained at the data boundary to preserve schemas and model formulas. Internal temporary objects use descriptive names. Numerical compatibility details are documented next to the relevant operations, including the early ACS income-band construction and the unused `state_capi` scaling.

Run the complete workflow with `Rscript --vanilla scripts/run_replication.R`. For exact regression checks, run `Rscript --vanilla tests/check_regression.R`. Exploratory diagnostics have their own entry point, `scripts/diagnose_spending_bounds.R`.

Historical scripts are preserved in `staging/original/scripts/`. See the [audit](../docs/reference/replication-audit.md) for compatibility changes and substantive recovery decisions.

See [the workflow explanation](../docs/explanation/workflow.md) for target names, graph inspection, and cache behavior.
