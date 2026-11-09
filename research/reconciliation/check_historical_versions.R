#!/usr/bin/env Rscript
# Downloads CRAN source archives and installs ONLY into ignored research libraries.
args <- commandArgs(trailingOnly = FALSE)
script <- sub('^--file=', '', args[grepl('^--file=', args)])
if (length(script) != 1) {
  stop('Run this file with Rscript --vanilla.')
}
setwd(dirname(dirname(dirname(normalizePath(script)))))
source('scripts/activate_environment.R')
out <- 'outputs/diagnostics/reconciliation'
if (!file.exists(file.path(out, 'fits.rds'))) {
  stop('Run research/reconciliation/run_diagnostics.R first.')
}
historical <- file.path(out, 'historical')
dir.create(historical, recursive = TRUE, showWarnings = FALSE)
versions <- c('0.1.2', '0.1.3', '0.1.4')
provenance <- list()
for (version in versions) {
  archive <- file.path(historical, paste0('sensemakr_', version, '.tar.gz'))
  url <- paste0(
    'https://cran.r-project.org/src/contrib/Archive/sensemakr/',
    basename(archive)
  )
  if (!file.exists(archive)) {
    download.file(url, archive, mode = 'wb', quiet = TRUE)
  }
  library_path <- file.path(historical, version, 'library')
  dir.create(library_path, recursive = TRUE, showWarnings = FALSE)
  library_path <- normalizePath(library_path)
  installed <- installed.packages(lib.loc = library_path)
  if (
    !'sensemakr' %in% rownames(installed) ||
      installed['sensemakr', 'Version'] != version
  ) {
    log <- file.path(historical, paste0(version, '_install.log'))
    status <- system2(
      file.path(R.home('bin'), 'R'),
      c(
        'CMD',
        'INSTALL',
        paste0('--library=', shQuote(library_path)),
        shQuote(normalizePath(archive))
      ),
      stdout = log,
      stderr = log
    )
    if (status != 0) stop('Historical install failed; see ', log)
  }
  sha <- if (nzchar(Sys.which('shasum'))) {
    sub(
      ' .*$',
      '',
      system2('shasum', c('-a', '256', shQuote(archive)), stdout = TRUE)
    )
  } else {
    NA_character_
  }
  provenance[[version]] <- data.frame(
    version = version,
    url = url,
    archive_md5 = unname(tools::md5sum(archive)),
    archive_sha256 = sha
  )
}
for (version in c(versions, '0.1.6')) {
  library_path <- if (version == '0.1.6') {
    'project'
  } else {
    normalizePath(file.path(historical, version, 'library'))
  }
  log <- file.path(historical, paste0(version, '_worker.log'))
  status <- system2(
    file.path(R.home('bin'), 'Rscript'),
    c(
      '--vanilla',
      shQuote('research/reconciliation/historical_worker.R'),
      version,
      shQuote(library_path)
    ),
    stdout = log,
    stderr = log
  )
  if (status != 0) stop('Historical calculation failed; see ', log)
}
write.csv(
  do.call(rbind, provenance),
  file.path(out, 'historical_source_manifest.csv'),
  row.names = FALSE
)
comparison <- do.call(
  rbind,
  lapply(c(versions, '0.1.6'), function(version) {
    read.csv(file.path(historical, paste0(version, '_comparison.csv')))
  })
)
write.csv(
  comparison,
  file.path(out, 'historical_version_comparison.csv'),
  row.names = FALSE
)
stopifnot(all(comparison$max_absolute_difference_from_current < 1e-12))
print(
  aggregate(
    max_absolute_difference_from_current ~ version + example,
    comparison,
    max
  ),
  row.names = FALSE
)
cat('Historical source/library artifacts remain in', historical, '\n')
cat('The root lockfile and project library were not changed.\n')
