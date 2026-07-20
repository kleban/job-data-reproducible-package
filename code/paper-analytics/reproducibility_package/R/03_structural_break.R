# =============================================================================
# Ukraine Research Working Paper
# Script: 03_structural_break.R
# Purpose: Address Reviewer Comment on Structural Break vs. Continuous Regressor
#
# Reviewer Comment:
#   "It is unclear why variation in war intensity should directly affect firms'
#    adjustment of skill requirements. Conceptually, it would be more appropriate
#    to treat the war as a structural break rather than as a continuously varying
#    regressor."
#
# Response strategy:
#   1. Formally test for a structural break at/around the full-scale invasion
#      (Feb 24, 2022) using Chow test, CUSUM, and Bai-Perron tests.
#   2. Re-estimate the baseline model replacing log(fatalities) with a binary
#      invasion dummy (level-shift structural break specification).
#   3. Estimate an Interrupted Time Series (ITS) model that allows both the
#      level AND the trend to shift at the break #      break treatment.
#   4. Show all specifications alongside the paper's original continuous-
#      regressor results, demonstrating they yield consistent conclusions.
# =============================================================================

# -----------------------------------------------------------------------------
# 0. Setup
# -----------------------------------------------------------------------------

packages_needed <- c(
  "here",
  "arrow",        # Parquet I/O
  "tidyverse",    # Data wrangling
  "lubridate",    # Date arithmetic
  "strucchange",  # Chow / CUSUM / Bai-Perron structural break tests
  "sandwich",     # HAC (Newey-West) covariance estimator
  "lmtest",       # coeftest() with robust SEs
  "modelsummary", # Regression tables
  "kableExtra",   # LaTeX table backend for modelsummary
  "ggplot2",      # Plots
  "janitor"       # clean_names()
)

packages_to_install <- packages_needed[
  !packages_needed %in% installed.packages()[, "Package"]
]
if (length(packages_to_install) > 0) {
  # On Windows, force binary installation to avoid source-build conflicts
  # (e.g. modelsummary source requires data.table >= 1.17.8 but the binary
  #  available on CRAN may be older; binary modelsummary has no such constraint).
  pkg_type <- if (.Platform$OS.type == "windows") "binary" else getOption("pkgType")
  install.packages(packages_to_install, type = pkg_type)
}

suppressPackageStartupMessages({
  library(arrow)
  library(tidyverse)
  library(lubridate)
  library(strucchange)
  library(sandwich)
  library(lmtest)
  library(modelsummary)
  library(kableExtra)
  library(ggplot2)
  library(janitor)
})


# -----------------------------------------------------------------------------
# 1. Load & Prepare Data
# -----------------------------------------------------------------------------

# ---- 1a. Load ---------------------------------------------------------------
if (!exists("pkg_root")) pkg_root <- if (dir.exists(here::here("R"))) here::here() else here::here("code", "paper-analytics", "reproducibility_package")
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

# ---- 1b. Key dates ----------------------------------------------------------
# Full-scale invasion: February 24, 2022
invasion_date <- as.POSIXct("2022-02-24", tz = "UTC")
# ChatGPT public release: November 30, 2022
chatgpt_date  <- as.POSIXct("2022-11-30", tz = "UTC")

# ---- 1c. Derived variables --------------------------------------------------
df <- df |>
  arrange(week) |>
  mutate(
    # ---- Outcome & regressors (matching paper's specification) ----
    # Log-transform conflict variables (log1p handles zero-fatality weeks)
    log_fatalities = log1p(total_fatalities),
    log_events     = log1p(num_events),

    # ---- Structural break indicators ----
    # Binary dummy: 1 in all weeks on/after Feb 24, 2022
    post_invasion = as.integer(week >= invasion_date),

    # Integer time trend (0 = first week of data)
    time_trend = as.integer(difftime(week, min(week), units = "weeks")),

    # "Time since invasion" interaction for ITS slope shift
    # = 0 in pre-invasion weeks; = weeks elapsed since invasion in post-invasion
    time_since_invasion = pmax(0, as.integer(
      difftime(week, invasion_date, units = "weeks")
    )) * post_invasion,

    # ---- Control dummies ----
    chatgpt_rollout = as.integer(week >= chatgpt_date),

    # Calendar quarter fixed effects (Q1 = omitted reference)
    quarter = factor(lubridate::quarter(week))
  )

# Quick sanity check
cat("=== Pre/Post Split ===\n")
cat("Pre-invasion weeks :", sum(df$post_invasion == 0), "\n")
cat("Post-invasion weeks:", sum(df$post_invasion == 1), "\n\n")

# =============================================================================
# 2. Descriptive: Before vs. After Comparison
# =============================================================================

cat("=== Descriptive Before/After Comparison ===\n")

before_after <- df |>
  group_by(post_invasion) |>
  summarise(
    period        = ifelse(first(post_invasion) == 0,
                           "Pre-2022 (2021 -- Feb 2022)",
                           "Post-2022 (Mar 2022 -- Jun 2025)"),
    n_weeks       = n(),
    mean_dig_share = round(mean(avg_digital_skill_share, na.rm = TRUE), 4),
    sd_dig_share   = round(sd(avg_digital_skill_share,   na.rm = TRUE), 4),
    mean_fatalities = round(mean(total_fatalities, na.rm = TRUE), 1),
    .groups = "drop"
  )

print(before_after)

# Two-sample t-test for difference in means
t_result <- t.test(
  avg_digital_skill_share ~ post_invasion,
  data = df,
  alternative = "two.sided"
)
cat("\nt-test: Pre vs. Post digital skill share\n")
cat(sprintf("  Mean pre : %.4f | Mean post: %.4f\n",
            t_result$estimate[1], t_result$estimate[2]))
cat(sprintf("  t = %.3f, df = %.1f, p-value = %.4f\n\n",
            t_result$statistic, t_result$parameter, t_result$p.value))

# =============================================================================
# 3. Formal Structural Break Tests
# =============================================================================

cat("=== 3. Formal Structural Break Tests ===\n\n")

# Formula used for break testing: outcome on simple time trend and controls
# (keeps it comparable to the paper's baseline; we include the controls
#  from the paper that don't require the continuous conflict variable)
formula_base <- avg_digital_skill_share ~ time_trend + chatgpt_rollout + quarter

# ---- 3a. Andrews sup-F test (unknown break date) ----------------------------
# Searches all break dates between 15% and 85% of the sample
cat("--- 3a. Andrews Sup-F Test (unknown breakpoint) ---\n")
fs <- strucchange::Fstats(formula_base, data = df, from = 0.15, to = 0.85)

supF_test <- sctest(fs, type = "supF")
cat(sprintf("  Sup-F statistic: %.3f  |  p-value: %.4f\n",
            supF_test$statistic, supF_test$p.value))

# Identify the date of the maximum F-statistic
break_idx_supF <- fs$breakpoint          # index in the trimmed range
cat(sprintf("  Break identified at index %d => week: %s\n\n",
            break_idx_supF, as.character(df$week[break_idx_supF])))

# ---- 3b. Chow test at the known invasion date (Feb 24, 2022) ----------------
# Find the sample fraction for Feb 24, 2022
invasion_idx  <- which(df$week >= invasion_date)[1]
invasion_frac <- invasion_idx / nrow(df)

cat("--- 3b. Chow Test (known break: Feb 24, 2022) ---\n")
cat(sprintf("  Break at observation %d (fraction = %.3f)\n",
            invasion_idx, invasion_frac))

# Chow test at the invasion observation using sctest.formula
# (sctest on an Fstats object only supports supF/aveF/expF, not Chow).
chow_sctest <- sctest(formula_base, data = df, type = "Chow", point = invasion_idx)
chow_F <- as.numeric(chow_sctest$statistic)
chow_p <- as.numeric(chow_sctest$p.value)
cat(sprintf("  Chow F-statistic: %.3f  |  p-value: %.4f\n\n", chow_F, chow_p))

# ---- 3c. CUSUM test ---------------------------------------------------------
cat("--- 3c. CUSUM Test (structural stability) ---\n")
cusum_test <- efp(formula_base, data = df, type = "OLS-CUSUM")
cusum_sctest <- sctest(cusum_test)
cat(sprintf("  CUSUM statistic: %.3f  |  p-value: %.4f\n\n",
            cusum_sctest$statistic, cusum_sctest$p.value))

# ---- 3d. Bai-Perron: unknown number and location of breaks -----------------
cat("--- 3d. Bai-Perron Multiple Structural Break Test ---\n")
bp_result <- strucchange::breakpoints(formula_base, data = df,
                                      h = 0.10)   # minimum 10% of obs per segment
print(summary(bp_result))

# Retrieve optimal number of breaks and their dates
# which.min(BIC()) returns 1-based position; BIC[1] = m=0, BIC[2] = m=1, etc.
opt_breaks <- which.min(BIC(bp_result)) - 1L   # convert to number of breaks (m)
if (opt_breaks > 0) {
  # Use the strucchange API (not direct slot access) to get indices for that m
  bp_indices <- breakpoints(bp_result, breaks = opt_breaks)$breakpoints
  bp_indices <- bp_indices[!is.na(bp_indices)]
  cat("Optimal breakpoints at weeks:\n")
  for (idx in bp_indices) {
    cat(sprintf("  Index %d => %s\n", idx, as.character(df$week[idx])))
  }
} else {
  cat("  No structural breaks detected by BIC criterion.\n")
}
cat("\n")

# =============================================================================
# 4. Regression Models: Continuous vs. Structural Break Specifications
# =============================================================================
# All models include quarter fixed effects and use HAC standard errors
# (Newey-West, 4 lags) to match the paper's original specification.

cat("=== 4. Regression Models ===\n\n")

# Helper: fit OLS and return coeftest with Newey-West HAC SE (4 lags)
hac_se <- function(model, lags = 4) {
  coeftest(model, vcov = NeweyWest(model, lag = lags, prewhite = FALSE))
}

# ---- Model 1: Paper baseline
m1 <- lm(avg_digital_skill_share ~ log_fatalities + quarter,
          data = df)

# ---- Model 2: Invasion dummy only (pure level-shift structural break) --------
m2 <- lm(avg_digital_skill_share ~ post_invasion + quarter,
          data = df)

# ---- Model 3: ITS (level shift + slope change at invasion) ------------------
m3 <- lm(avg_digital_skill_share ~
            time_trend + post_invasion + time_since_invasion + quarter,
          data = df)

# ---- Model 4: ITS + full controls (mirrors paper's richest specification) ---
m4 <- lm(avg_digital_skill_share ~
            time_trend + post_invasion + time_since_invasion +
            vacancy_count + chatgpt_rollout + avg_military_skill_share +
            quarter,
          data = df)

# ---- Model 5: ITS with both structural break + continuous regressor ---------
# Tests whether log(fatalities) still adds explanatory power conditional
# on the structural break being controlled for. This speaks directly to the
# reviewer's concern: if # the reviewer is right; if it remains significant, the continuous variation
# carries additional information beyond the break.
m5 <- lm(avg_digital_skill_share ~
            time_trend + post_invasion + time_since_invasion +
            log_fatalities +
            vacancy_count + chatgpt_rollout + avg_military_skill_share +
            quarter,
          data = df)

# Print HAC-corrected results for each model
for (m_obj in list(m1, m2, m3, m4, m5)) {
  cat("Formula:", deparse(formula(m_obj)), "\n")
  print(hac_se(m_obj))
  cat("R-squared:", round(summary(m_obj)$r.squared, 3), "\n\n")
}

# =============================================================================
# 5. Regression Table (for paper / response letter)
# =============================================================================

# Custom coefficient labels
coef_labels <- c(
  "log_fatalities"          = "Log(Fatalities)",
  "post_invasion"           = "Post-2022 (0/1)",
  "time_trend"              = "Linear Time Trend",
  "time_since_invasion"     = "Time Since 2022 (slope shift)",
  "vacancy_count"           = "Vacancy Count",
  "chatgpt_rollout"         = "ChatGPT Rollout (0/1)",
  "avg_military_skill_share"= "Military Skill Share",
  "(Intercept)"             = "Intercept"
)

# Build table with HAC SEs
models_list <- list(
  "(1) Baseline\n(Continuous)" = m1,
  "(2) Post-2022\nDummy"        = m2,
  "(3) ITS\n(Level+Slope)"     = m3,
  "(4) ITS +\nControls"        = m4,
  "(5) ITS +\nContinuous"      = m5
)

# vcov function for modelsummary using NeweyWest
nw_vcov <- function(x) NeweyWest(x, lag = 4, prewhite = FALSE)

# Save as LaTeX (.tex) for direct inclusion in the paper
table_notes <- paste(
  "HAC standard errors (Newey-West, 4 lags) in parentheses.",
  "Quarter fixed effects included in all models but not shown.",
  "Dependent variable: avg\\_digital\\_skill\\_share (weekly).",
  "Targeted date: Feb 24, 2022.",
  sep = " "
)

if (!exists("pkg_root")) pkg_root <- if (dir.exists(here::here("R"))) here::here() else here::here("code", "paper-analytics", "reproducibility_package")
tables_dir <- file.path(pkg_root, "output", "tables")
if (!dir.exists(tables_dir)) dir.create(tables_dir, recursive = TRUE)

# Use kableExtra backend: produces standard booktabs LaTeX (no tabularray/siunitx needed)
options(modelsummary_factory_latex = "kableExtra")

table_path <- file.path(tables_dir, "table_structural_break.tex")

# Capture LaTeX as string, inject \label after \caption, then write to file
tbl_latex <- modelsummary(
  models_list,
  vcov     = nw_vcov,
  coef_map = coef_labels,
  gof_map  = c("nobs", "r.squared", "adj.r.squared"),
  stars    = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title    = "Digital Skill Share Regressions: Continuous vs. Structural Break Specifications",
  notes    = table_notes,
  output   = "latex"
)

tbl_latex <- sub(
  "(\\\\caption\\{[^}]*\\})",
  "\\1\n\\\\label{tab:structural_break}",
  tbl_latex
)

writeLines(tbl_latex, table_path)
cat("Table saved to:", table_path, "\n\n")

# ---- Structural Break Test Statistics Table ---------------------------------
# Export Sup-F, Chow, and CUSUM test statistics as a small standalone LaTeX
# table for inclusion in the paper (e.g. as Table A0 or in the main text).

# Pre-extract every value as a guaranteed length-1 numeric scalar.
# Recompute Chow test using sctest.formula (supports type="Chow").
chow_sctest_tbl <- sctest(formula_base, data = df, type = "Chow", point = invasion_idx)
supF_stat_val  <- as.numeric(supF_test$statistic)
supF_pval_val  <- as.numeric(supF_test$p.value)
chow_stat_val  <- as.numeric(chow_sctest_tbl$statistic)
chow_pval_val  <- as.numeric(chow_sctest_tbl$p.value)
cusum_stat_val <- as.numeric(cusum_sctest$statistic)
cusum_pval_val <- as.numeric(cusum_sctest$p.value)

cat(sprintf(
  "Scalar lengths (all must be 1): supF=%d supF_p=%d chow=%d chow_p=%d cusum=%d cusum_p=%d\n",
  length(supF_stat_val), length(supF_pval_val),
  length(chow_stat_val), length(chow_pval_val),
  length(cusum_stat_val), length(cusum_pval_val)
))

break_tests_df <- data.frame(
  Test = c(
    "Andrews Sup-F (unknown break date)",
    "Chow test (Feb 24, 2022)",
    "CUSUM (OLS)"
  ),
  Statistic = c(
    round(supF_stat_val,  3),
    round(chow_stat_val,  3),
    round(cusum_stat_val, 3)
  ),
  `p-value` = c(
    format.pval(supF_pval_val,  digits = 3, eps = 0.001),
    format.pval(chow_pval_val,  digits = 3, eps = 0.001),
    format.pval(cusum_pval_val, digits = 3, eps = 0.001)
  ),
  `H0 rejected` = c(
    ifelse(supF_pval_val  < 0.05, "Yes", "No"),
    ifelse(chow_pval_val  < 0.05, "Yes", "No"),
    ifelse(cusum_pval_val < 0.05, "Yes", "No")
  ),
  check.names = FALSE
)

break_tests_latex <- kableExtra::kbl(
  break_tests_df,
  format   = "latex",
  booktabs = TRUE,
  align    = c("l", "r", "r", "c"),
  caption  = "Structural Break Test Statistics",
  label    = "break_tests"
) |>
  kableExtra::kable_styling(latex_options = c("hold_position")) |>
  kableExtra::footnote(
    general = paste(
      "Null hypothesis ($H_0$): parameter stability (no structural break).",
      "Sup-F and Chow tests use an $F$-distribution; CUSUM uses the",
      "Kolmogorov--Smirnov boundary. All tests estimated on",
      "\\\\texttt{avg\\\\_digital\\\\_skill\\\\_share} regressed on a linear",
      "time trend, ChatGPT rollout dummy, and quarter fixed effects.",
      "Break date for Chow test: February 24, 2022."
    ),
    general_title  = "",
    escape         = FALSE,
    threeparttable = TRUE
  )

break_tests_path <- file.path(tables_dir, "table_break_tests.tex")
writeLines(break_tests_latex, break_tests_path)
cat("Break tests table saved to:", break_tests_path, "\n\n")

# =============================================================================
# 6. Visualizations
# =============================================================================

cat("=== 6. Producing Figures ===\n")

if (!exists("pkg_root")) pkg_root <- if (dir.exists(here::here("R"))) here::here() else here::here("code", "paper-analytics", "reproducibility_package")
figures_dir <- file.path(pkg_root, "output", "figures")
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

# Theme for publication-quality plots
theme_paper <- theme_bw(base_size = 12) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold", size = 12),
    plot.caption     = element_text(size = 8, color = "grey50"),
    legend.position  = "bottom"
  )

# ---- Figure 1: Digital Skill Share over time with invasion break mark --------
fig1 <- ggplot(df, aes(x = as.Date(week), y = avg_digital_skill_share)) +
  geom_line(color = "steelblue", linewidth = 0.6) +
  geom_smooth(aes(group = factor(post_invasion)),
              method = "lm", se = TRUE, color = "firebrick",
              linewidth = 0.8, fill = "firebrick", alpha = 0.12) +
  geom_vline(xintercept = as.Date(invasion_date),
             linetype = "dashed", color = "black", linewidth = 0.8) +
  annotate("text", x = as.Date(invasion_date) + 20, y = max(df$avg_digital_skill_share) * 0.97,
           label = "Feb 24, 2022\n(Structural Break)", hjust = 0, size = 3.2) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  labs(
    title   = "Weekly Digital Skill Share with Structural Break (Feb 24, 2022)",
    x       = NULL,
    y       = "Avg. Digital Skill Share",
    caption = "Red lines: OLS trend fit separately for pre- and post-2022 periods. Shading = 95% CI."
  ) +
  theme_paper +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(figures_dir, "fig1_digital_share_structural_break.pdf"),
       fig1, width = 9, height = 5, device = "pdf")
ggsave(file.path(figures_dir, "fig1_digital_share_structural_break.png"),
       fig1, width = 9, height = 5, dpi = 300)
cat("Saved: fig1_digital_share_structural_break\n")

# ---- Figure 2: CUSUM plot ---------------------------------------------------
cusum_pdf <- file.path(figures_dir, "fig2_cusum_test.pdf")
pdf(cusum_pdf, width = 8, height = 5)
plot(cusum_test, main = "CUSUM Test for Parameter Stability\n(OLS Residuals)",
     xlab = "Observation", ylab = "Empirical Fluctuation Process",
     col = "steelblue", lwd = 1.5)
abline(v = invasion_frac, col = "firebrick", lty = 2, lwd = 1.5)
legend("topright", legend = c("CUSUM", "Feb 24, 2022", "5% boundary"),
       col = c("steelblue", "firebrick", "red"), lty = c(1, 2, 1), bty = "n")
dev.off()

cusum_png <- file.path(figures_dir, "fig2_cusum_test.png")
png(cusum_png, width = 8, height = 5, units = "in", res = 300)
plot(cusum_test, main = "CUSUM Test for Parameter Stability\n(OLS Residuals)",
     xlab = "Observation", ylab = "Empirical Fluctuation Process",
     col = "steelblue", lwd = 1.5)
abline(v = invasion_frac, col = "firebrick", lty = 2, lwd = 1.5)
legend("topright", legend = c("CUSUM", "Feb 24, 2022", "5% boundary"),
       col = c("steelblue", "firebrick", "red"), lty = c(1, 2, 1), bty = "n")
dev.off()
cat("Saved: fig2_cusum_test\n")

# ---- Figure 3: F-statistics across potential break dates -------------------
# Build the F-statistic data frame without relying on ts time() internals.
# as.numeric(fs$Fstats) flattens the full trimmed vector of F-statistics.
# We reconstruct matching observation indices by spacing evenly across the
# [from, to] trimming window (0.15f_vals  <- as.numeric(fs$Fstats)
obs_seq <- round(seq(ceiling(0.15 * nrow(df)),
                     floor(0.85 * nrow(df)),
                     length.out = length(f_vals)))
fs_df <- data.frame(
  week_approx = as.Date(df$week[obs_seq]),
  F_stat      = f_vals
)

fig3 <- ggplot(fs_df, aes(x = week_approx, y = F_stat)) +
  geom_line(color = "steelblue", linewidth = 0.8) +
  geom_vline(xintercept = as.Date(invasion_date),
             linetype = "dashed", color = "firebrick", linewidth = 0.9) +
  geom_hline(yintercept = fs_df$F_stat[which.max(fs_df$F_stat)],
             linetype = "dotted", color = "grey40") +
  annotate("text", x = as.Date(invasion_date) + 20,
           y = max(fs_df$F_stat) * 0.95,
           label = "Feb 24, 2022", hjust = 0, size = 3) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  labs(
    title   = "Andrews Sup-F: F-Statistics Across All Potential Break Dates",
    x       = NULL,
    y       = "F-Statistic",
    caption = "Dashed line: Feb 24, 2022 (structural break). Sup-F test for unknown structural break."
  ) +
  theme_paper +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(figures_dir, "fig3_supF_breakpoints.pdf"),
       fig3, width = 9, height = 5, device = "pdf")
ggsave(file.path(figures_dir, "fig3_supF_breakpoints.png"),
       fig3, width = 9, height = 5, dpi = 300)
cat("Saved: fig3_supF_breakpoints\n")

# ---- Figure 4: ITS fitted values vs. actuals --------------------------------
df_its <- df |>
  mutate(
    fitted_its  = fitted(m3),
    fitted_base = fitted(m1)
  )

fig4 <- df_its |>
  select(week, avg_digital_skill_share, fitted_its, fitted_base) |>
  pivot_longer(-week, names_to = "series", values_to = "value") |>
  mutate(series = case_match(series,
    "avg_digital_skill_share" ~ "Observed",
    "fitted_its"              ~ "ITS Model (level + slope)",
    "fitted_base"             ~ "Baseline (continuous fatalities)"
  )) |>
  ggplot(aes(x = as.Date(week), y = value, color = series, linetype = series)) +
  geom_line(linewidth = 0.7) +
  geom_vline(xintercept = as.Date(invasion_date),
             linetype = "dashed", color = "black", linewidth = 0.7) +
  scale_color_manual(values = c(
    "Observed"                          = "grey50",
    "ITS Model (level + slope)"         = "firebrick",
    "Baseline (continuous fatalities)"  = "steelblue"
  )) +
  scale_linetype_manual(values = c(
    "Observed"                          = "solid",
    "ITS Model (level + slope)"         = "solid",
    "Baseline (continuous fatalities)"  = "dashed"
  )) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  labs(
    title   = "Fitted Values: ITS Structural Break Model vs. Continuous Regressor Baseline",
    x       = NULL,
    y       = "Avg. Digital Skill Share",
    color   = NULL, linetype = NULL,
    caption = "Vertical dashed line: Feb 24, 2022. Quarter FEs included in both models."
  ) +
  theme_paper +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave(file.path(figures_dir, "fig4_its_fitted_vs_actual.pdf"),
       fig4, width = 9, height = 5, device = "pdf")
ggsave(file.path(figures_dir, "fig4_its_fitted_vs_actual.png"),
       fig4, width = 9, height = 5, dpi = 300)
cat("Saved: fig4_its_fitted_vs_actual\n\n")

# =============================================================================
# 7. Summary for Reviewer Response
# =============================================================================

cat("=== 7. Summary for Reviewer Response ===\n\n")

cat("STRUCTURAL BREAK TESTS:\n")
cat(sprintf("  Andrews Sup-F : stat = %.3f, p = %.4f  => %s\n",
            supF_test$statistic, supF_test$p.value,
            ifelse(supF_test$p.value < 0.05, "REJECT stability (break exists)", "Cannot reject stability")))
cat(sprintf("  Chow test at Feb 24, 2022: F = %.3f, p = %.4f  => %s\n",
            chow_F, chow_p,
            ifelse(chow_p < 0.05, "REJECT structural stability", "Cannot reject")))
cat(sprintf("  CUSUM test   : stat = %.3f, p = %.4f  => %s\n\n",
            cusum_sctest$statistic, cusum_sctest$p.value,
            ifelse(cusum_sctest$p.value < 0.05, "REJECT stability", "Cannot reject stability")))

cat("ITS MODEL (Model 3: level + slope shift):\n")
its_coef <- hac_se(m3)
post_row  <- its_coef["post_invasion", ]
slope_row <- its_coef["time_since_invasion", ]
cat(sprintf("  Level shift (post_invasion)     : coef = %+.4f, p = %.4f\n",
            post_row[1], post_row[4]))
cat(sprintf("  Slope shift (time_since_invasion): coef = %+.6f, p = %.4f\n",
            slope_row[1], slope_row[4]))
cat(sprintf("  R-squared: %.3f\n\n", summary(m3)$r.squared))

cat("MODEL 5 (continuous + structural break):\n")
m5_coef <- hac_se(m5)
if ("log_fatalities" %in% rownames(m5_coef)) {
  cf_row <- m5_coef["log_fatalities", ]
  cat(sprintf("  log(Fatalities): coef = %+.4f, p = %.4f\n", cf_row[1], cf_row[4]))
  cat("  Interpretation: If p > 0.05, continuous regressor adds no information beyond\n")
  cat("  the structural break -- the reviewer's concern is confirmed.\n")
  cat("  If p < 0.05, both approaches capture distinct variation (complementary).\n\n")
}

cat("Figures saved to:", figures_dir, "\n")
cat("\n=== 03_structural_break.R complete. ===\n")
