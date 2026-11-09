# File boundaries for targets: return every input/output path explicitly.
replication_input_files <- function(example, raw_dir = "data/raw") {
  paths <- switch(
    example,
    shared = c(
      "shared/state_unemployment.xls",
      "shared/stateideology_v2018.xlsx"
    ),
    spending = c(
      "spending/1991-2017 Exp Report Data - 031518.xlsx",
      "spending/fy2017_fix.xlsx",
      "spending/state.codes.xlsx",
      sprintf("spending/aff_download/ACS_%02d_1YR_B19301_with_ann.csv", 10:15),
      "shared/us_1969_2017_19ages_adjusted",
      "shared/state_abbr.xlsx",
      "shared/staadata.txt"
    ),
    enrollment = sprintf("enrollment/ACS_%02d_1YR_B27016_with_ann.csv", 9:17),
    stop("Unknown input group: ", example)
  )
  file.path(raw_dir, paths)
}

prepare_output_directories <- function(derived_dir, output_dir) {
  dir.create(derived_dir, recursive = TRUE, showWarnings = FALSE)
  for (directory in c(
    "tables",
    "diagnostics",
    "models",
    "samples",
    "environment"
  )) {
    dir.create(
      file.path(output_dir, directory),
      recursive = TRUE,
      showWarnings = FALSE
    )
  }
}

write_prepared_panels <- function(
  spending_panel,
  enrollment_panel,
  validation,
  derived_dir = "data/derived"
) {
  stopifnot(isTRUE(validation))
  dir.create(derived_dir, recursive = TRUE, showWarnings = FALSE)
  paths <- file.path(
    derived_dir,
    c("spending_panel.rds", "enrollment_panel.rds")
  )
  saveRDS(spending_panel, paths[1])
  saveRDS(enrollment_panel, paths[2])
  paths
}

write_analysis_outputs <- function(
  spending,
  enrollment,
  validation,
  derived_dir = "data/derived",
  output_dir = "outputs",
  spending_sensitivity = NULL
) {
  stopifnot(isTRUE(validation))
  prepare_output_directories(derived_dir, output_dir)
  export_results(
    spending,
    enrollment,
    output_dir,
    derived_dir,
    spending_sensitivity
  )
}

write_comparison_outputs <- function(
  comparisons,
  validation,
  output_dir = "outputs"
) {
  stopifnot(isTRUE(validation))
  dir.create(
    file.path(output_dir, "diagnostics"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  export_comparisons(comparisons, output_dir)
}

write_environment_record <- function(
  analysis_files,
  comparison_files,
  output_dir = "outputs"
) {
  stopifnot(all(file.exists(c(analysis_files, comparison_files))))
  dir.create(
    file.path(output_dir, "environment"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  paths <- file.path(
    output_dir,
    "environment",
    c("session_info.txt", "package_versions.csv")
  )
  capture.output(sessionInfo(), file = paths[1])
  packages <- as.data.frame(installed.packages()[, c("Package", "Version")])
  write.csv(packages, paths[2], row.names = FALSE)
  paths
}
