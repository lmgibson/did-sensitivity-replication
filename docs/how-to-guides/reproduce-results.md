# Reproduce the results

## Set up dependencies

Install **R 4.5.0** from [CRAN](https://cran.r-project.org/), then run from the repository root:

```sh
Rscript --vanilla scripts/setup_environment.R
```

Setup bootstraps renv and restores the exact versions recorded in `renv.lock`, including sensemakr 0.1.6. `DESCRIPTION` declares direct runtime dependencies and optional editor/environment tools; `scripts/dependencies.R` reads the runtime list from it. The lockfile includes these dependencies and their transitive requirements. The local library is isolated from the system library and excluded from version control; renv uses a shared package cache to avoid unnecessary copies.

`.R-version`, `DESCRIPTION`, and `renv.lock` specify R 4.5.0. The entry points reject a different R version before loading the project environment. renv restores packages but does not install R; `.R-version` is a version declaration for humans and compatible tooling, not an automatic installer. Native system libraries may still be needed when restoring compiled packages on another platform.

Interactive R sessions started in the project load renv through `.Rprofile`. CLI entry points explicitly activate it too, including under `--vanilla`. The optional R language server is locked so Zed keeps working with the isolated library; its lintr dependency does not change the editor's selection of Jarl for diagnostics.

To inspect the environment from R, run `renv::status()`. To intentionally change dependencies, update `DESCRIPTION`, install the desired versions with `renv::install()`, run both regression checks below, then call `renv::snapshot()`. Review the resulting lockfile changes. Explicit snapshot mode uses `DESCRIPTION`; development dependencies in `Suggests` are included through `snapshot.dev`.

The lockfile preserves the currently verified environment. It does not resolve the documented discrepancies with the published tables or guarantee byte-identical numerical results across operating systems. The [package upgrade evaluation](../reference/package-upgrade-evaluation.md) records the accepted updates, the preserved original lockfile, and why R 4.6.2 is not yet the exact-reproduction runtime.

## Run both examples

```sh
Rscript --vanilla scripts/run_replication.R
```

The entry point resolves the repository from its own location, so an absolute script path also works from another working directory. `--vanilla` avoids loading saved workspaces and user startup files; the scripts explicitly activate the project environment.

The run uses `_targets.R` to track raw/reference files, prepare both panels, fit models, validate comparisons, and export results. Current steps are reused from `_targets/`; only outdated steps are rebuilt. Exported files are tracked too, so deleting one triggers regeneration. It does not edit raw or archived material.

## Review the comparisons

- [Summary](../../outputs/diagnostics/published_table_comparison_summary.csv): matching cells per table.
- [Cell-level comparison](../../outputs/diagnostics/published_table_comparison.csv): published values, recovered values, differences, precision, and pass/fail flags.
- [Replication audit](../reference/replication-audit.md): model specifications, adaptations, and unresolved issues.

Tables 1 and 4 match at published precision. Table 3 has a small effect-entry discrepancy; Table 2 remains unresolved. The validation requires the established Table 1/4 matches, sample sizes, unique state/year keys, valid enrollment percentages, and agreement between independently computed first-difference estimates and `plm`.

See `outputs/tables/` for full estimates and `outputs/samples/` for model membership. `outputs/environment/session_info.txt` and `package_versions.csv` record the environment. Generated files are replaced when their export targets need rebuilding. Environment files describe the run that last built those exports.

## Explore the Table 2 discrepancy

After a full run, execute from the repository root:

```sh
Rscript --vanilla scripts/diagnose_spending_bounds.R
```

This separate exploratory script compares nearby time windows and calendar/fiscal-year LFP. It writes `outputs/diagnostics/spending_sensitivity_diagnostics.csv` and does not alter the canonical models or reference targets.

## Check a code change against the recovered baseline

```sh
Rscript --vanilla tests/check_regression.R
```

The checks regenerate all results in a temporary directory, including the exploratory diagnostics, and compare them with fixtures frozen before the readability refactor. They require byte-identical CSVs, identical full prepared panels, and exact equality for model coefficients, covariance matrices, residuals, fitted values, model frames, degrees of freedom, and sensitivity bounds. They also check that loading source modules does not execute the workflow.

This is separate from comparison with the paper: the recovery baseline intentionally contains the documented Table 2/3 discrepancies. See [the fixture notes](../../tests/README.md). The test does not overwrite normal outputs or update fixtures automatically.

## Lint the maintained code

Install [Jarl](https://jarl.etiennebacher.com/) separately from R dependencies. On macOS with Homebrew:

```sh
brew install jarl
jarl check .
```

The repository was checked with Jarl 0.7.1. `jarl.toml` selects maintained code in `_targets.R`, `src/`, `scripts/`, and `tests/`; source archives and generated outputs are outside that scope. The configuration keeps the existing `%>%` pipe style. The check command reports problems without modifying files.

After applying any suggested code changes, run the exact regression checks as well. Lint success does not establish numerical equivalence.

## Format the maintained code

Install [Air](https://posit-dev.github.io/air/) separately from R dependencies:

```sh
brew install air
air format .
```

The project uses Air 0.13.0 with 80-column formatting and two-space indentation, configured in `air.toml`. Archives, raw/reference/derived data, generated outputs, agent skills, and regression fixtures are excluded. Formatting does not change those files.

Check formatting and linting without editing files, then verify numerical equivalence:

```sh
air format . --check
jarl check .
Rscript --vanilla tests/check_regression.R
```

For Zed, `.zed/settings.json` selects the installed `air` executable as the R formatter using Air's [documented stdin integration](https://posit-dev.github.io/air/cli.html#stdin). Zed's R extension is required for language recognition; it is installed on this machine. The project setting disables on-type formatting so the R language server does not compete with Air. Normal Zed formatting commands and its default format-on-save behavior use the selected formatter; global editor settings are unchanged.

Install the Jarl extension in Zed for editor diagnostics. This project enables both `jarl` and `r_language_server`: Jarl provides lint diagnostics, while the R language server provides completion, hover information, and navigation. The project sets `lsp.r_language_server.settings.r.lsp.diagnostics` to `false` to disable the R server’s default lintr diagnostics and avoid duplicate warnings. Both the R and Jarl extensions are installed on this machine.

## Inspect and run the dependency graph

From R in the repository root:

```r
targets::tar_visnetwork(targets_only = TRUE)
targets::tar_manifest()
targets::tar_outdated()
targets::tar_make()
targets::tar_read(spending_models)
```

For an HTML graph you can open outside an R editor:

```sh
Rscript --vanilla scripts/view_workflow.R
```

This saves `outputs/diagnostics/workflow_graph.html` and its companion asset directory. Keep them together. See the [workflow explanation](../explanation/workflow.md) for the full structure.

To force a complete rebuild from R, use `targets::tar_invalidate(names = tidyselect::everything())` followed by `targets::tar_make()`. Do this after changing R or installed package versions: dependency versions are recorded but are not automatically tracked as analysis inputs. The lockfile records package versions, but targets does not automatically invalidate results when that lockfile changes.

Check the actual cached workflow in isolation:

```sh
Rscript --vanilla tests/check_workflow.R
```

This test copies raw inputs and uses a separate cache/output directory, verifies the frozen numerical baseline, confirms the second run is cached, checks branch-specific invalidation for raw/reference edits, and tests recovery of a deleted table without refitting models.
