# Replication checks

Run all checks from the repository root, or invoke the command script by absolute path:

```sh
Rscript --vanilla scripts/run_replication.R check
```

The command runs the numerical and workflow suites in separate fresh R processes. The suites can also be run individually.

## Numerical regression

```sh
Rscript --vanilla tests/check_regression.R
```

This one suite checks two deliberately distinct contracts in temporary output directories:

- The original ACS recovery baseline: 18 CSV checksums, both full prepared panels, all seven original models' coefficients/covariance/residuals/fitted values/model frames/df, both sensitivity-bound objects, and source-only module loading. It includes the original exploratory diagnostics.
- The default revenue reconstruction: byte-identical Table 2 output against independent research evidence, its model parameters/sample/df, preserved ACS panel plus the separate revenue field, 20/24 direct and 22/24 reporting comparison flags, saved model/data exports, and unchanged original seven models.

The original baseline fixtures were captured on 2026-11-08 before the readability refactor. They intentionally retain the original ACS Table 2 discrepancy and the Table 3 effect discrepancy. They are not overwritten to accept the later source-supported revenue reconstruction; that model is checked against independently recorded archival evidence under `research/reconciliation/evidence/`.

`fixtures/output_baseline_checksums.csv` records SHA-256 provenance hashes and MD5 equality checks. MD5 is used for deterministic file equality, without a cryptographic security claim. Model fixtures exclude source calls and environment-bearing metadata; every checked numerical value and sample must remain identical. The published targets remain a separate reference.

Tests never regenerate fixtures or overwrite normal analysis outputs. Successful runs remove temporary workspaces. Failed runs retain the workspace and report its path for inspection.

## Cached workflow integration

```sh
Rscript --vanilla tests/check_workflow.R
```

This suite runs `_targets.R` with copied raw/reference inputs and its own cache/output directory. It verifies the original numerical baseline through explicitly labeled ACS diagnostic exports and the promoted revenue model against independent evidence. It also checks:

- Cached second runs preserve target metadata.
- Enrollment/shared/reference changes invalidate the appropriate branches.
- Deleting an analysis table or reporting export recreates it without refitting models.

`helpers.R` contains shared assertions; it is not a third test entry point. The uncached numerical runner remains independent of workflow caching.
