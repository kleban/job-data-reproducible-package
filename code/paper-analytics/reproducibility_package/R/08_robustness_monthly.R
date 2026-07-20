# =============================================================================
# Ukraine Research Working Paper
# Script: 08_robustness_monthly.R
# Purpose: Re-estimate main OLS models using monthly-aggregated data to address
#          reviewer concern that weekly data is too high-frequency to capture
#          firm hiring-strategy adjustments.
#
# Monthly aggregation reduces week-to-week volatility in both hiring behavior
# and attack patterns. If the relationship between invasion intensity and
# digital-skill demand persists at monthly frequency, high-frequency noise
# cannot account for the main findings.
#
# Data source: final_monthly.parquet (pre-aggregated monthly panel).
# Key variables: avg_digital_skill_share (vacancy-count-weighted mean of
#   weekly values), avg_military_skill_share, total_fatalities, num_events,
#   vacancy_count, quarter, year.
# Time indicator variables: derived directly from month-start dates.
#
# Time indicator conventions at monthly frequency:
#   post_invasion:   month >= February 2022 (invasion occurred Feb 24;
#                    February is treated as the invasion month since 24/28
#                    days fall in the post-invasion period)
#   chatgpt_rollout: month >= December 2022 (first full calendar month after
#                    the Nov 30 launch; November has ChatGPT for only 1 day)
#   ai_wave2:        month >= March 2023 (Claude 1.0, GPT-4, and Google Bard
#                    all launched in the week of March 14, 2023)
#
# Exports:
#   table_monthlyols.tex  # =============================================================================

# -----------------------------------------------------------------------------
# 0. Setup
# -----------------------------------------------------------------------------

packages_needed <- c(
  "here",
  "arrow", "tidyverse", "lubridate",
  "sandwich", "lmtest",
  "modelsummary", "kableExtra",
  "janitor"
)

packages_to_install <- packages_needed[
  !packages_needed %in% installed.packages()[, "Package"]
]
if (length(packages_to_install) > 0) {
  pkg_type <- if (.Platform$OS.type == "windows") "binary" else getOption("pkgType")
  install.packages(packages_to_install, type = pkg_type)
}

suppressPackageStartupMessages({
  library(arrow); library(tidyverse); library(lubridate)
  library(sandwich); library(lmtest)
  library(modelsummary); library(kableExtra); library(janitor)
})

if (!exists("pkg_root")) pkg_root <- if (dir.exists(here::here("R"))) here::here() else here::here("reproducibility_package")
tables_dir  <- file.path(pkg_root, "output", "tables")
figures_dir <- file.path(pkg_root, "output", "figures")
if (!dir.exists(tables_dir))  dir.create(tables_dir,  recursive = TRUE)
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

options(modelsummary_factory_latex = "kableExtra")

# Required LaTeX packages in Overleaf preamble:
#   \usepackage{booktabs}   % \toprule, \midrule, \bottomrule
#   \usepackage{siunitx}    % \num{} (used by kableExtra for all numeric cells)
#   \usepackage{graphicx}   % \resizebox
#   \usepackage{array}      % extended column specs

# HC3 SE helper # matches the weekly main table's column (1) SE choice.
hc3_se  <- function(model) coeftest(model, vcov = vcovHC(model, type = "HC3"))
hc3_vcov <- function(model) vcovHC(model, type = "HC3")

# HAC SE helper # consistent with using 4 lags for weekly data which also spans ~one quarter)
hac_se  <- function(model) coeftest(model, vcov = NeweyWest(model, lag = 3, prewhite = FALSE))
nw_vcov <- function(model) NeweyWest(model, lag = 3, prewhite = FALSE)

# -----------------------------------------------------------------------------
# 1. Load Monthly Data
# -----------------------------------------------------------------------------

if (!exists("data_dir")) data_dir <- file.path(pkg_root, "data")
data_path <- file.path(data_dir, "final_monthly.parquet")
if (!file.exists(data_path)) stop("Data file not found: ", data_path)

df_monthly <- arrow::read_parquet(data_path) |>
  janitor::clean_names() |>
  rename(month = year_month) |>
  mutate(month = as.Date(month)) |>
  arrange(month)

cat("Monthly data loaded:", nrow(df_monthly), "observations\n")
cat("Coverage:", as.character(min(df_monthly$month)), "to",
    as.character(max(df_monthly$month)), "\n\n")

# --- Derive time variables at monthly frequency ---
# Reference dates: defined directly at monthly resolution to avoid ambiguity.
invasion_month  <- as.Date("2022-02-01")   # invasion occurred Feb 24
chatgpt_month   <- as.Date("2022-12-01")   # first full calendar month after ChatGPT launch
ai_wave2_month  <- as.Date("2023-03-01")   # Claude 1.0, GPT-4, Bard (week of Mar 14 2023)

df_monthly <- df_monthly |>
  mutate(
    log_fatalities      = log1p(total_fatalities),
    log_events          = log1p(num_events),
    post_invasion       = as.integer(month >= invasion_month),
    # time_trend: months elapsed since first observation (0-indexed)
    time_trend          = as.integer(row_number() - 1L),
    # time_since_invasion: months elapsed since invasion month, 0 pre-invasion
    time_since_invasion = pmax(0L, as.integer(
      round(as.numeric(difftime(month, invasion_month, units = "days")) / 30.44)
    )) * as.integer(month >= invasion_month),
    chatgpt_rollout     = as.integer(month >= chatgpt_month),
    ai_wave2            = as.integer(month >= ai_wave2_month),
    quarter             = factor(quarter),
    year                = factor(year),
    month_of_year       = factor(lubridate::month(month))
  )

cat("Time variable summary:\n")
cat("  Months post_invasion = 1 :", sum(df_monthly$post_invasion), "\n")
cat("  Months chatgpt_rollout = 1:", sum(df_monthly$chatgpt_rollout), "\n")
cat("  Months ai_wave2 = 1      :", sum(df_monthly$ai_wave2), "\n")
cat("  log_fatalities range: [",
    round(min(df_monthly$log_fatalities), 2), ",",
    round(max(df_monthly$log_fatalities), 2), "]\n")
cat("  log_events range:     [",
    round(min(df_monthly$log_events), 2), ",",
    round(max(df_monthly$log_events), 2), "]\n")
cat("  avg_digital_skill_share range: [",
    round(min(df_monthly$avg_digital_skill_share, na.rm = TRUE), 4), ",",
    round(max(df_monthly$avg_digital_skill_share, na.rm = TRUE), 4), "]\n")
cat("  N (months):", nrow(df_monthly), "\n\n")

# =============================================================================
# 2A. Monthly OLS
# =============================================================================
# Five-column design mirrors the main weekly OLS table (tab:ols_combined):
#   (1) No FE,                HC3 SE
#   (2) Quarter FE,           HAC SE (NW, 3 lags)
#   (3) Quarter + Year FE,    HAC SE (NW, 3 lags)
#   (4) Month-of-year FE,     HAC SE (NW, 3 lags)
#   (5) Full controls + Quarter FE, HAC SE # This allows direct column-by-column comparison with the weekly results.

cat("=== 2A. Monthly OLS ===\n\n")
fat_m1 <- lm(avg_digital_skill_share ~ log_fatalities,
             data = df_monthly)

fat_m2 <- lm(avg_digital_skill_share ~ log_fatalities + quarter,
             data = df_monthly)

fat_m3 <- lm(avg_digital_skill_share ~ log_fatalities + quarter + year,
             data = df_monthly)

fat_m4 <- lm(avg_digital_skill_share ~ log_fatalities + month_of_year,
             data = df_monthly)

# Column (5): fully-controlled spec
fat_m5 <- lm(avg_digital_skill_share ~ log_fatalities + vacancy_count +
               avg_military_skill_share + time_trend +
               chatgpt_rollout + ai_wave2 + quarter,
             data = df_monthly)

# Column (5b): same as (5) but dropping time_trend
fat_m5b <- lm(avg_digital_skill_share ~ log_fatalities + vacancy_count +
                avg_military_skill_share +
                chatgpt_rollout + ai_wave2 + quarter,
              data = df_monthly)

for (i in 1:5) {
  mod <- get(paste0("fat_m", i))
  if (i == 1) {
    ct <- hc3_se(mod)
  } else {
    ct <- hac_se(mod)
  }
  cat(sprintf("  fat_M%d: coef = %+.4f  p = %.4f  R2 = %.3f  N = %d\n",
              i, ct["log_fatalities", 1], ct["log_fatalities", 4],
              summary(mod)$r.squared, nobs(mod)))
}
ct5b <- hac_se(fat_m5b)
cat(sprintf("  fat_M5b (no trend): coef = %+.4f  p = %.4f  R2 = %.3f  N = %d\n",
            ct5b["log_fatalities", 1], ct5b["log_fatalities", 4],
            summary(fat_m5b)$r.squared, nobs(fat_m5b)))
cat("\n")

# =============================================================================
# 2B. Monthly OLS
# =============================================================================
# Mirror of 2A replacing log_fatalities with log_events.
# Parallels the weekly robustness table (tab:ols_events_combined).

cat("=== 2B. Monthly OLS ===\n\n")
evt_m1 <- lm(avg_digital_skill_share ~ log_events,
             data = df_monthly)

evt_m2 <- lm(avg_digital_skill_share ~ log_events + quarter,
             data = df_monthly)

evt_m3 <- lm(avg_digital_skill_share ~ log_events + quarter + year,
             data = df_monthly)

evt_m4 <- lm(avg_digital_skill_share ~ log_events + month_of_year,
             data = df_monthly)

# Column (5): fully-controlled spec
evt_m5 <- lm(avg_digital_skill_share ~ log_events + vacancy_count +
               avg_military_skill_share + time_trend +
               chatgpt_rollout + ai_wave2 + quarter,
             data = df_monthly)

# Column (5b): same as (5) but dropping time_trend
evt_m5b <- lm(avg_digital_skill_share ~ log_events + vacancy_count +
                avg_military_skill_share +
                chatgpt_rollout + ai_wave2 + quarter,
              data = df_monthly)

for (i in 1:5) {
  mod <- get(paste0("evt_m", i))
  if (i == 1) {
    ct <- hc3_se(mod)
  } else {
    ct <- hac_se(mod)
  }
  cat(sprintf("  evt_M%d: coef = %+.4f  p = %.4f  R2 = %.3f  N = %d\n",
              i, ct["log_events", 1], ct["log_events", 4],
              summary(mod)$r.squared, nobs(mod)))
}
ct5b <- hac_se(evt_m5b)
cat(sprintf("  evt_M5b (no trend): coef = %+.4f  p = %.4f  R2 = %.3f  N = %d\n",
            ct5b["log_events", 1], ct5b["log_events", 4],
            summary(evt_m5b)$r.squared, nobs(evt_m5b)))
cat("\n")

# =============================================================================
# 3. Helper: export a 4-column monthly OLS table
# =============================================================================

export_monthly_table <- function(models, conflict_var, conflict_label,
                                  title_str, label_str, out_file) {

  coef_labels <- c(
    setNames(conflict_label, conflict_var),
    "(Intercept)" = "Intercept"
  )

  # vcov list: HC3 for column 1, HAC for columns 2-4
  vcov_list <- list(
    hc3_vcov(models[[1]]),
    nw_vcov(models[[2]]),
    nw_vcov(models[[3]]),
    nw_vcov(models[[4]])
  )

  note_text <- paste0(
    "\\textit{Dependent variable:} average digital skill share (monthly frequency, ",
    "vacancy-count-weighted mean of weekly values). ",
    conflict_label, " is log(1 + monthly sum of ACLED ",
    if (conflict_var == "log_fatalities") "fatalities" else "events", "). ",
    "Columns mirror the main weekly OLS table (Table~\\ref{tab:ols_combined}): ",
    "(1) no fixed effects, HC3 standard errors; ",
    "(2) quarter fixed effects, HAC SE (Newey-West, 3 lags); ",
    "(3) quarter and year fixed effects, HAC SE; ",
    "(4) month-of-year fixed effects (12 indicators), HAC SE. ",
    "3-lag Newey-West is the monthly analogue of the 4-lag choice in the weekly models, ",
    "both spanning approximately one quarter."
  )

  tbl_latex <- modelsummary(
    setNames(models, c("(1)", "(2)", "(3)", "(4)")),
    vcov        = vcov_list,
    coef_map    = coef_labels,
    coef_omit   = "quarter|year|month_of_year",
    gof_map     = c("nobs", "r.squared", "adj.r.squared"),
    stars       = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
    title       = title_str,
    notes       = note_text,
    output      = "latex",
    escape      = FALSE
  )

  # Add FE rows manually (analogous to the paper's main table)
  fe_block <- paste0(
    "\\midrule\n",
    "Quarter FE  & No  & Yes & Yes & No  \\\\\n",
    "Year FE     & No  & No  & Yes & No  \\\\\n",
    "Month FE    & No  & No  & No  & Yes \\\\\n"
  )
  tbl_latex <- sub(
    "(\\\\midrule[^\\\\]*\\\\\\\\\n\\s*Num\\.Obs\\.)",
    paste0(fe_block, "\\1"),
    tbl_latex
  )

  # Inject \label
  tbl_latex <- sub(
    "(\\\\caption\\{[^}]*\\})",
    paste0("\\1\n\\\\label{", label_str, "}"),
    tbl_latex
  )

  # Fix note column width (4 model cols + 1 label = 5)
  tbl_latex <- gsub(
    "\\multicolumn{5}{l}{\\rule{0pt}{1em}",
    "\\multicolumn{5}{p{16cm}}{\\footnotesize\\rule{0pt}{1em}",
    tbl_latex,
    fixed = TRUE
  )

  writeLines(tbl_latex, out_file)
  cat("Saved:", out_file, "\n")
  invisible(tbl_latex)
}

# =============================================================================
# 4. Export Tables
# =============================================================================

cat("=== 4. Exporting Monthly OLS Tables ===\n\n")

export_monthly_table(
  models        = list(fat_m1, fat_m2, fat_m3, fat_m4),
  conflict_var  = "log_fatalities",
  conflict_label = "Log(Fatalities)",
  title_str     = "Monthly Aggregation Robustness: Digital Skill Demand and Fatalities",
  label_str     = "tab:monthlyols",
  out_file      = file.path(tables_dir, "table_monthlyols.tex")
)

export_monthly_table(
  models        = list(evt_m1, evt_m2, evt_m3, evt_m4),
  conflict_var  = "log_events",
  conflict_label = "Log(Events)",
  title_str     = "Monthly Aggregation Robustness: Digital Skill Demand and Events",
  label_str     = "tab:monthlyols_events",
  out_file      = file.path(tables_dir, "table_monthlyols_events.tex")
)

# =============================================================================
# 5. Console Summary for Reviewer Response
# =============================================================================

cat("\n=== 5. Key Monthly Results ===\n\n")

cat("Log(Fatalities) results:\n\n")
se_labels <- c("(1) No FE [HC3]", "(2) Quarter FE [HAC]",
                "(3) Qtr+Year FE [HAC]", "(4) Month FE [HAC]",
                "(5) Full controls [HAC]")
for (i in 1:5) {
  mod <- get(paste0("fat_m", i))
  ct  <- if (i == 1) hc3_se(mod) else hac_se(mod)
  cat(sprintf("  %-26s coef = %+.4f  p = %.4f  N = %d\n",
              se_labels[i], ct["log_fatalities", 1], ct["log_fatalities", 4], nobs(mod)))
}

cat("\nLog(Events) results:\n\n")
for (i in 1:5) {
  mod <- get(paste0("evt_m", i))
  ct  <- if (i == 1) hc3_se(mod) else hac_se(mod)
  cat(sprintf("  %-26s coef = %+.4f  p = %.4f  N = %d\n",
              se_labels[i], ct["log_events", 1], ct["log_events", 4], nobs(mod)))
}

cat("\nTables saved to:", tables_dir, "\n")
cat("\n=== 08_robustness_monthly.R complete ===\n")
