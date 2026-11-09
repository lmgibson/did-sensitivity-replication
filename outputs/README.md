# Generated results

Run `Rscript --vanilla scripts/run_replication.R` to regenerate:

| Directory | Contents |
| --- | --- |
| `tables/` | Full-precision Tables 1–4, plus a separately labeled Table 2 reporting reconstruction |
| `diagnostics/` | Direct/reporting comparisons, original ACS diagnostics, model specifications, and legacy missing-data results |
| `samples/` | State/year membership and treatment flags for each model |
| `models/` | Saved fitted models and sensitivity objects |
| `environment/` | Session information and installed-package versions |

These generated directories are ignored by Git. Logs, manuscript table previews, and optional Table 2 diagnostics may also be present from recovery work. The main run does not regenerate those optional artifacts. `scripts/view_workflow.R` generates an interactive dependency graph here.

Begin with `diagnostics/published_table_comparison_summary.csv` and `diagnostics/published_table_comparison.csv`. The run exits unsuccessfully if an integrity check fails, Tables 1/4 stop matching, or the recovered Table 2 SE/t cells stop matching. It reports the existing Table 2/3 discrepancies without treating them as execution failures. Successful execution does not establish complete replication.

The main workflow tracks exported file contents through `targets`; missing or modified outputs trigger their export steps. `_targets/` is the separate, ignored cache.

Table 1 uses ACS personal income per capita; Table 2 uses the archived NASBO revenue-per-capita construction. `tables/table_2_spending_sensitivity.csv` keeps full precision (20/24 matches). `tables/table_2_spending_reporting_reconstruction.csv` separately applies the supported four-decimal log-rounding pathway (22/24); `diagnostics/table_2_reporting_comparison.csv` records its discrepancies. Neither path changes the two inconsistent p-values.

`diagnostics/table_2_acs_sensitivity.csv` and the comparison files suffixed `_acs` preserve the original recovery baseline (2/24 Table 2 matches). `diagnostics/model_specifications.csv` labels the construction used by each table. The Table 2 analytic dataset is in `data/derived/table_2_spending_panel.{csv,rds}`; its sample is in `samples/spending_sensitivity_sample.csv`. The saved `models/replication_models.rds` contains `table2_revenue` (model, panel, bounds, reporting table), the primary `spending_sensitivity`, and the preserved `spending_sensitivity_acs`.
