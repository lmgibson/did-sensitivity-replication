#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(script) != 1) {
  stop("Run with Rscript --vanilla scripts/diagnose_spending_bounds.R")
}
root <- dirname(dirname(normalizePath(script)))
setwd(root)
source("scripts/activate_environment.R")
source("scripts/load_modules.R")
panel_path <- "data/derived/spending_panel.rds"
if (!file.exists(panel_path)) {
  stop("Run Rscript --vanilla scripts/run_replication.R first.")
}
diagnostics <- diagnose_table2(readRDS(panel_path))
dir.create("outputs/diagnostics", recursive = TRUE, showWarnings = FALSE)
write.csv(
  diagnostics,
  "outputs/diagnostics/spending_sensitivity_diagnostics.csv",
  row.names = FALSE
)
print(diagnostics[
  diagnostics$bound_label %in% c("2x lfp", "2x lfp_calendar"),
  c(
    "start",
    "end",
    "lfp",
    "n",
    "base",
    "adjusted_estimate",
    "adjusted_se",
    "adjusted_t"
  )
])
