# Replication audit

Recovery date: 2026-11-08.

The original recovery used a local `graduate_school/` archive. Paths to original manuscripts and scripts in this audit are relative to that archive unless stated otherwise. The archive and `staging/` are not distributed or required to run the analysis. Primary input copies are committed in `data/raw/`. Public raw-input source locations and checksums are recorded in [the source manifest](../../data/reference/source_manifest.csv); the complete local staging manifest is not distributed. The originals have not been moved or edited.

The numeric targets in [published_targets.csv](../../data/reference/published_targets.csv) were transcribed from Tables 1–4 of the archived manuscript, `submitted_papers/LG-FZ-Sensitivity-Diff-in-Diff.pdf`, and checked against the [published article](https://journals.sagepub.com/doi/full/10.1177/26320843211061306). The archived PDF is a submission manuscript, not the publisher's typeset edition. Its four tables agree with the publisher's displayed tables.

## Current status

| Table | Matches at published precision | Finding |
| --- | --- | --- |
| 1: spending models | 16 / 16 | Effect, p-value, RV, and EV match for every row. |
| 2: spending sensitivity bounds | 20 / 24 direct; 22 / 24 with intermediate log rounding | Recovered revenue-per-capita specification; two p-values remain inconsistent. |
| 3: enrollment models | 11 / 12 | All p-value thresholds, RVs, EVs, and the first two effects match. Fully adjusted effect is 7.6949196, versus printed 7.70. |
| 4: enrollment sensitivity bounds | 12 / 12 | All adjusted estimates, SEs, and t-values match. |

Matching is evaluated against each cell's reported precision (half a unit of its last reported decimal), or its stated p-value threshold. Full-precision estimates, differences, and pass/fail flags are generated locally in `outputs/diagnostics/published_table_comparison.csv`; the separate reporting comparison is `outputs/diagnostics/table_2_reporting_comparison.csv`. A mismatch is retained, not rounded or calibrated away.

## Spending example: recovered specification

Preparation was recovered from `dissertation/chp2/code/state_expenditure/code/sommers_replication.R`. Two later scripts under `code/` were also examined in the local archive. Their corresponding data files are byte-identical to the staged dissertation inputs where compared.

- NASBO input: `1991-2017 Exp Report Data - 031518.xlsx`. This filename is not proof of its download date. The archive contains a FY2017 actual-spending correction, which does not affect the 2010–2015 estimation window.
- Outcome: `log(mcaid_gfof)`, where `mcaid_gfof = mcaid_gf + mcaid_of`: general fund plus other state funds, excluding federal funds. The reported effect is `100 * (exp(coefficient) - 1)`.
- Window: 2010–2015; state and year fixed effects.
- A fixed list of 27 expansion states is treated from 2014 onward. The recovered code does not use state-specific fiscal-year expansion dates. Exact state/year assignments are exported in the model sample files.
- Model 1 includes unemployment and per-capita income, despite the published row label “No controls.” Model 2 retains these controls but excludes Ohio and Connecticut. Model 3 substitutes fiscal-year LFP for unemployment. Model 4 adds institutional ideology (`inst6017_nom`).
- Per-capita income comes from ACS B19301 files for 2010–2015. Fiscal-year LFP is calculated from the archived labor spreadsheet by assigning Q3/Q4 to the following fiscal year, averaging within quarters and then within fiscal year.
- Ideology comes from `stateideology_v2018.xlsx`; the archived related code identifies [Richard Fording's state ideology data](https://rcfording.wordpress.com/state-ideology-data/) as its source. The fitted covariate is institutional ideology, not the citizen ideology column.
- Model 1 has 300 observations; subsequent models have 288. Residual degrees of freedom are 242, 232, 232, and 231.

### Standard errors and sensitivity metrics

The exact Table 1 reproduction uses `plm`'s within estimator, `effect = "twoways"`, `vcovHC()` defaults (HC0, clustered by group), and `coeftest()` p-values. The RV/EV calculations use those cluster-adjusted SEs with the panel model's residual degrees of freedom, following the historical numeric sensitivity calls.

The ordinary OLS SEs are also exported. They are **not** interchangeable: in model 1, the cluster SE is 0.03658855 and the OLS SE is 0.03017269. `RV_ols` and `EV_ols` provide an explicit alternative calculated from the conventional regression geometry. Reproducing the published cluster-SE-based statistics does not establish that substituting a cluster SE into the OLS sensitivity formula is methodologically justified.

### Recovered Table 2 specification

The default Table 2 analysis now uses a separate revenue-per-capita fit: `NASBO total rev * 1000000 / Population`. This formula survives as a commented earlier construction of `pc_inc`, immediately before the archived script switches to ACS personal income. Table 1 continues to use the later ACS construction. The Table 2 fit otherwise follows the fully adjusted Table 1 model: 2010–2015 window, state/year effects, LFP and institutional ideology, and the Ohio/Connecticut exclusion. The recovered Table 2 model has 288 observations, 231 residual df, and an original effect of −6.6966164%, which rounds to the older −6.70%.

This is a source-supported regression on archived observations. It matches all six published SEs and all six t-values. The default full-precision comparison matches 20/24 cells. A separately exported reporting hypothesis rounds adjusted log estimates to four decimals before percentage conversion, recovering two more effect cells (22/24). It does not alter the primary full-precision estimates.

The remaining p-values are .1292956 versus printed .130 at 8× LFP, and .2728568 versus printed .272 at 10×. The latter printed t/p pair is incompatible with ordinary nearest rounding for any positive Student-t df. Displayed probabilities are largely one-sided, while the discussion of significance appears to use two-sided probabilities. Both probability conventions remain exported.

The older dissertation manuscript has a −6.70% final model and the same 24 Table 2 cells; later drafts update Table 1 to −6.58% but retain the sensitivity table. See the [provenance recovery](table2-provenance-recovery.md) and [initial numerical investigation](table-reconciliation.md). The final historical session and table-export operation were not recovered, so the exact reporting pathway remains a hypothesis.

The original ACS-based sensitivity call still yields t-values −2.163534 and 0.351357 at 2×/12× LFP and only 2/24 matches. It is preserved as an explicitly labeled diagnostic, together with the original comparison outputs. The original seven models, panels, and 18-file regression contract remain tested without changing any fixtures.

## Enrollment example: recovered specification

Preparation comes from `dissertation/chp3/code/sens_mcaid_enroll.R`.

- The archive contains ACS **published aggregate tables**, B27016, for 2009–2017. This recovered workflow does not require ACS PUMS microdata.
- The analyzed outcome is the percentage with Medicaid coverage among adults below 150% of the poverty threshold. The code selects adult 18–64 cells in the analysis years. The import function switches to ages 19–64 in 2017, outside the fitted window.
- Historical income-band exception: the archived code sums the first four bands in every year. In 2009–2010, band 4 covers 150–199% FPL, so those years actually include adults below 200% FPL. From 2011, a new 100–137% band means the first four bands end below 150%. The cleanup preserves this construction exactly; it does not silently harmonize the income population. The 2011 first difference therefore crosses the band-definition change. This is a preserved methodological limitation of the recovered construction; it should be considered when interpreting the public materials.
- The code defines 22 treated and 24 control states, and removes unassigned geographies. Treated states are assigned `Post = 1` beginning in 2014; other rows are zero. The exact flags are exported with the analytic panel and model samples.
- Published analyses use annual first differences ending in 2010–2014 for the naive and LFP models (230 observations), and 2011–2014 for the ideology-adjusted model (184 observations). The latter loses a year because ideology is only joined from 2010 onward, and differencing requires the prior year's value.
- Models include an intercept but **no year indicators** in the main first-difference specifications. LFP is aggregated to calendar year, unlike the spending example's fiscal-year construction.
- State institutional ideology is `inst6017_nom`. In Table 4, this is the benchmark, despite the table caption referring to LFP.

### Missing-data recovery decision

The archived script applies `complete.cases()` to the whole panel, including all covariates and their lags, before fitting any model. Taken literally, this gives 184 observations in every model, with naive/LFP effects of 7.372039 and 7.495315. Those do not match the paper.

The working recovery constructs differences on the panel before allowing each formula to select its own complete observations. This recovers the published naive/LFP estimates and all corresponding RVs/EVs. It leaves the fully adjusted fit and every Table 4 value unchanged. The legacy results are saved in `enrollment_legacy_complete_cases.csv` so this substantive adaptation is explicit.

The fully adjusted effect is 7.6949196, which rounds directly to 7.69, not the published 7.70. Its RV/EV and Table 4 match, so the 7.70 entry is a possible reporting or double-rounding discrepancy; the archival evidence does not establish the cause.

## Verification and next work

The readability refactor on 2026-11-08 replaced session-dependent scripts with functions taking explicit inputs, extracted shared covariate imports, and removed unused intermediate outcomes and commented exploratory code. `Rscript --vanilla tests/check_regression.R` verifies the pre-cleanup baseline independently: 18 CSVs, both full prepared panels, all seven models' numerical results and samples, and both sets of sensitivity bounds must remain exactly equal. The existing paper discrepancies and historical data transformations remain unchanged. See `tests/README.md` for fixture provenance and comparison scope.

The 2026-11-08 reorganization was checked against a saved pre-move baseline: 18 CSV outputs and both derived RDS panels were byte-identical, and all seven models retained identical coefficients, covariance matrices, and model frames. The entry point ran successfully from outside the repository. All 63 imported files retained their manifest checksums. A local `outputs/diagnostics/reorganization_check.csv` recorded that check during recovery; it is not distributed or regenerated by the current workflow. The public source manifest covers the 31 committed raw inputs.

Run `Rscript --vanilla scripts/run_replication.R` from a clean session. The run verifies unique state/year keys, valid enrollment percentages, recovered sample sizes, and agreement between independently constructed first-difference OLS estimates and `plm(model = "fd")`. Table 1 and Table 4 comparisons, and all Table 2 SE/t comparisons, are required to pass. The run also reports remaining mismatches explicitly.

The source checksums and fresh-session run establish a usable recovery baseline. The public repository is labeled a recovered replication with documented discrepancies, not a claim of complete agreement with the paper. Active code now lives in `src/`, primary inputs in `data/raw/`, and generated results in `outputs/`. Explain the mixed Table 1/2 covariate constructions and remaining p-values, and review the Table 1 SE interpretation and Table 3 effect entry before preparing materials for the requester.
