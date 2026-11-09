#!/usr/bin/env Rscript
# Verify the default uncached runner against independently recovered Table 2 evidence.
args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(script) != 1) {
  stop("Run with Rscript --vanilla tests/check_reconciliation.R")
}
setwd(dirname(dirname(normalizePath(script))))
source("scripts/activate_environment.R")
source("scripts/load_modules.R")
source("tests/helpers.R")
workspace <- tempfile(
  "replication-reconciliation-",
  tmpdir = dirname(tempdir())
)
dir.create(workspace)
tryCatch(
  {
    result <- run_replication(
      output_dir = file.path(workspace, "outputs"),
      derived_dir = file.path(workspace, "data/derived")
    )
    assert_spending_reconstruction(
      workspace,
      result$spending,
      result$spending_sensitivity
    )
    original <- readRDS("tests/fixtures/model_baseline.rds")
    assert_identical(
      lapply(result$spending$models, model_values),
      original$spending,
      "Unchanged Table 1 models in the default runner"
    )
    assert_identical(
      lapply(result$enrollment$models, model_values),
      original$enrollment,
      "Unchanged enrollment models in the default runner"
    )
    cat(
      "Reconciliation checks passed: independent revenue-model evidence, 20/24 direct, 22/24 reporting, preserved panels/models, saved model and analytic data.\n"
    )
    unlink(workspace, recursive = TRUE)
  },
  error = function(error) {
    cat("Reconciliation workspace retained at:", workspace, "\n")
    stop(conditionMessage(error), call. = FALSE)
  }
)
