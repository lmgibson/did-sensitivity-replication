#!/usr/bin/env Rscript
# Launched in a fresh process by check_historical_versions.R.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
  stop('Expected package version and isolated library path.')
}
source('scripts/activate_environment.R')
version <- args[1]
if (version == '0.1.6') {
  library(sensemakr)
} else {
  library(sensemakr, lib.loc = args[2])
}
stopifnot(as.character(getNamespaceVersion('sensemakr')) == version)
out <- 'outputs/diagnostics/reconciliation'
fits <- readRDS(file.path(out, 'fits.rds'))
results <- list()
for (example in c('spending', 'enrollment')) {
  object <- fits[[example]]
  # Old releases re-evaluate the lm call when fitting treatment-on-covariates.
  # Explicit, in-scope data/formula bindings are required for those versions.
  if (example == 'spending') {
    model_data <- object$restricted_panel
    model <- lm(
      log(mcaid_gfof) ~ Post +
        lfp +
        pc_inc +
        inst6017_nom +
        state +
        year_factor,
      data = model_data
    )
    treatment <- 'Post'
    benchmark <- 'lfp'
    k <- seq(2, 12, 2)
  } else {
    model_data <- object$differences
    model <- lm(fd.a ~ fd.Post + fd.lfp + fd.inst6017_nom, data = model_data)
    treatment <- 'fd.Post'
    benchmark <- 'fd.inst6017_nom'
    k <- c(1, 2, 5, 10)
  }
  sensitivity <- sensemakr(
    model,
    treatment = treatment,
    benchmark_covariates = benchmark,
    kd = k
  )
  baseline <- object$sensitivity$bounds
  # Data-frame class/labels and CI columns changed across releases; compare the
  # five common numeric columns that determine the published bounds.
  columns <- c(
    'r2dz.x',
    'r2yz.dx',
    'adjusted_estimate',
    'adjusted_se',
    'adjusted_t'
  )
  differences <- vapply(
    columns,
    function(column) {
      max(abs(sensitivity$bounds[[column]] - baseline[[column]]))
    },
    numeric(1)
  )
  results[[example]] <- data.frame(
    version = version,
    example = example,
    metric = columns,
    max_absolute_difference_from_current = unname(differences),
    original_estimate = unname(coef(model)[treatment]),
    summary_default_digits = eval(
      formals(getS3method('summary', 'sensemakr'))$digits
    )
  )
  write.csv(
    sensitivity$bounds,
    file.path(out, 'historical', paste0(version, '_', example, '_bounds.csv')),
    row.names = FALSE
  )
  capture.output(
    summary(sensitivity),
    file = file.path(
      out,
      'historical',
      paste0(version, '_', example, '_summary.txt')
    )
  )
}
write.csv(
  do.call(rbind, results),
  file.path(out, 'historical', paste0(version, '_comparison.csv')),
  row.names = FALSE
)
