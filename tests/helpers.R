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
