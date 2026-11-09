# Shared imports. Keep the archived column names at the analytic-data boundary.
read_labor_measure <- function(
  raw_dir,
  sheet,
  value_name,
  state_positions,
  columns = NULL
) {
  labor <- readxl::read_xls(
    file.path(raw_dir, "shared/state_unemployment.xls"),
    sheet = sheet
  )
  if (!is.null(columns)) {
    labor <- labor[, columns]
  }

  state_names <- names(labor)
  state_names[-1] <- substr(
    state_names[-1],
    state_positions[1],
    state_positions[2]
  )
  names(labor) <- state_names
  long <- reshape(
    as.data.frame(labor),
    idvar = "Date",
    varying = state_names[-1],
    v.names = value_name,
    times = state_names[-1],
    direction = "long"
  )
  # reshape() appends an unused generated ID; retain date, state, and measure.
  long <- long[, 1:3]
  names(long) <- c("DATE", "State", value_name)
  long
}

read_lfp <- function(raw_dir, period = c("calendar", "fiscal")) {
  period <- match.arg(period)
  labor <- read_labor_measure(
    raw_dir,
    sheet = 2,
    value_name = "lfp",
    state_positions = c(6, 7)
  )
  labor$State <- as.numeric(labor$State)
  labor$Year <- as.numeric(format(labor$DATE, "%Y"))

  if (period == "calendar") {
    annual <- labor %>%
      group_by(State, Year) %>%
      summarise(lfp = mean(lfp), .groups = "drop") %>%
      select(Year, State, lfp)
    names(annual) <- c("Year", "id", "lfp")
    return(annual)
  }

  # Spending uses equal-weight quarterly means, then fiscal-year means.
  labor$Quarter <- quarters(labor$DATE)
  labor$FiscalYear <- labor$Year
  later_half <- labor$Quarter %in% c("Q3", "Q4")
  labor$FiscalYear[later_half] <- labor$Year[later_half] + 1
  annual <- labor %>%
    group_by(State, Year, Quarter) %>%
    summarise(
      FiscalYear = mean(FiscalYear),
      lfp = mean(lfp),
      .groups = "drop"
    ) %>%
    group_by(State, FiscalYear) %>%
    summarise(lfp = mean(lfp), .groups = "drop") %>%
    select(State, FiscalYear, lfp)
  names(annual) <- c("State.Code", "year", "lfp")
  annual
}

read_u6 <- function(raw_dir) {
  labor <- read_labor_measure(
    raw_dir,
    sheet = 3,
    value_name = "U6",
    state_positions = c(8, 9),
    columns = c(1, 21:51)
  )
  labor$Year <- as.numeric(format(labor$DATE, "%Y"))
  annual <- labor %>%
    group_by(State, Year) %>%
    summarise(U6 = mean(U6), .groups = "drop") %>%
    select(Year, State, U6) %>%
    filter(Year > 2003)
  names(annual) <- c("year", "State_abr", "U6")
  annual
}

read_ideology <- function(raw_dir) {
  ideology <- readxl::read_xlsx(
    file.path(raw_dir, "shared/stateideology_v2018.xlsx"),
    col_names = FALSE
  )
  names(ideology) <- c(
    "state",
    "State.Code",
    "year",
    "citi6016",
    "inst6017_nom"
  )
  ideology <- ideology[ideology$year >= 2010, ]
  # The workbook only supplies names on some rows; recover them by state code.
  state_names <- unique(ideology[
    !is.na(ideology$state),
    c("state", "State.Code")
  ])
  ideology <- ideology[, c("State.Code", "year", "inst6017_nom", "citi6016")]
  ideology <- left_join(ideology, state_names, by = "State.Code")
  ideology[, c("state", "year", "inst6017_nom", "citi6016")]
}

# File boundaries for targets: return every input/output path explicitly.
replication_input_files <- function(example, raw_dir = "data/raw") {
  paths <- switch(
    example,
    shared = c(
      "shared/state_unemployment.xls",
      "shared/stateideology_v2018.xlsx"
    ),
    spending = c(
      "spending/1991-2017 Exp Report Data - 031518.xlsx",
      "spending/fy2017_fix.xlsx",
      "spending/state.codes.xlsx",
      sprintf("spending/aff_download/ACS_%02d_1YR_B19301_with_ann.csv", 10:15),
      "shared/us_1969_2017_19ages_adjusted",
      "shared/state_abbr.xlsx",
      "shared/staadata.txt"
    ),
    enrollment = sprintf("enrollment/ACS_%02d_1YR_B27016_with_ann.csv", 9:17),
    stop("Unknown input group: ", example)
  )
  file.path(raw_dir, paths)
}
