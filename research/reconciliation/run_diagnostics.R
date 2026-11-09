#!/usr/bin/env Rscript
# Research only: recompute the recovered models and audit printed-table arithmetic.
# Inverse fitting below describes the printed targets, not an identified source model.
args <- commandArgs(trailingOnly = FALSE)
script <- sub('^--file=', '', args[grepl('^--file=', args)])
if (length(script) != 1) {
  stop('Run this file with Rscript --vanilla.')
}
root <- dirname(dirname(dirname(normalizePath(script))))
setwd(root)
source('scripts/activate_environment.R')
source('scripts/load_modules.R')
out <- 'outputs/diagnostics/reconciliation'
dir.create(out, recursive = TRUE, showWarnings = FALSE)
write_result <- function(x, name) {
  write.csv(x, file.path(out, name), row.names = FALSE)
}

spending <- fit_spending(prepare_spending('data/raw'))
enrollment <- fit_enrollment(prepare_enrollment('data/raw'))
saveRDS(
  list(spending = spending, enrollment = enrollment),
  file.path(out, 'fits.rds')
)
write_result(spending$table1, 'recovered_spending_models.csv')
write_result(spending$table2, 'recovered_spending_bounds.csv')
write_result(enrollment$table3, 'recovered_enrollment_models.csv')
write_result(enrollment$table4, 'recovered_enrollment_bounds.csv')
write_result(enrollment$legacy, 'enrollment_legacy_complete_cases.csv')

published <- read.csv('data/reference/published_targets.csv')
target <- function(table, metric) {
  rows <- published[published$table == table & published$metric == metric, ]
  rows[order(rows$row), ]
}
ptarget <- target(2, 'p_one_sided')
ttarget <- target(2, 'adjusted_t')
etarget <- target(2, 'effect')
starget <- target(2, 'adjusted_se')
k <- seq(2, 12, 2)
dof <- df.residual(spending$models[[4]])

# Audit probabilities using the printed t values and their rounding intervals.
# For |t| > 0, a positive-df Student t has a larger tail than the normal limit.
p_audit <- data.frame(
  k = k,
  printed_t = ttarget$published,
  printed_p = ptarget$published,
  one_sided_df230 = pt(-abs(ttarget$published), dof - 1),
  two_sided_df230 = 2 * pt(-abs(ttarget$published), dof - 1),
  normal_limit = pnorm(-abs(ttarget$published)),
  minimum_possible_tail_with_t_rounding = pnorm(
    -(abs(ttarget$published) + 0.5 * 10^(-ttarget$digits))
  ),
  printed_p_interval_upper = ptarget$published + 0.5 * 10^(-ptarget$digits)
)
p_audit$rounded_one_sided <- round(p_audit$one_sided_df230, ptarget$digits)
p_audit$impossible_for_any_positive_df <-
  p_audit$minimum_possible_tail_with_t_rounding >
    p_audit$printed_p_interval_upper
write_result(p_audit, 'table2_probability_audit.csv')

# Inverse curve: beta/se, benchmark R2 with treatment, benchmark R2 with outcome.
# The residual df is ASSUMED to equal the recovered model, not identified by print.
curve <- function(parameters, dof) {
  bounds <- sensemakr::ovb_partial_r2_bound(
    r2dxj.x = parameters[2],
    r2yxj.dx = parameters[3],
    kd = k
  )
  data.frame(
    k = k,
    estimate_per_original_se = sensemakr::adjusted_estimate(
      estimate = parameters[1],
      se = 1,
      dof = dof,
      r2dz.x = bounds$r2dz.x,
      r2yz.dx = bounds$r2yz.dx
    ),
    se_per_original_se = sensemakr::adjusted_se(
      se = 1,
      dof = dof,
      r2dz.x = bounds$r2dz.x,
      r2yz.dx = bounds$r2yz.dx
    )
  )
}
fit_inverse <- function(df) {
  objective <- function(z) {
    p <- c(z[1], exp(z[2:3]))
    if (p[1] >= 0 || p[2] >= 0.02 || p[3] >= 0.07) {
      return(1e6)
    }
    predicted <- curve(p, df)
    sum(
      (predicted$estimate_per_original_se /
        predicted$se_per_original_se -
        ttarget$published)^2
    )
  }
  fit <- optim(
    c(-2.5, log(0.003), log(0.06)),
    objective,
    method = 'Nelder-Mead',
    control = list(reltol = 1e-14, maxit = 20000)
  )
  parameters <- c(fit$par[1], exp(fit$par[2:3]))
  prediction <- curve(parameters, df)
  prediction$t <- prediction$estimate_per_original_se /
    prediction$se_per_original_se
  list(fit = fit, parameters = parameters, prediction = prediction, dof = df)
}
inverse <- fit_inverse(dof)
stopifnot(inverse$fit$convergence == 0)
candidate <- inverse$prediction
candidate$printed_t <- ttarget$published
candidate$t_difference <- candidate$t - candidate$printed_t
candidate$t_matches <- abs(candidate$t_difference) <= 0.5 * 10^(-ttarget$digits)
stopifnot(all(candidate$t_matches))
write_result(candidate, 'table2_inverse_t_curve.csv')

# Derive admissible original-SE intervals; do not pick a model or edit the data.
# A summary table rounds the log coefficients to 4 decimals before copying.
# Only the finite grid of possible displayed log coefficients is enumerated here.
intervals <- lapply(seq_along(k), function(i) {
  effect_half_unit <- 0.5 * 10^(-etarget$digits[i])
  direct <- sort(
    log1p(
      (etarget$published[i] +
        c(-effect_half_unit, effect_half_unit)) /
        100
    ) /
      candidate$estimate_per_original_se[i]
  )
  grid <- seq(-0.1, 0.1, by = 0.0001)
  possible <- grid[
    abs(100 * expm1(grid) - etarget$published[i]) < effect_half_unit
  ]
  stopifnot(length(possible) == 1)
  via_summary <- sort(
    (possible + c(-0.00005, 0.00005)) /
      candidate$estimate_per_original_se[i]
  )
  se_interval <- (starget$published[i] +
    c(-0.5, 0.5) * 10^(-starget$digits[i])) /
    candidate$se_per_original_se[i]
  data.frame(
    k = k[i],
    direct_lower = direct[1],
    direct_upper = direct[2],
    via_summary4_lower = via_summary[1],
    via_summary4_upper = via_summary[2],
    se_lower = se_interval[1],
    se_upper = se_interval[2]
  )
})
intervals <- do.call(rbind, intervals)
write_result(intervals, 'table2_scale_intervals.csv')
# The paper's narrative says that the original effect was -6.70%.
narrative_interval <- sort(
  log1p(c(-6.705, -6.695) / 100) / inverse$parameters[1]
)
scale_interval <- c(
  max(intervals$via_summary4_lower, intervals$se_lower, narrative_interval[1]),
  min(intervals$via_summary4_upper, intervals$se_upper, narrative_interval[2])
)
stopifnot(diff(scale_interval) > 0)
synthetic_se <- mean(scale_interval)
synthetic_beta <- inverse$parameters[1] * synthetic_se
synthetic <- data.frame(
  k = k,
  estimate = candidate$estimate_per_original_se * synthetic_se,
  adjusted_se = candidate$se_per_original_se * synthetic_se,
  adjusted_t = candidate$t
)
synthetic$effect_direct <- 100 * expm1(synthetic$estimate)
synthetic$effect_after_summary4 <- 100 * expm1(round(synthetic$estimate, 4))
synthetic$printed_effect <- etarget$published
synthetic$effect_direct_matches <- abs(
  synthetic$effect_direct - etarget$published
) <=
  0.005
synthetic$effect_summary4_matches <- abs(
  synthetic$effect_after_summary4 - etarget$published
) <=
  0.005
synthetic$se_matches <- abs(synthetic$adjusted_se - starget$published) <=
  0.5 * 10^(-starget$digits)
synthetic$t_matches <- candidate$t_matches
synthetic$p_one_sided <- pt(-abs(synthetic$adjusted_t), dof - 1)
synthetic$printed_p <- ptarget$published
synthetic$p_matches <- abs(synthetic$p_one_sided - ptarget$published) <= 0.0005
stopifnot(all(synthetic$effect_summary4_matches), all(synthetic$se_matches))
write_result(synthetic, 'table2_synthetic_reporting_example.csv')

restricted <- spending$restricted_panel
m <- spending$models[[4]]
rD <- sensemakr::partial_r2(
  lm(
    Post ~ lfp + pc_inc + inst6017_nom + state + year_factor,
    data = restricted
  ),
  'lfp'
)
rY <- sensemakr::partial_r2(m, 'lfp')
recovered_t <- coef(summary(m))['Post', 3]
# An SE substitution changes beta/se, but cannot change the benchmark R2 curve.
se_only <- optimize(
  function(t0) {
    prediction <- curve(c(t0, rD, rY), dof)
    sum(
      (prediction$estimate_per_original_se /
        prediction$se_per_original_se -
        ttarget$published)^2
    )
  },
  interval = c(-4, -1),
  tol = 1e-13
)
se_only_curve <- curve(c(se_only$minimum, rD, rY), dof)
se_only_t <- se_only_curve$estimate_per_original_se /
  se_only_curve$se_per_original_se
write_result(
  data.frame(
    k = k,
    printed_t = ttarget$published,
    best_t_with_recovered_benchmark_R2 = se_only_t,
    difference = se_only_t - ttarget$published
  ),
  'table2_se_substitution_only.csv'
)
write_result(
  data.frame(
    source = c(
      'recovered_archived_fit',
      'inverse_printed_curve_synthetic_scale'
    ),
    dof = dof,
    coefficient = c(coef(m)['Post'], synthetic_beta),
    original_se = c(coef(summary(m))['Post', 2], synthetic_se),
    original_t = c(recovered_t, inverse$parameters[1]),
    original_effect = 100 * expm1(c(coef(m)['Post'], synthetic_beta)),
    benchmark_r2_treatment = c(rD, inverse$parameters[2]),
    benchmark_r2_outcome = c(rY, inverse$parameters[3])
  ),
  'table2_parameter_comparison.csv'
)
# Rounded tables do not uniquely identify df or a model specification.
profiles <- lapply(c(180, 230, 231, 232, 242, 288), function(df) {
  fit <- fit_inverse(df)
  data.frame(
    dof = df,
    convergence = fit$fit$convergence,
    t0 = fit$parameters[1],
    rD = fit$parameters[2],
    rY = fit$parameters[3],
    max_t_error = max(abs(fit$prediction$t - ttarget$published))
  )
})
write_result(do.call(rbind, profiles), 'table2_df_profiles.csv')

# Bounded source-supported alternatives: covariate combinations appear in the
# archived spending scripts. These are diagnostics, never replacement analyses.
controls <- c(
  'pc_inc',
  'pc_inc + ump_rate',
  'pc_inc + inst6017_nom',
  'pc_inc + inst6017_nom + citi6016',
  'pc_inc + citi6016',
  'inst6017_nom',
  '1'
)
alternatives <- lapply(controls, function(covariates) {
  formula <- as.formula(paste(
    'log(mcaid_gfof) ~ Post + lfp +',
    covariates,
    '+ state + year_factor'
  ))
  model <- lm(formula, data = restricted)
  bounds <- sensemakr::sensemakr(
    model,
    treatment = 'Post',
    benchmark_covariates = 'lfp',
    kd = k
  )$bounds
  data.frame(
    controls = covariates,
    dof = df.residual(model),
    original_effect = 100 * expm1(coef(model)['Post']),
    original_t = coef(summary(model))['Post', 3],
    t_at_2 = bounds$adjusted_t[1],
    t_at_12 = bounds$adjusted_t[6],
    max_t_error = max(abs(bounds$adjusted_t - ttarget$published))
  )
})
write_result(do.call(rbind, alternatives), 'archived_control_alternatives.csv')

# Table 3: show the rounding pathways and sample adaptation separately.
effects <- enrollment$table3$effect
write_result(
  data.frame(
    model = seq_along(effects),
    exact_effect = effects,
    printed_effect = target(3, 'effect')$published,
    directly_to_2 = round(effects, 2),
    via_3_then_2 = round(round(effects, 3), 2),
    via_default_summary4_then_2 = round(round(effects, 4), 2)
  ),
  'table3_rounding_paths.csv'
)
capture.output(
  summary(enrollment$sensitivity),
  file = file.path(out, 'enrollment_default_summary.txt')
)
capture.output(
  summary(enrollment$sensitivity, digits = 3),
  file = file.path(out, 'enrollment_summary_digits3.txt')
)
capture.output(sessionInfo(), file = file.path(out, 'session_info.txt'))
cat('Diagnostics written to', normalizePath(out), '\n')
cat('Table 2 inverse t-curve matches:', sum(candidate$t_matches), '/ 6\n')
cat(
  'Synthetic summary4 effect/SE/t/p matches:',
  sum(synthetic$effect_summary4_matches) +
    sum(synthetic$se_matches) +
    sum(synthetic$t_matches) +
    sum(synthetic$p_matches),
  '/ 24\n'
)
cat(
  'Synthetic fit is inferred from targets; it is NOT a recovered regression.\n'
)
cat(
  'Default Table 3 rounding:',
  paste(round(effects, 2), collapse = ', '),
  '\n'
)
