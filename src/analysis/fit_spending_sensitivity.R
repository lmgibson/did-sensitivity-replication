# Table 2 uses the earlier revenue-per-capita construction retained in the archive.
# Table 1 and its original ACS-based sensitivity diagnostic remain in fit_spending().
fit_spending_sensitivity <- function(prepared_panel) {
  panel <- as.data.frame(prepared_panel)
  panel$state <- factor(panel$state)
  panel$year_factor <- factor(panel$year)
  panel <- subset(
    panel,
    year <= 2015 & !state %in% c("Ohio", "Connecticut")
  )
  panel$revenue_per_capita <- panel$`total rev` * 1000000 / panel$Population
  model <- lm(
    log(mcaid_gfof) ~ Post +
      lfp +
      revenue_per_capita +
      inst6017_nom +
      state +
      year_factor,
    data = panel
  )
  sensitivity <- sensemakr::sensemakr(
    model,
    treatment = "Post",
    benchmark_covariates = "lfp",
    kd = c(2, 4, 6, 8, 10, 12)
  )
  bounds <- sensitivity$bounds
  bounds$effect <- 100 * expm1(bounds$adjusted_estimate)
  bounds$p_one_sided <- pt(-abs(bounds$adjusted_t), df = df.residual(model) - 1)
  bounds$p_two_sided <- 2 * bounds$p_one_sided

  # Keep the supported reporting hypothesis separate from full-precision effects.
  reporting <- bounds
  reporting$adjusted_estimate_rounded_4 <- round(bounds$adjusted_estimate, 4)
  reporting$effect <- 100 * expm1(reporting$adjusted_estimate_rounded_4)
  list(
    panel = panel,
    model = model,
    sensitivity = sensitivity,
    table2 = bounds,
    reporting_table = reporting
  )
}
