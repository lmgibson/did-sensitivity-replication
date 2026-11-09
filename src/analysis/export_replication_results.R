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

export_results <- function(
  spending,
  enrollment,
  output_dir = "outputs",
  derived_dir = "data/derived",
  spending_sensitivity = NULL
) {
  tables <- replication_tables(spending, enrollment, spending_sensitivity)
  table_files <- c(
    "table_1_spending_models.csv",
    "table_2_spending_sensitivity.csv",
    "table_3_enrollment_models.csv",
    "table_4_enrollment_sensitivity.csv"
  )
  for (i in seq_along(tables)) {
    cat("\nTABLE", i, "\n")
    print(tables[[i]])
    write.csv(
      tables[[i]],
      file.path(output_dir, "tables", table_files[i]),
      row.names = FALSE
    )
  }
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
    file.path(output_dir, "models/replication_models.rds")
  )
  write.csv(
    enrollment$legacy,
    file.path(output_dir, "diagnostics/enrollment_legacy_complete_cases.csv"),
    row.names = FALSE
  )
  write.csv(
    spending$panel,
    file.path(derived_dir, "spending_panel.csv"),
    row.names = FALSE
  )
  write.csv(
    enrollment$panel,
    file.path(derived_dir, "enrollment_panel.csv"),
    row.names = FALSE
  )
  write.csv(
    as.data.frame(enrollment$differences),
    file.path(derived_dir, "enrollment_differences.csv"),
    row.names = FALSE
  )

  for (i in seq_along(spending$models)) {
    panel <- if (i == 1) spending$panel else spending$restricted_panel
    sample <- model_sample(
      spending$models[[i]],
      panel,
      c("state", "year", "Tr", "Post")
    )
    write.csv(
      sample,
      file.path(
        output_dir,
        "samples",
        paste0("spending_model_", i, "_sample.csv")
      ),
      row.names = FALSE
    )
  }
  for (i in seq_along(enrollment$models)) {
    sample <- model_sample(
      enrollment$models[[i]],
      as.data.frame(enrollment$differences),
      c("State", "Year", "Tr", "Post")
    )
    write.csv(
      sample,
      file.path(
        output_dir,
        "samples",
        paste0("enrollment_model_", i, "_sample.csv")
      ),
      row.names = FALSE
    )
  }
  invisible(c(
    file.path(output_dir, "tables", table_files),
    file.path(output_dir, "models/replication_models.rds"),
    file.path(output_dir, "diagnostics/enrollment_legacy_complete_cases.csv"),
    file.path(
      derived_dir,
      c(
        "spending_panel.csv",
        "enrollment_panel.csv",
        "enrollment_differences.csv"
      )
    ),
    file.path(
      output_dir,
      "samples",
      paste0("spending_model_", seq_along(spending$models), "_sample.csv")
    ),
    file.path(
      output_dir,
      "samples",
      paste0("enrollment_model_", seq_along(enrollment$models), "_sample.csv")
    )
  ))
}
