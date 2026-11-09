#!/usr/bin/env Rscript
# Save an interactive graph of the same workflow used by tar_make().
args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(script) != 1) {
  stop("Run with Rscript --vanilla scripts/view_workflow.R")
}
root <- dirname(dirname(normalizePath(script)))
setwd(root)
source("scripts/activate_environment.R")
source("scripts/dependencies.R")
missing <- workflow_packages[
  !vapply(workflow_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing)) {
  stop("Install workflow dependencies with scripts/setup_environment.R")
}
path <- "outputs/diagnostics/workflow_graph.html"
dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
graph <- targets::tar_visnetwork(targets_only = TRUE)
htmlwidgets::saveWidget(graph, path, selfcontained = FALSE)
cat("Interactive workflow graph:", normalizePath(path), "\n")
