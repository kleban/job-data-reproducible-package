# =============================================================================
# Ukraine Research Working Paper
# Script: 06_decomposition.R
# Purpose: Address Reviewer Comment on Ratio Confounding
#
# Reviewer Comment:
#   "An increase in the digital skill share may reflect a rise in demand for
#    digital skills, but it may also result from a collapse in non-digital
#    demand. In the context of a war that destroys physical capital, displaces
#    workers, and disproportionately affects non-digital sectors, the latter
#    explanation is highly plausible. The paper does not disentangle these
#    mechanisms."
#
# Response strategy:
#   Decompose avg_digital_skill_share into its numerator and denominator:
#     - Numerator  : total_digital_skills  (raw count of digital postings)
#     - Denominator: vacancy_count         (total job postings)
#
#   If conflict drives GENUINE upskilling   ? numerator rises, denominator stable
#   If conflict drives SECTOR COLLAPSE      ? denominator falls, numerator stable
#   If both mechanisms operate              ? both move; share still rises
#
#   We estimate the same ITS specifications on all three outcomes and export
#   a single side-by-side LaTeX table for direct comparison.
#
# Exports:
#   table_decomposition.tex  #   table_digital_count.tex  # =============================================================================

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

invasion_date <- as.POSIXct("2022-02-24", tz = "UTC")
chatgpt_date  <- as.POSIXct("2022-11-30", tz = "UTC")

df <- df |>
  arrange(week) |>
  mutate(
    # Conflict variables
    log_fatalities      = log1p(total_fatalities),
    post_invasion       = as.integer(week >= invasion_date),
    time_trend          = as.integer(difftime(week, min(week), units = "weeks")),
    time_since_invasion = pmax(0L, as.integer(
      difftime(week, invasion_date, units = "weeks")
    )) * as.integer(week >= invasion_date),
    chatgpt_rollout     = as.integer(week >= chatgpt_date),
    quarter             = factor(lubridate::quarter(week)),

    # Decomposition outcomes
    log_digital         = log1p(total_digital_skills),           # numerator (log)
    log_vacancy         = log1p(vacancy_count),                  # denominator (log)
    log_fatalities      = log1p(total_fatalities)
  )

cat("Data loaded:", nrow(df), "weeks\n")
cat("Coverage:", as.character(min(df$week)), "to", as.character(max(df$week)), "\n\n")

#Check
df |> select(week, total_digital_skills, vacancy_count) |> summary()
df |> filter(week >= as.POSIXct("2022-01-01")) |> 
  select(week, total_digital_skills, vacancy_count) |> 
  summary()

# =============================================================================
# 2. Descriptive: Plot numerator, denominator, non-digital over time
# =============================================================================

cat("=== 2. Descriptive Plots ===\n\n")

plot_df <- df |>
  select(week, total_digital_skills, vacancy_count) |>
  pivot_longer(-week, names_to = "series", values_to = "value") |>
  mutate(series = case_match(series,
    "total_digital_skills" ~ "Digital postings (numerator)",
    "vacancy_count"        ~ "Total postings (denominator)"
  ))

p_decomp <- ggplot(plot_df, aes(x = as.Date(week), y = value, colour = series)) +
  geom_line(linewidth = 0.7) +
  geom_vline(xintercept = as.Date(invasion_date), linetype = "dashed",
             colour = "red", linewidth = 0.8) +
  geom_vline(xintercept = as.Date(chatgpt_date), linetype = "dotted",
             colour = "blue", linewidth = 0.8) +
  annotate("text", x = as.Date(invasion_date) + 20, y = Inf,
           label = "Feb 2022", colour = "red", vjust = 1.5, hjust = 0, size = 3) +
  annotate("text", x = as.Date(chatgpt_date) + 20, y = Inf,
           label = "ChatGPT", colour = "blue", vjust = 1.5, hjust = 0, size = 3) +
  facet_wrap(~series, scales = "free_y", ncol = 1) +
  scale_colour_manual(values = c("steelblue", "darkorange"))+
  labs(
    title   = "Decomposition of Digital Skill Share: Numerator vs. Denominator",
    x       = NULL,
    y       = "Count",
    colour  = NULL,
    caption = "Dashed = targeted date; dotted = ChatGPT rollout"
  ) +
  theme_bw(base_size = 11) +
  theme(legend.position = "none",
        strip.background = element_rect(fill = "grey92"),
        strip.text = element_text(face = "bold"))

ggsave(file.path(figures_dir, "fig_decomposition_linear.pdf"), p_decomp,
       width = 8, height = 9, device = cairo_pdf)
ggsave(file.path(figures_dir, "fig_decomposition_linear.png"), p_decomp,
       width = 8, height = 9, dpi = 300)
cat("Decomposition figure (linear scale) saved.\n\n")


# =============================================================================
# 2.b Descriptive: Plot numerator, denominator, non-digital over time (log scale)
# =============================================================================

cat("=== 2.b Descriptive Plots (log scale) ===\n\n")

plot_df <- df |>
  select(week, total_digital_skills, vacancy_count) |>
  pivot_longer(-week, names_to = "series", values_to = "value") |>
  mutate(series = case_match(series,
    "total_digital_skills" ~ "Digital postings (numerator)",
    "vacancy_count"        ~ "Total postings (denominator)"
  ))

p_decomp <- ggplot(plot_df, aes(x = as.Date(week), y = value, colour = series)) +
  geom_line(linewidth = 0.7) +
  geom_vline(xintercept = as.Date(invasion_date), linetype = "dashed",
             colour = "red", linewidth = 0.8) +
  geom_vline(xintercept = as.Date(chatgpt_date), linetype = "dotted",
             colour = "blue", linewidth = 0.8) +
  annotate("text", x = as.Date(invasion_date) + 20, y = Inf,
           label = "Feb 2022", colour = "red", vjust = 1.5, hjust = 0, size = 3) +
  annotate("text", x = as.Date(chatgpt_date) + 20, y = Inf,
           label = "ChatGPT", colour = "blue", vjust = 1.5, hjust = 0, size = 3) +
  facet_wrap(~series, scales = "free_y", ncol = 1) +
  scale_y_continuous(
    trans  = "log1p",
    labels = scales::comma,
    breaks = c(500, 1000, 5000, 10000, 50000, 100000)
  ) +
  scale_colour_manual(values = c("steelblue", "darkorange")) +
  labs(
    title   = "Decomposition of Digital Skill Share: Numerator vs. Denominator",
    x       = NULL,
    y       = "Count (log scale)",
    colour  = NULL,
    caption = "Dashed = targeted date; dotted = ChatGPT rollout. Y-axis on log(1+x) scale."
  ) +
  theme_bw(base_size = 11) +
  theme(legend.position = "none",
        strip.background = element_rect(fill = "grey92"),
        strip.text = element_text(face = "bold"))

ggsave(file.path(figures_dir, "fig_decomposition.pdf"), p_decomp,
       width = 8, height = 9, device = cairo_pdf)
ggsave(file.path(figures_dir, "fig_decomposition.png"), p_decomp,
       width = 8, height = 9, dpi = 300)
cat("Decomposition figure (log scale) saved.\n\n")

cat("=== 3. Decomposition Regressions ===\n\n")

# We estimate three parallel ITS specifications, one for each outcome:
#   (A) log(total_digital_skills)  #   (B) log(vacancy_count)         #   (C) log(non_digital_count)     #
# Key interpretation:
#   If invasion raises (A) and leaves (B)/(C) unchanged ? genuine upskilling
#   If invasion lowers (B) and (C) but leaves (A) unchanged ? non-digital collapse
#   Both effects can coexist; the share decomposition separates them.

# ---- Specification: ITS + full controls (matches paper's main model) --------

# Numerator: log(digital postings)
dig_m1 <- lm(log_digital ~ log_fatalities + quarter, data = df)
dig_m2 <- lm(log_digital ~ post_invasion + time_since_invasion + quarter, data = df)
dig_m3 <- lm(log_digital ~ post_invasion + time_since_invasion +
               log_fatalities + vacancy_count + chatgpt_rollout +
               avg_military_skill_share + time_trend + quarter,
             data = df)

# Denominator: log(total vacancies)
vac_m1 <- lm(log_vacancy ~ log_fatalities + quarter, data = df)
vac_m2 <- lm(log_vacancy ~ post_invasion + time_since_invasion + quarter, data = df)
vac_m3 <- lm(log_vacancy ~ post_invasion + time_since_invasion +
               log_fatalities + chatgpt_rollout +
               avg_military_skill_share + time_trend + quarter,
             data = df)

# Print HAC results for key models
cat("--- Numerator: log(digital postings) ---\n")
print(hac_se(dig_m3))
cat("\n--- Denominator: log(total vacancies) ---\n")
print(hac_se(vac_m3))
cat("\n")

# =============================================================================
# 4. Export: Side-by-side decomposition table
# =============================================================================

cat("=== 4. Export LaTeX Tables ===\n\n")

# ---- Table A: Baseline specs (log-fatalities) for all three outcomes --------

decomp_coef_labels <- c(
  "log_fatalities"         = "Log(Fatalities)",
  "post_invasion"          = "Post-2022",
  "time_since_invasion"    = "Time Since 2022",
  "chatgpt_rollout"        = "ChatGPT Rollout",
  "avg_military_skill_share" = "Military Skill Share",
  "time_trend"             = "Time Trend",
  "vacancy_count"          = "Vacancy Count",
  "(Intercept)"            = "Intercept"
)

# Panel A: Baseline (log-fatalities only + quarter)
panel_a <- list(
  "Digital (numerator)"  = dig_m1,
  "Total (denominator)"  = vac_m1
)

# Panel B: ITS (post-invasion + trend since)
panel_b <- list(
  "Digital (numerator)"  = dig_m2,
  "Total (denominator)"  = vac_m2
)

# Panel C: Full controls
panel_c <- list(
  "Digital (numerator)"  = dig_m3,
  "Total (denominator)"  = vac_m3
)

decomp_notes <- paste(
  "Dependent variables: log(1 + total digital skill postings) [numerator] and",
  "log(1 + total vacancy count) [denominator].",
  "These models decompose the digital skill share into its numerator and denominator",
  "to distinguish genuine upskilling from a collapse in overall labour demand.",
  "HAC standard errors (Newey-West, 4 lags) in parentheses.",
  "Quarter fixed effects included in all models but not shown.",
  sep = " "
)

# Export Panel C (full controls) as the main decomposition table
decomp_tbl_latex <- modelsummary(
  panel_c,
  vcov     = nw_vcov,
  coef_map = decomp_coef_labels,
  gof_map  = c("nobs", "r.squared", "adj.r.squared"),
  stars    = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title    = "Decomposition of Digital Skill Share: Numerator and Denominator Regressions",
  notes    = decomp_notes,
  output   = "latex",
  escape   = FALSE
)

decomp_tbl_latex <- sub(
  "(\\\\caption\\{[^}]*\\})",
  "\\1\n\\\\label{tab:decomposition}",
  decomp_tbl_latex
)

decomp_tbl_latex <- gsub(
  "\\multicolumn{3}{l}{\\rule{0pt}{1em}",
  "\\multicolumn{3}{p{11cm}}{\\footnotesize\\rule{0pt}{1em}",
  decomp_tbl_latex,
  fixed = TRUE
)

writeLines(decomp_tbl_latex, file.path(tables_dir, "table_decomposition.tex"))
cat("Decomposition table (full controls) saved.\n\n")

# ---- Table B: All three panels (baseline / ITS / full) for digital only ----
# Useful as a robustness check on the numerator across specifications

digital_all_latex <- modelsummary(
  list(
    "(1) Fatalities"  = dig_m1,
    "(2) ITS"         = dig_m2,
    "(3) Full"        = dig_m3
  ),
  vcov     = nw_vcov,
  coef_map = decomp_coef_labels,
  gof_map  = c("nobs", "r.squared", "adj.r.squared"),
  stars    = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title    = "Digital Posting Count: Specifications Across Models",
  notes    = paste(
    "Dependent variable: log(1 + total digital skill postings).",
    "HAC standard errors (Newey-West, 4 lags) in parentheses.",
    "Quarter fixed effects included but not shown.",
    sep = " "
  ),
  output   = "latex",
  escape   = FALSE
)

digital_all_latex <- sub(
  "(\\\\caption\\{[^}]*\\})",
  "\\1\n\\\\label{tab:digital_count}",
  digital_all_latex
)

# Prevent long notes from stretching the table: replace l-aligned multicolumn
# with a fixed-width paragraph cell and use footnotesize text
digital_all_latex <- gsub(
  "\\multicolumn{4}{l}{\\rule{0pt}{1em}",
  "\\multicolumn{4}{p{11cm}}{\\footnotesize\\rule{0pt}{1em}",
  digital_all_latex,
  fixed = TRUE
)

writeLines(digital_all_latex, file.path(tables_dir, "table_digital_count.tex"))
cat("Digital count table saved.\n\n")

# =============================================================================
# 5. Console Summary for Reviewer Response
# =============================================================================

cat("=== 5. Key Results Summary ===\n\n")

summarise_model <- function(model, label) {
  ct <- hac_se(model)
  r2 <- round(summary(model)$r.squared, 3)
  cat(sprintf("  %s (R2 = %.3f):\n", label, r2))
  vars <- intersect(c("log_fatalities", "post_invasion", "time_since_invasion",
                      "chatgpt_rollout"), rownames(ct))
  for (v in vars)
    cat(sprintf("    %-28s coef = %+.4f  p = %.4f\n", v, ct[v, 1], ct[v, 4]))
  cat("\n")
}

cat("--- Baseline spec (log-fatalities + quarter) ---\n")
summarise_model(dig_m1,  "log(digital postings)")
summarise_model(vac_m1,  "log(total vacancies)")

cat("--- ITS spec (post_invasion + time_since_invasion + quarter) ---\n")
summarise_model(dig_m2,  "log(digital postings)")
summarise_model(vac_m2,  "log(total vacancies)")

cat("--- Full controls spec ---\n")
summarise_model(dig_m3,  "log(digital postings)")
summarise_model(vac_m3,  "log(total vacancies)")

cat("Tables saved to:", tables_dir, "\n")
cat("Figures saved to:", figures_dir, "\n")
cat("\n=== 06_decomposition.R complete. ===\n")
