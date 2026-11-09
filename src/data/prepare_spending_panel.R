# Recovered NASBO preparation from sommers_replication_dissertation.R.
read_state_spending <- function(raw_dir) {
  panel <- readxl::read_excel(file.path(
    raw_dir,
    "spending/1991-2017 Exp Report Data - 031518.xlsx"
  ))
  names(panel) <- tolower(names(panel))
  correction <- readxl::read_excel(file.path(
    raw_dir,
    "spending/fy2017_fix.xlsx"
  ))
  names(correction) <- c("state", "mcaid_gf", "mcaid_ff", "mcaid_of")

  wyoming_1999 <- panel$state == "Wyoming" & panel$year == 1999
  panel$mcaid_gf[wyoming_1999] <- 50
  panel$mcaid_ff[wyoming_1999] <- 124
  panel$mcaid_of[wyoming_1999] <- 0
  for (column in c("mcaid_gf", "mcaid_ff", "mcaid_of")) {
    actual_2017 <- panel$year == 2017
    panel[[column]][actual_2017] <- correction[[column]][
      match(panel$state[actual_2017], correction$state)
    ]
  }
  panel <- panel[panel$state != "Puerto Rico", ]

  # Historical revenue corrections, retained even outside the fitted window.
  corrections <- data.frame(
    state = c("Nevada", "Oklahoma", "Wyoming", "North Carolina", "Virginia"),
    year = c(1999, 1999, 1999, 2003, 2003),
    revenue = c(1501, 4028, 504, 14246, 10807)
  )
  for (i in seq_len(nrow(corrections))) {
    rows <- panel$state == corrections$state[i] &
      panel$year == corrections$year[i]
    panel$`total rev`[rows] <- corrections$revenue[i]
  }
  panel$mcaid_gfof <- panel$mcaid_gf + panel$mcaid_of
  state_codes <- readxl::read_excel(file.path(
    raw_dir,
    "spending/state.codes.xlsx"
  ))
  panel <- left_join(panel, state_codes, by = "state")

  treated <- c(
    "Arizona",
    "Arkansas",
    "California",
    "Colorado",
    "Connecticut",
    "Delaware",
    "Hawaii",
    "Illinois",
    "Iowa",
    "Kentucky",
    "Maryland",
    "Massachusetts",
    "Minnesota",
    "Nevada",
    "New Jersey",
    "New Mexico",
    "New York",
    "Ohio",
    "Oregon",
    "Rhode Island",
    "Vermont",
    "Washington",
    "West Virginia",
    "Michigan",
    "New Hampshire",
    "Pennsylvania",
    "Indiana"
  )
  panel$Tr <- 0
  panel$Tr[panel$state %in% treated] <- 1
  panel$Post <- 0
  panel$Post[panel$Tr == 1 & panel$year >= 2014] <- 1
  select(
    panel,
    state,
    State.Code,
    year,
    Tr,
    Post,
    mcaid_gf,
    mcaid_ff,
    mcaid_of,
    mcaid_gfof,
    `total rev`,
    gftot_capi,
    fftot_capi,
    oftot_capi,
    bftot_capi,
    total_capi
  )
}

add_population_measures <- function(panel, raw_dir) {
  # Strip obsolete grouping metadata from the archived population object.
  population <- as.data.frame(readRDS(file.path(
    raw_dir,
    "shared/us_1969_2017_19ages_adjusted"
  )))
  names(population) <- c("State_abr", "year", "Population")
  state_names <- readxl::read_xlsx(file.path(raw_dir, "shared/state_abbr.xlsx"))
  names(state_names) <- c("state", "State_abr")
  panel <- left_join(panel, state_names, by = "state")
  panel <- left_join(panel, population, by = c("State_abr", "year"))

  for (column in c("mcaid_gf", "mcaid_ff", "mcaid_of", "mcaid_gfof")) {
    panel[[paste0(column, "_pc")]] <- (panel[[column]] * 1000000) /
      panel$Population
  }
  for (column in c("gftot_capi", "fftot_capi", "oftot_capi", "bftot_capi")) {
    panel[[column]] <- (panel[[column]] * 1000000) / panel$Population
  }
  # Compatibility: the legacy code scales these already-scaled values again.
  # state_capi is unused in the fitted models; retain its exported values.
  panel$state_capi <- ((panel$gftot_capi + panel$oftot_capi) * 1000000) /
    panel$Population
  panel$total_capi <- (panel$total_capi * 1000000) / panel$Population
  panel
}

read_unemployment <- function(raw_dir) {
  lines <- readLines(file.path(raw_dir, "shared/staadata.txt"))
  # Archived BLS text: 48-line state blocks, with 43 annual records per state.
  states <- stringr::str_trim(lines[seq(17, length(lines), by = 48)])
  starts <- seq(20, length(lines), by = 48)
  ends <- seq(62, length(lines), by = 48)
  records <- unlist(lapply(seq_along(starts), function(i) {
    lines[starts[i]:ends[i]]
  }))
  data.frame(
    state = rep(states, each = 43),
    year = as.numeric(stringr::str_sub(records, start = 1, end = 4)),
    ump_rate = as.numeric(stringr::str_sub(records, start = 98, end = 101))
  )
}

read_per_capita_income <- function(raw_dir) {
  years <- 2010:2015
  tables <- lapply(years, function(year) {
    filename <- sprintf("ACS_%02d_1YR_B19301_with_ann.csv", year %% 100)
    readr::read_csv(
      file.path(raw_dir, "spending/aff_download", filename),
      skip = 1,
      trim_ws = TRUE
    )
  })
  # Preserve archived row alignment: each year uses the first file's geography order.
  data.frame(
    state = rep(unlist(tables[[1]]$Geography), length(years)),
    year = rep(years, each = 52),
    pc_inc = unlist(lapply(tables, function(table) {
      as.numeric(unlist(table[, 4]))
    }))
  )
}

prepare_spending <- function(raw_dir = "data/raw") {
  panel <- add_population_measures(read_state_spending(raw_dir), raw_dir)
  panel <- left_join(panel, read_unemployment(raw_dir), by = c("state", "year"))
  panel <- left_join(
    panel,
    read_per_capita_income(raw_dir),
    by = c("state", "year")
  )
  for (column in c("mcaid_gf", "mcaid_gfof", "mcaid_gf_pc", "mcaid_gfof_pc")) {
    panel[[column]][panel[[column]] == 0] <- NA
  }
  panel <- left_join(panel, read_u6(raw_dir), by = c("State_abr", "year"))
  panel <- left_join(
    panel,
    read_lfp(raw_dir, "fiscal"),
    by = c("State.Code", "year")
  )
  panel <- left_join(panel, read_ideology(raw_dir), by = c("state", "year"))
  panel[panel$year >= 2010, ]
}
