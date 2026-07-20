# =============================================================================
# Ukraine Research Working Paper
# Script: 02_baseline_regression.R
# Purpose: Estimate main OLS specifications at weekly frequency for
#          Log(Fatalities) and Log(Events), producing Tables 2 and 3
#          in the paper (tab:ols_combined and tab:ols_events_combined).
#
# Six-column design:
#   (1) No FE,                          HC3 SE
#   (2) Quarter FE,                     HAC SE (NW, 4 lags)
#   (3) Quarter + Year FE,              HAC SE (NW, 4 lags)
#   (4) Month-of-year FE,               HAC SE (NW, 4 lags)
#   (5) Partial controls (no military), HAC SE (NW, 4 lags)
#   (6) Full controls (with military),  HAC SE (NW, 4 lags)
#
# Exports:
#   table_ols_combined.tex        #   table_ols_events_combined.tex # =============================================================================

# -----------------------------------------------------------------------------
# 0. Setup
# -----------------------------------------------------------------------------

packages_needed <- c(
  "here",
  "arrow", "tidyverse", "lubridate",
  "sandwich", "lmtest",
  "modelsummary", "kableExtra",
  "janitor", "readxl"
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

if (!exists("pkg_root")) pkg_root <- if (dir.exists(here::here("R"))) here::here() else here::here("code", "paper-analytics", "reproducibility_package")
tables_dir  <- file.path(pkg_root, "output", "tables")
figures_dir <- file.path(pkg_root, "output", "figures")
if (!dir.exists(tables_dir))  dir.create(tables_dir,  recursive = TRUE)
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

options(modelsummary_factory_latex = "kableExtra")

# SE helpers
hc3_vcov <- function(model) vcovHC(model, type = "HC3")
hc3_se   <- function(model) coeftest(model, vcov = hc3_vcov(model))
nw_vcov  <- function(model) NeweyWest(model, lag = 4, prewhite = FALSE)
hac_se   <- function(model) coeftest(model, vcov = nw_vcov(model))

# -----------------------------------------------------------------------------
# 1. Load & Prepare Data
# -----------------------------------------------------------------------------

if (!exists("data_dir")) data_dir <- file.path(pkg_root, "data")
data_path <- file.path(data_dir, "final_weekly.parquet")
if (!file.exists(data_path)) stop("Data file not found: ", data_path)

df <- arrow::read_parquet(data_path) |>
  janitor::clean_names() |>
  arrange(week) |>
  mutate(
    # Conflict variables
    log_fatalities  = log1p(total_fatalities),
    log_events      = log1p(num_events),
    # Fixed effect factors
    quarter         = factor(lubridate::quarter(week)),
    year            = factor(lubridate::year(week)),
    month_of_year   = factor(lubridate::month(week)),
    # Control dummies
    chatgpt_rollout = as.integer(week >= as.POSIXct("2022-11-30", tz = "UTC")),
    ai_wave2        = as.integer(week >= as.POSIXct("2023-03-14", tz = "UTC"))
  )

cat("Data loaded:", nrow(df), "weeks\n")
cat("Coverage:", as.character(min(df$week)), "to", as.character(max(df$week)), "\n\n")

# -----------------------------------------------------------------------------
# 1b. Load and merge energy infrastructure controls
# -----------------------------------------------------------------------------

# Hourly outage data (energy-map.info): starts Jan 2023; pre-2023 set to 0
outage_path <- file.path(data_dir, "2025_10_14_electricity_outages.xlsx")
if (!file.exists(outage_path)) stop("Outage file not found: ", outage_path)
outage_raw <- readxl::read_excel(outage_path)
names(outage_raw) <- c("date", "hour_slot", "outage_yn", "num_queues")
outage_weekly <- outage_raw |>
  mutate(
    date   = as.Date(date),
    week   = lubridate::floor_date(date, unit = "week", week_start = 1),
    outage = as.integer(outage_yn == "\u0442\u0430\u043a")
  ) |>
  group_by(week) |>
  summarise(outage_hours = sum(outage, na.rm = TRUE), .groups = "drop") |>
  mutate(week = as.POSIXct(week, tz = "UTC"))

# MinEnergo combat-action disconnections: starts March 2022; pre-war set to 0
minenergo_path <- file.path(data_dir, "2025_10_14_elektro_boiovi_dii_ukraina_minenergo.xlsx")
if (!file.exists(minenergo_path)) stop("MinEnergo file not found: ", minenergo_path)
minenergo_raw <- readxl::read_excel(minenergo_path)
names(minenergo_raw) <- c("date", "consumers_disconnected", "settlements_disconnected",
                          "consumers_restored", "cause", "source_link")
combat_weekly <- minenergo_raw |>
  mutate(
    date = as.Date(date),
    week = lubridate::floor_date(date, unit = "week", week_start = 1),
    consumers_disconnected = tidyr::replace_na(consumers_disconnected, 0)
  ) |>
  group_by(week) |>
  summarise(combat_consumers = sum(consumers_disconnected, na.rm = TRUE), .groups = "drop") |>
  mutate(week = as.POSIXct(week, tz = "UTC"))

# Merge energy controls; fill pre-data zeros
df <- df |>
  left_join(outage_weekly, by = "week") |>
  left_join(combat_weekly, by = "week") |>
  mutate(
    outage_hours     = tidyr::replace_na(outage_hours, 0),
    combat_consumers = tidyr::replace_na(combat_consumers, 0),
    # Standardise for comparability
    outage_hrs_std   = as.numeric(scale(outage_hours)),
    combat_cons_std  = as.numeric(scale(combat_consumers))
  )

cat("Energy controls merged.\n")
cat("Obs with outage_hours > 0:", sum(df$outage_hours > 0), "\n")
cat("Obs with combat_consumers > 0:", sum(df$combat_consumers > 0), "\n\n")

# =============================================================================
# 2A. Weekly OLS
# =============================================================================

cat("=== 2A. Weekly OLS ===\n\n")
fat_m1 <- lm(avg_digital_skill_share ~ log_fatalities,
             data = df)

fat_m2 <- lm(avg_digital_skill_share ~ log_fatalities + quarter,
             data = df)

fat_m3 <- lm(avg_digital_skill_share ~ log_fatalities + quarter + year,
             data = df)

fat_m4 <- lm(avg_digital_skill_share ~ log_fatalities + month_of_year,
             data = df)

# Column (5): partial controls # with quarter FE but WITHOUT military skill share
fat_m5 <- lm(avg_digital_skill_share ~ log_fatalities +
               vacancy_count + chatgpt_rollout + ai_wave2 + quarter,
             data = df)

# Column (6): full controls
fat_m6 <- lm(avg_digital_skill_share ~ log_fatalities +
               vacancy_count + avg_military_skill_share +
               chatgpt_rollout + ai_wave2 + quarter,
             data = df)

# Column (7): full controls + energy infrastructure variables
fat_m7 <- lm(avg_digital_skill_share ~ log_fatalities +
               vacancy_count + avg_military_skill_share +
               chatgpt_rollout + ai_wave2 +
               outage_hrs_std + combat_cons_std + quarter,
             data = df)

# Console summary
se_labels <- c("(1) No FE [HC3]", "(2) Quarter FE [HAC]",
               "(3) Qtr+Year FE [HAC]", "(4) Month FE [HAC]",
               "(5) No military [HAC]", "(6) Full controls [HAC]",
               "(7) + Energy [HAC]")

for (i in 1:7) {
  mod <- get(paste0("fat_m", i))
  ct  <- if (i == 1) hc3_se(mod) else hac_se(mod)
  cat(sprintf("  %-26s coef = %+.4f  SE = %.4f  p = %.4f  R2 = %.3f  N = %d\n",
              se_labels[i],
              ct["log_fatalities", 1], ct["log_fatalities", 2],
              ct["log_fatalities", 4],
              summary(mod)$r.squared, nobs(mod)))
}
cat("\n")

# =============================================================================
# 2B. Weekly OLS
# =============================================================================

cat("=== 2B. Weekly OLS ===\n\n")
evt_m1 <- lm(avg_digital_skill_share ~ log_events,
             data = df)

evt_m2 <- lm(avg_digital_skill_share ~ log_events + quarter,
             data = df)

evt_m3 <- lm(avg_digital_skill_share ~ log_events + quarter + year,
             data = df)

evt_m4 <- lm(avg_digital_skill_share ~ log_events + month_of_year,
             data = df)

evt_m5 <- lm(avg_digital_skill_share ~ log_events +
               vacancy_count + chatgpt_rollout + ai_wave2 + quarter,
             data = df)

evt_m6 <- lm(avg_digital_skill_share ~ log_events +
               vacancy_count + avg_military_skill_share +
               chatgpt_rollout + ai_wave2 + quarter,
             data = df)

evt_m7 <- lm(avg_digital_skill_share ~ log_events +
               vacancy_count + avg_military_skill_share +
               chatgpt_rollout + ai_wave2 +
               outage_hrs_std + combat_cons_std + quarter,
             data = df)

for (i in 1:7) {
  mod <- get(paste0("evt_m", i))
  ct  <- if (i == 1) hc3_se(mod) else hac_se(mod)
  cat(sprintf("  %-26s coef = %+.4f  SE = %.4f  p = %.4f  R2 = %.3f  N = %d\n",
              se_labels[i],
              ct["log_events", 1], ct["log_events", 2],
              ct["log_events", 4],
              summary(mod)$r.squared, nobs(mod)))
}
cat("\n")

# =============================================================================
# 3. Export Tables
# =============================================================================

export_weekly_table <- function(models, conflict_var, conflict_label,
                                 title_str, label_str, out_file) {

  coef_labels <- c(
    setNames(conflict_label, conflict_var),
    "vacancy_count"            = "Vacancy Count",
    "avg_military_skill_share" = "Military Skill Share",
    "chatgpt_rollout"          = "ChatGPT Rollout",
    "ai_wave2"                 = "AI Wave 2",
    "outage_hrs_std"           = "Outage Hours (std.)",
    "combat_cons_std"          = "Power Disconnections (std.)",
    "(Intercept)"              = "Intercept"
  )

  vcov_list <- lapply(seq_along(models), function(i)
    if (i == 1) hc3_vcov(models[[i]]) else nw_vcov(models[[i]])
  )

  note_text <- paste(
    "Dependent variable: average digital skill share (weekly).",
    sprintf(
      "%s is $\\\\log(1 + \\\\text{weekly ACLED %s})$.",
      conflict_label,
      if (conflict_var == "log_fatalities") "fatalities" else "events"
    ),
    "(1) no fixed effects, HC3 standard errors;",
    "(2) quarter fixed effects, HAC SE (Newey-West, 4 lags);",
    "(3) quarter and year fixed effects, HAC SE;",
    "(4) month-of-year fixed effects (12 indicators), HAC SE;",
    "(5) partial controls (vacancy count, ChatGPT rollout, AI wave 2)",
    "with quarter fixed effects, HAC SE --- military skill share excluded;",
    "(6) full controls adding military skill share to column (5), HAC SE;",
    "(7) column (6) plus energy infrastructure controls: standardised weekly",
    "electricity outage hours and standardised security-related consumer",
    "disconnections (MinEnergo), HAC SE.",
    "Model (1) uses HC3 SE. Models (2)--(7) use HAC SE with 4 lags.",
    sep = " "
  )

  col_names <- paste0("(", seq_along(models), ")")

  tbl_latex <- modelsummary(
    setNames(models, col_names),
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

  # Inject \label after \caption
  tbl_latex <- sub(
    "(\\\\caption\\{[^}]*\\})",
    paste0("\\1\n\\\\label{", label_str, "}"),
    tbl_latex
  )

  # Inject FE indicator rows before Num.Obs. row
  n_cols <- length(models)
  fe_block <- paste0(
    "\\\\midrule\n",
    if (n_cols >= 7)
      "Quarter FE       & No  & Yes & Yes & No  & Yes & Yes & Yes \\\\\\\\\n"
    else
      "Quarter FE       & No  & Yes & Yes & No  & Yes & Yes \\\\\\\\\n",
    if (n_cols >= 7)
      "Year FE          & No  & No  & Yes & No  & No  & No  & No  \\\\\\\\\n"
    else
      "Year FE          & No  & No  & Yes & No  & No  & No  \\\\\\\\\n",
    if (n_cols >= 7)
      "Month FE         & No  & No  & No  & Yes & No  & No  & No  \\\\\\\\\n"
    else
      "Month FE         & No  & No  & No  & Yes & No  & No  \\\\\\\\\n",
    if (n_cols >= 7)
      "Partial controls & No  & No  & No  & No  & Yes & Yes & Yes \\\\\\\\\n"
    else
      "Partial controls & No  & No  & No  & No  & Yes & Yes \\\\\\\\\n",
    if (n_cols >= 7)
      "Military share   & No  & No  & No  & No  & No  & Yes & Yes \\\\\\\\\n"
    else
      "Military share   & No  & No  & No  & No  & No  & Yes \\\\\\\\\n",
    if (n_cols >= 7)
      "Energy controls  & No  & No  & No  & No  & No  & No  & Yes \\\\\\\\\n"
    else
      ""
  )

  tbl_latex <- gsub(
    "(\\\\midrule\n)(\\\\num\\{235\\}|Num\\.Obs\\.)",
    paste0(fe_block, "\\2"),
    tbl_latex
  )

  # Fix note column width dynamically
  n_multicol <- length(models) + 1L   # model cols + label col
  tbl_latex <- gsub(
    paste0("\\multicolumn{", n_multicol, "}{l}{\\rule{0pt}{1em}"),
    paste0("\\multicolumn{", n_multicol, "}{p{22cm}}{\\footnotesize\\rule{0pt}{1em}"),
    tbl_latex,
    fixed = TRUE
  )

  # Wrap tabular in \resizebox so the table scales to text width automatically
  tbl_latex <- gsub(
    "(\\\\begin\\{tabular\\})",
    "\\\\resizebox{\\\\textwidth}{!}{\\1",
    tbl_latex
  )
  tbl_latex <- gsub(
    "(\\\\end\\{tabular\\})",
    "\\1}",
    tbl_latex
  )

  writeLines(tbl_latex, out_file)
  cat("Saved:", out_file, "\n")
  invisible(tbl_latex)
}

# =============================================================================
# 4. Export
# =============================================================================

cat("=== 4. Exporting Tables ===\n\n")

export_weekly_table(
  models         = list(fat_m1, fat_m2, fat_m3, fat_m4, fat_m5, fat_m6, fat_m7),
  conflict_var   = "log_fatalities",
  conflict_label = "Log(Fatalities)",
  title_str      = "OLS Regression Results - Log(Fatalities)",
  label_str      = "tab:ols_combined",
  out_file       = file.path(tables_dir, "table_ols_combined.tex")
)

export_weekly_table(
  models         = list(evt_m1, evt_m2, evt_m3, evt_m4, evt_m5, evt_m6, evt_m7),
  conflict_var   = "log_events",
  conflict_label = "Log(Events)",
  title_str      = "OLS Regression Results - Log(Events)",
  label_str      = "tab:ols_events_combined",
  out_file       = file.path(tables_dir, "table_ols_events_combined.tex")
)

# =============================================================================
# 5. Console Summary
# =============================================================================

cat("\n=== 5. Summary ===\n\n")

cat("Log(Fatalities) results:\n\n")
for (i in 1:7) {
  mod <- get(paste0("fat_m", i))
  ct  <- if (i == 1) hc3_se(mod) else hac_se(mod)
  cat(sprintf("  %-26s coef = %+.4f  p = %.4f\n",
              se_labels[i], ct["log_fatalities", 1], ct["log_fatalities", 4]))
}

cat("\nLog(Events) results:\n\n")
for (i in 1:7) {
  mod <- get(paste0("evt_m", i))
  ct  <- if (i == 1) hc3_se(mod) else hac_se(mod)
  cat(sprintf("  %-26s coef = %+.4f  p = %.4f\n",
              se_labels[i], ct["log_events", 1], ct["log_events", 4]))
}

cat("\nTables saved to:", tables_dir, "\n")
cat("\n=== 03_main_ols.R complete ===\n")

# =============================================================================
# 6. Economic Magnitude
# =============================================================================

cat("\n=== 6. Economic Magnitude ===\n\n")

# Pre-invasion mean of the outcome (baseline level)
pre_invasion_date <- as.POSIXct("2022-02-24", tz = "UTC")
pre_invasion_mean <- df |>
  filter(week < pre_invasion_date) |>
  summarise(mean_share = mean(avg_digital_skill_share, na.rm = TRUE)) |>
  pull(mean_share)

post_invasion_mean <- df |>
  filter(week >= pre_invasion_date) |>
  summarise(mean_share = mean(avg_digital_skill_share, na.rm = TRUE)) |>
  pull(mean_share)

cat(sprintf("Pre-invasion mean digital skill share:  %.4f (%.1f%%)\n",
            pre_invasion_mean, pre_invasion_mean * 100))
cat(sprintf("Post-invasion mean digital skill share: %.4f (%.1f%%)\n",
            post_invasion_mean, post_invasion_mean * 100))
cat(sprintf("Absolute increase:                      %.4f (%.1f pp)\n\n",
            post_invasion_mean - pre_invasion_mean,
            (post_invasion_mean - pre_invasion_mean) * 100))

# SD of conflict variables (full sample and post-invasion)
sd_fat_full <- sd(df$log_fatalities, na.rm = TRUE)
sd_fat_post <- df |>
  filter(week >= pre_invasion_date) |>
  summarise(sd = sd(log_fatalities, na.rm = TRUE)) |>
  pull(sd)

sd_evt_full <- sd(df$log_events, na.rm = TRUE)
sd_evt_post <- df |>
  filter(week >= pre_invasion_date) |>
  summarise(sd = sd(log_events, na.rm = TRUE)) |>
  pull(sd)

cat(sprintf("SD of log(fatalities) -- full sample:    %.4f\n", sd_fat_full))
cat(sprintf("SD of log(fatalities) -- post-invasion:  %.4f\n", sd_fat_post))
cat(sprintf("SD of log(events)     -- full sample:    %.4f\n", sd_evt_full))
cat(sprintf("SD of log(events)     -- post-invasion:  %.4f\n\n", sd_evt_post))
# Retrieve baseline coefficients from model (2): quarter FE, HAC SE
coef_fat_m2 <- coeftest(fat_m2, vcov = nw_vcov(fat_m2))["log_fatalities", 1]
coef_evt_m2 <- coeftest(evt_m2, vcov = nw_vcov(evt_m2))["log_events",     1]

# Retrieve full-controls coefficients from model (6)
coef_fat_m6 <- coeftest(fat_m6, vcov = nw_vcov(fat_m6))["log_fatalities", 1]
coef_evt_m6 <- coeftest(evt_m6, vcov = nw_vcov(evt_m6))["log_events",     1]

# SD-scaled effects
sd_effect_fat_m2_full <- coef_fat_m2 * sd_fat_full
sd_effect_fat_m2_post <- coef_fat_m2 * sd_fat_post
sd_effect_fat_m6_full <- coef_fat_m6 * sd_fat_full
sd_effect_fat_m6_post <- coef_fat_m6 * sd_fat_post

sd_effect_evt_m2_full <- coef_evt_m2 * sd_evt_full
sd_effect_evt_m2_post <- coef_evt_m2 * sd_evt_post
sd_effect_evt_m6_full <- coef_evt_m6 * sd_evt_full
sd_effect_evt_m6_post <- coef_evt_m6 * sd_evt_post

cat("--- Log(Fatalities) ---\n")
cat(sprintf("  Baseline coef (M2):               %.4f pp per log unit\n",
            coef_fat_m2 * 100))
cat(sprintf("  1-SD effect (full sample, M2):    %.4f pp  |  %.1f%% of pre-invasion mean\n",
            sd_effect_fat_m2_full * 100,
            sd_effect_fat_m2_full / pre_invasion_mean * 100))
cat(sprintf("  1-SD effect (post-invasion, M2):  %.4f pp  |  %.1f%% of pre-invasion mean\n",
            sd_effect_fat_m2_post * 100,
            sd_effect_fat_m2_post / pre_invasion_mean * 100))
cat(sprintf("  Full-controls coef (M6):          %.4f pp per log unit\n",
            coef_fat_m6 * 100))
cat(sprintf("  1-SD effect (full sample, M6):    %.4f pp  |  %.1f%% of pre-invasion mean\n",
            sd_effect_fat_m6_full * 100,
            sd_effect_fat_m6_full / pre_invasion_mean * 100))
cat(sprintf("  1-SD effect (post-invasion, M6):  %.4f pp  |  %.1f%% of pre-invasion mean\n\n",
            sd_effect_fat_m6_post * 100,
            sd_effect_fat_m6_post / pre_invasion_mean * 100))

cat("--- Log(Events) ---\n")
cat(sprintf("  Baseline coef (M2):               %.4f pp per log unit\n",
            coef_evt_m2 * 100))
cat(sprintf("  1-SD effect (full sample, M2):    %.4f pp  |  %.1f%% of pre-invasion mean\n",
            sd_effect_evt_m2_full * 100,
            sd_effect_evt_m2_full / pre_invasion_mean * 100))
cat(sprintf("  1-SD effect (post-invasion, M2):  %.4f pp  |  %.1f%% of pre-invasion mean\n",
            sd_effect_evt_m2_post * 100,
            sd_effect_evt_m2_post / pre_invasion_mean * 100))
cat(sprintf("  Full-controls coef (M6):          %.4f pp per log unit\n",
            coef_evt_m6 * 100))
cat(sprintf("  1-SD effect (full sample, M6):    %.4f pp  |  %.1f%% of pre-invasion mean\n",
            sd_effect_evt_m6_full * 100,
            sd_effect_evt_m6_full / pre_invasion_mean * 100))
cat(sprintf("  1-SD effect (post-invasion, M6):  %.4f pp  |  %.1f%% of pre-invasion mean\n\n",
            sd_effect_evt_m6_post * 100,
            sd_effect_evt_m6_post / pre_invasion_mean * 100))

cat("Economic magnitude summary saved to console.\n")
cat("\n=== 02_baseline_regression.R complete ===\n")
