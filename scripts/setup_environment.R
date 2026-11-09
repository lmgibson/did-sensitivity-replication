#!/usr/bin/env Rscript
# Restore the exact package versions recorded for the replication.
args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(script) != 1) {
  stop("Run with Rscript --vanilla scripts/setup_environment.R")
}
root <- dirname(dirname(normalizePath(script)))
setwd(root)
source("scripts/activate_environment.R")
renv::restore(prompt = FALSE)
renv::status()
