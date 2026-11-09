# Uncached orchestration, retained for independent regression checks and debugging.
run_replication <- function(
  raw_dir = "data/raw",
  derived_dir = "data/derived",
  output_dir = "outputs",
  targets_file = "data/reference/published_targets.csv",
  table2_specification = c("revenue", "acs")
) {
  table2_specification <- match.arg(table2_specification)
  prepare_output_directories(derived_dir, output_dir)
  spending_panel <- prepare_spending(raw_dir)
  enrollment_panel <- prepare_enrollment(raw_dir)
  spending <- fit_spending(spending_panel)
  enrollment <- fit_enrollment(enrollment_panel)
  spending_sensitivity <- if (table2_specification == "revenue") {
    fit_spending_sensitivity(spending_panel)
  } else {
    NULL
  }
  published_targets <- read.csv(targets_file)
  comparisons <- compare_published_tables(
    replication_tables(spending, enrollment, spending_sensitivity),
    published_targets
  )
  validation <- validate_replication(
    spending,
    enrollment,
    comparisons,
    spending_sensitivity
  )

  write_prepared_panels(
    spending_panel,
    enrollment_panel,
    validation,
    derived_dir
  )
  analysis_files <- export_results(
    spending,
    enrollment,
    validation,
    derived_dir,
    output_dir,
    spending_sensitivity
  )
  if (!is.null(spending_sensitivity)) {
    analysis_files <- c(
      analysis_files,
      export_spending_reconciliation(
        spending_sensitivity,
        spending,
        enrollment,
        published_targets,
        validation,
        output_dir,
        derived_dir
      )
    )
  }
  comparison_files <- export_comparisons(
    comparisons,
    validation,
    output_dir
  )
  write_environment_record(analysis_files, comparison_files, output_dir)
  cat("\nDerived data:", derived_dir, "\nResults:", output_dir, "\n")
  invisible(list(
    spending = spending,
    enrollment = enrollment,
    comparisons = comparisons,
    spending_sensitivity = spending_sensitivity
  ))
}
