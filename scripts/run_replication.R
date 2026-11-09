#!/usr/bin/env Rscript
# One entry point for replication, environment setup, inspection, and checks.
args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(script) != 1) {
  stop("Run this file with Rscript --vanilla.")
}
setwd(dirname(dirname(normalizePath(script))))
commands <- commandArgs(trailingOnly = TRUE)
usage <- "Usage: Rscript --vanilla scripts/run_replication.R [run|setup|graph|check|diagnose]"
if (length(commands) > 1) {
  stop(usage, call. = FALSE)
}
command <- if (length(commands)) commands[1] else "run"
if (command %in% c("help", "--help", "-h")) {
  cat(usage, "\n")
  quit(status = 0)
}
if (!command %in% c("run", "setup", "graph", "check", "diagnose")) {
  stop(usage, call. = FALSE)
}
source("scripts/activate_environment.R")

if (command == "setup") {
  renv::restore(prompt = FALSE)
  renv::status()
} else if (command == "check") {
  for (test in c("tests/check_regression.R", "tests/check_workflow.R")) {
    status <- system2(
      file.path(R.home("bin"), "Rscript"),
      c("--vanilla", shQuote(test))
    )
    if (status != 0) quit(status = status)
  }
} else if (command %in% c("run", "graph")) {
  packages <- if (command == "run") {
    "targets"
  } else {
    c("targets", "visNetwork", "htmlwidgets")
  }
  missing <- packages[
    !vapply(packages, requireNamespace, logical(1), quietly = TRUE)
  ]
  if (length(missing)) {
    stop("Run setup first: ", usage, call. = FALSE)
  }
  if (command == "run") {
    targets::tar_make()
  } else {
    path <- "outputs/diagnostics/workflow_graph.html"
    dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
    graph <- targets::tar_visnetwork(targets_only = TRUE)
    htmlwidgets::saveWidget(graph, path, selfcontained = FALSE)
    cat("Interactive workflow graph:", normalizePath(path), "\n")
  }
} else {
  source("scripts/load_modules.R")
  source("research/reconciliation/diagnose_spending_bounds.R")
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
}
