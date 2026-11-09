#!/usr/bin/env Rscript
# Frozen pre-cleanup outputs, not regenerated expectations from the refactored code.
args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(script) != 1) {
  stop("Run with Rscript --vanilla tests/check_regression.R")
}
root <- dirname(dirname(normalizePath(script)))
setwd(root)
source("scripts/activate_environment.R")
source("scripts/load_modules.R")

source("tests/helpers.R")

# Isolate generated files so checking the refactor does not overwrite normal outputs.
workspace <- tempfile("replication-regression-", tmpdir = dirname(tempdir()))
dir.create(workspace)
on_failure <- function() {
  cat("Regression workspace retained at:", workspace, "\n")
}
tryCatch(
  {
    output_dir <- file.path(workspace, "outputs")
    derived_dir <- file.path(workspace, "data/derived")
    result <- run_replication(
      derived_dir = derived_dir,
      output_dir = output_dir
    )
    diagnostics <- diagnose_table2(readRDS(file.path(
      derived_dir,
      "spending_panel.rds"
    )))
    write.csv(
      diagnostics,
      file.path(output_dir, "diagnostics/spending_sensitivity_diagnostics.csv"),
      row.names = FALSE
    )

    manifest <- read.csv(
      "tests/fixtures/output_baseline_checksums.csv",
      stringsAsFactors = FALSE
    )
    for (i in seq_len(nrow(manifest))) {
      path <- file.path(workspace, manifest$path[i])
      if (!file.exists(path)) {
        stop("Missing regression output: ", manifest$path[i])
      }
      assert_identical(
        unname(tools::md5sum(path)),
        manifest$md5[i],
        manifest$path[i]
      )
    }
    for (example in c("spending", "enrollment")) {
      filename <- paste0(example, "_panel.rds")
      assert_identical(
        readRDS(file.path(derived_dir, filename)),
        readRDS(file.path(
          "tests/fixtures",
          paste0(example, "_panel_baseline.rds")
        )),
        paste(example, "full prepared panel")
      )
    }
    actual_models <- list(
      spending = lapply(result$spending$models, model_values),
      enrollment = lapply(result$enrollment$models, model_values),
      spending_bounds = result$spending$sensitivity$bounds,
      enrollment_bounds = result$enrollment$sensitivity$bounds
    )
    assert_identical(
      actual_models,
      readRDS("tests/fixtures/model_baseline.rds"),
      "Models and sensitivity bounds"
    )

    # Loading source files should define functions without running an analysis.
    definitions <- new.env(parent = globalenv())
    for (module in modules) {
      sys.source(module, envir = definitions)
    }
    stopifnot(all(vapply(as.list(definitions), is.function, logical(1))))
    cat(
      "\nExact regression checks passed:",
      nrow(manifest),
      "CSV files, both prepared panels,\n"
    )
    cat(
      "all seven models (coefficients, covariance, residuals, fitted values, samples, df),\n"
    )
    cat("both sets of sensitivity bounds, and source-only module loading.\n")
    unlink(workspace, recursive = TRUE)
  },
  error = function(error) {
    on_failure()
    stop(conditionMessage(error), call. = FALSE)
  }
)
