# Published-table reconciliation research

Start with the [current provenance findings](../../docs/reference/table2-provenance-recovery.md); the [initial numerical investigation](../../docs/reference/table-reconciliation.md) is a historical report from before the revenue construction was recovered. These diagnostics preserve the canonical replication and distinguish actual recomputation from inverse fitting to published targets.

Run with R 4.5.0 and the restored project environment:

```sh
Rscript --vanilla research/reconciliation/run_diagnostics.R
Rscript --vanilla research/reconciliation/check_historical_versions.R
```

`run_diagnostics.R` prepares the archived inputs using the maintained code, fits both examples, audits the published Table 2 probabilities, fits a synthetic curve to all six reported t values, and checks Table 3 rounding paths. The synthetic curve is not a recovered regression.

`check_historical_versions.R` downloads CRAN sensemakr 0.1.2, 0.1.3, and 0.1.4 into isolated libraries and launches `historical_worker.R` in separate R processes. A current-version worker provides the comparison. It never replaces a package in the project library or changes `renv.lock`.

Generated outputs and historical package installations live under ignored `outputs/diagnostics/reconciliation/`. The small `evidence/` CSV snapshots were copied from the successful 2026-11-08 run for review. The inverse-fit and historical-version snapshots record the investigation, rather than define regression expectations. The later `revenue_sensitivity_bounds.csv`, `revenue_model_parameters.csv`, and `revenue_table2_comparison.csv` are independent evidence used by the numerical and workflow suites to verify the promoted revenue model. None of these checks overwrites the original ACS fixtures or loosens tolerances. The source manifest records the downloaded archive hashes.

The directory has a scoped `jarl.toml` because the repository's root include list covers maintained analysis/workflow code, not this optional research directory. Check these files explicitly:

```sh
air format research/reconciliation
jarl check research/reconciliation/*.R
```

A [follow-up provenance investigation](../../docs/reference/table2-provenance-recovery.md) reconstructs the archived revenue-per-capita covariate. Run `Rscript --vanilla research/reconciliation/recover_revenue_benchmark.R` to reproduce its actual regression and 20/24 direct (22/24 with intermediate rounding) Table 2 comparisons. The default analysis now implements that construction in `src/analysis/fit_spending_models.R`. This optional script independently recomputes it into research-only outputs; it does not overwrite the main analysis outputs.

The optional legacy ACS window/LFP search is defined in `diagnose_spending_bounds.R` and is not loaded during normal replication. Run it with `Rscript --vanilla scripts/run_replication.R diagnose` after a normal analysis run.
