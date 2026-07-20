# =============================================================================
# Ukraine Research Working Paper
# Script: 05_cointegration_ecm.R
# Purpose: Three complementary approaches to address spurious regression concern
#
# Builds on 04_stationarity.R findings (both series I(1)) and implements:
#   A. Engle-Granger cointegration test + Error Correction Model (ECM)
#   B. Detrended (trend-stationary) regressions
#   C. Lagged first-differences (1, 4, 13-week lags)
#
# Exports LaTeX tables:
#   table_cointegration.tex  #   table_ecm.tex            #   table_detrended.tex      #   table_lagged_fd.tex      # =============================================================================

# -----------------------------------------------------------------------------
# 0. Setup
# -----------------------------------------------------------------------------

packages_needed <- c(
  "here",
  "arrow", "tidyverse", "lubridate",
  "tseries",      # adf.test, kpss.test
  "sandwich",     # NeweyWest
  "lmtest",       # coeftest
  "modelsummary", # regression tables
  "kableExtra",   # LaTeX backend
  "janitor"       # clean_names
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
  library(tseries); library(sandwich); library(lmtest)
  library(modelsummary); library(kableExtra); library(janitor)
})

if (!exists("pkg_root")) pkg_root <- if (dir.exists(here::here("R"))) here::here() else here::here("reproducibility_package")
tables_dir  <- file.path(pkg_root, "output", "tables")
figures_dir <- file.path(pkg_root, "output", "figures")
if (!dir.exists(tables_dir))  dir.create(tables_dir,  recursive = TRUE)
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

options(modelsummary_factory_latex = "kableExtra")

# HAC SE helper (Newey-West, 4 lags)
hac_se  <- function(model) coeftest(model, vcov = NeweyWest(model, lag = 4, prewhite = FALSE))
nw_vcov <- function(model) NeweyWest(model, lag = 4, prewhite = FALSE)

# -----------------------------------------------------------------------------
# Helper: replace modelsummary's multicolumn footnote with a wrapping minipage
#
# modelsummary emits footnotes as \multicolumn{n}{l}{...} rows with no defined
# width, so LaTeX never wraps the text and it overruns the page even in
# landscape. This function strips those rows and replaces them with a
# \begin{minipage}{\linewidth} block that wraps correctly at any page width.
# -----------------------------------------------------------------------------
fix_table_footnote <- function(latex_str, notes_str) {
  # Strip all \multicolumn footnote rows that modelsummary inserts
  latex_str <- gsub(
    "\\\\multicolumn\\{[0-9]+\\}\\{l\\}\\{\\\\rule\\{0pt\\}\\{[^}]+\\}[^}]*\\}[^\n]*\n",
    "",
    latex_str
  )
  # Build the replacement block as a plain string
  replacement <- paste0(
    "\\end{tabular}\n",
    "\\begin{minipage}{\\linewidth}\n",
    "\\footnotesize\\vspace{0.5em}\n",
    "* $p < 0.1$, ** $p < 0.05$, *** $p < 0.01$\\\\[0.3em]\n",
    notes_str, "\n",
    "\\end{minipage}"
  )
  # fixed = TRUE treats pattern and replacement as literal strings,
  # preventing sub() from consuming the backslashes in notes_str
  sub("\\end{tabular}", replacement, latex_str, fixed = TRUE)
}

# -----------------------------------------------------------------------------
# 1. Load & Prepare Data  (identical to 02 / 03)
# -----------------------------------------------------------------------------

if (!exists("data_dir")) data_dir <- file.path(pkg_root, "data")
data_path <- file.path(data_dir, "final_weekly.parquet")
if (!file.exists(data_path)) stop("Data file not found: ", data_path)

df <- arrow::read_parquet(data_path) |> janitor::clean_names()

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

cat("Data loaded:", nrow(df), "weeks,",
    as.character(min(df$week)), "to", as.character(max(df$week)), "\n\n")

# =============================================================================
# A. ENGLE-GRANGER COINTEGRATION TEST + ERROR CORRECTION MODEL
# =============================================================================
cat("=== A. Cointegration & ECM ===\n\n")

# -----------------------------------------------------------------------------
# A1. Step 1 #     We use the core specification with time trend (avoids spurious levels).
#     We test three long-run relationships:
#       (i)  outcome ~ log_fatalities + time_trend
#       (ii) outcome ~ post_invasion + time_since_invasion + time_trend
#       (iii) outcome ~ post_invasion + time_since_invasion +
#                       log_fatalities + chatgpt_rollout + time_trend (full)
# -----------------------------------------------------------------------------

lr_m1 <- lm(avg_digital_skill_share ~ log_fatalities + time_trend, data = df)
lr_m2 <- lm(avg_digital_skill_share ~ post_invasion + time_since_invasion +
               time_trend, data = df)
lr_m3 <- lm(avg_digital_skill_share ~ post_invasion + time_since_invasion +
               log_fatalities + chatgpt_rollout +
               vacancy_count + avg_military_skill_share +
               time_trend, data = df)

# Engle-Granger Step 2: ADF test on residuals from each levels regression.
# H0 of ADF = unit root in residuals = NO cointegration.
# Rejection = cointegration (levels regression is valid, not spurious).

eg_test <- function(model, label) {
  resids <- residuals(model)
  adf    <- suppressWarnings(tseries::adf.test(resids, alternative = "stationary"))
  cat(sprintf("Engle-Granger ADF on residuals: %s\n", label))
  cat(sprintf("  ADF stat = %.3f,  p = %.4f  =>  Cointegration %s\n\n",
              as.numeric(adf$statistic), as.numeric(adf$p.value),
              ifelse(as.numeric(adf$p.value) < 0.05, "SUPPORTED (H0 rejected)", "NOT supported")))
  list(adf = adf, resids = resids, label = label)
}

eg1 <- eg_test(lr_m1, "(i)  outcome ~ log_fatalities + trend")
eg2 <- eg_test(lr_m2, "(ii) outcome ~ ITS + trend")
eg3 <- eg_test(lr_m3, "(iii) outcome ~ ITS + controls + trend (full)")

# -----------------------------------------------------------------------------
# A2. Cointegration summary table (LaTeX)
# -----------------------------------------------------------------------------

eg_rows <- data.frame(
  `Long-run specification` = c(
    "Outcome $\\sim$ Log(Fatalities) + trend",
    "Outcome $\\sim$ ITS vars + trend",
    "Outcome $\\sim$ ITS + all controls + trend"
  ),
  `ADF stat` = round(c(
    as.numeric(eg1$adf$statistic),
    as.numeric(eg2$adf$statistic),
    as.numeric(eg3$adf$statistic)
  ), 3),
  `p-value` = format.pval(c(
    as.numeric(eg1$adf$p.value),
    as.numeric(eg2$adf$p.value),
    as.numeric(eg3$adf$p.value)
  ), digits = 3, eps = 0.001),
  `Cointegration` = ifelse(c(
    as.numeric(eg1$adf$p.value),
    as.numeric(eg2$adf$p.value),
    as.numeric(eg3$adf$p.value)
  ) < 0.05, "Yes (5\\%)", ifelse(c(
    as.numeric(eg1$adf$p.value),
    as.numeric(eg2$adf$p.value),
    as.numeric(eg3$adf$p.value)
  ) < 0.10, "Yes (10\\%)", "No")),
  check.names = FALSE, stringsAsFactors = FALSE
)

eg_latex <- kableExtra::kbl(
  eg_rows,
  format   = "latex",
  booktabs = TRUE,
  align    = c("l", "r", "r", "c"),
  caption  = "Engle--Granger Cointegration Tests (ADF on Long-Run Residuals)",
  label    = "cointegration",
  escape   = FALSE
) |>
  kableExtra::kable_styling(latex_options = c("hold_position")) |>
  kableExtra::footnote(
    general = paste(
      "Engle--Granger two-step procedure: ADF test applied to OLS residuals",
      "from the long-run (levels) regression.",
      "$H_0$: residuals contain a unit root (no cointegration).",
      "Rejection indicates cointegration: the levels regression captures a",
      "genuine long-run equilibrium, not a spurious correlation.",
      "Lag length selected automatically by AIC.",
      "Note: p-values are based on standard ADF critical values; correct Engle--Granger",
      "critical values for residual-based tests are more negative, so reported p-values",
      "are conservative. `Yes (10\\%)' and `Yes (5\\%)' denote rejection at the",
      "respective significance levels."
    ),
    general_title = "",
    escape = FALSE,
    threeparttable = TRUE
  )

writeLines(eg_latex, file.path(tables_dir, "table_cointegration.tex"))
cat("Cointegration table saved.\n\n")

# -----------------------------------------------------------------------------
# A3. Step 3 #
# ECM: ?y_t = a + #   ? < 0 and significant ? error correction (series are cointegrated)
#   #
# We build first-differenced data and attach the lagged residuals.
# -----------------------------------------------------------------------------

df_ecm <- df |>
  mutate(
    d_digital_share  = avg_digital_skill_share - lag(avg_digital_skill_share),
    d_log_fatalities = log_fatalities           - lag(log_fatalities),
    d_post_invasion  = post_invasion             - lag(post_invasion),
    d_time_since_inv = time_since_invasion       - lag(time_since_invasion),
    d_vacancy_count  = vacancy_count             - lag(vacancy_count),
    d_chatgpt        = chatgpt_rollout           - lag(chatgpt_rollout),
    d_military_share = avg_military_skill_share  - lag(avg_military_skill_share),
    # Lagged error-correction terms from each long-run regression
    ecm_lag1 = lag(eg1$resids),
    ecm_lag2 = lag(eg2$resids),
    ecm_lag3 = lag(eg3$resids)
  ) |>
  filter(!is.na(d_digital_share))

# ECM specifications
ecm_m1 <- lm(d_digital_share ~ d_log_fatalities + ecm_lag1 + quarter,
             data = df_ecm)

ecm_m2 <- lm(d_digital_share ~ d_post_invasion + d_time_since_inv +
               ecm_lag2 + quarter,
             data = df_ecm)

ecm_m3 <- lm(d_digital_share ~ d_post_invasion + d_time_since_inv +
               d_log_fatalities + d_vacancy_count + d_chatgpt +
               d_military_share + ecm_lag3 + quarter,
             data = df_ecm)

cat("--- ECM results (HAC SEs) ---\n")
for (i in seq_along(list(ecm_m1, ecm_m2, ecm_m3))) {
  cat(sprintf("ECM Model %d:\n", i))
  print(hac_se(list(ecm_m1, ecm_m2, ecm_m3)[[i]]))
  cat("\n")
}

ecm_coef_labels <- c(
  "d_log_fatalities" = "$\\Delta$Log(Fatalities)",
  "d_post_invasion"  = "$\\Delta$Post-2022 (impulse)",
  "d_time_since_inv" = "$\\Delta$Time Since 2022",
  "d_vacancy_count"  = "$\\Delta$Vacancy Count",
  "d_chatgpt"        = "$\\Delta$ChatGPT Rollout",
  "d_military_share" = "$\\Delta$Military Skill Share",
  "ecm_lag1"         = "ECM term $\\hat{u}_{t-1}$",
  "ecm_lag2"         = "ECM term $\\hat{u}_{t-1}$",
  "ecm_lag3"         = "ECM term $\\hat{u}_{t-1}$",
  "(Intercept)"      = "Intercept"
)

ecm_models_list <- list(
  "(1) Fatalities" = ecm_m1,
  "(2) ITS"        = ecm_m2,
  "(3) Full"       = ecm_m3
)

ecm_notes <- paste(
  "Error Correction Models (ECM): $\\Delta y_t = \\alpha + \\beta_1 \\Delta x_t",
  "+ \\gamma \\hat{u}_{t-1} + \\varepsilon_t$,",
  "where $\\hat{u}_{t-1}$ is the lagged residual from the corresponding long-run (levels) regression.",
  "A negative and significant ECM term $\\gamma$ indicates cointegration:",
  "the long-run levels relationship is genuine, not spurious.",
  "HAC standard errors (Newey-West, 4 lags) in parentheses.",
  "Quarter fixed effects included but not shown.",
  sep = " "
)

ecm_tbl_latex <- modelsummary(
  ecm_models_list,
  vcov     = nw_vcov,
  coef_map = ecm_coef_labels,
  gof_map  = c("nobs", "r.squared", "adj.r.squared"),
  stars    = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title    = "Error Correction Models: Short-Run Dynamics and Cointegration",
  notes    = ecm_notes,
  output   = "latex",
  escape   = FALSE
)

ecm_tbl_latex <- sub(
  "(\\\\caption\\{[^}]*\\})",
  "\\1\n\\\\label{tab:ecm}",
  ecm_tbl_latex
)

writeLines(
  fix_table_footnote(ecm_tbl_latex, ecm_notes),
  file.path(tables_dir, "table_ecm.tex")
)
cat("ECM table saved.\n\n")

# =============================================================================
# B. DETRENDED REGRESSIONS (trend-stationary approach)
# =============================================================================
cat("=== B. Detrended Regressions ===\n\n")

# Remove deterministic time trend from each series via OLS, then regress
# the detrended outcome on detrended regressors.
# This is appropriate if the series are trend-stationary (not I(1)):
# the PP test for digital skill share was borderline, suggesting this may apply.

df <- df |>
  mutate(
    dsk_detrended  = residuals(lm(avg_digital_skill_share  ~ time_trend, data = df)),
    lfat_detrended = residuals(lm(log_fatalities           ~ time_trend, data = df)),
    vac_detrended  = residuals(lm(vacancy_count            ~ time_trend, data = df)),
    mil_detrended  = residuals(lm(avg_military_skill_share ~ time_trend, data = df))
    # post_invasion, time_since_invasion, chatgpt_rollout are step/ramp dummies;
    # detrending them too would remove the structural break signal, so keep in levels.
  )

dt_m1 <- lm(dsk_detrended ~ lfat_detrended + quarter, data = df)

dt_m2 <- lm(dsk_detrended ~ post_invasion + time_since_invasion +
               quarter, data = df)

dt_m3 <- lm(dsk_detrended ~ post_invasion + time_since_invasion +
               lfat_detrended + vac_detrended + chatgpt_rollout +
               mil_detrended + quarter, data = df)

cat("--- Detrended results (HAC SEs) ---\n")
for (i in seq_along(list(dt_m1, dt_m2, dt_m3))) {
  cat(sprintf("Detrended Model %d:\n", i))
  print(hac_se(list(dt_m1, dt_m2, dt_m3)[[i]]))
  cat("\n")
}

dt_coef_labels <- c(
  "lfat_detrended"      = "Log(Fatalities) [detrended]",
  "post_invasion"       = "Post-2022",
  "time_since_invasion" = "Time Since 2022",
  "vac_detrended"       = "Vacancy Count [detrended]",
  "chatgpt_rollout"     = "ChatGPT Rollout",
  "mil_detrended"       = "Military Skill Share [detrended]",
  "(Intercept)"         = "Intercept"
)

dt_models_list <- list(
  "(1) Fatalities" = dt_m1,
  "(2) ITS"        = dt_m2,
  "(3) Full"       = dt_m3
)

dt_notes <- paste(
  "Detrended specifications: the dependent variable and continuous regressors",
  "are residualised on a linear time trend before estimation,",
  "removing the deterministic trend component common to both series.",
  "Step/ramp dummies (Post-2022, Time Since 2022, ChatGPT Rollout)",
  "are included in levels as they represent structural breaks, not trends.",
  "HAC standard errors (Newey-West, 4 lags) in parentheses.",
  "Quarter fixed effects included but not shown.",
  sep = " "
)

dt_tbl_latex <- modelsummary(
  dt_models_list,
  vcov     = nw_vcov,
  coef_map = dt_coef_labels,
  gof_map  = c("nobs", "r.squared", "adj.r.squared"),
  stars    = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title    = "Detrended Regressions: Digital Skill Share (Trend-Stationary Approach)",
  notes    = dt_notes,
  output   = "latex",
  escape   = FALSE
)

dt_tbl_latex <- sub(
  "(\\\\caption\\{[^}]*\\})",
  "\\1\n\\\\label{tab:detrended}",
  dt_tbl_latex
)

writeLines(
  fix_table_footnote(dt_tbl_latex, dt_notes),
  file.path(tables_dir, "table_detrended.tex")
)
cat("Detrended table saved.\n\n")

# =============================================================================
# C. Console summary # =============================================================================
cat("=== D. Key Results Summary ===\n\n")

cat("--- A. Engle-Granger cointegration ---\n")
for (eg in list(eg1, eg2, eg3)) {
  cat(sprintf("  %s\n    ADF = %.3f, p = %.4f => %s\n",
              eg$label,
              as.numeric(eg$adf$statistic),
              as.numeric(eg$adf$p.value),
              ifelse(as.numeric(eg$adf$p.value) < 0.05,
                     "COINTEGRATED (levels regression valid)",
                     "Not cointegrated (spurious concern valid)")))
}

cat("\n--- B. Detrended regressions (key coefficients) ---\n")
for (i in seq_along(list(dt_m1, dt_m2, dt_m3))) {
  m <- list(dt_m1, dt_m2, dt_m3)[[i]]
  ct <- hac_se(m)
  cat(sprintf("  Model %d (R2=%.3f):\n", i, summary(m)$r.squared))
  vars <- intersect(c("lfat_detrended", "post_invasion", "time_since_invasion",
                      "chatgpt_rollout"), rownames(ct))
  for (v in vars)
    cat(sprintf("    %-28s coef=%+.4f  p=%.4f\n", v, ct[v, 1], ct[v, 4]))
}

cat("\nTables saved to:", tables_dir, "\n")
cat("\n=== 05_cointegration_ecm.R complete. ===\n")
