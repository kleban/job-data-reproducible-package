# =============================================================================
# Ukraine Research Working Paper
# Script: 07_robustness_ovb.R
# Purpose: Address Reviewer Comment on Omitted Variable Bias
#
# Reviewer Comment:
#   "The main empirical specification relies on a regression with log(fatalities)
#    or log(events) as the sole explanatory variable, aside from seasonal dummies.
#    This specification is likely subject to severe omitted variable bias, as
#    conflict intensity is correlated with regional economic activity, sectoral
#    composition, firm posting behavior, internet access, and platform usage,
#    all of which directly affect job postings and skill requirements."
#
# Response strategy:
#   1. Coefficient stability table: progressively add controls and show the
#      log(fatalities) / post_invasion coefficient is stable #      robustness check for OVB (Oster 2019; Altonji et al. 2005).
#   2. NOTE: remote_share is intentionally EXCLUDED from stability models.
#      Remote work adoption rose because of the conflict (firms adapted to
#      operate under war conditions), making remote_share a MEDIATOR of the
#      invasion effect, not a confounder. Including a mediator induces
#      bad-control bias and is methodologically incorrect for OVB robustness.
#   3. vacancy_count: controls for overall labour market volume / platform
#      usage / aggregate economic conditions.
#   4. avg_military_skill_share: controls for sectoral composition shift
#      (militarisation of posting demand).
#   5. time_trend: absorbs smooth, gradually-evolving confounders.
#   6. chatgpt_rollout + log_events: technology and measurement robustness.
#   7. ITS model: the discrete invasion shock (post_invasion) controls for
#      smooth time-varying confounders better than a continuous regressor.
#
# Exports:
#   table_coef_stability.tex   #   table_its_robustness.tex   # =============================================================================

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
  library(readxl)
})

if (!exists("pkg_root")) pkg_root <- if (dir.exists(here::here("R"))) here::here() else here::here("code", "paper-analytics", "reproducibility_package")
tables_dir  <- file.path(pkg_root, "output", "tables")
figures_dir <- file.path(pkg_root, "output", "figures")
if (!dir.exists(tables_dir))  dir.create(tables_dir,  recursive = TRUE)
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

options(modelsummary_factory_latex = "kableExtra")

hac_se  <- function(model) coeftest(model, vcov = NeweyWest(model, lag = 4, prewhite = FALSE))
nw_vcov <- function(model) NeweyWest(model, lag = 4, prewhite = FALSE)

# -----------------------------------------------------------------------------
# 1. Load & Prepare Data
# -----------------------------------------------------------------------------

if (!exists("data_dir")) data_dir <- file.path(pkg_root, "data")
data_path <- file.path(data_dir, "final_weekly.parquet")
if (!file.exists(data_path)) stop("Data file not found: ", data_path)

df <- arrow::read_parquet(data_path) |> janitor::clean_names()

cat("Columns in data:", paste(names(df), collapse = ", "), "\n\n")

invasion_date <- as.POSIXct("2022-02-24", tz = "UTC")
chatgpt_date  <- as.POSIXct("2022-11-30", tz = "UTC")
# Second AI wave: Claude 1.0 (Mar 14 2023), GPT-4 (Mar 14 2023), Google Bard
# (Mar 21 2023) all launched within the same week on weekly data
ai_wave2_date <- as.POSIXct("2023-03-14", tz = "UTC")

df <- df |>
  arrange(week) |>
  mutate(
    log_fatalities      = log1p(total_fatalities),
    log_events          = log1p(num_events),
    post_invasion       = as.integer(week >= invasion_date),
    time_trend          = as.integer(difftime(week, min(week), units = "weeks")),
    time_since_invasion = pmax(0L, as.integer(
      difftime(week, invasion_date, units = "weeks")
    )) * as.integer(week >= invasion_date),
    chatgpt_rollout     = as.integer(week >= chatgpt_date),
    ai_wave2            = as.integer(week >= ai_wave2_date),  # Claude/GPT-4/Bard
    quarter             = factor(lubridate::quarter(week))
  )

cat("Data loaded:", nrow(df), "weeks\n")
cat("Coverage:", as.character(min(df$week)), "to", as.character(max(df$week)), "\n")
cat("remote_share available:", "remote_share" %in% names(df), "\n\n")

# -----------------------------------------------------------------------------
# 1b. Load and merge energy infrastructure controls
# -----------------------------------------------------------------------------

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

df <- df |>
  left_join(outage_weekly, by = "week") |>
  left_join(combat_weekly, by = "week") |>
  mutate(
    outage_hours     = tidyr::replace_na(outage_hours, 0),
    combat_consumers = tidyr::replace_na(combat_consumers, 0),
    outage_hrs_std   = as.numeric(scale(outage_hours)),
    combat_cons_std  = as.numeric(scale(combat_consumers))
  )

cat("Energy controls merged.\n\n")

# =============================================================================
# 2. Coefficient Stability Table
# =============================================================================
# The key empirical response to OVB: if the log(fatalities) coefficient on
# avg_digital_skill_share is stable as we progressively add controls that
# proxy for the omitted variables, the OVB concern is weakened.
#
# Controls added sequentially and what they address:
#   M1: log_fatalities + quarter FE                  (baseline / paper's spec)
#   M2: + vacancy_count                              (platform usage, economic activity)
#   M3: + avg_military_skill_share                   (sectoral composition)
#   M4: + time_trend                                 (smooth time-varying confounders)
#   M5: + chatgpt_rollout                            (AI technology shock)
#   M6: + ai_wave2                                   (fully-controlled internal spec)
#   M7: log_events replaces log_fatalities           (alternative conflict measure)
#       #         log_events is NOT included alongside log_fatalities (multicollinearity)
#
# remote_share is EXCLUDED: it is a mediator (conflict-induced remote adoption),
# not a confounder. Including it would induce bad-control bias.

cat("=== 2. Coefficient Stability ===\n\n")

m1 <- lm(avg_digital_skill_share ~ log_fatalities + quarter,
         data = df)

m2 <- lm(avg_digital_skill_share ~ log_fatalities + vacancy_count +
           quarter,
         data = df)

m3 <- lm(avg_digital_skill_share ~ log_fatalities + vacancy_count +
           avg_military_skill_share + quarter,
         data = df)

m4 <- lm(avg_digital_skill_share ~ log_fatalities + vacancy_count +
           avg_military_skill_share + time_trend +
           quarter,
         data = df)

m5 <- lm(avg_digital_skill_share ~ log_fatalities + vacancy_count +
           avg_military_skill_share + time_trend +
           chatgpt_rollout + quarter,
         data = df)

# M6: fully-controlled internal spec (ai_wave2 added; log_events excluded)
m6 <- lm(avg_digital_skill_share ~ log_fatalities + vacancy_count +
           avg_military_skill_share + time_trend +
           chatgpt_rollout + ai_wave2 + quarter,
         data = df)

# M7: log_events REPLACES log_fatalities # Tests whether the result depends on the choice of conflict proxy.
# log_events is NOT included alongside log_fatalities to avoid multicollinearity.
m7 <- lm(avg_digital_skill_share ~ log_events + vacancy_count +
           avg_military_skill_share + time_trend +
           chatgpt_rollout + ai_wave2 + quarter,
         data = df)

# Print key coefficient across models
cat("log_fatalities (M1-M6) / log_events (M7) coefficient on avg_digital_skill_share:\n")
for (i in 1:6) {
  mod <- get(paste0("m", i))
  ct  <- hac_se(mod)
  coef_val <- ct["log_fatalities", 1]
  pval     <- ct["log_fatalities", 4]
  r2       <- summary(mod)$r.squared
  cat(sprintf("  M%d (log_fatalities): coef = %+.4f  p = %.4f  R2 = %.3f\n", i, coef_val, pval, r2))
}
ct7 <- hac_se(m7)
cat(sprintf("  M7 (log_events):      coef = %+.4f  p = %.4f  R2 = %.3f\n",
            ct7["log_events", 1], ct7["log_events", 4], summary(m7)$r.squared))
cat("\n")

# =============================================================================
# 3. ITS Robustness with Full Controls
# =============================================================================
# Replace continuous log_fatalities with post_invasion dummy in the fully-
# controlled specification. The discrete invasion shock isolates a single
# date that is exogenous to gradual, time-varying confounders.

cat("=== 3. ITS + Full Controls ===\n\n")

# ITS baseline
its_m1 <- lm(avg_digital_skill_share ~
               post_invasion + time_since_invasion + quarter,
             data = df)

# ITS + economic/platform controls (no remote_share)
its_m2 <- lm(avg_digital_skill_share ~
               post_invasion + time_since_invasion +
               vacancy_count + avg_military_skill_share + quarter,
             data = df)

# ITS + all controls
its_m3 <- lm(avg_digital_skill_share ~
               post_invasion + time_since_invasion +
               vacancy_count + avg_military_skill_share +
               time_trend + chatgpt_rollout + quarter,
             data = df)

# ITS + all controls + second AI wave (Claude / GPT-4 / Bard)
its_m4 <- lm(avg_digital_skill_share ~
               post_invasion + time_since_invasion +
               vacancy_count + avg_military_skill_share +
               time_trend + chatgpt_rollout + ai_wave2 + quarter,
             data = df)

# ITS + all controls + energy infrastructure disruptions
its_m5 <- lm(avg_digital_skill_share ~
               post_invasion + time_since_invasion +
               vacancy_count + avg_military_skill_share +
               time_trend + chatgpt_rollout + ai_wave2 +
               outage_hrs_std + combat_cons_std + quarter,
             data = df)

cat("--- ITS: post_invasion coefficient on avg_digital_skill_share ---\n")
for (i in 1:5) {
  mod <- get(paste0("its_m", i))
  ct  <- hac_se(mod)
  coef_val <- ct["post_invasion", 1]
  pval     <- ct["post_invasion", 4]
  r2       <- summary(mod)$r.squared
  cat(sprintf("  ITS M%d: post_invasion coef = %+.4f  p = %.4f  R2 = %.3f\n",
              i, coef_val, pval, r2))
}
cat("\n")

print(hac_se(its_m4))
cat("\n")

# =============================================================================
# 4. Export: ITS Robustness Table
# =============================================================================

cat("=== 4. Export LaTeX Tables ===\n\n")

# ---- ITS robustness table ---------------------------------------------------

its_coef_labels <- c(
  "post_invasion"            = "Post-2022",
  "time_since_invasion"      = "Time Since 2022",
  "vacancy_count"            = "Vacancy Count",
  "avg_military_skill_share" = "Military Skill Share",
  "time_trend"               = "Time Trend",
  "chatgpt_rollout"          = "ChatGPT Rollout",
  "ai_wave2"                 = "AI Wave 2 (Claude/GPT-4/Bard)",
  "outage_hrs_std"           = "Outage Hours (std.)",
  "combat_cons_std"          = "Power Disconnections (std.)",
  "(Intercept)"              = "Intercept"
)

its_note <- paste(
  "Dependent variable: average digital skill share.",
  "All models use an Interrupted Time Series (ITS) design with a discrete",
  "post-2022 indicator in place of the continuous log(fatalities) regressor.",
  "The discrete shock on February 24, 2022 is exogenous to gradual,",
  "time-varying confounders.",
  "(1) ITS baseline + quarter FE;",
  "(2) adds vacancy count and military skill share;",
  "(3) extended controls: adds time trend and ChatGPT rollout;",
  "(4) additionally controls for the second AI wave (Claude 1.0, GPT-4, and Google Bard,",
  "all launched in the week of March 14, 2023);",
  "(5) additionally controls for energy infrastructure disruptions:",
  "standardised weekly electricity outage hours (energy-map.info, from January 2023;",
  "pre-2023 set to zero) and standardised security-related consumer disconnections",
  "(Ukrainian Ministry of Energy, from March 2022; pre-invasion set to zero).",
  "HAC standard errors (Newey-West, 4 lags) in parentheses.",
  "Quarter fixed effects included but not shown.",
  sep = " "
)

# Generate WITHOUT notes
its_latex <- modelsummary(
  list(
    "(1) ITS Baseline"          = its_m1,
    "(2) ITS + Econ. Controls"  = its_m2,
    "(3) ITS + Extended Controls" = its_m3,
    "(4) ITS + AI Wave 2"       = its_m4,
    "(5) ITS + Energy"          = its_m5
  ),
  vcov     = nw_vcov,
  coef_map = its_coef_labels,
  gof_map  = c("nobs", "r.squared", "adj.r.squared"),
  stars    = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title    = "ITS Robustness: Digital Skill Share with Progressive Controls",
  notes    = NULL,
  output   = "latex",
  escape   = FALSE
)

its_latex <- sub(
  "(\\\\caption\\{[^}]*\\})",
  "\\1\n\\\\label{tab:its_robustness}",
  its_latex
)

# Wrap tabular in \resizebox
its_latex <- sub(
  "(\\\\begin\\{tabular\\})",
  "\\\\resizebox{\\\\textwidth}{!}{\\1",
  its_latex
)
its_latex <- sub(
  "(\\\\end\\{tabular\\})",
  "\\1}",
  its_latex
)

# Add notes OUTSIDE the resizebox as a full-linewidth minipage,
# so they always span the full table width regardless of scaling.
its_note_block <- paste0(
  "\n\\begin{minipage}{\\linewidth}\\footnotesize\n",
  "\\rule{0pt}{1em}* p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01\\\\\n",
  "\\rule{0pt}{1em}", its_note, "\n",
  "\\end{minipage}"
)
its_latex <- sub(
  "\\end{table}",
  paste0(its_note_block, "\n\\end{table}"),
  its_latex,
  fixed = TRUE
)

writeLines(its_latex, file.path(tables_dir, "table_its_robustness.tex"))
cat("ITS robustness table saved.\n\n")

# =============================================================================
# 5. Console Summary for Reviewer Response
# =============================================================================

cat("=== 5. Key Results for Reviewer Response ===\n\n")

cat("Coefficient on log_fatalities (M1-M6) / log_events (M7), avg_digital_skill_share:\n")
labels_for_print <- c(
  "M1 Baseline (quarter only)",
  "M2 + vacancy_count",
  "M3 + military_share",
  "M4 + time_trend",
  "M5 + chatgpt_rollout",
  "M6 + ai_wave2 (fully controlled)"
)
for (i in 1:6) {
  mod  <- get(paste0("m", i))
  ct   <- hac_se(mod)
  cat(sprintf("  %-40s coef = %+.4f  p = %.4f\n",
              labels_for_print[i], ct["log_fatalities", 1], ct["log_fatalities", 4]))
}
ct7 <- hac_se(m7)
cat(sprintf("  %-40s coef = %+.4f  p = %.4f\n",
            "M7 log_events (alt. measure, full controls)", ct7["log_events", 1], ct7["log_events", 4]))

cat("\nPost-invasion coefficient (ITS specs):\n")
its_labels <- c("ITS baseline", "ITS + vacancy + military",
                "ITS + extended controls", "ITS + AI Wave 2", "ITS + Energy")
for (i in 1:5) {
  mod <- get(paste0("its_m", i))
  ct  <- hac_se(mod)
  cat(sprintf("  %-40s coef = %+.4f  p = %.4f\n",
              its_labels[i], ct["post_invasion", 1], ct["post_invasion", 4]))
}

cat("\nTables saved to:", tables_dir, "\n")
cat("\n=== 07_robustness_ovb.R complete. ===\n")
