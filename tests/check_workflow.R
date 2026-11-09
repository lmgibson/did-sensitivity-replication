#!/usr/bin/env Rscript
# Exercise the actual targets graph in isolated inputs, outputs, and cache.
args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(script) != 1) {
  stop("Run with Rscript --vanilla tests/check_workflow.R")
}
root <- dirname(dirname(normalizePath(script)))
setwd(root)
source("scripts/activate_environment.R")
source("scripts/load_modules.R")
source("tests/helpers.R")
if (!requireNamespace("targets", quietly = TRUE)) {
  stop("Run scripts/setup_environment.R first.")
}

check_workflow <- function() {
  workspace <- tempfile("replication-workflow-", tmpdir = dirname(tempdir()))
  dir.create(file.path(workspace, "data"), recursive = TRUE)
  stopifnot(file.copy(
    "data/raw",
    file.path(workspace, "data"),
    recursive = TRUE
  ))
  reference_file <- file.path(workspace, "published_targets.csv")
  stopifnot(file.copy("data/reference/published_targets.csv", reference_file))
  settings <- c(
    DID_RAW_DIR = file.path(workspace, "data/raw"),
    DID_DERIVED_DIR = file.path(workspace, "data/derived"),
    DID_OUTPUT_DIR = file.path(workspace, "outputs"),
    DID_REFERENCE_FILE = reference_file
  )
  previous <- Sys.getenv(names(settings), unset = NA_character_)
  on.exit(
    {
      Sys.unsetenv(names(settings))
      known <- !is.na(previous)
      if (any(known)) do.call(Sys.setenv, as.list(previous[known]))
    },
    add = TRUE
  )
  do.call(Sys.setenv, as.list(settings))
  store <- file.path(workspace, "cache")
  workflow_script <- file.path(root, "_targets.R")
  make <- function() {
    targets::tar_make(
      script = workflow_script,
      store = store,
      reporter = "silent"
    )
  }
  outdated <- function() {
    targets::tar_outdated(
      script = workflow_script,
      store = store,
      reporter = "silent"
    )
  }
  metadata <- function() {
    values <- targets::tar_meta(
      fields = c("name", "time", "data"),
      targets_only = TRUE,
      store = store
    )
    as.data.frame(values[order(values$name), ])
  }
  tryCatch(
    {
      make()
      stopifnot(length(outdated()) == 0L)
      before <- metadata()
      make()
      assert_identical(
        metadata(),
        before,
        "Second run's cached target metadata"
      )

      spending <- targets::tar_read(spending_models, store = store)
      enrollment <- targets::tar_read(enrollment_models, store = store)
      diagnostics <- diagnose_table2(
        readRDS(file.path(settings[["DID_DERIVED_DIR"]], "spending_panel.rds")),
        settings[["DID_RAW_DIR"]]
      )
      write.csv(
        diagnostics,
        file.path(
          settings[["DID_OUTPUT_DIR"]],
          "diagnostics/spending_sensitivity_diagnostics.csv"
        ),
        row.names = FALSE
      )
      manifest <- read.csv(
        "tests/fixtures/output_baseline_checksums.csv",
        stringsAsFactors = FALSE
      )
      for (i in seq_len(nrow(manifest))) {
        assert_identical(
          unname(tools::md5sum(file.path(workspace, manifest$path[i]))),
          manifest$md5[i],
          manifest$path[i]
        )
      }
      for (example in c("spending", "enrollment")) {
        assert_identical(
          readRDS(file.path(
            settings[["DID_DERIVED_DIR"]],
            paste0(example, "_panel.rds")
          )),
          readRDS(file.path(
            "tests/fixtures",
            paste0(example, "_panel_baseline.rds")
          )),
          paste(example, "workflow panel")
        )
      }
      assert_identical(
        list(
          spending = lapply(spending$models, model_values),
          enrollment = lapply(enrollment$models, model_values),
          spending_bounds = spending$sensitivity$bounds,
          enrollment_bounds = enrollment$sensitivity$bounds
        ),
        readRDS("tests/fixtures/model_baseline.rds"),
        "Cached workflow models"
      )

      # Mutate only copied inputs; check which branches become stale, then restore.
      check_input_change <- function(path, expected, unaffected = character()) {
        original <- readBin(path, "raw", n = file.info(path)$size)
        on.exit(writeBin(original, path))
        writeBin(c(original, charToRaw("\n")), path)
        changed <- outdated()
        stopifnot(all(expected %in% changed), !any(unaffected %in% changed))
      }
      check_input_change(
        file.path(
          settings[["DID_RAW_DIR"]],
          "enrollment/ACS_09_1YR_B27016_with_ann.csv"
        ),
        c("enrollment_source_files", "enrollment_panel", "enrollment_models"),
        c("spending_panel", "spending_models")
      )
      check_input_change(
        file.path(settings[["DID_RAW_DIR"]], "shared/stateideology_v2018.xlsx"),
        c(
          "shared_source_files",
          "spending_panel",
          "enrollment_panel",
          "spending_models",
          "enrollment_models"
        )
      )
      check_input_change(
        reference_file,
        c("reference_file", "published_targets", "comparisons", "validation"),
        c(
          "spending_panel",
          "enrollment_panel",
          "spending_models",
          "enrollment_models"
        )
      )
      stopifnot(length(outdated()) == 0L)

      # A missing exported file is recreated without refitting either example.
      output <- file.path(
        settings[["DID_OUTPUT_DIR"]],
        "tables/table_1_spending_models.csv"
      )
      unlink(output)
      changed <- outdated()
      stopifnot(
        "analysis_files" %in% changed,
        !any(c("spending_models", "enrollment_models") %in% changed)
      )
      make()
      after <- metadata()
      models <- before$name %in% c("spending_models", "enrollment_models")
      assert_identical(
        after[models, ],
        before[models, ],
        "Models after export recreation"
      )
      assert_identical(
        unname(tools::md5sum(output)),
        manifest$md5[
          manifest$path == "outputs/tables/table_1_spending_models.csv"
        ],
        "Recreated table"
      )
      stopifnot(length(outdated()) == 0L)
      cat(
        "Workflow checks passed: exact baseline, cached second run, input/reference invalidation, and missing-output recovery.\n"
      )
      unlink(workspace, recursive = TRUE)
    },
    error = function(error) {
      cat("Workflow workspace retained at:", workspace, "\n")
      stop(conditionMessage(error), call. = FALSE)
    }
  )
}
check_workflow()
