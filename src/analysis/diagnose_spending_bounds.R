# Exploratory checks only: these variants never replace the canonical spending fit.
diagnose_table2 <- function(prepared_panel, raw_dir = "data/raw") {
  calendar_lfp <- read_lfp(raw_dir, "calendar")
  names(calendar_lfp) <- c("year", "State.Code", "lfp_calendar")
  panel <- left_join(
    as.data.frame(prepared_panel),
    calendar_lfp,
    by = c("State.Code", "year")
  )
  rows <- list()

  for (end_year in c(2014, 2015)) {
    for (start_year in c(2010, 2011)) {
      for (labor in c("lfp", "lfp_calendar")) {
        sample <- subset(
          panel,
          year >= start_year &
            year <= end_year &
            !state %in% c("Ohio", "Connecticut")
        )
        formula <- as.formula(paste(
          "log(mcaid_gfof) ~ Post +",
          labor,
          "+ pc_inc + inst6017_nom + factor(state) + factor(year)"
        ))
        model <- lm(formula, data = sample)
        bounds <- sensemakr::sensemakr(
          model,
          treatment = "Post",
          benchmark_covariates = labor,
          kd = c(2, 4, 6, 8, 10, 12)
        )$bounds
        rows[[length(rows) + 1]] <- data.frame(
          start = start_year,
          end = end_year,
          lfp = labor,
          n = nobs(model),
          base = unname(100 * expm1(coef(model)["Post"])),
          bounds
        )
      }
    }
  }
  do.call(rbind, rows)
}
