# How the workflow fits together

`_targets.R` is the central workflow file. It loads methods from `src/` via `scripts/load_modules.R`, then declares named targets and their dependencies. The statistical methods stay in the existing functions; the workflow specifies when they run and how their results flow between steps.

```mermaid
flowchart LR
  S[Spending source files] --> SP[spending_panel]
  E[Enrollment source files] --> EP[enrollment_panel]
  C[Shared labor and ideology files] --> SP
  C --> EP
  SP --> SM[spending_models]
  EP --> EM[enrollment_models]
  SM --> CMP[comparisons]
  EM --> CMP
  REF[Published reference values] --> CMP
  CMP --> V[validation]
  SM --> V
  EM --> V
  V --> OUT[Prepared panels and exported results]
  SP --> OUT
  EP --> OUT
  SM --> OUT
  EM --> OUT
  OUT --> ENV[Environment record]
```

The actual workflow has 15 targets:

| Targets | Role |
| --- | --- |
| `shared_source_files`, `spending_source_files`, `enrollment_source_files` | Track the exact raw files read by the preparation functions |
| `reference_file`, `published_targets` | Track and read the published comparison values |
| `spending_panel`, `enrollment_panel` | Prepare data independently |
| `spending_models`, `enrollment_models` | Fit each example and calculate its sensitivity statistics |
| `comparisons`, `validation` | Compare with the paper and run consistency checks |
| `prepared_panel_files`, `analysis_files`, `comparison_files` | Write and track validated outputs |
| `environment_files` | Record the environment after the analysis/comparison exports exist |

The preparation commands explicitly reference their source-file targets because the underlying readers accept a directory. Those references are essential: tracking the directory name alone would not detect edits to file contents. Shared labor and ideology changes invalidate both examples. Enrollment-only input changes invalidate the enrollment branch; changes to the reference table affect comparison/validation and downstream exports without refitting models.

## Commands and caching

The existing shell command, `Rscript --vanilla scripts/run_replication.R`, resolves the repository root and calls `targets::tar_make()`. In an R session at the root, `targets::tar_make()` does the same work. `targets::tar_read(spending_models)` retrieves a cached result; its list contains the fitted models, tables, panel, and sensitivity results.

`targets::tar_visnetwork(targets_only = TRUE)` displays the dependency graph. `scripts/view_workflow.R` saves an interactive HTML version. `targets::tar_outdated()` lists steps that need rebuilding.

Targets caches intermediate objects in the ignored `_targets/` directory and skips current work. All generated analysis files are returned by file targets, so missing or edited exports are detected. Exports are currently grouped: deleting one table regenerates the analysis export group, while cached model fits are reused. This keeps the first integration small and readable.

Installed package versions and R are recorded with the exports but do not automatically invalidate cached calculations. After an environment change, invalidate and rerun the workflow; environment locking is a separate future improvement. If you copy or relocate the repository, discard the old `_targets/` cache and rebuild, because file targets contain paths.

## Regression checks and optional work

`src/run_replication.R` retains an uncached function for debugging and the independent exact regression check. Both orchestrators call the same preparation, modeling, validation, and export functions. `tests/check_regression.R` verifies the uncached runner; `tests/check_workflow.R` verifies the real cached workflow against the same frozen baseline and tests cache/file behavior.

The exploratory spending-bounds diagnostics remain a separate command. They are not part of the default graph, so speculative variants do not become dependencies of the published-table replication.

For isolated workflow tests or alternate export destinations, `_targets.R` reads `DID_RAW_DIR`, `DID_DERIVED_DIR`, `DID_OUTPUT_DIR`, and `DID_REFERENCE_FILE`. Normal use needs none of these variables. They change paths only, not the analysis specifications.
