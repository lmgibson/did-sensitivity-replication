# Tables 3–4: annual first differences, without year indicators.
enrollment_differences <- function(
  prepared_panel,
  legacy_complete_cases = FALSE
) {
  panel <- plm::pdata.frame(
    prepared_panel[prepared_panel$Year <= 2014, ],
    index = c("State", "Year")
  )
  variables <- c("a", "lfp", "Post", "inst6017_nom")
  for (variable in variables) {
    panel[[paste0("lag.", variable)]] <- plm::lag(
      panel[[variable]],
      k = 1,
      shift = "time"
    )
  }
  # Only the archival diagnostic filters all variables before fitting any model.
  if (legacy_complete_cases) {
    panel <- panel[complete.cases(panel), ]
  }
  for (variable in variables) {
    panel[[paste0("fd.", variable)]] <- panel[[variable]] -
      panel[[paste0("lag.", variable)]]
  }
  panel
}

fit_enrollment <- function(prepared_panel) {
  panel <- enrollment_differences(prepared_panel)
  legacy_panel <- enrollment_differences(
    prepared_panel,
    legacy_complete_cases = TRUE
  )
  formulas <- list(
    fd.a ~ fd.Post,
    fd.a ~ fd.Post + fd.lfp,
    fd.a ~ fd.Post + fd.lfp + fd.inst6017_nom
  )
  # lm() selects complete cases separately for each specification.
  models <- lapply(formulas, function(formula) lm(formula, data = panel))
  rows <- lapply(seq_along(models), function(i) {
    model <- models[[i]]
    sensitivity_stats <- sensemakr::sensitivity_stats(
      model,
      treatment = "fd.Post"
    )
    data.frame(
      model = i,
      effect = coef(model)["fd.Post"],
      p_value = coef(summary(model))["fd.Post", 4],
      RV = 100 * sensitivity_stats$rv_q,
      EV = 100 * sensitivity_stats$r2yd.x,
      n = nobs(model),
      dof = df.residual(model)
    )
  })
  sensitivity <- sensemakr::sensemakr(
    models[[3]],
    treatment = "fd.Post",
    benchmark_covariates = "fd.inst6017_nom",
    kd = c(1, 2, 5, 10)
  )
  legacy <- do.call(
    rbind,
    lapply(seq_along(models), function(i) {
      model <- lm(formula(models[[i]]), data = legacy_panel)
      data.frame(
        model = i,
        n = nobs(model),
        effect = unname(coef(model)["fd.Post"])
      )
    })
  )

  list(
    panel = prepared_panel,
    differences = panel,
    models = models,
    table3 = do.call(rbind, rows),
    table4 = sensitivity$bounds,
    sensitivity = sensitivity,
    legacy = legacy
  )
}
