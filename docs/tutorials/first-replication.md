# Run your first replication

This tutorial walks through the recovered spending and enrollment examples. You will generate the analytic datasets, inspect agreement with the published tables, and see how the workflow fits together.

## Get the project ready

Install R **4.5.0**, the version used for the exact baseline checks, and Git. Then clone the public repository:

```sh
git clone https://github.com/lmgibson/did-sensitivity-replication.git
cd did-sensitivity-replication
Rscript --vanilla scripts/run_replication.R setup
```

Setup restores pinned R packages with renv. It does not install R itself. The primary inputs are included; no local staging archive, manuscript files, or PUMS microdata are needed. Compiled packages may require additional system libraries on another operating system. See the [reproduction guide](../how-to-guides/reproduce-results.md) if setup needs attention.

## Generate the analysis

```sh
Rscript --vanilla scripts/run_replication.R
```

The workflow prepares both panels, fits the models, validates results, and exports tables and datasets. Spending Table 1 uses ACS personal income per capita. Table 2 uses the earlier NASBO revenue-per-capita construction recovered from the archive. Enrollment Tables 3–4 use first differences.

The normal comparison summary should show:

| Table | Matches at reported precision |
| --- | --- |
| 1 | 16 / 16 |
| 2, full precision | 20 / 24 |
| 3 | 11 / 12 |
| 4 | 12 / 12 |

These counts describe agreement with the paper, not whether the code ran successfully. The separately exported Table 2 reporting reconstruction matches 22/24 cells after intermediate log rounding. Two p-values remain inconsistent; the adjusted Table 3 effect is 7.6949, which rounds to 7.69 rather than the printed 7.70. The [audit](../reference/replication-audit.md) explains the preserved sample adaptation, ACS income-band change, and other limitations.

## Inspect the generated files

Open these local CSVs after the run:

- `outputs/diagnostics/published_table_comparison_summary.csv`: the counts above.
- `outputs/diagnostics/published_table_comparison.csv`: every published target and its direct comparison.
- `outputs/diagnostics/table_2_reporting_comparison.csv`: the separate 22/24 comparison.
- `outputs/diagnostics/model_specifications.csv`: covariate and reporting labels for each table.

Full tables are under `outputs/tables/`, analytic panels under `data/derived/`, and sample memberships under `outputs/samples/`. These are generated files, not links available in the public repository. See the [output inventory](../../outputs/README.md) for saved models and other results.

## See the workflow and its cache

```sh
Rscript --vanilla scripts/run_replication.R graph
```

Open `outputs/diagnostics/workflow_graph.html` locally. It contains the actual 17-target dependency graph; keep its companion asset directory beside it. The [workflow explanation](../explanation/workflow.md) provides a readable Mermaid overview and explains the spending branches.

Run the analysis command again. With inputs, code, packages, and outputs unchanged, current targets are skipped. This is how targets avoids repeating completed work.

## Verify the results

```sh
Rscript --vanilla scripts/run_replication.R check
```

The numerical suite checks the original ACS baseline and the promoted revenue reconstruction. The separate workflow suite checks caching, file tracking, and output recovery in isolation. The checks preserve the documented discrepancies rather than replacing expectations to force a complete match.

For the source-supported Table 2 explanation, continue with [the provenance report](../reference/table2-provenance-recovery.md). For optional forensic scripts, use the [research guide](../../research/reconciliation/README.md).
