# Package upgrade evaluation, 2026-11-08

This records dependency compatibility against the original ACS-based recovery baseline. The subsequent [Table 2 revenue reconstruction](table2-provenance-recovery.md) is an intentional analysis change, tested separately; package updates did not cause that change.

## Decision

Accept the updated package environment in the root `renv.lock`; retain **R 4.5.0** for exact reproduction. Every maintained numerical regression check and workflow integration check passes in the main project after restoring that lockfile. Statistical code, raw inputs, published references, and frozen fixtures were not changed.

The original environment had 103 locked packages. The accepted environment has 95: **60 retained packages upgraded, 33 unchanged, 10 removed, and 2 added**. Removed packages were no longer needed after upgrading the R language server; additions are `otel` and `rdtools`. No further updates are reported for the accepted library at evaluation time. The [package inventory](upgrade-evaluation/package_changes.csv) records every before/after version, including removals.

| Direct dependency | Before | Accepted |
| --- | --- | --- |
| dplyr | 1.1.4 | 1.2.1 |
| readr | 2.1.5 | 2.2.0 |
| readxl | 1.4.5 | 1.6.0 |
| stringr | 1.5.1 | 1.6.0 |
| plm | 2.6-6 | 2.6-7 |
| sandwich | 3.1-1 | 3.1-3 |
| lmtest | 0.9-40 | 0.9-40 |
| sensemakr | 0.1.6 | 0.1.6 |
| targets | 1.12.0 | 1.12.0 |
| visNetwork | 2.1.4 | 2.1.4 |
| htmlwidgets | 1.6.4 | 1.6.4 |
| languageserver (development) | 0.3.16 | 0.3.21 |
| renv (environment) | 1.3.1 | 1.3.1 |

## Evaluation method

The original lockfile was copied to [r-4.5.0-baseline.lock](environments/r-4.5.0-baseline.lock) before changes. Tests ran in an independent project copy with its own renv library, followed by restoration and verification in the main project. Shared renv cache entries were reused without modifying the original package installations.

Updates were cumulative: editor/workflow tools, data preparation, statistical packages, and remaining binary packages. Both the independent numerical regression test and the workflow integration test passed after each of these batches. The final batch added languageserver 0.3.21 from source and explicitly installed the newer recommended packages MASS, Matrix, lattice, and nlme. Ordinary `renv::update()` had skipped those recommended packages in the R-provided sandbox. The complete final environment passed both tests before and after promotion to the main project.

The checks require:

- All 18 fixture CSVs to match byte-for-byte.
- Both prepared panels to match exactly, including attributes and order.
- All seven models' coefficients, covariance, residuals, fitted values, model frames, and residual degrees of freedom to match exactly.
- Both sensitivity-bound objects to match exactly.
- Workflow caching, branch invalidation, and missing-output recovery to work.

The [stage inventory](upgrade-evaluation/stages.csv), [final regression log](upgrade-evaluation/09_project_regression.log), [workflow log](upgrade-evaluation/09_project_workflow.log), and [remaining-update check](upgrade-evaluation/09_remaining_updates.log) preserve the evidence. The normal workflow was then fully invalidated and [rebuilt all 15 targets](upgrade-evaluation/09_project_run.log), refreshing the environment inventory. That was before Table 2 integration; the current workflow has 17 targets. Existing warnings that some binaries were built under R 4.5.2 remain; both suites passed under R 4.5.0.

## R 4.6.2 candidate

R 4.6.2 was obtained from the official CRAN macOS installer, whose developer signature and notarization were verified. Only its framework version was copied alongside the existing installation. During that experiment, the default R and framework `Current` link were left pointing to R 4.5.0. The candidate was run using its explicit executable and `R_HOME`, in a second isolated project. No R GUI or installer postflight scripts were run.

The final candidate used **the same package names and versions as the accepted R 4.5.0 environment**, recorded in [r-4.6.2-candidate.lock](environments/r-4.6.2-candidate.lock). This controls package versions, though platform binaries and R builds can still differ.

It failed both strict suites at the comparison CSV. Further inspection found:

- 17 of 18 CSV files remained byte-identical. This includes all four exported model/sensitivity tables.
- Both full prepared panels, all seven models' checked values, and both sensitivity-bound objects remained exactly identical.
- Only `outputs/diagnostics/published_table_comparison.csv` differed: three values in its `difference` column changed by at most approximately `1.01e-16`. The serialized `observed` values and all match flags remained unchanged.
- These rows concerned Table 1 models 1 and 4 p-values and the Table 2 fourth bound's one-sided p-value. The differences are consistent with runtime/build-level numerical variation and disappear at published precision; their internal cause was not traced further.

See the [candidate regression log](upgrade-evaluation/08_r462_regression.log), [workflow log](upgrade-evaluation/08_r462_workflow.log), [per-file checks](upgrade-evaluation/08_r462_csv_checks.csv), and [model/panel inspection](upgrade-evaluation/08_r462_differences.log). The workflow suite stops at its numerical baseline gate, so its subsequent caching checks were not completed under R 4.6.2.

R 4.6.2 therefore preserves the reported scientific results in this evaluation but does **not** satisfy the current byte-exact contract. It is not the default supported runtime. No fixtures or test tolerances were changed to accept it.

## Agreement with the paper at the time of the upgrade audit

At that stage, the accepted environment and R 4.6.2 candidate both retained the original ACS comparison. The current revenue-based Table 2 results are documented separately in the [replication audit](replication-audit.md):

| Table | Matching numeric cells at published precision |
| --- | --- |
| 1 | 16 / 16 |
| 2 | 2 / 24 |
| 3 | 11 / 12 |
| 4 | 12 / 12 |

Those discrepancies were unresolved at the end of this package experiment. Upgrading dependencies did not resolve or worsen them; the later source-supported covariate reconstruction explains most Table 2 cells. The Table 3 adjusted effect still rounds to 7.69 rather than the printed 7.70. Exact baseline reproduction and complete reproduction of the published paper are separate claims; see the [replication audit](replication-audit.md).

## Repeat the evaluation

1. Make an independent project copy, excluding generated outputs and local renv libraries, and preserve its initial lockfile.
2. Install the declared R version and restore its environment with `Rscript --vanilla scripts/run_replication.R setup`.
3. Check available upgrades with `renv::update(check = TRUE)`. Also inspect recommended packages supplied by R; these may be omitted from the ordinary project-library update check.
4. Update a coherent package batch and snapshot the candidate library. Restart R for tests so previously loaded namespaces cannot hide changes.
5. Run `Rscript --vanilla tests/check_regression.R` and `Rscript --vanilla tests/check_workflow.R`. On failure, retain the outputs, compare values/attributes separately, and isolate the responsible changes. Preserve fixtures and thresholds.
6. Promote a candidate lockfile only after both checks pass, restore it in the main project, and verify both checks again. Invalidate the targets cache when changing the environment, since package versions are not automatically tracked as workflow inputs.
7. Test an R runtime upgrade separately, aligning package versions where possible and using its own project copy and lockfile.

For a historical baseline experiment, use R 4.5.0 in a separate project copy and restore with `renv::restore(lockfile = "docs/reference/environments/r-4.5.0-baseline.lock", prompt = FALSE)`. Preserve that copy's baseline lockfile as its root `renv.lock` so subsequent setup commands restore the same environment.

This evaluation covers this project's exercised paths on the macOS recovery system. It does not establish that every feature of every updated package, or another operating system, behaves identically.
