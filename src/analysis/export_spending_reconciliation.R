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
  files <- c(
    reporting = file.path(
      output_dir,
      "tables/table_2_spending_reporting_reconstruction.csv"
    ),
    reporting_comparison = file.path(
      output_dir,
      "diagnostics/table_2_reporting_comparison.csv"
    ),
    acs_bounds = file.path(
      output_dir,
      "diagnostics/table_2_acs_sensitivity.csv"
    ),
    specifications = file.path(
      output_dir,
      "diagnostics/model_specifications.csv"
    ),
    panel_csv = file.path(derived_dir, "table_2_spending_panel.csv"),
    panel_rds = file.path(derived_dir, "table_2_spending_panel.rds"),
    sample = file.path(output_dir, "samples/spending_sensitivity_sample.csv")
  )
  write.csv(
    spending_sensitivity$reporting_table,
    files[["reporting"]],
    row.names = FALSE
  )
  write.csv(
    reporting_comparisons,
    files[["reporting_comparison"]],
    row.names = FALSE
  )
  write.csv(spending$table2, files[["acs_bounds"]], row.names = FALSE)
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
  write.csv(specifications, files[["specifications"]], row.names = FALSE)
  write.csv(spending_sensitivity$panel, files[["panel_csv"]], row.names = FALSE)
  saveRDS(spending_sensitivity$panel, files[["panel_rds"]])
  write.csv(
    model_sample(
      spending_sensitivity$model,
      spending_sensitivity$panel,
      c("state", "year", "Tr", "Post", "revenue_per_capita")
    ),
    files[["sample"]],
    row.names = FALSE
  )
  baseline_files <- export_comparisons(
    baseline_comparisons,
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
  invisible(c(unname(files), baseline_files))
}
