# Source code

`_targets.R` is the single cached workflow definition. `scripts/run_replication.R` is the command entry point; `scripts/load_modules.R` loads eight modules that define functions without reading data, fitting models, or writing files.

| Module | Responsibility |
| --- | --- |
| `data/read_covariates.R` | Shared input inventory and labor/ideology imports |
| `data/prepare_spending_panel.R` | Spending panel preparation |
| `data/prepare_enrollment_panel.R` | Enrollment panel preparation |
| `analysis/fit_spending_models.R` | Table 1, the original ACS sensitivity diagnostic, and the revenue-based Table 2 model; shared sensitivity calculation |
| `analysis/fit_enrollment_models.R` | First differences, Tables 3–4, and the legacy missing-data diagnostic |
| `output/export_results.R` | Validated exports, model samples, panels, comparisons, reporting reconstruction, and environment record |
| `validation/validate_replication.R` | Published-table comparisons and numerical/sample consistency checks |
| `run_replication.R` | Uncached orchestration for independent numerical verification and debugging |

The uncached runner deliberately remains independent of targets caching. Both runners call the same preparation, modeling, validation, and export functions. Its default `table2_specification = "revenue"` reproduces the targets workflow; `"acs"` replays the original baseline. The numerical regression suite exercises both paths.

All output writers live together and share a CSV writer; thin wrappers around exports have been removed. Writers return every generated path so targets can detect missing or changed files. The validation result is still an explicit dependency of each analysis export.

Legacy analytic column names are preserved at the data boundary. Table 2 adds a separately named `revenue_per_capita` field instead of overwriting the ACS `pc_inc`. The [audit](../docs/reference/replication-audit.md) documents the sample adaptation and other compatibility decisions.

Optional specification searches live under `research/reconciliation/`, not in the normal module loader. Run them with `Rscript --vanilla scripts/run_replication.R diagnose`. Original source archives remain in ignored `staging/`.
