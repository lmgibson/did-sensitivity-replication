# All generated files are returned explicitly so targets can track their contents.
replication_tables <- function(
  spending,
  enrollment,
  spending_sensitivity = NULL
) {
  table2 <- if (is.null(spending_sensitivity)) {
    spending$table2
  } else {
    spending_sensitivity$table2
  }
  list(spending$table1, table2, enrollment$table3, enrollment$table4)
}

model_sample <- function(model, panel, columns) {
  rows <- match(rownames(model.frame(model)), rownames(panel))
  panel[rows, columns]
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

write_csv_files <- function(data, paths) {
  stopifnot(length(data) == length(paths))
  for (i in seq_along(paths)) {
    write.csv(data[[i]], paths[i], row.names = FALSE)
  }
  unname(paths)
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

export_results <- function(
  spending,
  enrollment,
  validation,
  derived_dir = "data/derived",
  output_dir = "outputs",
  spending_sensitivity = NULL
) {
  stopifnot(isTRUE(validation))
  prepare_output_directories(derived_dir, output_dir)
  tables <- replication_tables(spending, enrollment, spending_sensitivity)
  for (i in seq_along(tables)) {
    cat("\nTABLE", i, "\n")
    print(tables[[i]])
  }
  table_files <- write_csv_files(
    tables,
    file.path(
      output_dir,
      "tables",
      c(
        "table_1_spending_models.csv",
        "table_2_spending_sensitivity.csv",
        "table_3_enrollment_models.csv",
        "table_4_enrollment_sensitivity.csv"
      )
    )
  )
  model_file <- file.path(output_dir, "models/replication_models.rds")
  saveRDS(
    list(
      spending = spending$models,
      enrollment = enrollment$models,
      enrollment_differences = enrollment$differences,
      spending_sensitivity = if (is.null(spending_sensitivity)) {
        spending$sensitivity
      } else {
        spending_sensitivity$sensitivity
      },
      spending_sensitivity_acs = spending$sensitivity,
      enrollment_sensitivity = enrollment$sensitivity,
      table2_revenue = spending_sensitivity
    ),
    model_file
  )
  legacy_file <- write_csv_files(
    list(enrollment$legacy),
    file.path(output_dir, "diagnostics/enrollment_legacy_complete_cases.csv")
  )
  panel_files <- write_csv_files(
    list(
      spending$panel,
      enrollment$panel,
      as.data.frame(enrollment$differences)
    ),
    file.path(
      derived_dir,
      c(
        "spending_panel.csv",
        "enrollment_panel.csv",
        "enrollment_differences.csv"
      )
    )
  )
  spending_samples <- lapply(seq_along(spending$models), function(i) {
    panel <- if (i == 1) spending$panel else spending$restricted_panel
    model_sample(spending$models[[i]], panel, c("state", "year", "Tr", "Post"))
  })
  enrollment_samples <- lapply(enrollment$models, function(model) {
    model_sample(
      model,
      as.data.frame(enrollment$differences),
      c("State", "Year", "Tr", "Post")
    )
  })
  sample_files <- write_csv_files(
    c(spending_samples, enrollment_samples),
    file.path(
      output_dir,
      "samples",
      c(
        paste0("spending_model_", seq_along(spending_samples), "_sample.csv"),
        paste0(
          "enrollment_model_",
          seq_along(enrollment_samples),
          "_sample.csv"
        )
      )
    )
  )
  invisible(c(table_files, model_file, legacy_file, panel_files, sample_files))
}

export_comparisons <- function(
  comparisons,
  validation,
  output_dir = "outputs",
  suffix = "",
  verbose = TRUE
) {
  stopifnot(isTRUE(validation))
  dir.create(
    file.path(output_dir, "diagnostics"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  counts <- aggregate(
    match ~ table,
    data = comparisons,
    FUN = function(matches) paste(sum(matches), "/", length(matches))
  )
  paths <- write_csv_files(
    list(comparisons, counts),
    file.path(
      output_dir,
      "diagnostics",
      c(
        paste0("published_table_comparison", suffix, ".csv"),
        paste0("published_table_comparison_summary", suffix, ".csv")
      )
    )
  )
  if (verbose) {
    cat("\nMATCHES AT PUBLISHED PRECISION\n")
    print(counts)
    cat("Integrity, sample-size, and independent FD estimator checks passed.\n")
  }
  invisible(paths)
}

# Keep the two historical covariate constructions and reporting paths explicit.
export_spending_reconciliation <- function(
  spending_sensitivity,
  spending,
  enrollment,
  targets,
  validation,
  output_dir = "outputs",
  derived_dir = "data/derived"
) {
  stopifnot(isTRUE(validation))
  prepare_output_directories(derived_dir, output_dir)
  reporting_comparisons <- compare_published_tables(
    list(NULL, spending_sensitivity$reporting_table),
    targets[targets$table == 2, ]
  )
  baseline_comparisons <- compare_published_tables(
    replication_tables(spending, enrollment),
    targets
  )
  specifications <- data.frame(
    table = c(1, 2, 3, 4),
    covariate = c(
      "ACS personal income per capita",
      "NASBO total rev times 1000000 divided by population",
      "LFP; institutional ideology in adjusted model",
      "LFP and institutional ideology"
    ),
    sensitivity_benchmark = c(
      "Not applicable",
      "Fiscal-year LFP",
      "Not applicable",
      "Institutional ideology"
    ),
    reporting = c(
      "Full precision",
      "Full precision; four-decimal log rounding exported separately",
      "Full precision; published 7.70 remains 7.69",
      "Full precision"
    )
  )
  paths <- write_csv_files(
    list(
      spending_sensitivity$reporting_table,
      reporting_comparisons,
      spending$table2,
      specifications,
      spending_sensitivity$panel,
      model_sample(
        spending_sensitivity$model,
        spending_sensitivity$panel,
        c("state", "year", "Tr", "Post", "revenue_per_capita")
      )
    ),
    c(
      file.path(
        output_dir,
        c(
          "tables/table_2_spending_reporting_reconstruction.csv",
          "diagnostics/table_2_reporting_comparison.csv",
          "diagnostics/table_2_acs_sensitivity.csv",
          "diagnostics/model_specifications.csv"
        )
      ),
      file.path(derived_dir, "table_2_spending_panel.csv"),
      file.path(output_dir, "samples/spending_sensitivity_sample.csv")
    )
  )
  panel_rds <- file.path(derived_dir, "table_2_spending_panel.rds")
  saveRDS(spending_sensitivity$panel, panel_rds)
  baseline_files <- export_comparisons(
    baseline_comparisons,
    validation,
    output_dir,
    suffix = "_acs",
    verbose = FALSE
  )
  cat(
    "Table 2 reporting reconstruction (intermediate log rounding):",
    sum(reporting_comparisons$match),
    "/",
    nrow(reporting_comparisons),
    "matches; remaining p-value discrepancies are retained.\n"
  )
  invisible(c(paths, panel_rds, baseline_files))
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
