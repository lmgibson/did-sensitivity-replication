# The workflow definition: load methods, then declare steps and dependencies.
source("scripts/activate_environment.R")
library(targets)
source("scripts/load_modules.R")
tar_option_set(packages = required_packages)

# Defaults reproduce the project; overrides isolate workflow tests and exports.
workflow_paths <- list(
  raw_dir = Sys.getenv("DID_RAW_DIR", "data/raw"),
  derived_dir = Sys.getenv("DID_DERIVED_DIR", "data/derived"),
  output_dir = Sys.getenv("DID_OUTPUT_DIR", "outputs"),
  reference_file = Sys.getenv(
    "DID_REFERENCE_FILE",
    "data/reference/published_targets.csv"
  )
)

list(
  # Inputs are tracked by contents, including shared covariates used by both examples.
  tar_target(
    shared_source_files,
    replication_input_files("shared", workflow_paths$raw_dir),
    format = "file"
  ),
  tar_target(
    spending_source_files,
    replication_input_files("spending", workflow_paths$raw_dir),
    format = "file"
  ),
  tar_target(
    enrollment_source_files,
    replication_input_files("enrollment", workflow_paths$raw_dir),
    format = "file"
  ),
  tar_target(reference_file, workflow_paths$reference_file, format = "file"),

  # Directory-based readers need these explicit file dependencies for invalidation.
  tar_target(spending_panel, {
    shared_source_files
    spending_source_files
    prepare_spending(workflow_paths$raw_dir)
  }),
  tar_target(enrollment_panel, {
    shared_source_files
    enrollment_source_files
    prepare_enrollment(workflow_paths$raw_dir)
  }),

  tar_target(spending_models, fit_spending(spending_panel)),
  tar_target(spending_sensitivity, fit_spending_sensitivity(spending_panel)),
  tar_target(enrollment_models, fit_enrollment(enrollment_panel)),
  tar_target(published_targets, read.csv(reference_file)),
  tar_target(
    comparisons,
    compare_published_tables(
      replication_tables(
        spending_models,
        enrollment_models,
        spending_sensitivity
      ),
      published_targets
    )
  ),
  tar_target(
    validation,
    validate_replication(
      spending_models,
      enrollment_models,
      comparisons,
      spending_sensitivity
    )
  ),

  # Exports depend on successful validation and return their paths for file tracking.
  tar_target(
    prepared_panel_files,
    write_prepared_panels(
      spending_panel,
      enrollment_panel,
      validation,
      workflow_paths$derived_dir
    ),
    format = "file"
  ),
  tar_target(
    analysis_files,
    export_results(
      spending_models,
      enrollment_models,
      validation,
      workflow_paths$derived_dir,
      workflow_paths$output_dir,
      spending_sensitivity
    ),
    format = "file"
  ),
  tar_target(
    reconciliation_files,
    export_spending_reconciliation(
      spending_sensitivity,
      spending_models,
      enrollment_models,
      published_targets,
      validation,
      workflow_paths$output_dir,
      workflow_paths$derived_dir
    ),
    format = "file"
  ),
  tar_target(
    comparison_files,
    export_comparisons(
      comparisons,
      validation,
      workflow_paths$output_dir
    ),
    format = "file"
  ),
  tar_target(
    environment_files,
    write_environment_record(
      c(analysis_files, reconciliation_files),
      comparison_files,
      workflow_paths$output_dir
    ),
    format = "file"
  )
)
