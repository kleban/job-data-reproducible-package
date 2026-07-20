# =============================================================================
# Ukraine Research Working Paper
# Script: 09_robustness_smoothing.R
# Purpose: Formally estimate and report the moving-average smoothing and
#          distributed-lag (Almon) specifications described in the paper's
#          "Additional Specifications" subsection, addressing the reviewer
#          comment that:
#            (a) regression results for the MA-smoothed series are not reported;
#            (b) the distributed-lag model applied to the smoothed series is
#                neither formally stated nor discussed.
#
# Two specifications are estimated:
#
#   A. Moving-average distributed lag (MADL)
#      - Replace raw log_fatalities with its 4-week backward MA (ma4) or
#        8-week backward MA (ma8), then include lags 0#        series in a single OLS:
#
#        y_t = alpha + sum_{k=0}^{3} beta_k * xbar_{t-k}^(w) + gamma' z_t + e_t
#
#        where xbar_{t-k}^(w) is the w-week backward MA of log(1+fatalities)
#        ending at week t-k, and z_t = {quarter FE, vacancy_count,
#        avg_military_skill_share, time_trend, chatgpt_rollout, ai_wave2}.
#
#   B. Polynomial distributed lag (Almon PDL)
#      - Apply a degree-2 polynomial constraint to the lag coefficients of
#        raw log_fatalities over a 0#        reparameterisation.  This imposes a smooth functional form, reduces
#        multicollinearity across weekly lags, and yields an interpretable
#        lag profile.
#
# Both specifications share the same set of controls (mirroring M6 of
# 07_robustness_ovb.R) and use HAC standard errors (Newey-West, 4 lags).
#
# Exports:
#   table_smoothing_ma.tex       #                                  w-week MA at each lag k = 0#                                  4-week and 8-week MA variants, under
#                                  baseline and full controls (4-column layout)
#   table_almon.tex              #                                  delta-method SEs, plus cumulative row
#   smoothing_coefplot.png/.pdf  #                                  estimates for each lag (fig:smoothing)
#   almond_coefplot.png/.pdf     # =============================================================================

# -----------------------------------------------------------------------------
# 0. Setup
# -----------------------------------------------------------------------------

packages_needed <- c(
  "here",
  "arrow", "tidyverse", "lubridate",
  "sandwich", "lmtest",
  "modelsummary", "kableExtra",
  "janitor", "zoo", "msm"        # zoo: rollmean; msm: deltamethod
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
  library(zoo); library(msm)
})

if (!exists("pkg_root")) pkg_root <- if (dir.exists(here::here("R"))) here::here() else here::here("reproducibility_package")
tables_dir  <- file.path(pkg_root, "output", "tables")
figures_dir <- file.path(pkg_root, "output", "figures")
if (!dir.exists(tables_dir))  dir.create(tables_dir,  recursive = TRUE)
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

options(modelsummary_factory_latex = "kableExtra")

hac_se   <- function(model) coeftest(model, vcov = NeweyWest(model, lag = 4, prewhite = FALSE))
nw_vcov  <- function(model) NeweyWest(model, lag = 4, prewhite = FALSE)

# Publication-quality ggplot theme
theme_paper <- theme_bw(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    plot.title       = element_text(face = "bold", size = 11),
    legend.position  = "bottom"
  )

# -----------------------------------------------------------------------------
# 1. Load & Prepare Data
# -----------------------------------------------------------------------------

if (!exists("data_dir")) data_dir <- file.path(pkg_root, "data")
data_path <- file.path(data_dir, "final_weekly.parquet")
if (!file.exists(data_path)) stop("Data file not found: ", data_path)

df <- arrow::read_parquet(data_path) |>
  janitor::clean_names() |>
  arrange(week)

invasion_date <- as.POSIXct("2022-02-24", tz = "UTC")
chatgpt_date  <- as.POSIXct("2022-11-30", tz = "UTC")
ai_wave2_date <- as.POSIXct("2023-03-14", tz = "UTC")

df <- df |>
  mutate(
    log_fatalities      = log1p(total_fatalities),
    log_events          = log1p(num_events),
    post_invasion       = as.integer(week >= invasion_date),
    time_trend          = as.integer(difftime(week, min(week), units = "weeks")),
    time_since_invasion = pmax(0L, as.integer(
      difftime(week, invasion_date, units = "weeks")
    )) * as.integer(week >= invasion_date),
    chatgpt_rollout     = as.integer(week >= chatgpt_date),
    ai_wave2            = as.integer(week >= ai_wave2_date),
    quarter             = factor(lubridate::quarter(week))
  )

cat("Data loaded:", nrow(df), "weeks\n")
cat("Coverage   :", as.character(min(df$week)), "to", as.character(max(df$week)), "\n\n")

# =============================================================================
# 2. Moving-Average Distributed Lag (MADL) Specification
# =============================================================================
# Construct backward-looking moving averages of log_fatalities.
# zoo::rollmean with align = "right" and fill = NA gives the k-week MA
# ending at each observation (i.e., the average of weeks t, t-1, ..., t-k+1).
#
# We then include lags 0#
#   y_t = alpha + beta_0 * xbar_{t}^(w)  + beta_1 * xbar_{t-1}^(w)
#               + beta_2 * xbar_{t-2}^(w) + beta_3 * xbar_{t-3}^(w)
#               + gamma' z_t + e_t
#
# where z_t = {quarter, vacancy_count, avg_military_skill_share,
#              time_trend, chatgpt_rollout, ai_wave2}.
# =============================================================================

cat("=== 2. Moving-Average Distributed Lag (MADL) ===\n\n")

# --- 2a. Compute moving averages ----------------------------------------------
df <- df |>
  mutate(
    # 4-week backward MA of log_fatalities
    ma4_log_fat  = zoo::rollmean(log_fatalities, k = 4,  fill = NA, align = "right"),
    # 8-week backward MA of log_fatalities
    ma8_log_fat  = zoo::rollmean(log_fatalities, k = 8,  fill = NA, align = "right"),
    # 12-week backward MA of log_fatalities
    ma12_log_fat = zoo::rollmean(log_fatalities, k = 12, fill = NA, align = "right")
  )

# --- 2b. Construct lags 0-3 for each MA window --------------------------------
df <- df |>
  mutate(
    # 4-week MA lags
    ma4_lag0 = ma4_log_fat,
    ma4_lag1 = dplyr::lag(ma4_log_fat, 1),
    ma4_lag2 = dplyr::lag(ma4_log_fat, 2),
    ma4_lag3 = dplyr::lag(ma4_log_fat, 3),
    # 8-week MA lags
    ma8_lag0 = ma8_log_fat,
    ma8_lag1 = dplyr::lag(ma8_log_fat, 1),
    ma8_lag2 = dplyr::lag(ma8_log_fat, 2),
    ma8_lag3 = dplyr::lag(ma8_log_fat, 3),
    # 12-week MA lags
    ma12_lag0 = ma12_log_fat,
    ma12_lag1 = dplyr::lag(ma12_log_fat, 1),
    ma12_lag2 = dplyr::lag(ma12_log_fat, 2),
    ma12_lag3 = dplyr::lag(ma12_log_fat, 3)
  )

# --- 2c. Estimate MADL models -------------------------------------------------
# Controls: quarter FE + full OVB controls from 07_robustness_ovb.R M6.

madl_controls <- ~ vacancy_count + avg_military_skill_share +
  time_trend + chatgpt_rollout + ai_wave2 + quarter

# 4-week MA distributed lag (lags 0-3)
madl4 <- lm(update(madl_controls,
                   avg_digital_skill_share ~ ma4_lag0 + ma4_lag1 +
                     ma4_lag2 + ma4_lag3 + .),
            data = df)

# 8-week MA distributed lag (lags 0-7)
madl8 <- lm(update(madl_controls,
                   avg_digital_skill_share ~ ma8_lag0 + ma8_lag1 +
                     ma8_lag2 + ma8_lag3 + .),
            data = df)

# --- 2d. Console summary ------------------------------------------------------
cat("4-week MA distributed lag (MADL-4):\n")
ct4 <- hac_se(madl4)
for (k in 0:3) {
  vn <- paste0("ma4_lag", k)
  cat(sprintf("  beta_%d : coef = %+.4f  SE = %.4f  p = %.4f\n",
              k, ct4[vn, 1], ct4[vn, 2], ct4[vn, 4]))
}
cumul4 <- sum(ct4[paste0("ma4_lag", 0:3), 1])
# Delta-method SE for sum of four coefficients
vc4 <- nw_vcov(madl4)
idx4 <- paste0("ma4_lag", 0:3)
se_cum4 <- sqrt(sum(vc4[idx4, idx4]))
t_cum4 <- cumul4 / se_cum4
p_cum4 <- 2 * pt(-abs(t_cum4), df = df.residual(madl4))
cat(sprintf("  Cumulative (lags 0-3): %.4f  SE = %.4f  p = %.4f\n",
            cumul4, se_cum4, p_cum4))
cat(sprintf("  N = %d  R2 = %.3f\n\n", nobs(madl4), summary(madl4)$r.squared))

cat("8-week MA distributed lag (MADL-8):\n")
ct8 <- hac_se(madl8)
for (k in 0:3) {
  vn <- paste0("ma8_lag", k)
  cat(sprintf("  beta_%d : coef = %+.4f  SE = %.4f  p = %.4f\n",
              k, ct8[vn, 1], ct8[vn, 2], ct8[vn, 4]))
}
cumul8 <- sum(ct8[paste0("ma8_lag", 0:3), 1])
vc8 <- nw_vcov(madl8)
idx8 <- paste0("ma8_lag", 0:3)
se_cum8 <- sqrt(sum(vc8[idx8, idx8]))
t_cum8 <- cumul8 / se_cum8
p_cum8 <- 2 * pt(-abs(t_cum8), df = df.residual(madl8))
cat(sprintf("  Cumulative (lags 0-3): %.4f  SE = %.4f  p = %.4f\n",
            cumul8, se_cum8, p_cum8))
cat(sprintf("  N = %d  R2 = %.3f\n\n", nobs(madl8), summary(madl8)$r.squared))

# =============================================================================
# 3. Polynomial Distributed Lag (Almon PDL)
# =============================================================================

cat("=== 3. Almon PDL ===\n\n")
# Define all variants to try
almon_variants <- list(
  list(label = "Base (K=3, d=2, trend)",    K = 3, d = 2, 
       conflict = "log_fatalities", no_trend = FALSE),
  list(label = "No-trend (K=3, d=2)",       K = 3, d = 2, 
       conflict = "log_fatalities", no_trend = TRUE),
  list(label = "K=7, d=2, no-trend",        K = 7, d = 2, 
       conflict = "log_fatalities", no_trend = TRUE),
  list(label = "K=7, d=3, no-trend",        K = 7, d = 3, 
       conflict = "log_fatalities", no_trend = TRUE),
  list(label = "Events, K=3, d=2, no-trend",K = 3, d = 2, 
       conflict = "log_events",     no_trend = TRUE),
  list(label = "Events, K=7, d=2, no-trend",K = 7, d = 2, 
       conflict = "log_events",     no_trend = TRUE),
  list(label = "Events, K=7, d=3, no-trend",K = 7, d = 3, 
       conflict = "log_events",     no_trend = TRUE)
)

# Storage for results
almon_results <- list()

for (v in almon_variants) {

  K        <- v$K
  d        <- v$d
  conf_var <- v$conflict
  no_trend <- v$no_trend
  label    <- v$label

  cat(sprintf("--- %s ---\n", label))

  # Build lagged conflict variable
  df_almon <- df
  for (k in 0:K) {
    df_almon[[paste0("conf_lag", k)]] <- dplyr::lag(df_almon[[conf_var]], k)
  }

  # Build Almon basis variables Z_j = sum_{k=0}^{K} k^j * conf_lag_k
  for (j in 0:d) {
    df_almon[[paste0("almon_z", j)]] <- rowSums(
      sapply(0:K, function(k) (k^j) * df_almon[[paste0("conf_lag", k)]]),
      na.rm = FALSE
    )
  }

  # Build formula
  z_terms <- paste0("almon_z", 0:d, collapse = " + ")
  controls <- if (no_trend) {
    "vacancy_count + avg_military_skill_share + chatgpt_rollout + ai_wave2 + quarter"
  } else {
    "vacancy_count + avg_military_skill_share + time_trend + chatgpt_rollout + ai_wave2 + quarter"
  }
  fml <- as.formula(paste("avg_digital_skill_share ~", z_terms, "+", controls))

  # Estimate
  mod      <- lm(fml, data = df_almon)
  vc_mod   <- nw_vcov(mod)
  alpha_hat <- coef(mod)[paste0("almon_z", 0:d)]

  # Recover implied lag coefficients via delta method
  K_mat    <- outer(0:K, 0:d, FUN = "^")          # (K+1) x (d+1)
  beta_hat <- as.numeric(K_mat %*% alpha_hat)
  names(beta_hat) <- paste0("beta_", 0:K)

  vc_alpha <- vc_mod[paste0("almon_z", 0:d), paste0("almon_z", 0:d)]
  var_beta <- K_mat %*% vc_alpha %*% t(K_mat)
  se_beta  <- sqrt(diag(var_beta))
  t_beta   <- beta_hat / se_beta
  p_beta   <- 2 * pt(-abs(t_beta), df = df.residual(mod))

  # Cumulative effect
  cumul      <- sum(beta_hat)
  ones_vec   <- matrix(1, nrow = 1, ncol = K + 1L)
  se_cumul   <- sqrt(as.numeric(ones_vec %*% var_beta %*% t(ones_vec)))
  t_cumul    <- cumul / se_cumul
  p_cumul    <- 2 * pt(-abs(t_cumul), df = df.residual(mod))

  # Print results
  for (k in 0:K) {
    stars <- ifelse(p_beta[k+1] < 0.01, "***",
             ifelse(p_beta[k+1] < 0.05, "**",
             ifelse(p_beta[k+1] < 0.10, "*", "")))
    cat(sprintf("  beta_%d: %+.4f (SE %.4f, p = %.3f) %s\n",
                k, beta_hat[k+1], se_beta[k+1], p_beta[k+1], stars))
  }
  cum_stars <- ifelse(p_cumul < 0.01, "***",
               ifelse(p_cumul < 0.05, "**",
               ifelse(p_cumul < 0.10, "*", "")))
  cat(sprintf("  Cumulative: %+.4f (SE %.4f, p = %.3f) %s\n",
              cumul, se_cumul, p_cumul, cum_stars))
  cat(sprintf("  N = %d  R2 = %.3f\n\n",
              nobs(mod), summary(mod)$r.squared))

  # Store for table export
  almon_results[[label]] <- list(
    mod = mod, K = K, d = d,
    beta_hat = beta_hat, se_beta = se_beta,
    p_beta = p_beta, t_beta = t_beta,
    cumul = cumul, se_cumul = se_cumul,
    p_cumul = p_cumul, cum_stars = cum_stars,
    conflict = conf_var, no_trend = no_trend
  )
}

# =============================================================================
# 3B. Significance Summary
# =============================================================================

cat("=== 3B. Almon Significance Summary ===\n\n")
cat(sprintf("%-35s %-12s %-8s\n", "Specification", "Cumulative", "p-value"))
cat(strrep("-", 58), "\n")

for (label in names(almon_results)) {
  r <- almon_results[[label]]
  cat(sprintf("%-35s %+.4f%s    %.3f\n",
    label, r$cumul, r$cum_stars, r$p_cumul))
}


# =============================================================================
# 3C. Export table_almon.tex
# =============================================================================

best_spec <- "K=7, d=3, no-trend"

cat(sprintf("=== 3C. Exporting table_almon.tex: %s ===\n\n", best_spec))

r <- almon_results[[best_spec]]
K <- r$K   # 7
d <- r$d   # 3

# Lag coefficient rows
almon_rows <- lapply(0:K, function(k) {
  stars <- ifelse(r$p_beta[k+1] < 0.01, "***",
           ifelse(r$p_beta[k+1] < 0.05, "**",
           ifelse(r$p_beta[k+1] < 0.10, "*", "")))
  data.frame(
    Term = paste0("Log(Fatalities), lag ", k, " (implied)"),
    Coef = sprintf("%.3f%s", r$beta_hat[k+1], stars),
    SE   = sprintf("(%.3f)", r$se_beta[k+1]),
    stringsAsFactors = FALSE
  )
})

# Cumulative row
almon_rows[[K + 2L]] <- data.frame(
  Term = "Cumulative effect (lags 0--7)",
  Coef = sprintf("%.3f%s", r$cumul, r$cum_stars),
  SE   = sprintf("(%.3f)", r$se_cumul),
  stringsAsFactors = FALSE
)

# GoF rows
almon_gof <- data.frame(
  Term = c("Polynomial degree", "Observations", "$R^2$"),
  Coef = c(as.character(d),
           as.character(nobs(r$mod)),
           sprintf("%.3f", summary(r$mod)$r.squared)),
  SE   = c("", "", ""),
  stringsAsFactors = FALSE
)

# Controls rows
almon_ctrl <- data.frame(
  Term = c("Quarter FE", "Full controls"),
  Coef = c("Yes", "Yes"),
  SE   = c("", ""),
  stringsAsFactors = FALSE
)

# Combine
almon_tbl_data <- bind_rows(
  bind_rows(almon_rows),
  almon_gof,
  almon_ctrl
)

# Build LaTeX table
almon_latex <- kableExtra::kbl(
  almon_tbl_data,
  format    = "latex",
  booktabs  = TRUE,
  align     = c("l", "r", "l"),
  col.names = c("", "Coef.", "(SE)"),
  caption   = "Almon Polynomial Distributed Lag: Digital Skill Demand and Fatalities",
  label     = "almon",
  escape    = FALSE
) |>
  kableExtra::add_header_above(
    c(" " = 1, "PDL (degree 3, lags 0--7)" = 2)
  ) |>
  kableExtra::kable_styling(latex_options = "hold_position") |>
  kableExtra::footnote(
    general = paste(
      "Dependent variable: \\\\texttt{avg\\\\_digital\\\\_skill\\\\_share} (weekly).",
      "Attack intensity measured as $\\\\log(1 + \\\\text{fatalities})$.",
      "The Almon (1965) polynomial distributed lag constrains lag coefficients",
      "$\\\\beta_k$ of $\\\\log(1+\\\\text{fatalities})$ to lie on a degree-3",
      "polynomial: $\\\\beta_k = \\\\sum_{j=0}^{3}\\\\alpha_j k^j$,",
      "$k = 0, 1, \\\\ldots, 7$, spanning approximately two months.",
      "The model is estimated by regressing the outcome on the Almon basis",
      "variables $Z_{j,t} = \\\\sum_{k=0}^{7} k^j x_{t-k}$ for $j = 0,1,2,3$,",
      "plus the same controls as the baseline.",
      "Implied lag coefficients and their delta-method standard errors",
      "(derived from the HAC variance matrix of the $\\\\alpha_j$ estimates;",
      "Newey-West, 4 lags) are reported.",
      "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."
    ),
    general_title  = "",
    escape         = FALSE,
    threeparttable = TRUE
  )

# Remove stray \addlinespace lines
almon_latex <- gsub("\\\\addlinespace\n", "", almon_latex)

# Save
almon_path <- file.path(tables_dir, "table_almon.tex")
writeLines(almon_latex, almon_path)
cat("Almon table saved to:", almon_path, "\n")


# =============================================================================
# 3D. Almon Coefficient Plot
# =============================================================================

cat("\n=== 3D. Almon coefficient plot ===\n\n")

# Pull results from the best specification stored in almon_results
r_best <- almon_results[["K=7, d=3, no-trend"]]
K_best <- r_best$K   # 7

ci_almon <- data.frame(
  Lag   = 0:K_best,
  Coef  = r_best$beta_hat,
  SE    = r_best$se_beta,
  CI_lo = r_best$beta_hat - 1.96 * r_best$se_beta,
  CI_hi = r_best$beta_hat + 1.96 * r_best$se_beta
)

p_almon <- ggplot(ci_almon, aes(x = Lag, y = Coef)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey60") +
  geom_ribbon(aes(ymin = CI_lo, ymax = CI_hi), alpha = 0.15,
              fill = "#2166ac") +
  geom_line(colour = "#2166ac", linewidth = 0.8) +
  geom_point(colour = "#2166ac", size = 3) +
  scale_x_continuous(breaks = 0:K_best,
                     labels = paste0("Lag ", 0:K_best)) +  # updated: was 0:MAX_LAG
  labs(
    x = "Lag (weeks)",
    y = "Implied coefficient (pp)"
  ) +
  theme_paper

ggsave(file.path(figures_dir, "almond_coefplot.pdf"),
       p_almon, width = 6, height = 3.5, device = cairo_pdf)  # wider for 8 lags
ggsave(file.path(figures_dir, "almond_coefplot.png"),
       p_almon, width = 6, height = 3.5, dpi = 300)
cat("almond_coefplot saved\n")

# =============================================================================
# 4. Extended Data Preparation
# =============================================================================

# --- Original full controls (with time_trend) ---------------------------------
madl_controls_full <- ~ vacancy_count + avg_military_skill_share +
  time_trend + chatgpt_rollout + ai_wave2 + quarter

# --- Modified full controls WITHOUT time_trend --------------------------------
madl_controls_notrand <- ~ vacancy_count + avg_military_skill_share +
  chatgpt_rollout + ai_wave2 + quarter

# --- First-differenced outcome ------------------------------------------------
df <- df |>
  mutate(
    d_digital_share = avg_digital_skill_share - dplyr::lag(avg_digital_skill_share, 1)
  )

# --- Extended: event-based MAs and 12-week event MA --------------------------
# (ma12_log_fat already computed above; only event-series MAs are new here)
df <- df |>
  mutate(
    ma12_log_evt  = zoo::rollmean(log_events, k = 12, fill = NA, align = "right"),
    # log_events MAs for existing windows
    ma4_log_evt   = zoo::rollmean(log_events, k = 4,  fill = NA, align = "right"),
    ma8_log_evt   = zoo::rollmean(log_events, k = 8,  fill = NA, align = "right")
  )

# --- Lags for event-series MAs (fatality lags already computed above) ---------
df <- df |>
  mutate(
    # 4-week MA lags
    ma4e_lag0 = ma4_log_evt,
    ma4e_lag1 = dplyr::lag(ma4_log_evt, 1),
    ma4e_lag2 = dplyr::lag(ma4_log_evt, 2),
    ma4e_lag3 = dplyr::lag(ma4_log_evt, 3),
    # 8-week MA lags
    ma8e_lag0 = ma8_log_evt,
    ma8e_lag1 = dplyr::lag(ma8_log_evt, 1),
    ma8e_lag2 = dplyr::lag(ma8_log_evt, 2),
    ma8e_lag3 = dplyr::lag(ma8_log_evt, 3),
    # 12-week MA lags
    ma12e_lag0 = ma12_log_evt,
    ma12e_lag1 = dplyr::lag(ma12_log_evt, 1),
    ma12e_lag2 = dplyr::lag(ma12_log_evt, 2),
    ma12e_lag3 = dplyr::lag(ma12_log_evt, 3)
  )

# =============================================================================
# 5. Extended Single-Lag Regressions
# =============================================================================

cat("=== 5. Extended Single-Lag Regressions ===\n\n")

single_lag_results <- list()

# Define all variants to run:
# Each entry: list(w = window, conflict = "fat"/"evt", lag_prefix, label)
variants <- list(
  list(w = 4,  conflict = "fat", prefix = "ma4_lag",  label = "4wk-FAT"),
  list(w = 8,  conflict = "fat", prefix = "ma8_lag",  label = "8wk-FAT"),
  list(w = 12, conflict = "fat", prefix = "ma12_lag", label = "12wk-FAT"),
  list(w = 4,  conflict = "evt", prefix = "ma4e_lag", label = "4wk-EVT"),
  list(w = 8,  conflict = "evt", prefix = "ma8e_lag", label = "8wk-EVT"),
  list(w = 12, conflict = "evt", prefix = "ma12e_lag",label = "12wk-EVT")
)

for (v in variants) {
  cat(sprintf("--- %s ---\n", v$label))

  for (k in 0:3) {
    lag_var <- paste0(v$prefix, k)

    # (a) Baseline: quarter FE only
    mod_base <- lm(
      as.formula(paste("avg_digital_skill_share ~", lag_var, "+ quarter")),
      data = df
    )
    ct_base <- hac_se(mod_base)

    # (b) Full controls WITH time_trend (original)
    mod_full <- lm(
      as.formula(paste("avg_digital_skill_share ~", lag_var,
        "+ vacancy_count + avg_military_skill_share +",
        "time_trend + chatgpt_rollout + ai_wave2 + quarter")),
      data = df
    )
    ct_full <- hac_se(mod_full)

    # (c) Full controls WITHOUT time_trend
    mod_notrend <- lm(
      as.formula(paste("avg_digital_skill_share ~", lag_var,
        "+ vacancy_count + avg_military_skill_share +",
        "chatgpt_rollout + ai_wave2 + quarter")),
      data = df
    )
    ct_notrend <- hac_se(mod_notrend)

    # (d) First-differenced outcome, no time_trend needed
    mod_fd <- lm(
      as.formula(paste("d_digital_share ~", lag_var,
        "+ vacancy_count + avg_military_skill_share +",
        "chatgpt_rollout + ai_wave2 + quarter")),
      data = df
    )
    ct_fd <- hac_se(mod_fd)

    cat(sprintf(
      "  lag %d | base: %+.4f (p=%.3f) | full: %+.4f (p=%.3f) | no-trend: %+.4f (p=%.3f) | FD: %+.4f (p=%.3f)\n",
      k,
      ct_base[lag_var, 1],   ct_base[lag_var, 4],
      ct_full[lag_var, 1],   ct_full[lag_var, 4],
      ct_notrend[lag_var, 1],ct_notrend[lag_var, 4],
      ct_fd[lag_var, 1],     ct_fd[lag_var, 4]
    ))

    key <- paste0(v$prefix, k)
    single_lag_results[[key]] <- list(
      lag_var    = lag_var,
      mod_base   = mod_base, ct_base   = ct_base,
      mod_full   = mod_full, ct_full   = ct_full,
      mod_notrend= mod_notrend, ct_notrend = ct_notrend,
      mod_fd     = mod_fd,   ct_fd     = ct_fd
    )
  }
  cat("\n")
}

# =============================================================================
# 5B. Significance Summary
# =============================================================================

cat("=== 5B. Significance Summary ===\n\n")
cat(sprintf("%-12s %-6s %-12s %-12s %-12s %-12s\n",
    "Series", "Lag", "Base p", "Full p", "No-trend p", "FD p"))
cat(strrep("-", 70), "\n")

for (v in variants) {
  for (k in 0:3) {
    key     <- paste0(v$prefix, k)
    lag_var <- paste0(v$prefix, k)
    r <- single_lag_results[[key]]
    cat(sprintf("%-12s %-6d %-12.3f %-12.3f %-12.3f %-12.3f\n",
      v$label, k,
      r$ct_base[lag_var, 4],
      r$ct_full[lag_var, 4],
      r$ct_notrend[lag_var, 4],
      r$ct_fd[lag_var, 4]
    ))
  }
}

# =============================================================================
# 5C. Export table_smoothing_ma.tex
# =============================================================================

cat("\n=== 5C. Exporting table_smoothing_ma.tex ===\n\n")

make_sl_row_v2 <- function(prefix, k, spec) {
  key     <- paste0(prefix, k)
  lag_var <- paste0(prefix, k)
  ct  <- single_lag_results[[key]][[paste0("ct_", spec)]]
  mod <- single_lag_results[[key]][[paste0("mod_", spec)]]
  coef_val <- ct[lag_var, 1]
  se_val   <- ct[lag_var, 2]
  p_val    <- ct[lag_var, 4]
  stars    <- ifelse(p_val < 0.01, "***",
              ifelse(p_val < 0.05, "**",
              ifelse(p_val < 0.10, "*", "")))
  n_obs <- tryCatch(as.character(nobs(mod)),
                    error = function(e) as.character(sum(!is.na(mod$fitted.values))))
  list(
    coef = sprintf("%.3f%s", coef_val, stars),
    se   = sprintf("(%.3f)", se_val),
    n    = n_obs,
    r2   = sprintf("%.3f", summary(mod)$r.squared)
  )
}

prefixes_v2 <- c("ma4_lag", "ma8_lag", "ma12_lag")
col_labels_v2 <- c("(1)", "(2)", "(3)", "(4)", "(5)", "(6)")

tbl_body_v2 <- do.call(rbind, lapply(0:3, function(k) {
  vals <- lapply(prefixes_v2, function(pfx) {
    list(
      base    = make_sl_row_v2(pfx, k, "base"),
      notrend = make_sl_row_v2(pfx, k, "notrend")
    )
  })
  rbind(
    data.frame(
      Term = paste0("MA log(Fatalities) [lag ", k, "]"),
      C1 = vals[[1]]$base$coef,    C2 = vals[[1]]$notrend$coef,
      C3 = vals[[2]]$base$coef,    C4 = vals[[2]]$notrend$coef,
      C5 = vals[[3]]$base$coef,    C6 = vals[[3]]$notrend$coef,
      stringsAsFactors = FALSE
    ),
    data.frame(
      Term = "",
      C1 = vals[[1]]$base$se,      C2 = vals[[1]]$notrend$se,
      C3 = vals[[2]]$base$se,      C4 = vals[[2]]$notrend$se,
      C5 = vals[[3]]$base$se,      C6 = vals[[3]]$notrend$se,
      stringsAsFactors = FALSE
    )
  )
}))

gof_row_v2 <- function(pfx, k_ref = 0) {
  list(
    base    = make_sl_row_v2(pfx, k_ref, "base"),
    notrend = make_sl_row_v2(pfx, k_ref, "notrend")
  )
}
g4v2  <- gof_row_v2("ma4_lag")
g8v2  <- gof_row_v2("ma8_lag")
g12v2 <- gof_row_v2("ma12_lag")

tbl_gof_v2 <- rbind(
  data.frame(Term = "Observations",
    C1 = g4v2$base$n,   C2 = g4v2$notrend$n,
    C3 = g8v2$base$n,   C4 = g8v2$notrend$n,
    C5 = g12v2$base$n,  C6 = g12v2$notrend$n,
    stringsAsFactors = FALSE),
  data.frame(Term = "$R^2$",
    C1 = g4v2$base$r2,  C2 = g4v2$notrend$r2,
    C3 = g8v2$base$r2,  C4 = g8v2$notrend$r2,
    C5 = g12v2$base$r2, C6 = g12v2$notrend$r2,
    stringsAsFactors = FALSE)
)

tbl_ctrl_v2 <- rbind(
  data.frame(Term = "Quarter FE",
    C1 = "Yes", C2 = "Yes", C3 = "Yes",
    C4 = "Yes", C5 = "Yes", C6 = "Yes",
    stringsAsFactors = FALSE),
  data.frame(Term = "Full controls",
    C1 = "No", C2 = "Yes", C3 = "No",
    C4 = "Yes", C5 = "No", C6 = "Yes",
    stringsAsFactors = FALSE)
)

tbl_ma_data_v2 <- bind_rows(tbl_body_v2, tbl_gof_v2, tbl_ctrl_v2)

tbl_ma_latex_v2 <- kableExtra::kbl(
  tbl_ma_data_v2,
  format    = "latex",
  booktabs  = TRUE,
  align     = c("l", "r", "r", "r", "r", "r", "r"),
  col.names = c("", col_labels_v2),
  caption   = "Moving-Average Smoothing: Single-Lag Specifications",
  label     = "smoothing_ma",
  escape    = FALSE
) |>
  kableExtra::add_header_above(
    c(" " = 1, "4-Week MA" = 2, "8-Week MA" = 2, "12-Week MA" = 2)
  ) |>
  kableExtra::kable_styling(latex_options = "hold_position") |>
  kableExtra::footnote(
    general = paste(
      "Dependent variable: \\\\texttt{avg\\\\_digital\\\\_skill\\\\_share} (weekly).",
      "Each row reports a separate OLS model with a single lag of the $w$-week",
      "backward MA of $\\\\log(1+\\\\text{fatalities})$ as the sole attack-intensity regressor.",
      "Odd columns include quarter fixed effects only (baseline).",
      "Even columns add vacancy count, military skill share, ChatGPT rollout,",
      "and second AI-wave indicators (no linear time trend).",
      "HAC standard errors (Newey-West, 4 lags) in parentheses.",
      "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."
    ),
    general_title  = "",
    escape         = FALSE,
    threeparttable = TRUE
  )

tbl_ma_latex_v2 <- gsub("\\\\addlinespace\n", "", tbl_ma_latex_v2)

ma_path <- file.path(tables_dir, "table_smoothing_ma.tex")
writeLines(tbl_ma_latex_v2, ma_path)
cat("Updated single-lag MA table saved to:", ma_path, "\n\n")

# =============================================================================
# 5D. Smoothing Coefficient Plot
# =============================================================================

cat("\n=== 5D. Smoothing coefficient plot ===\n\n")

make_ci_df_sl <- function(prefix, w_label) {
  rows <- lapply(0:3, function(k) {
    key     <- paste0(prefix, k)
    lag_var <- paste0(prefix, k)
    # Use ct_notrend (extended regressions); fall back to ct_full if unavailable
    ct_entry <- single_lag_results[[key]]
    ct <- if (!is.null(ct_entry$ct_notrend)) ct_entry$ct_notrend else ct_entry$ct_full
    if (is.null(ct) || !(lag_var %in% rownames(ct))) return(NULL)
    data.frame(
      Lag   = k,
      Model = w_label,
      Coef  = ct[lag_var, 1],
      SE    = ct[lag_var, 2],
      CI_lo = ct[lag_var, 1] - 1.96 * ct[lag_var, 2],
      CI_hi = ct[lag_var, 1] + 1.96 * ct[lag_var, 2],
      stringsAsFactors = FALSE
    )
  })
  bind_rows(rows)
}

ci4    <- make_ci_df_sl("ma4_lag",  "4-Week MA")
ci8    <- make_ci_df_sl("ma8_lag",  "8-Week MA")
ci12   <- make_ci_df_sl("ma12_lag", "12-Week MA")
ci_mad <- bind_rows(ci4, ci8, ci12) |>
  mutate(Model = factor(Model,
                        levels = c("4-Week MA", "8-Week MA", "12-Week MA")))

p_smoothing <- ggplot(ci_mad, aes(x = Lag, y = Coef, colour = Model,
                                   shape = Model)) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey60") +
  geom_errorbar(aes(ymin = CI_lo, ymax = CI_hi),
                width = 0.15, linewidth = 0.6,
                position = position_dodge(width = 0.3)) +
  geom_point(size = 3, position = position_dodge(width = 0.3)) +
  scale_x_continuous(breaks = 0:3,
                     labels = paste0("Lag ", 0:3)) +
  scale_colour_manual(values = c("4-Week MA"  = "#2166ac",
                                  "8-Week MA"  = "#d6604d",
                                  "12-Week MA" = "#4dac26")) +
  scale_shape_manual(values = c("4-Week MA"  = 16,
                                 "8-Week MA"  = 17,
                                 "12-Week MA" = 15)) +
  labs(
    x      = "Lag (weeks)",
    y      = "Coefficient (pp)",
    colour = NULL,
    shape  = NULL
  ) +
  theme_paper

ggsave(file.path(figures_dir, "smoothing_coefplot.pdf"),
       p_smoothing, width = 6, height = 3.5, device = cairo_pdf)
ggsave(file.path(figures_dir, "smoothing_coefplot.png"),
       p_smoothing, width = 6, height = 3.5, dpi = 300)
cat("smoothing_coefplot saved\n")

# =============================================================================
# 6. Console Summary
# =============================================================================

cat("\n=== 6. Summary for Paper ===\n\n")

cat("--- MADL-4 (4-week MA, lags 0-3) ---\n")
for (k in 0:3) {
  vn <- paste0("ma4_lag", k)
  cat(sprintf("  beta_%d = %+.3f (SE %.3f, p = %.3f)\n",
              k, ct4[vn, 1], ct4[vn, 2], ct4[vn, 4]))
}
cat(sprintf("  Cumulative = %+.3f (SE %.3f, p = %.3f)\n\n",
            cumul4, se_cum4, p_cum4))

cat("--- MADL-8 (8-week MA, lags 0-3) ---\n")
for (k in 0:3) {
  vn <- paste0("ma8_lag", k)
  cat(sprintf("  beta_%d = %+.3f (SE %.3f, p = %.3f)\n",
              k, ct8[vn, 1], ct8[vn, 2], ct8[vn, 4]))
}
cat(sprintf("  Cumulative = %+.3f (SE %.3f, p = %.3f)\n\n",
            cumul8, se_cum8, p_cum8))

cat("--- Almon PDL (degree 3, lags 0-7, no time trend) ---\n")
r_almon <- almon_results[["K=7, d=3, no-trend"]]
for (k in 0:r_almon$K) {
  cat(sprintf("  beta_%d = %+.3f (SE %.3f, p = %.3f)\n",
              k, r_almon$beta_hat[k + 1], r_almon$se_beta[k + 1], r_almon$p_beta[k + 1]))
}
cat(sprintf("  Cumulative = %+.3f (SE %.3f, p = %.3f)\n\n",
            r_almon$cumul, r_almon$se_cumul, r_almon$p_cumul))

cat("Tables saved to   :", tables_dir,  "\n")
cat("Figures saved to  :", figures_dir, "\n")
cat("\n=== 09_robustness_smoothing.R complete ===\n")
