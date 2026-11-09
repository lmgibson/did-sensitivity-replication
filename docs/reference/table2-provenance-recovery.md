# Table 2 provenance: recovering the revenue-per-capita construction

Investigation date: 2026-11-08. This follows the [initial reconciliation research](table-reconciliation.md). It provides a source-supported regression reconstruction, stronger than the initial curve inferred from printed targets. The reviewed revenue reconstruction is now integrated as the default Table 2 model; Table 1 retains ACS income. Historical fixtures remain unchanged.

Archive-relative manuscript and script paths below identify local recovery sources, which are not distributed. Their hashes and extracted evidence are committed; the research commands and default workflow use the committed raw inputs without needing the local archive.

## Main finding

The original archived spending code retains two different constructions of the covariate named `pc_inc`:

```r
# Earlier construction, commented in the surviving script:
d$pc_inc = (d$`total rev` * 1000000) / d$Population

# Later active construction:
# Import ACS B19301 personal income per capita and join it as pc_inc.
```

The first formula appears at line 180 of `dissertation/chp2/code/state_expenditure/code/sommers_replication.R`, followed by a comment beginning “Oops looks like they used BLS or ACS data” and the active ACS import at lines 187–201. Corresponding comments survive in the other two spending scripts. NASBO's `total rev` is in millions and the saved population is in persons. The replacement is therefore a different covariate, not a unit conversion of personal income.

Reconstructing the commented revenue-per-capita covariate on the archived analytic data, while retaining the same sample, outcome, LFP construction, ideology, state/year effects, and sensitivity settings, produces:

| Quantity | Revenue-per-capita reconstruction |
| --- | ---: |
| Original log coefficient | −0.0693138134582608 |
| Original percent effect | −6.69661644432812% |
| OLS standard error | 0.0276832266563154 |
| Original t | −2.50381988771703 |
| Observations / residual df | 288 / 231 |
| LFP partial R² with treatment | 0.00296834608282845 |
| LFP partial R² with outcome | 0.0601517411915743 |

The effect rounds to **−6.70%**, the starting effect described in the article's Table 2 discussion. All six Table 2 adjusted t-values and all six SEs match at their reported precision. This regression was calculated from archived observations and an archived formula, without optimizing its specification or parameters against publication targets.

## Manuscript lineage supports the reconstruction

Two byte-identical dissertation source backups, `dissertation/backup/main/chapter3/chapter3.tex` and `main-2/chapter3/chapter3.tex`, have a filesystem modification date of 2019-12-02. That date is a provenance clue rather than an independently authenticated publication date.

Their spending model table reports a final effect of **−6.70%**, p=.0152, EV=2.52%, RV=14.85%. Their sensitivity table already contains **all 24 numeric values of the published Table 2**, including the two questionable probabilities. The [extracted older table](../../research/reconciliation/evidence/older_dissertation_table2.csv) records source line numbers and was checked against every current published reference value.

The revenue construction also reproduces all displayed numeric values in the older model table's rows 2–4. It does not reproduce the entire older model table: row 1's effect, EV, and RV still differ, although its p-value matches. No claim is made that the entire 2019 analysis has been recovered.

The later manuscript source `submitted_papers/RMMHS/latex/sens.tex` reports **−6.58%** in its final Table 1 row but retains the older Table 2 values and −6.70% narrative. A PDF in `dissertation/publishing/p3_hsr/`, with internal creation date 2020-04-30, already shows this combination; June/July 2021 submission PDFs do too. The April 2020 sensitivity table is numbered Table 4 in that draft, whereas it is Table 2 in the published article. PDF metadata supports ordering but is not independent proof of authorship or creation time. The older source table, active/commented code, and actual regression agreement carry the substantive evidence.

Together these findings strongly support a **mixed-version explanation**: the spending-model table reflects the ACS personal-income construction, while the sensitivity table retains results compatible with the earlier revenue-per-capita construction. The archive does not contain a saved final spending model or an export operation proving exactly when the switch occurred.

## Reporting precision explains two more cells

The reconstructed model directly matches **20/24 Table 2 cells**. Two percent effects differ under direct conversion of the full-precision log estimates:

| LFP multiple | Direct percent effect, rounded | After rounding the log coefficient to 4 decimals | Printed |
| --- | ---: | ---: | ---: |
| 4× | −4.48% | −4.49% | −4.49% |
| 6× | −3.35% | −3.34% | −3.34% |

Four-decimal log coefficients are compatible with the default historical/current `sensemakr` summaries. Applying that intermediate reporting step reproduces all six displayed effects and raises agreement to **22/24 cells**. This is a plausible reporting pathway; no original table-export script establishes it.

The two remaining cells are:

| LFP multiple | Printed p | Calculated one-sided p, df 230 | Ordinary 3-decimal rounding |
| --- | ---: | ---: | ---: |
| 8× | .130 | .1292956 | .129 |
| 10× | .272 | .2728568 | .273 |

The 10× t/p pair is incompatible with ordinary nearest rounding for any positive Student-t df, as established in the initial report. Do not alter df, truncate selected values, or change test tolerances to force agreement. The displayed probabilities remain reporting discrepancies.

## Other provenance checks

- Five surviving NASBO workbook variants were read, including the 2017/2019 XLSX and macro-enabled XLSM copies. Their file hashes differ, but the state/year Medicaid general-plus-other fund spending values used in 2010–2015 are identical. Substituting those outcomes leaves all four recovered spending fits unchanged. See [the comparison](../../research/reconciliation/evidence/alternative_outcomes.csv).
- The saved spending workspaces `code/.RData` and `dissertation/chp2/code/state_expenditure/code/.RData` each load zero objects. They do not preserve a final fit. Their 512-line histories concern other spending analyses, not the missing sensitivity export.
- The larger proposal `dissertation/proposal/code/p3/.RData` contains 163 objects; the inspected fitted regressions concern simulation outcomes, not the needed Medicaid spending model.
- A bounded search of the connected personal Gmail account located a pre-submission manuscript sent to the coauthor on 2020-09-04, but no analysis code in that message. This is not an exhaustive search of any separate UCLA mailbox. No correspondence was sent, and email bodies or unrelated personal material were not copied into this repository.
- Historical package checks from the initial investigation still apply: tested released `sensemakr` formulas differ only at numerical precision. Table 3's sample adaptation and 7.69-versus-7.70 reporting discrepancy are unchanged.

## Reproduce and review

With the pinned project environment restored, run:

```sh
Rscript --vanilla research/reconciliation/recover_revenue_benchmark.R
```

The script recomputes the panel from raw inputs, substitutes only the commented covariate construction, and calls the maintained spending analysis. It writes fitted-model parameters, bounds, direct/intermediate-rounding cell comparisons, and a research fitted object under ignored `outputs/diagnostics/provenance/`. The small committed CSVs record the independent reconstruction. Three revenue snapshots are now used by regression checks for the promoted model; they do not replace the original ACS fixtures. [Source hashes](../../research/reconciliation/evidence/table_lineage_sources.csv) identify the local archive documents.

The research script passes Air and Jarl, and its results and match counts were independently recomputed by the Astra reviewer. It established the evidence subsequently used to integrate `fit_spending_sensitivity()` into the cleaned analysis. No raw data, published targets, root dependency lockfile, or frozen fixture was changed. The original ACS baseline is tested explicitly, while new reconciliation tests check the promoted revenue model against the independent evidence.

## Current integration and remaining questions

Following review, the default workflow now uses the revenue reconstruction for Table 2 and the ACS model for Table 1, with both constructions labeled in `model_specifications.csv`. The primary Table 2 comparison is 20/24; the separately exported reporting-path comparison is 22/24. The original ACS Table 2 diagnostic and its 2/24 comparison remain available and byte-exact against the original baseline.

For eventual replication materials, provide both clearly labeled constructions: the ACS model reproducing published Table 1 and the source-supported revenue model explaining Table 2. State the intermediate-rounding hypothesis and the two remaining p-value discrepancies. Do not describe all four tables as one perfectly reproduced, consistent specification.

Coauthor confirmation can now be specific: did the sensitivity table remain from the revenue-per-capita version when Table 1 was updated to ACS personal income? The surviving evidence makes that a focused provenance question rather than a request to remember an unspecified missing model. No contact has been made.
