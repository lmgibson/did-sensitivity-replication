# Shared by command-line entry points and regression checks. Run from the project root.
# DESCRIPTION is the source of truth for direct runtime dependencies.
runtime_packages <- trimws(strsplit(
  read.dcf("DESCRIPTION", fields = "Imports")[[1]],
  ","
)[[1]])
workflow_packages <- c("targets", "visNetwork", "htmlwidgets")
required_packages <- setdiff(runtime_packages, workflow_packages)
missing <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing)) {
  stop(
    "Install missing packages with Rscript --vanilla scripts/run_replication.R setup: ",
    paste(missing, collapse = ", ")
  )
}
suppressPackageStartupMessages(invisible(lapply(
  required_packages,
  library,
  character.only = TRUE
)))
options(dplyr.summarise.inform = FALSE, readr.show_col_types = FALSE)
modules <- c(
  "src/data/read_covariates.R",
  "src/data/prepare_spending_panel.R",
  "src/data/prepare_enrollment_panel.R",
  "src/analysis/fit_spending_models.R",
  "src/analysis/fit_enrollment_models.R",
  "src/output/export_results.R",
  "src/validation/validate_replication.R",
  "src/run_replication.R"
)
for (module in modules) {
  source(module, local = TRUE)
}
