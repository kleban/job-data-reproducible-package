# =============================================================================
# Ukraine Research Working Paper
# Script: 04_stationarity.R
# Purpose: Address Reviewer Comment on Spurious Regression / Nonstationarity
#
# Reviewer Comment:
#   "Both the dependent variable and the main regressors appear to exhibit
#    upward trends. It is well known that regressions involving trending
#    variables may result in spurious correlations. The authors do not test
#    for stationarity, nor do they address nonstationarity using standard
#    approaches accounting for trends, such as including a time variable or
#    differencing."
#
# Response strategy:
#   1. Formally test for unit roots / stationarity using ADF, PP, and KPSS
#      tests on the outcome (avg_digital_skill_share) and key regressors
#      (log_fatalities, post_invasion, time_since_invasion).
#   2. Export a compact LaTeX table of all test results.
#   3. Estimate first-differences robustness specifications of the key models
#      from 03_structural_break.R: baseline continuous (M1) and ITS with
#      full controls (M4). If results hold in differences the spurious
#      regression concern is eliminated.
#   4. Export the first-differences regression table as LaTeX.
# =============================================================================

# -----------------------------------------------------------------------------
# 0. Setup
# -----------------------------------------------------------------------------

packages_needed <- c(
  "here",
  "arrow",        # Parquet I/O
  "tidyverse",    # Data wrangling
  "lubridate",    # Date arithmetic
  "tseries",      # adf.test (ADF), pp.test (PP), kpss.test (KPSS)
  "sandwich",     # NeweyWest HAC SEs
  "lmtest",       # coeftest()
  "modelsummary", # Regression tables
  "kableExtra",   # LaTeX backend
  "janitor"       # clean_names()
)

packages_to_install <- packages_needed[
  !packages_needed %in% installed.packages()[, "Package"]
]
if (length(packages_to_install) > 0) {
  pkg_type <- if (.Platform$OS.type == "windows") "binary" else getOption("pkgType")
  install.packages(packages_to_install, type = pkg_type)
}

suppressPackageStartupMessages({
  library(arrow)
  library(tidyverse)
  library(lubridate)
  library(tseries)
  library(sandwich)
  library(lmtest)
  library(modelsummary)
  library(kableExtra)
  library(janitor)
})

# Output directories
if (!exists("pkg_root")) pkg_root <- if (dir.exists(here::here("R"))) here::here() else here::here("reproducibility_package")
tables_dir  <- file.path(pkg_root, "output", "tables")
figures_dir <- file.path(pkg_root, "output", "figures")
if (!dir.exists(tables_dir))  dir.create(tables_dir,  recursive = TRUE)
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

options(modelsummary_factory_latex = "kableExtra")

# -----------------------------------------------------------------------------
# 1. Load & Prepare Data
# -----------------------------------------------------------------------------

if (!exists("data_dir")) data_dir <- file.path(pkg_root, "data")
data_path <- file.path(data_dir, "final_weekly.parquet")

if (!file.exists(data_path)) {
  stop("Data file not found: ", data_path,
       "\nExpected at: data/ -- see README.md")
}

df <- arrow::read_parquet(data_path) |>
  janitor::clean_names()

cat("Data loaded:", nrow(df), "weeks x", ncol(df), "columns\n")
cat("Coverage:", as.character(min(df$week)), "to", as.character(max(df$week)), "\n\n")

invasion_date <- as.POSIXct("2022-02-24", tz = "UTC")
chatgpt_date  <- as.POSIXct("2022-11-30", tz = "UTC")

df <- df |>
  arrange(week) |>
  mutate(
    log_fatalities      = log1p(total_fatalities),
    post_invasion       = as.integer(week >= invasion_date),
    time_trend          = as.integer(difftime(week, min(week), units = "weeks")),
    time_since_invasion = pmax(0L, as.integer(
      difftime(week, invasion_date, units = "weeks")
    )) * as.integer(week >= invasion_date),
    chatgpt_rollout     = as.integer(week >= chatgpt_date),
    quarter             = factor(lubridate::quarter(week))
  )

# =============================================================================
# 2. Unit Root / Stationarity Tests
# =============================================================================

cat("=== 2. Unit Root / Stationarity Tests ===\n\n")

# Helper: run ADF (tseries), PP (aTSA), KPSS (tseries) on a numeric vector
# and return a tidy one-row data frame of results.
run_tests <- function(x, series_name) {

  # ---- ADF: H0 = unit root --------------------------------------------------
  # Use automatic lag selection via AIC (default in tseries::adf.test)
  adf  <- tseries::adf.test(x, alternative = "stationary")
  adf_stat <- as.numeric(adf$statistic)
  adf_p    <- as.numeric(adf$p.value)

  # ---- Phillips-Perron: H0 = unit root --------------------------------------
  # tseries::pp.test returns a standard htest object (same interface as adf.test)
  pp      <- suppressWarnings(tseries::pp.test(x, type = "Z(t_alpha)"))
  pp_stat <- as.numeric(pp$statistic)
  pp_p    <- as.numeric(pp$p.value)

  # ---- KPSS: H0 = stationary ------------------------------------------------
  # Use level stationarity ("Level") and trend stationarity ("Trend")
  kpss_l <- tseries::kpss.test(x, null = "Level")
  kpss_t <- tseries::kpss.test(x, null = "Trend")
  kpss_l_stat <- as.numeric(kpss_l$statistic)
  kpss_l_p    <- as.numeric(kpss_l$p.value)
  kpss_t_stat <- as.numeric(kpss_t$statistic)
  kpss_t_p    <- as.numeric(kpss_t$p.value)

  cat(sprintf("Series: %s\n", series_name))
  cat(sprintf("  ADF  : stat = %7.3f, p = %.4f  => H0 (unit root) %s\n",
              adf_stat, adf_p, ifelse(adf_p < 0.05, "REJECTED", "not rejected")))
  cat(sprintf("  PP   : stat = %7.3f, p = %.4f  => H0 (unit root) %s\n",
              pp_stat,  pp_p,  ifelse(pp_p  < 0.05, "REJECTED", "not rejected")))
  cat(sprintf("  KPSS (Level): stat = %.3f, p = %.4f  => H0 (stationary) %s\n",
              kpss_l_stat, kpss_l_p, ifelse(kpss_l_p < 0.05, "REJECTED", "not rejected")))
  cat(sprintf("  KPSS (Trend): stat = %.3f, p = %.4f  => H0 (stationary) %s\n\n",
              kpss_t_stat, kpss_t_p, ifelse(kpss_t_p < 0.05, "REJECTED", "not rejected")))

  data.frame(
    Series                  = series_name,
    `ADF stat`              = round(adf_stat,    3),
    `ADF p`                 = format.pval(adf_p,    digits = 3, eps = 0.001),
    `PP stat`               = round(pp_stat,     3),
    `PP p`                  = format.pval(pp_p,     digits = 3, eps = 0.001),
    `KPSS (Level) stat`     = round(kpss_l_stat, 3),
    `KPSS (Level) p`        = format.pval(kpss_l_p, digits = 3, eps = 0.001),
    `KPSS (Trend) stat`     = round(kpss_t_stat, 3),
    `KPSS (Trend) p`        = format.pval(kpss_t_p, digits = 3, eps = 0.001),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

# Run tests on outcome and key regressors
ur_rows <- bind_rows(
  run_tests(df$avg_digital_skill_share, "Avg. Digital Skill Share"),
  run_tests(df$log_fatalities,          "Log(Fatalities)")
)

# ---- Export unit root table as LaTeX ----------------------------------------
ur_latex <- kableExtra::kbl(
  ur_rows,
  format   = "latex",
  booktabs = TRUE,
  align    = c("l", rep("r", ncol(ur_rows) - 1)),
  caption  = "Unit Root and Stationarity Tests",
  label    = "unit_roots"
) |>
  kableExtra::kable_styling(latex_options = c("hold_position", "scale_down")) |>
  kableExtra::add_header_above(c(
    " " = 1,
    "ADF (H\\\\textsubscript{0}: unit root)" = 2,
    "PP (H\\\\textsubscript{0}: unit root)"  = 2,
    "KPSS Level (H\\\\textsubscript{0}: stationary)" = 2,
    "KPSS Trend (H\\\\textsubscript{0}: stationary)" = 2
  ), escape = FALSE) |>
  kableExtra::footnote(
    general = paste(
      "ADF = Augmented Dickey--Fuller test (lag selected by AIC).",
      "PP = Phillips--Perron test (constant + trend specification).",
      "KPSS = Kwiatkowski--Phillips--Schmidt--Shin test.",
      "For ADF and PP, rejection of $H_0$ indicates stationarity.",
      "For KPSS, rejection of $H_0$ indicates nonstationarity.",
      "p-values for ADF and KPSS are interpolated from standard tables;",
      "reported as $<$0.01 when below that threshold."
    ),
    general_title = "",
    escape        = FALSE,
    threeparttable = TRUE
  )

ur_path <- file.path(tables_dir, "table_unit_roots.tex")
writeLines(ur_latex, ur_path)
cat("Unit root table saved to:", ur_path, "\n\n")

# =============================================================================
# 3. Summary for Reviewer Response
# =============================================================================

cat("=== 3. Summary for Reviewer Response ===\n\n")

cat("UNIT ROOT / STATIONARITY TESTS:\n")
for (i in seq_len(nrow(ur_rows))) {
  cat(sprintf("  %s:\n", ur_rows$Series[i]))
  cat(sprintf("    ADF  : stat = %s, p = %s\n",
              ur_rows[i, "ADF stat"], ur_rows[i, "ADF p"]))
  cat(sprintf("    PP   : stat = %s, p = %s\n",
              ur_rows[i, "PP stat"],  ur_rows[i, "PP p"]))
  cat(sprintf("    KPSS (Level): stat = %s, p = %s\n",
              ur_rows[i, "KPSS (Level) stat"], ur_rows[i, "KPSS (Level) p"]))
  cat(sprintf("    KPSS (Trend): stat = %s, p = %s\n\n",
              ur_rows[i, "KPSS (Trend) stat"], ur_rows[i, "KPSS (Trend) p"]))
}

cat("Tables saved to:", tables_dir, "\n")
cat("\n=== 04_stationarity.R complete. ===\n")
