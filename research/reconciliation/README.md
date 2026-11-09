# Published-table reconciliation research

Read [the findings](../../docs/reference/table-reconciliation.md) first. These diagnostics preserve the canonical replication and distinguish actual recomputation from inverse fitting to published targets.

Run with R 4.5.0 and the restored project environment:

```sh
Rscript --vanilla research/reconciliation/run_diagnostics.R
Rscript --vanilla research/reconciliation/check_historical_versions.R
```

`run_diagnostics.R` prepares the archived inputs using the maintained code, fits both examples, audits the published Table 2 probabilities, fits a synthetic curve to all six reported t values, and checks Table 3 rounding paths. The synthetic curve is not a recovered regression.

`check_historical_versions.R` downloads CRAN sensemakr 0.1.2, 0.1.3, and 0.1.4 into isolated libraries and launches `historical_worker.R` in separate R processes. A current-version worker provides the comparison. It never replaces a package in the project library or changes `renv.lock`.

Generated outputs and historical package installations live under ignored `outputs/diagnostics/reconciliation/`. The small `evidence/` CSV snapshots were copied from the successful 2026-11-08 run for review. They are not fixtures and are not used to set canonical expectations or tolerances. The source manifest records the downloaded archive hashes.

The directory has a scoped `jarl.toml` because the repository's root include list covers maintained analysis/workflow code, not this optional research directory. Check these files explicitly:

```sh
air format research/reconciliation
jarl check research/reconciliation/*.R
```

A [follow-up provenance investigation](../../docs/reference/table2-provenance-recovery.md) reconstructs the archived revenue-per-capita covariate. Run `Rscript --vanilla research/reconciliation/recover_revenue_benchmark.R` to reproduce its actual regression and 20/24 direct (22/24 with intermediate rounding) Table 2 comparisons. This optional reconstruction does not replace the default analysis.
