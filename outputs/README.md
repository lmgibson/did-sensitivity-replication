# Generated results

Run `Rscript --vanilla scripts/run_replication.R` to regenerate:

| Directory | Contents |
| --- | --- |
| `tables/` | Full-precision recovered Tables 1–4 |
| `diagnostics/` | Cell-level comparisons, match counts, and legacy missing-data results |
| `samples/` | State/year membership and treatment flags for each model |
| `models/` | Saved fitted models and sensitivity objects |
| `environment/` | Session information and installed-package versions |

These generated directories are ignored by Git. Logs, manuscript table previews, and optional Table 2 diagnostics may also be present from recovery work. The main run does not regenerate those optional artifacts. `scripts/view_workflow.R` generates an interactive dependency graph here.

Begin with `diagnostics/published_table_comparison_summary.csv` and `diagnostics/published_table_comparison.csv`. The run exits unsuccessfully if an integrity check fails or Tables 1/4 stop matching. It reports the existing Table 2/3 discrepancies without treating them as execution failures. Successful execution does not establish complete replication.

The main workflow tracks exported file contents through `targets`; missing or modified outputs trigger their export steps. `_targets/` is the separate, ignored cache.
