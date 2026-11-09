#!/usr/bin/env Rscript
# Resolve the repository from this file, so the command also works outside it.
args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(script) != 1) {
  stop("Run with Rscript --vanilla scripts/run_replication.R")
}
root <- dirname(dirname(normalizePath(script)))
setwd(root)
source("scripts/activate_environment.R")
if (!requireNamespace("targets", quietly = TRUE)) {
  stop(
    "Install workflow dependencies with Rscript --vanilla scripts/setup_environment.R"
  )
}
targets::tar_make()
