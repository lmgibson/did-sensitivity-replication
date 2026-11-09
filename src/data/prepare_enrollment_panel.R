# Recovered ACS B27016 construction from sens_mcaid_enroll.R.
read_enrollment_year <- function(raw_dir, year) {
  filename <- sprintf("ACS_%02d_1YR_B27016_with_ann.csv", year %% 100)
  raw <- read.csv(file.path(raw_dir, "enrollment", filename), skip = 1)
  age <- if (year < 2017) "18.to.64.years" else "19.to.64.years"
  estimates <- !grepl("Margin.of.Error", names(raw))
  adult <- grepl(age, names(raw))
  medicaid <- raw[,
    estimates & adult & grepl("Medicaid", names(raw)),
    drop = FALSE
  ]
  population <- raw[,
    estimates & grepl(paste0(age, "\\.$"), names(raw)),
    drop = FALSE
  ]

  # Preserve the original first-four-band sum and division order exactly.
  # Before 2011, band 4 includes 150–199% FPL; from 2011 it ends below 150%.
  # Correcting that historical inconsistency would change the recovery baseline.
  coverage <- (rowSums(medicaid[, 1:4]) / rowSums(population[, 1:4])) * 100
  data.frame(
    id = raw$Id2,
    State = raw$Geography,
    Year = as.numeric(year),
    a = coverage
  )
}

flag_enrollment_treatment <- function(panel) {
  treated <- c(
    "Arkansas",
    "Arizona",
    "California",
    "Colorado",
    "Connecticut",
    "Hawaii",
    "Illinois",
    "Iowa",
    "Kentucky",
    "Maryland",
    "Michigan",
    "Minnesota",
    "New Hampshire",
    "New Jersey",
    "New Mexico",
    "Nevada",
    "North Dakota",
    "Ohio",
    "Oregon",
    "Rhode Island",
    "Washington",
    "West Virginia"
  )
  controls <- c(
    "Alabama",
    "Alaska",
    "Florida",
    "Georgia",
    "Idaho",
    "Indiana",
    "Kansas",
    "Louisiana",
    "Maine",
    "Mississippi",
    "Missouri",
    "Montana",
    "Nebraska",
    "North Carolina",
    "Oklahoma",
    "Pennsylvania",
    "South Carolina",
    "South Dakota",
    "Tennessee",
    "Texas",
    "Utah",
    "Virginia",
    "Wisconsin",
    "Wyoming"
  )
  panel$Tr <- NA_real_
  panel$Tr[panel$State %in% treated] <- 1
  panel$Tr[panel$State %in% controls] <- 0
  panel$Post <- 0
  panel$Post[is.na(panel$Tr)] <- NA
  panel$Post[panel$Tr == 1 & panel$Year > 2013] <- 1
  panel[complete.cases(panel), ]
}

prepare_enrollment <- function(raw_dir = "data/raw") {
  years <- lapply(2009:2017, function(year) read_enrollment_year(raw_dir, year))
  panel <- flag_enrollment_treatment(do.call(rbind, years))
  panel <- left_join(panel, read_lfp(raw_dir, "calendar"), by = c("id", "Year"))
  ideology <- read_ideology(raw_dir)
  names(ideology)[1:2] <- c("State", "Year")
  left_join(panel, ideology, by = c("State", "Year"))
}
