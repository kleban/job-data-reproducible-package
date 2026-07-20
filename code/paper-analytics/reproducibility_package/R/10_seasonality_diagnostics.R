# =============================================================================
# Ukraine Research Working Paper
# Script: 10_seasonality_diagnostics.R
# Purpose: Address reviewer comment that the inclusion of seasonal (quarter)
#          dummies is not adequately justified and that diagnostic tools such
#          as time-series plots or autocorrelation functions are needed to
#          establish whether seasonal patterns are present.
#
# Three complementary diagnostics are produced:
#
#   1. Quarterly mean plots
#      Raw weekly values of avg_digital_skill_share and log_fatalities are
#      averaged by calendar quarter (Q1-Q4) within each year and plotted as
#      bar charts. Systematic variation across quarters within years is prima
#      facie evidence of seasonality.
#
#   2. ACF/PACF plots
#      Autocorrelation and partial-autocorrelation functions of the raw and
#      quarter-demeaned residuals of avg_digital_skill_share.  Peaks at lags
#      13, 26, 39 (multiples of ~13 weeks = one quarter) indicate quarterly
#      periodicity. After quarter demeaning the peaks should disappear,
#      confirming the dummies absorb the seasonal signal.
#
#   3. Formal seasonality tests
#      (a) Kruskal-Wallis test: non-parametric test of equal distributions
#          across the four quarters. Rejection implies quarter-correlated
#          variation.
#      (b) F-test for joint significance of quarter dummies in an OLS
#          regression of each series on Q2, Q3, Q4 (Q1 omitted).
#      (c) Friedman test on the within-year quarter means: tests whether the
#          seasonal profile is consistent across years.
#      Results are tabulated and exported as LaTeX.
#
# Exports:
#   fig_seasonal_means.png/.pdf    #   fig_acf_raw.png/.pdf           #   fig_acf_demeaned.png/.pdf      #   table_seasonality_tests.tex    # =============================================================================

# -----------------------------------------------------------------------------
# 0. Setup
# -----------------------------------------------------------------------------

packages_needed <- c(
  "here",
  "arrow", "tidyverse", "lubridate",
  "sandwich", "lmtest", "car",
  "kableExtra",
  "janitor", "forecast",
  "patchwork"
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
  library(sandwich); library(lmtest); library(car)
  library(kableExtra); library(janitor); library(forecast)
  library(patchwork)
})

if (!exists("pkg_root")) pkg_root <- if (dir.exists(here::here("R"))) here::here() else here::here("code", "paper-analytics", "reproducibility_package")
tables_dir  <- file.path(pkg_root, "output", "tables")
figures_dir <- file.path(pkg_root, "output", "figures")
if (!dir.exists(tables_dir))  dir.create(tables_dir,  recursive = TRUE)
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

theme_paper <- theme_bw(base_size = 11) +
  theme(
    panel.grid.minor = element_blank(),
    strip.background = element_blank(),
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
  arrange(week) |>
  mutate(
    log_fatalities = log1p(total_fatalities),
    quarter        = lubridate::quarter(week),
    year           = lubridate::year(week),
    quarter_label  = paste0("Q", quarter),
    # week index for ts objects
    week_idx       = row_number()
  )

cat("Data loaded:", nrow(df), "weeks\n")
cat("Coverage   :", as.character(min(df$week)), "to",
    as.character(max(df$week)), "\n\n")

#Check data coverage
nrow(df)

# Check year coverage
df |> 
  count(year) |> 
  print()

# Check the earliest weeks specifically
df |> 
  arrange(week) |> 
  select(week, year, quarter) |> 
  head(10)

# Check how many observations are in 2020
df |> 
  filter(year == 2020) |> 
  select(week, year, quarter, avg_digital_skill_share, log_fatalities) |> 
  print()

# =============================================================================
# 2. Quarterly Mean Plots
# =============================================================================
# Average each series by calendar quarter within each year.
# Consistent Q1/Q2/Q3/Q4 ordering within years is evidence of seasonality.

cat("=== 2. Quarterly Mean Plots ===\n\n")

qmeans <- df |>
  group_by(year, quarter, quarter_label) |>
  summarise(
    digital_share = mean(avg_digital_skill_share, na.rm = TRUE),
    log_fat       = mean(log_fatalities,          na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(quarter_label = factor(quarter_label, levels = paste0("Q", 1:4)))

# --- 2a. Digital skill share by quarter --------------------------------------
p_qmean_dig <- ggplot(qmeans,
                      aes(x = quarter_label, y = digital_share,
                          fill = quarter_label)) +
  geom_col(width = 0.6, show.legend = FALSE) +
  facet_wrap(~ year, nrow = 1) +
  scale_fill_brewer(palette = "Blues", direction = 1) +
  labs(
    x = "Calendar quarter",
    y = "Mean digital skill share"
  ) +
  theme_paper +
  theme(axis.text.x = element_text(size = 8))

# --- 2b. Log fatalities by quarter --------------------------------------------
p_qmean_fat <- ggplot(qmeans,
                      aes(x = quarter_label, y = log_fat,
                          fill = quarter_label)) +
  geom_col(width = 0.6, show.legend = FALSE) +
  facet_wrap(~ year, nrow = 1) +
  scale_fill_brewer(palette = "Reds", direction = 1) +
  labs(
    x = "Calendar quarter",
    y = "Mean log(1 + fatalities)"
  ) +
  theme_paper +
  theme(axis.text.x = element_text(size = 8))

# --- 2c. Combine into one figure (two rows) -----------------------------------
p_seasonal <- (p_qmean_dig / p_qmean_fat) +
  plot_annotation(tag_levels = "A",
                  theme = theme(plot.tag = element_text(face = "bold")))

ggsave(file.path(figures_dir, "fig_seasonal_means.pdf"),
       p_seasonal, width = 10, height = 5.5, device = cairo_pdf)
ggsave(file.path(figures_dir, "fig_seasonal_means.png"),
       p_seasonal, width = 10, height = 5.5, dpi = 300)
cat("fig_seasonal_means saved\n\n")

# =============================================================================
# 3. ACF / PACF Plots
# =============================================================================
# Inspect autocorrelation in levels and after quarter-demeaning.
# Quarterly periodicity in a weekly series appears at multiples of ~13 weeks.

cat("=== 3. ACF / PACF Plots ===\n\n")

y_raw <- df$avg_digital_skill_share

# Quarter-demeaned residuals: remove quarter group means
quarter_means <- df |>
  group_by(quarter) |>
  summarise(qmean = mean(avg_digital_skill_share, na.rm = TRUE), .groups = "drop")
df <- df |> left_join(quarter_means, by = "quarter")
y_demeaned <- df$avg_digital_skill_share - df$qmean

MAX_LAG_ACF <- 52L   # one full year of weekly lags

save_acf_plot <- function(series, title, fname_stem, max_lag = MAX_LAG_ACF) {

  acf_obj  <- acf( series, lag.max = max_lag, plot = FALSE, na.action = na.pass)
  pacf_obj <- pacf(series, lag.max = max_lag, plot = FALSE, na.action = na.pass)

  ci <- qnorm(0.975) / sqrt(length(na.omit(series)))

  acf_df <- data.frame(
    lag  = as.numeric(acf_obj$lag[-1]),
    acf  = as.numeric(acf_obj$acf[-1]),
    type = "ACF"
  )
  pacf_df <- data.frame(
    lag  = as.numeric(pacf_obj$lag),
    acf  = as.numeric(pacf_obj$acf),
    type = "PACF"
  )
  plot_df <- bind_rows(acf_df, pacf_df) |>
    mutate(type = factor(type, levels = c("ACF", "PACF")))

  # Mark lags that are multiples of 13 (quarterly)
  quarterly_lags <- seq(13, max_lag, by = 13)

  p <- ggplot(plot_df, aes(x = lag, y = acf)) +
    geom_hline(yintercept = 0,   colour = "grey40") +
    geom_hline(yintercept =  ci, linetype = "dashed", colour = "#e41a1c", linewidth = 0.4) +
    geom_hline(yintercept = -ci, linetype = "dashed", colour = "#e41a1c", linewidth = 0.4) +
    geom_vline(xintercept = quarterly_lags, colour = "grey80",
               linetype = "dotted", linewidth = 0.4) +
    geom_segment(aes(xend = lag, yend = 0), linewidth = 0.5, colour = "#2166ac") +
    geom_point(size = 1.2, colour = "#2166ac") +
    facet_wrap(~ type, ncol = 1, scales = "free_y") +
    scale_x_continuous(
      breaks = c(1, quarterly_lags),
      labels = c(1, paste0("13k\n(Q", seq_along(quarterly_lags), ")"))
    ) +
    labs(x = "Lag (weeks)", y = "Correlation", subtitle = title) +
    theme_paper +
    theme(axis.text.x = element_text(size = 7))

  ggsave(file.path(figures_dir, paste0(fname_stem, ".pdf")),
         p, width = 7, height = 4)
  ggsave(file.path(figures_dir, paste0(fname_stem, ".png")),
         p, width = 7, height = 4, dpi = 300)
  cat(fname_stem, "saved\n")
  invisible(p)
}

save_acf_plot(y_raw,      "Raw digital skill share",           "fig_acf_raw")
save_acf_plot(y_demeaned, "Quarter-demeaned digital skill share", "fig_acf_demeaned")
cat("\n")

# =============================================================================
# 4. Formal Seasonality Tests
# =============================================================================

cat("=== 4. Formal Seasonality Tests ===\n\n")

# --- 4a. Kruskal-Wallis test: equal distributions across quarters ------------
# H0: the distribution of avg_digital_skill_share is the same in all four quarters.
kw_dig <- kruskal.test(avg_digital_skill_share ~ factor(quarter), data = df)
kw_fat <- kruskal.test(log_fatalities           ~ factor(quarter), data = df)

cat(sprintf("Kruskal-Wallis (digital share): H = %.3f, df = %d, p = %.4f\n",
            kw_dig$statistic, kw_dig$parameter, kw_dig$p.value))
cat(sprintf("Kruskal-Wallis (log fatalities): H = %.3f, df = %d, p = %.4f\n\n",
            kw_fat$statistic, kw_fat$parameter, kw_fat$p.value))

# --- 4b. F-test: joint significance of quarter dummies in OLS ----------------
# Regress each series on Q2, Q3, Q4 (Q1 is omitted reference category)
# and test the null that all three dummies are jointly zero.
f_dig_mod <- lm(avg_digital_skill_share ~ factor(quarter), data = df)
f_fat_mod <- lm(log_fatalities           ~ factor(quarter), data = df)

f_dig <- linearHypothesis(
  f_dig_mod,
  c("factor(quarter)2 = 0", "factor(quarter)3 = 0", "factor(quarter)4 = 0"),
  vcov. = vcovHC(f_dig_mod, type = "HC3")
)
f_fat <- linearHypothesis(
  f_fat_mod,
  c("factor(quarter)2 = 0", "factor(quarter)3 = 0", "factor(quarter)4 = 0"),
  vcov. = vcovHC(f_fat_mod, type = "HC3")
)

f_dig_stat <- f_dig[2, "F"]
f_dig_p    <- f_dig[2, "Pr(>F)"]
f_fat_stat <- f_fat[2, "F"]
f_fat_p    <- f_fat[2, "Pr(>F)"]

cat(sprintf("F-test joint Q dummies (digital share):  F(3,N) = %.3f, p = %.4f\n",
            f_dig_stat, f_dig_p))
cat(sprintf("F-test joint Q dummies (log fatalities): F(3,N) = %.3f, p = %.4f\n\n",
            f_fat_stat, f_fat_p))

# --- 4c. Friedman test on within-year quarterly profiles ---------------------
# Requires a balanced year # Use only years with complete Q1-Q4 data.
qmat_df <- qmeans |>
  select(year, quarter, digital_share) |>
  pivot_wider(names_from = quarter, values_from = digital_share,
              names_prefix = "Q") |>
  drop_na()

if (nrow(qmat_df) >= 3) {
  qmat <- as.matrix(qmat_df[, paste0("Q", 1:4)])
  friedman_res <- friedman.test(qmat)
  fr_stat <- as.numeric(friedman_res$statistic)
  fr_p    <- as.numeric(friedman_res$p.value)
  cat(sprintf("Friedman test (within-year quarterly profile): chi2 = %.3f, p = %.4f\n\n",
              fr_stat, fr_p))
} else {
  fr_stat <- NA_real_; fr_p <- NA_real_
  cat("Friedman test skipped: fewer than 3 complete years available.\n\n")
}

# =============================================================================
# 5. Export LaTeX Table of Test Statistics
# =============================================================================

cat("=== 5. Exporting seasonality test table ===\n\n")

fmt_p <- function(p) {
  if (is.na(p)) return("---")
  if (p < 0.001) return("$<$0.001")
  sprintf("%.3f", p)
}

fmt_stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) return("***")
  if (p < 0.05) return("**")
  if (p < 0.10) return("*")
  return("")
}

tests_df <- data.frame(
  Test = c(
    "Kruskal--Wallis ($H_0$: equal distribution across quarters)",
    "F-test: joint significance of Q2, Q3, Q4 dummies",
    "Friedman ($H_0$: no consistent seasonal profile across years)"
  ),
  Series = c(
    "Digital skill share",
    "Digital skill share",
    "Digital skill share"
  ),
  Statistic = c(
    sprintf("$H$ = %.2f", kw_dig$statistic),
    sprintf("$F(3,\\,N)$ = %.2f", f_dig_stat),
    ifelse(is.na(fr_stat), "---", sprintf("$\\chi^2$ = %.2f", fr_stat))
  ),
  p_value = c(
    paste0(fmt_p(kw_dig$p.value), fmt_stars(kw_dig$p.value)),
    paste0(fmt_p(f_dig_p),        fmt_stars(f_dig_p)),
    paste0(fmt_p(fr_p),           fmt_stars(fr_p))
  ),
  stringsAsFactors = FALSE
)

# Add log_fatalities rows
fat_rows <- data.frame(
  Test = c(
    "Kruskal--Wallis ($H_0$: equal distribution across quarters)",
    "F-test: joint significance of Q2, Q3, Q4 dummies"
  ),
  Series = c("Log(1 + fatalities)", "Log(1 + fatalities)"),
  Statistic = c(
    sprintf("$H$ = %.2f", kw_fat$statistic),
    sprintf("$F(3,\\,N)$ = %.2f", f_fat_stat)
  ),
  p_value = c(
    paste0(fmt_p(kw_fat$p.value), fmt_stars(kw_fat$p.value)),
    paste0(fmt_p(f_fat_p),        fmt_stars(f_fat_p))
  ),
  stringsAsFactors = FALSE
)

tbl_data <- bind_rows(tests_df, fat_rows) |>
  arrange(Test, Series) |>
  rename(
    " "         = Test,
    "Series"    = Series,
    "Statistic" = Statistic,
    "$p$-value" = p_value
  )

season_latex <- kableExtra::kbl(
  tbl_data,
  format   = "latex",
  booktabs = TRUE,
  align    = c("l", "l", "r", "r"),
  caption  = "Seasonality Diagnostics: Tests for Quarterly Patterns",
  label    = "seasonality",
  escape   = FALSE
) |>
  kableExtra::kable_styling(latex_options = "hold_position") |>
  kableExtra::footnote(
    general = paste(
      "The Kruskal--Wallis test is a non-parametric test of the null hypothesis",
      "that the distribution of the series is identical across the four calendar",
      "quarters. The $F$-test is the joint significance test of Q2, Q3, Q4",
      "dummies in OLS (HC3 robust standard errors; Q1 is the omitted category).",
      "The Friedman test evaluates whether the within-year seasonal profile",
      "(quarterly means) is consistent across years; it requires a balanced",
      "year $\\\\times$ quarter panel and is reported for the digital skill share only.",
      "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$."
    ),
    general_title  = "",
    escape         = FALSE,
    threeparttable = TRUE
  )

season_path <- file.path(tables_dir, "table_seasonality_tests.tex")
writeLines(season_latex, season_path)
cat("Seasonality test table saved to:", season_path, "\n")

# =============================================================================
# 6. Console Summary
# =============================================================================

cat("\n=== 6. Summary ===\n\n")
cat(sprintf("Digital skill share             KW p=%.4f  F p=%.4f  FR p=%s\n",
            kw_dig$p.value, f_dig_p, ifelse(is.na(fr_p), "N/A", sprintf("%.4f", fr_p))))
cat(sprintf("Log fatalities                  KW p=%.4f  F p=%.4f\n",
            kw_fat$p.value, f_fat_p))

cat("Interpretation guide:\n")
cat("  p < 0.05 on KW or F-test => quarterly variation is statistically significant\n")
cat("  ACF peaks at lags 13, 26, 39 in raw series => quarterly periodicity present\n")
cat("  ACF peaks absent after quarter-demeaning   => quarter FEs absorb the signal\n\n")

cat("Figures saved to  :", figures_dir, "\n")
cat("Tables  saved to  :", tables_dir,  "\n")
cat("\n=== 10_seasonality_diagnostics.R complete ===\n")
