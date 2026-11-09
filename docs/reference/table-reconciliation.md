# Published Tables 2 and 3: reconciliation research

Research date: 2026-11-08. Baseline: `18249af`. Isolated branch: `research/reconcile-published-tables`.

The archived final spending specification still does **not** reproduce Table 2. The maintained comparison remains **2/24 cells** for Table 2 and **11/12 cells** for Table 3. This investigation identifies reporting inconsistencies and rules out the tested historical sensemakr releases as their cause. It does not recover a different final regression or change the replication baseline.

Three kinds of evidence are kept separate:

1. **Recovered calculations:** regressions on the archived inputs, using the maintained preparation and documented enrollment sample adaptation.
2. **Inverse calculations:** numerical parameters inferred from the printed Table 2 values. These describe a compatible curve, not a recovered model or dataset.
3. **Reporting hypotheses:** rounding steps that can produce particular printed cells. Compatibility does not establish what the authors actually did.

## Sources and reproduction

The targets were checked in the archived submission PDF, pages 9–11, and the [published article](https://journals.sagepub.com/doi/full/10.1177/26320843211061306). Both contain the same numbers. The article's paragraph introducing Table 2 describes an original effect of **−6.70%**, whereas its Table 1 final model reports **−6.58%**. This independent textual discrepancy is important evidence of a possible earlier or different fit.

The source scripts are the staged spending `sommers_replication_dissertation.R`, `sommers_replication.R`, `sommers_replication_v2.R`, and enrollment `sens_mcaid_enroll.R`. The [replication audit](replication-audit.md) and staging manifest document their provenance. The staged files are archival material, not proof that the exact final publication workflow survived.

Run from the repository root with the pinned R 4.5.0 environment:

```sh
Rscript --vanilla research/reconciliation/run_diagnostics.R
Rscript --vanilla research/reconciliation/check_historical_versions.R
```

The first command recomputes the maintained models from raw inputs and writes the research diagnostics under ignored `outputs/diagnostics/reconciliation/`. The second downloads the three CRAN source archives and installs each into a separate ignored research library, running each version in a fresh process. Neither command changes the root lockfile, project package installations, raw data, canonical methods, published targets, or fixtures.

The small committed [evidence snapshots](../../research/reconciliation/evidence/) preserve this run's key results. They are research outputs, not new regression-test expectations. The source-archive [manifest](../../research/reconciliation/evidence/historical_source_manifest.csv) includes URLs and SHA-256 hashes. Full intermediate objects, package libraries, source archives, and logs remain untracked.

## Table 2 has probability inconsistencies independent of the model

The printed probabilities are approximately one-sided tails, but they are not all consistent with the reported t statistics. At the recovered adjusted residual degrees of freedom, 230:

| LFP multiple | Printed t | Printed p | One-sided t tail | Two-sided t tail |
| --- | ---: | ---: | ---: | ---: |
| 2 | −2.2188 | .014 | .013739 | .027477 |
| 4 | −1.9075 | .029 | .028851 | .057702 |
| 6 | −1.5524 | .061 | .060971 | .121941 |
| 8 | −1.1325 | .130 | .129302 | .258604 |
| 10 | −.6051 | .272 | .272855 | .545709 |
| 12 | .1395 | .445 | .444589 | .889177 |

The **10× row cannot be explained by choosing another positive Student-t degrees of freedom**. Allowing the entire rounding interval for the reported absolute t, its greatest possible value is .60515. Even the normal limit gives

```text
pnorm(-0.60515) = 0.2725397 > 0.2725.
```

Every finite positive-df Student-t tail is larger. Thus the probability must round to at least .273 under ordinary nearest rounding, rather than .272. This is a reporting/arithmetic inconsistency; it does not depend on the archived regression, its standard errors, or the inverse fit.

The 8× row gives .129 rather than .130 at df 230. Other degrees of freedom can produce .130 for this row, so that finding alone is conditional on df. The 4× row's one-sided p is below .05, while its two-sided p is above .05. The article's claim that the effect is no longer significant at that point agrees with the two-sided calculation, rather than its displayed one-sided p column. See the [probability audit](../../research/reconciliation/evidence/table2_probability_audit.csv).

## The six t values describe a coherent curve, but not the recovered fit

For original coefficient `b`, standard error `s`, residual degrees of freedom `d`, and confounder bounds `RD(k)` and `RY(k)`, the bias-reducing calculations for a negative original coefficient are:

```text
b(k) = b + s * sqrt(d * RD(k) * RY(k) / (1 - RD(k)))
s(k) = s * sqrt(d / (d - 1) * (1 - RY(k)) / (1 - RD(k)))
t(k) = b(k) / s(k)
```

The benchmark bounds are the sensemakr `ovb_partial_r2_bound()` transformation of the benchmark's partial R² with treatment and outcome; they are not simply `k` times both input R² values. For fixed `d`, the t curve depends on just three quantities: `b/s`, benchmark treatment R², and benchmark outcome R².

Assuming **d = 231**, least squares against all six printed t values yields a curve that rounds to every reported t value; its maximum absolute t discrepancy is about `2.58e-5`, below the printed half-unit `5e-5`. A scale compatible with the reported SEs, the narrative −6.70% effect, and the four-decimal reporting path below gives this illustrative parameter set:

| Quantity | Recovered final archived fit | Inferred curve with compatible synthetic scale |
| --- | ---: | ---: |
| Original log coefficient | −.0681062062 | −.0693139134 |
| Original SE | .0276034610 | .0276828027 |
| Original t | −2.4673067704 | −2.5038618432 |
| Original percent effect | −6.5838745% | −6.6966258% |
| LFP partial R² with treatment | .0032016026 | .0029686229 |
| LFP partial R² with outcome | .0588544408 | .0601474564 |

The synthetic scale is the midpoint of an interval satisfying the displayed SE/effect constraints. It was **inferred from publication targets**, not estimated from observations. Its effect rounds to the article's narrative −6.70%; that agreement is a consistency check, not identification of the historical model. See the [parameter comparison](../../research/reconciliation/evidence/table2_parameter_comparison.csv).

The rounded table does not identify the model, dataset, or degrees of freedom. The [df profiles](../../research/reconciliation/evidence/table2_df_profiles.csv) also fit all six t values at their reported precision for assumed df values 180, 230, 232, 242, and 288, with different inferred benchmark associations. No such value is selected as a replacement analysis.

Changing only the treatment SE cannot reconcile the archived model's entire curve. Allowing `b/s` to vary freely while keeping its actual benchmark R² values and df gives a best least-squares fit whose maximum t error is approximately **.04273**, versus a printed half-unit of .00005. The discrepancy therefore is not explained merely by substituting the clustered treatment SE for its OLS SE in this model. See the [SE-only check](../../research/reconciliation/evidence/table2_se_substitution_only.csv).

The [bounded control-set diagnostics](../../research/reconciliation/evidence/archived_control_alternatives.csv) likewise fail to recover the t curve. They retain the 2010–2015 sample, Ohio/Connecticut exclusion, log state-fund spending outcome, and state/year effects, while checking covariate combinations appearing in the exploratory archive. These augment the existing window and calendar/fiscal-LFP checks; they are not an exhaustive search across possible data revisions or undocumented specifications.

## Intermediate rounding can explain the percent-effect pattern

Historical and current `summary.sensemakr()` use four decimal places under the usual R `options(digits = 7)`. All six percent effects are compatible with first copying those rounded log coefficients, then exponentiating and rounding the percentages to two decimal places.

For example, the synthetic curve above gives:

| Multiple | Unrounded synthetic log effect | Direct percent effect, rounded | Log effect copied at 4 decimals | Percent effect from copied value, rounded | Printed |
| --- | ---: | ---: | ---: | ---: | ---: |
| 4 | −.0458724690 | −4.48% | −.0459 | −4.49% | −4.49% |
| 6 | −.0340446709 | −3.35% | −.0340 | −3.34% | −3.34% |

At the fitted t-curve parameters, the intervals of original SE implied by directly transformed effects do not all overlap; allowing the four-decimal intermediate log values creates an overlapping interval. This is a diagnostic of that fitted curve, not a proof excluding every conceivable calculation from the rounded table.

The resulting [synthetic reporting example](../../research/reconciliation/evidence/table2_synthetic_reporting_example.csv), at **assumed df 231**, reproduces the six effect, six SE, six t, and four p cells at their displayed precision: **22/24 cells**. The .130 and .272 p cells remain inconsistent with that example. This **does not increase the archived-data replication count**, which stays 2/24. No saved original model or table-generation code establishes that this reporting pathway was used.

## Tested historical sensemakr releases do not explain the discrepancy

The [CRAN archive](https://cran.r-project.org/src/contrib/Archive/sensemakr/) contains releases 0.1.2 (2019-08-05), 0.1.3 (2020-04-28), and 0.1.4 (2021-10-08), all preceding publication. Each was tested against the recovered spending and enrollment fits under the pinned R 4.5.0 runtime, then compared with sensemakr 0.1.6.

For every tested historical version:

- The two benchmark R² bound columns and adjusted estimates equal the current values in the exercised calculations.
- Maximum absolute differences across the five common numeric bound columns are `2.22e-16` for spending and `1.78e-15` for enrollment, arising in SE/t calculations. They have no effect on any published-precision comparison.
- The default summary precision is four decimal places.

The [version comparison](../../research/reconciliation/evidence/historical_version_comparison.csv) records each metric separately. Older releases require re-evaluating an `lm` call in an environment containing its original data; the worker therefore refits the same explicit formulas and sample data before calling each package. This is environment compatibility, not a specification adjustment.

These results rule out the tested **released sensemakr calculation paths on the recovered model objects** as the source of the discrepancy. They do not reconstruct the original R runtime, unrecorded development versions, old data revisions, or unsaved session state.

## Table 3: retain the sample adaptation and the 7.69 discrepancy

The archived enrollment script filters the entire panel with `complete.cases()` before fitting its three models. That operation uses unused covariates/lags as well as model variables, leaving 184 observations in every fit. Its first two effects are 7.372039 and 7.495315, rather than the paper's 7.64 and 7.69.

The maintained recovery allows each model to select complete observations after differencing. It produces 230 observations and effects 7.6360874247 and 7.6852048516 for the first two models, reproducing their printed effects and sensitivity statistics. The adjusted model still uses 184 observations. **The adaptation remains necessary and explicit; untouched original code is not a complete reproduction.**

The adjusted effect is **7.69491959420143**. It is `0.0000804058` below the 7.695 rounding boundary. Its direct two-decimal value is 7.69, although its RV/EV and every Table 4 cell match. The [rounding diagnostic](../../research/reconciliation/evidence/table3_rounding_paths.csv) gives:

| Model | Direct to 2 decimals | R: 3 decimals then 2 | Default summary: 4 decimals then 2 | Printed |
| --- | ---: | ---: | ---: | ---: |
| Naive | 7.64 | 7.64 | 7.64 | 7.64 |
| + LFP | 7.69 | 7.68 | 7.69 | 7.69 |
| + ideology | 7.69 | 7.70 | 7.69 | 7.70 |

Three-decimal intermediate rounding can produce 7.70 for the adjusted effect. However, the default sensemakr summary produces 7.6949, which still rounds to 7.69. Applying R's three-then-two-decimal rule uniformly also changes the second row to 7.68 because of rounding at the intermediate half-unit. Manual decimal half-up rounding could behave differently, but there is no archived rounding/export operation establishing that path. A reporting or double-rounding explanation is plausible; it is not demonstrated, and an undocumented small difference in inputs remains possible.

The historical ACS income-band exception remains preserved exactly as documented in the replication audit. No population harmonization, alternative sample, or tolerance change was introduced to force agreement.

## Separate Table 4 interpretation issue

The article attributes increasing precision to a large association with treatment and a small association with outcome. The recovered Table 4 bounds show the reverse: at 1× ideology, treatment R² is .0063683 and outcome R² is .0835506; at 10× they are .0636830 and .8361483. In the SE formula above, removing outcome residual variance lowers the SE, while removing treatment residual variance raises it. Thus the reproduced numerical pattern is consistent with the larger outcome association. This is a prose interpretation issue, independent of the unresolved Table 2 source fit or Table 3 rounding.

## Review disposition and verification

Retain the canonical estimates, comparison tolerances, and unresolved statuses. The new evidence supports a narrower diagnosis: Table 2 combines a curve consistent with an original effect rounding to −6.70%, a plausible intermediate log-rounding pathway, and at least one impossible reported t/p pairing. The recovered −6.58% model does not generate that curve. Table 3 is numerically close to a rounding boundary, but the original reporting operation is unknown.

The useful next provenance target is the final Table 2 fitted object or table-generation source, including its actual sample and raw inputs. Searching arbitrary specifications solely to match the inferred parameters would not establish replication.

Both canonical checks passed in this worktree, with logs under `outputs/diagnostics/reconciliation/`: `tests/check_regression.R` and `tests/check_workflow.R`. The research scripts also completed successfully, were formatted with Air, and passed Jarl using their scoped configuration. No changes were made to canonical statistical code, raw inputs, frozen fixtures, published reference cells, root lockfile, or R-version pin.
