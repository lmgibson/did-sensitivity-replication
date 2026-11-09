assert_identical <- function(actual, expected, label) {
  if (!identical(actual, expected)) {
    detail <- paste(
      head(all.equal(actual, expected, tolerance = 0), 8),
      collapse = "\n"
    )
    stop(label, " differs from the pre-cleanup baseline:\n", detail)
  }
}

model_values <- function(model) {
  frame <- model.frame(model)
  # Function environments and source calls may change; all data and numbers must not.
  attr(frame, "terms") <- NULL
  list(
    coefficients = coef(model),
    covariance = vcov(model),
    residuals = residuals(model),
    fitted = fitted(model),
    model_frame = frame,
    dof = df.residual(model)
  )
}

assert_spending_reconstruction <- function(
  workspace,
  spending,
  spending_sensitivity
) {
  # Compare the promoted model against evidence from the independent archive search.
  evidence_dir <- "research/reconciliation/evidence"
  assert_identical(
    unname(tools::md5sum(file.path(
      workspace,
      "outputs/tables/table_2_spending_sensitivity.csv"
    ))),
    unname(tools::md5sum(file.path(
      evidence_dir,
      "revenue_sensitivity_bounds.csv"
    ))),
    "Revenue-based Table 2 versus independent reconstruction"
  )
  assert_identical(
    spending_sensitivity$panel[names(spending$restricted_panel)],
    spending$restricted_panel,
    "Table 2 preserves the ACS panel and adds a separate revenue covariate"
  )
  params <- read.csv(file.path(evidence_dir, "revenue_model_parameters.csv"))
  stopifnot(
    nobs(spending_sensitivity$model) == params$observations,
    df.residual(spending_sensitivity$model) == params$residual_df,
    abs(coef(spending_sensitivity$model)["Post"] - params$coefficient) < 1e-14,
    abs(
      coef(summary(spending_sensitivity$model))["Post", 2] -
        params$standard_error
    ) <
      1e-14
  )
  expected <- read.csv(file.path(evidence_dir, "revenue_table2_comparison.csv"))
  direct <- read.csv(file.path(
    workspace,
    "outputs/diagnostics/published_table_comparison.csv"
  ))
  direct <- direct[direct$table == 2, ]
  reporting <- read.csv(file.path(
    workspace,
    "outputs/diagnostics/table_2_reporting_comparison.csv"
  ))
  assert_identical(
    direct$match,
    expected$direct_match,
    "Table 2 direct comparison flags"
  )
  assert_identical(
    reporting$match,
    expected$summary4_match,
    "Table 2 reporting comparison flags"
  )
  stopifnot(
    sum(direct$match) == 20L,
    sum(reporting$match) == 22L,
    all(reporting$metric[!reporting$match] == "p_one_sided"),
    identical(reporting$row[!reporting$match], c(4L, 5L)),
    isTRUE(all.equal(
      reporting$observed,
      expected$via_summary4_log,
      tolerance = 1e-12
    ))
  )
  saved <- readRDS(file.path(
    workspace,
    "outputs/models/replication_models.rds"
  ))
  assert_identical(
    model_values(saved$table2_revenue$model),
    model_values(spending_sensitivity$model),
    "Saved revenue-based model"
  )
  assert_identical(
    saved$spending_sensitivity$bounds,
    spending_sensitivity$sensitivity$bounds,
    "Saved primary sensitivity object uses the revenue model"
  )
  assert_identical(
    saved$spending_sensitivity_acs$bounds,
    spending$sensitivity$bounds,
    "Saved ACS sensitivity diagnostic remains unchanged"
  )
  assert_identical(
    readRDS(file.path(workspace, "data/derived/table_2_spending_panel.rds")),
    spending_sensitivity$panel,
    "Exported revenue-based analytic panel"
  )
}
