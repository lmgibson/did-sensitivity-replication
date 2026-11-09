# Difference-in-difference sensitivity analysis

Code and documentation for sensitivity analysis of difference-in-difference estimates, building on Gibson and Zimmerman (2021) and Cinelli and Hazlett (2020).

## Run the replication

```sh
Rscript --vanilla scripts/setup_environment.R
Rscript --vanilla scripts/run_replication.R
```

Install **R 4.5.0** first. Setup restores the exact package versions in `renv.lock` into an isolated project library. The entry point runs the [`targets` workflow](_targets.R), rebuilding outdated steps and reusing current results. Tables 1 and 4 match at reported precision; Table 2 and one Table 3 effect entry remain unresolved. See the [replication audit](docs/reference/replication-audit.md).

Inspect the workflow with `targets::tar_visnetwork()` from R, or save an interactive graph with `Rscript --vanilla scripts/view_workflow.R`. See [how the workflow fits together](docs/explanation/workflow.md).

Check that code changes preserve the recovered baseline exactly:

```sh
Rscript --vanilla tests/check_regression.R
```

Check caching, file tracking, and output recovery with `Rscript --vanilla tests/check_workflow.R`.

The current lockfile includes dependency updates verified against the frozen baseline. R remains pinned to 4.5.0: an R 4.6.2 evaluation preserved the reported results but changed three comparison differences at about `1e-16`. See the [upgrade evaluation](docs/reference/package-upgrade-evaluation.md) for accepted versions and evidence.

Lint maintained R code with [Jarl](https://jarl.etiennebacher.com/):

```sh
jarl check .
```

The project configuration in `jarl.toml` checks `_targets.R`, `src/`, `scripts/`, and `tests/`, preserving the existing `%>%` pipe convention. Jarl is a separate development tool; it is not required to run the analyses.

Format code with [Air](https://posit-dev.github.io/air/), or check formatting without editing files:

```sh
air format .
air format . --check
```

`air.toml` defines the shared formatting rules and excludes archived inputs, generated files, and fixtures. Project-local Zed settings use the Air command-line formatter for R files.

## Structure

```text
.agents/skills/   Project-specific agent skills
DESCRIPTION      Project metadata and direct R dependencies
.R-version       Required R version (4.5.0)
renv.lock        Exact package versions and sources
renv/            Environment activation and settings
_targets.R       Central workflow definition and dependency graph
src/data/        Input preparation
src/analysis/    Spending/enrollment models and exploratory diagnostics
src/validation/  Published-table comparisons and consistency checks
scripts/         Setup and run entry points
tests/           Exact regression checks and frozen pre-cleanup fixtures
data/raw/        Unmodified primary inputs
data/reference/  Independently transcribed published targets
data/derived/    Generated analytic datasets
outputs/         Generated tables, diagnostics, model samples, and environment
docs/            Divio tutorials, how-to guides, reference, and explanation
staging/         Historical scripts, alternate inputs, manuscript, and provenance
```

See [how to reproduce the results](docs/how-to-guides/reproduce-results.md) and the [documentation index](docs/README.md).

Active R scripts and generated data use descriptive `snake_case` filenames. Entry points name the task, model files name the example, and table exports include both the published table number and their contents. Raw inputs and archived material retain their source filenames for provenance.
