# Uncached orchestration, retained for independent regression checks and debugging.
run_replication <- function(
  raw_dir = "data/raw",
  derived_dir = "data/derived",
  output_dir = "outputs",
  targets_file = "data/reference/published_targets.csv"
) {
  prepare_output_directories(derived_dir, output_dir)
  spending_panel <- prepare_spending(raw_dir)
  enrollment_panel <- prepare_enrollment(raw_dir)
  spending <- fit_spending(spending_panel)
  enrollment <- fit_enrollment(enrollment_panel)
  comparisons <- compare_published_tables(
    replication_tables(spending, enrollment),
    read.csv(targets_file)
  )
  validation <- validate_replication(spending, enrollment, comparisons)

  write_prepared_panels(
    spending_panel,
    enrollment_panel,
    validation,
    derived_dir
  )
  analysis_files <- write_analysis_outputs(
    spending,
    enrollment,
    validation,
    derived_dir,
    output_dir
  )
  comparison_files <- write_comparison_outputs(
    comparisons,
    validation,
    output_dir
  )
  write_environment_record(analysis_files, comparison_files, output_dir)
  cat("\nDerived data:", derived_dir, "\nResults:", output_dir, "\n")
  invisible(list(
    spending = spending,
    enrollment = enrollment,
    comparisons = comparisons
  ))
}
