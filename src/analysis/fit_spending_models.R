# Tables 1–2: state/year fixed effects and LFP sensitivity bounds.
fit_spending <- function(prepared_panel) {
  panel <- as.data.frame(prepared_panel)
  panel$state <- factor(panel$state)
  panel$year_factor <- factor(panel$year)
  panel <- panel[panel$year <= 2015, ]
  restricted_panel <- subset(panel, !state %in% c("Ohio", "Connecticut"))
  formulas <- list(
    log(mcaid_gfof) ~ Post + ump_rate + pc_inc,
    log(mcaid_gfof) ~ Post + ump_rate + pc_inc,
    log(mcaid_gfof) ~ Post + lfp + pc_inc,
    log(mcaid_gfof) ~ Post + lfp + pc_inc + inst6017_nom
  )

  models <- list()
  rows <- list()
  for (i in seq_along(formulas)) {
    model_data <- if (i == 1) panel else restricted_panel
    model <- lm(
      update(formulas[[i]], . ~ . + state + year_factor),
      data = model_data
    )
    within_model <- plm::plm(
      formulas[[i]],
      data = model_data,
      index = c("state", "year"),
      model = "within",
      effect = "twoways"
    )
    clustered <- lmtest::coeftest(
      within_model,
      vcov = sandwich::vcovHC(within_model)
    )
    # Preserve Table 1's historical cluster-SE substitution. Also report OLS values.
    historical_stats <- sensemakr::sensitivity_stats(
      estimate = coef(model)["Post"],
      se = clustered["Post", 2],
      dof = df.residual(within_model)
    )
    ols_stats <- sensemakr::sensitivity_stats(model, treatment = "Post")
    models[[i]] <- model
    rows[[i]] <- data.frame(
      model = i,
      estimate = coef(model)["Post"],
      effect = 100 * expm1(coef(model)["Post"]),
      p_value = clustered["Post", 4],
      RV = 100 * historical_stats$rv_q,
      EV = 100 * historical_stats$r2yd.x,
      RV_ols = 100 * as.numeric(ols_stats$rv_q),
      EV_ols = 100 * ols_stats$r2yd.x,
      n = nobs(model),
      dof = df.residual(within_model),
      se_ols = coef(summary(model))["Post", 2],
      se_cluster = clustered["Post", 2]
    )
  }

  sensitivity <- sensemakr::sensemakr(
    models[[4]],
    treatment = "Post",
    benchmark_covariates = "lfp",
    kd = c(2, 4, 6, 8, 10, 12)
  )
  bounds <- sensitivity$bounds
  # Effects are percent changes; adjusted SE/t remain on the log-outcome scale.
  bounds$effect <- 100 * expm1(bounds$adjusted_estimate)
  bounds$p_one_sided <- pt(
    -abs(bounds$adjusted_t),
    df = df.residual(models[[4]]) - 1
  )
  bounds$p_two_sided <- 2 * bounds$p_one_sided

  list(
    panel = panel,
    restricted_panel = restricted_panel,
    models = models,
    table1 = do.call(rbind, rows),
    table2 = bounds,
    sensitivity = sensitivity
  )
}
