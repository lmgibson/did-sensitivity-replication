#!/usr/bin/env Rscript
# Research reconstruction of the commented pre-ACS covariate in the archive.
# This does not replace the canonical personal-income specification or fixtures.
args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(script) != 1) {
  stop("Run this file with Rscript --vanilla.")
}
setwd(dirname(dirname(dirname(normalizePath(script)))))
source("scripts/activate_environment.R")
source("scripts/load_modules.R")
output_dir <- "outputs/diagnostics/provenance"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

panel <- prepare_spending("data/raw")
# Archived sommers_replication_dissertation.R:180, commented before the ACS import.
# NASBO total revenue is in millions; the saved population measure is persons.
panel$pc_inc <- panel$`total rev` * 1000000 / panel$Population
spending <- fit_spending(panel)
model <- spending$models[[4]]
bounds <- spending$table2
write.csv(
  spending$table1,
  file.path(output_dir, "revenue_spending_models.csv"),
  row.names = FALSE
)
write.csv(
  bounds,
  file.path(output_dir, "revenue_sensitivity_bounds.csv"),
  row.names = FALSE
)
saveRDS(model, file.path(output_dir, "revenue_spending_model.rds"))

published <- read.csv("data/reference/published_targets.csv")
comparison <- published[published$table == 2, ]
comparison$direct <- vapply(
  seq_len(nrow(comparison)),
  function(i) {
    bounds[[comparison$metric[i]]][comparison$row[i]]
  },
  numeric(1)
)
comparison$via_summary4_log <- comparison$direct
is_effect <- comparison$metric == "effect"
# A supported reporting hypothesis, rather than a change to fitted coefficients.
comparison$via_summary4_log[is_effect] <- 100 *
  expm1(round(
    bounds$adjusted_estimate[comparison$row[is_effect]],
    4
  ))
half_unit <- 0.5 * 10^(-comparison$digits)
comparison$direct_match <- abs(comparison$direct - comparison$published) <=
  half_unit
comparison$summary4_match <- abs(
  comparison$via_summary4_log - comparison$published
) <=
  half_unit
write.csv(
  comparison,
  file.path(output_dir, "revenue_table2_comparison.csv"),
  row.names = FALSE
)

restricted <- spending$restricted_panel
parameters <- data.frame(
  coefficient = unname(coef(model)["Post"]),
  standard_error = coef(summary(model))["Post", 2],
  t_statistic = coef(summary(model))["Post", 3],
  effect = 100 * expm1(coef(model)["Post"]),
  observations = nobs(model),
  residual_df = df.residual(model),
  lfp_r2_treatment = sensemakr::partial_r2(
    lm(
      Post ~ lfp + pc_inc + inst6017_nom + state + year_factor,
      data = restricted
    ),
    "lfp"
  ),
  lfp_r2_outcome = sensemakr::partial_r2(model, "lfp")
)
write.csv(
  parameters,
  file.path(output_dir, "revenue_model_parameters.csv"),
  row.names = FALSE
)
stopifnot(
  all(comparison$direct_match[comparison$metric == "adjusted_t"]),
  all(comparison$direct_match[comparison$metric == "adjusted_se"])
)
cat("Revenue per capita construction from commented archive code\n")
print(parameters)
cat("Table 2 direct matches:", sum(comparison$direct_match), "/ 24\n")
cat(
  "With four-decimal log intermediate:",
  sum(comparison$summary4_match),
  "/ 24\n"
)
print(comparison[!comparison$summary4_match, ])
cat("Canonical code, reference targets, and fixtures remain unchanged.\n")
