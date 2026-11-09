# DESCRIPTION is the source of truth for direct runtime dependencies.
runtime_packages <- trimws(strsplit(
  read.dcf("DESCRIPTION", fields = "Imports")[[1]],
  ","
)[[1]])
workflow_packages <- c("targets", "visNetwork", "htmlwidgets")
required_packages <- setdiff(runtime_packages, workflow_packages)
