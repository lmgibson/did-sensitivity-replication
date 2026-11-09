# Compare the paper's reported precision, independently of the recovery baseline.
compare_published_tables <- function(tables, targets) {
  rows <- lapply(seq_len(nrow(targets)), function(i) {
    target <- targets[i, ]
    observed <- as.numeric(tables[[target$table]][target$row, target$metric])
    matches <- if (target$relation == "less_than") {
      observed < target$published
    } else {
      abs(observed - target$published) <= 0.5 * 10^(-target$digits)
    }
    data.frame(
      target,
      observed = observed,
      difference = observed - target$published,
      match = matches
    )
  })
  do.call(rbind, rows)
}

validate_replication <- function(spending, enrollment, comparisons) {
  stopifnot(all(comparisons$match[comparisons$table %in% c(1, 4)]))
  stopifnot(all(
    vapply(enrollment$models, nobs, integer(1)) == c(230L, 230L, 184L)
  ))
  stopifnot(all(
    vapply(spending$models, nobs, integer(1)) == c(300L, 288L, 288L, 288L)
  ))
  stopifnot(!anyDuplicated(spending$panel[c("state", "year")]))
  stopifnot(!anyDuplicated(enrollment$panel[c("State", "Year")]))
  stopifnot(all(enrollment$panel$a >= 0 & enrollment$panel$a <= 100))

  # Independent panel estimator checks the manually constructed first differences.
  formulas <- list(a ~ Post, a ~ Post + lfp, a ~ Post + lfp + inst6017_nom)
  for (i in seq_along(enrollment$models)) {
    model <- plm::plm(
      formulas[[i]],
      data = enrollment$panel[enrollment$panel$Year <= 2014, ],
      index = c("State", "Year"),
      model = "fd"
    )
    stopifnot(
      abs(coef(model)["Post"] - coef(enrollment$models[[i]])["fd.Post"]) < 1e-9
    )
  }
  invisible(TRUE)
}

export_comparisons <- function(comparisons, output_dir = "outputs") {
  counts <- aggregate(
    match ~ table,
    data = comparisons,
    FUN = function(matches) paste(sum(matches), "/", length(matches))
  )
  write.csv(
    comparisons,
    file.path(output_dir, "diagnostics/published_table_comparison.csv"),
    row.names = FALSE
  )
  write.csv(
    counts,
    file.path(output_dir, "diagnostics/published_table_comparison_summary.csv"),
    row.names = FALSE
  )
  cat("\nMATCHES AT PUBLISHED PRECISION\n")
  print(counts)
  cat("Integrity, sample-size, and independent FD estimator checks passed.\n")
  invisible(file.path(
    output_dir,
    "diagnostics",
    c(
      "published_table_comparison.csv",
      "published_table_comparison_summary.csv"
    )
  ))
}
