# Difference-in-differences sensitivity analysis

> **Recovered replication with documented discrepancies.** This repository reconstructs the analyses in Gibson & Zimmerman (2021) and records the reconciliation findings. It does not claim complete agreement with every published table entry.

Code and documentation for sensitivity analysis of difference-in-difference estimates, building on Gibson and Zimmerman (2021) and Cinelli and Hazlett (2020).

## Run the replication

```sh
Rscript --vanilla scripts/run_replication.R setup
Rscript --vanilla scripts/run_replication.R
```

Install **R 4.5.0** first. Setup restores the exact package versions in `renv.lock` into an isolated project library. The entry point runs the [`targets` workflow](_targets.R), rebuilding outdated steps and reusing current results. Tables 1 and 4 match at reported precision. The source-supported revenue model matches 20/24 Table 2 cells directly, or 22/24 with separately exported intermediate log rounding; two p-values remain discrepant. Table 3 retains one effect-entry discrepancy. See the [replication audit](docs/reference/replication-audit.md).

Inspect the workflow with `targets::tar_visnetwork()` from R, or save an interactive graph with `Rscript --vanilla scripts/run_replication.R graph`. See [how the workflow fits together](docs/explanation/workflow.md).

Check that code changes preserve the recovered baseline exactly:

```sh
Rscript --vanilla tests/check_regression.R
```

The regression suite checks both the original ACS baseline and the integrated revenue reconstruction. Run all numerical and workflow checks through the same entry point:

```sh
Rscript --vanilla scripts/run_replication.R check
```

The command also accepts `setup`, `graph`, and `diagnose`; no argument runs the analysis. Use `--help` for the available commands. Original fixtures remain unchanged.

The current lockfile includes dependency updates verified against the frozen baseline. R remains pinned to 4.5.0: an R 4.6.2 evaluation of the original ACS baseline preserved its reported results but changed three comparison differences at about `1e-16`. The later revenue reconstruction was not part of that runtime experiment. See the [upgrade evaluation](docs/reference/package-upgrade-evaluation.md) for accepted versions and evidence.

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
src/analysis/    Spending and enrollment models
src/output/      Shared writers for tables, panels, comparisons, and models
src/validation/  Published-table comparisons and consistency checks
scripts/         One command entry point, environment activation, and module loader
tests/           Numerical regression, workflow integration, and frozen fixtures
data/raw/        Unmodified primary inputs
data/reference/  Independently transcribed published targets
data/derived/    Generated analytic datasets
outputs/         Generated tables, diagnostics, model samples, and environment
docs/            Divio tutorials, how-to guides, reference, and explanation
research/        Optional reconciliation investigations and their evidence
staging/         Optional local archive (not included in public clones)
```

Start with the [first replication tutorial](docs/tutorials/first-replication.md), use [how to reproduce the results](docs/how-to-guides/reproduce-results.md) for task instructions, or browse the [documentation index](docs/README.md).

Active R scripts and generated data use descriptive `snake_case` filenames. Entry points name the task, model files name the example, and table exports include both the published table number and their contents. Raw inputs and archived material retain their source filenames for provenance.

## License and citation

The project's original code and associated documentation are available under the [MIT license](LICENSE). Third-party datasets, imported material, and dependencies retain their own licenses and terms; the MIT grant does not relicense them. The local archival staging directory is excluded from the public Git history.

When using these materials, cite Gibson and Zimmerman (2021), [doi:10.1177/26320843211061306](https://doi.org/10.1177/26320843211061306), and identify the code version or commit used. Cite Cinelli and Hazlett (2020), [doi:10.1111/rssb.12348](https://doi.org/10.1111/rssb.12348), for the underlying sensitivity method. Machine-readable metadata is in [CITATION.cff](CITATION.cff). The repository has no software DOI or published release date assigned yet.

The public [raw-input manifest](data/reference/source_manifest.csv) preserves archive-relative source locations and SHA-256 hashes without distributing the manuscript or alternate staging materials.
