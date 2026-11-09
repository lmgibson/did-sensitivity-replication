# Entry points call this explicitly because --vanilla skips .Rprofile.
local({
  expected <- trimws(readLines(".R-version", warn = FALSE))
  actual <- as.character(getRversion())
  if (!identical(actual, expected)) {
    stop(
      "This replication requires R ",
      expected,
      "; running R ",
      actual,
      ". Install the specified R version before restoring packages.",
      call. = FALSE
    )
  }
  source("renv/activate.R")
})
