# =============================================================================
# Ukraine Research Working Paper
# Script: 12_mechanisms_remoteshare.R
# Purpose: Explore the extent to which remote work share mediates the
#          relationship between invasion intensity and digital skill demand.
#
# Three approaches:
#   A. Add remote share as a control #   B. Regress remote share on conflict intensity #      is itself conflict-induced (justifies mediator interpretation)
#   C. Causal mediation decomposition #      direct effect and indirect effect via remote share
#
# Exports:
#   table_remote_channel.tex # =============================================================================

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
    log_fatalities  = log1p(total_fatalities),
    log_events      = log1p(num_events),
    quarter         = factor(lubridate::quarter(week)),
    year            = factor(lubridate::year(week)),
    chatgpt_rollout = as.integer(week >= as.POSIXct("2022-11-30", tz = "UTC")),
    ai_wave2        = as.integer(week >= as.POSIXct("2023-03-14", tz = "UTC")),
    post_invasion   = as.integer(week >= as.POSIXct("2022-02-24", tz = "UTC")),
    time_trend      = as.integer(difftime(week, min(week), units = "weeks"))
  )

cat("Data loaded:", nrow(df), "weeks\n")
cat("Remote share summary:\n")
print(summary(df$remote_share))
cat("\n")

# =============================================================================
# 2A. Main outcome models
# =============================================================================

cat("=== 2A. Digital skill share ~ fatalities + remote share ===\n\n")

# M1: baseline (quarter FE only)
m1_fat <- lm(avg_digital_skill_share ~ log_fatalities + quarter,
             data = df)

# M2: add vacancy count and AI controls
m2_fat <- lm(avg_digital_skill_share ~ log_fatalities +
               vacancy_count + chatgpt_rollout + ai_wave2 + quarter,
             data = df)

# M3: add remote share
m3_fat <- lm(avg_digital_skill_share ~ log_fatalities + remote_share +
               vacancy_count + chatgpt_rollout + ai_wave2 + quarter,
             data = df)

# M4: full controls including military share + remote share
m4_fat <- lm(avg_digital_skill_share ~ log_fatalities + remote_share +
               vacancy_count + avg_military_skill_share +
               chatgpt_rollout + ai_wave2 + quarter,
             data = df)

# Print HAC results
for (i in 1:4) {
  mod <- get(paste0("m", i, "_fat"))
  ct  <- hac_se(mod)
  cat(sprintf("  M%d log_fatalities: coef = %+.4f  p = %.4f  R2 = %.3f\n",
              i, ct["log_fatalities", 1], ct["log_fatalities", 4],
              summary(mod)$r.squared))
  if ("remote_share" %in% rownames(ct)) {
    cat(sprintf("     remote_share:    coef = %+.4f  p = %.4f\n",
                ct["remote_share", 1], ct["remote_share", 4]))
  }
}
cat("\n")

# Mirror for events
cat("=== 2B. Digital skill share ~ events + remote share ===\n\n")

m1_evt <- lm(avg_digital_skill_share ~ log_events + quarter,
             data = df)
m2_evt <- lm(avg_digital_skill_share ~ log_events +
               vacancy_count + chatgpt_rollout + ai_wave2 + quarter,
             data = df)
m3_evt <- lm(avg_digital_skill_share ~ log_events + remote_share +
               vacancy_count + chatgpt_rollout + ai_wave2 + quarter,
             data = df)
m4_evt <- lm(avg_digital_skill_share ~ log_events + remote_share +
               vacancy_count + avg_military_skill_share +
               chatgpt_rollout + ai_wave2 + quarter,
             data = df)

for (i in 1:4) {
  mod <- get(paste0("m", i, "_evt"))
  ct  <- hac_se(mod)
  cat(sprintf("  M%d log_events:     coef = %+.4f  p = %.4f  R2 = %.3f\n",
              i, ct["log_events", 1], ct["log_events", 4],
              summary(mod)$r.squared))
  if ("remote_share" %in% rownames(ct)) {
    cat(sprintf("     remote_share:    coef = %+.4f  p = %.4f\n",
                ct["remote_share", 1], ct["remote_share", 4]))
  }
}
cat("\n")

# =============================================================================
# 2C. First stage
# =============================================================================
# Confirms that remote share is itself conflict-induced, justifying the
# mediator interpretation. If fatalities significantly predict remote share,
# including remote share as a control introduces bad-control bias.

cat("=== 2C. First stage: remote share ~ fatalities ===\n\n")

fs_fat <- lm(remote_share ~ log_fatalities + quarter, data = df)
fs_fat_full <- lm(remote_share ~ log_fatalities +
                    vacancy_count + chatgpt_rollout + ai_wave2 +
                    quarter,
                  data = df)

fs_evt <- lm(remote_share ~ log_events + quarter, data = df)
fs_evt_full <- lm(remote_share ~ log_events +
                    vacancy_count + chatgpt_rollout + ai_wave2 +
                    quarter,
                  data = df)

for (mod_name in c("fs_fat", "fs_fat_full", "fs_evt", "fs_evt_full")) {
  mod <- get(mod_name)
  ct  <- hac_se(mod)
  conflict_var <- if (grepl("fat", mod_name)) "log_fatalities" else "log_events"
  cat(sprintf("  %-16s %s: coef = %+.4f  p = %.4f  R2 = %.3f\n",
              mod_name, conflict_var,
              ct[conflict_var, 1], ct[conflict_var, 4],
              summary(mod)$r.squared))
}
cat("\n")

# =============================================================================
# 2D. Mediation decomposition
# =============================================================================
# Total effect    = coef on fatalities WITHOUT remote share (M2)
# Direct effect   = coef on fatalities WITH remote share (M3)
# Indirect effect = Total - Direct (effect via remote share channel)
# % mediated      = Indirect / Total * 100

cat("=== 2D. Mediation Decomposition ===\n\n")

for (spec in c("fat", "evt")) {
  conflict_var <- if (spec == "fat") "log_fatalities" else "log_events"
  m2 <- get(paste0("m2_", spec))
  m3 <- get(paste0("m3_", spec))

  total_effect    <- hac_se(m2)[conflict_var, 1]
  direct_effect   <- hac_se(m3)[conflict_var, 1]
  indirect_effect <- total_effect - direct_effect
  pct_mediated    <- (indirect_effect / total_effect) * 100

  cat(sprintf("  %s specification:\n", toupper(spec)))
  cat(sprintf("    Total effect    (M2): %+.4f\n", total_effect))
  cat(sprintf("    Direct effect   (M3): %+.4f\n", direct_effect))
  cat(sprintf("    Indirect effect      : %+.4f\n", indirect_effect))
  cat(sprintf("    %% mediated via remote: %.1f%%\n\n", pct_mediated))
}

# =============================================================================
# 3. Export Tables
# =============================================================================

cat("=== 3. Exporting remote channel tables ===\n\n")

export_remote_table <- function(models, conflict_var, conflict_label,
                                 title_str, label_str, out_file) {

  coef_labels_remote <- c(
    setNames(conflict_label, conflict_var),
    "remote_share"             = "Remote Share",
    "vacancy_count"            = "Vacancy Count",
    "avg_military_skill_share" = "Military Skill Share",
    "chatgpt_rollout"          = "ChatGPT Rollout",
    "ai_wave2"                 = "AI Wave 2",
    "(Intercept)"              = "Intercept"
  )

  vcov_list <- lapply(models, nw_vcov)

  note_text <- paste(
    "Dependent variable: average digital skill share (weekly).",
    sprintf("%s is $\\\\log(1 + \\\\text{weekly ACLED %s})$.",
            conflict_label,
            if (conflict_var == "log_fatalities") "fatalities" else "events"),
    "All models include quarter fixed effects and HAC standard errors",
    "(Newey-West, 4 lags).",
    "(1) quarter FE only;",
    "(2) adds vacancy count, ChatGPT rollout, and AI wave 2;",
    "(3) adds remote share to column (2);",
    "(4) further adds military skill share.",
    "Remote share is the weekly share of postings explicitly mentioning",
    "remote or distance work. Since remote adoption is itself partly",
    "attack-induced, column (3) provides a lower bound on the",
    "attack effect (bad-control bound).",
    sep = " "
  )

  tbl_latex <- modelsummary(
    setNames(models, c("(1) Baseline", "(2) + Controls",
                       "(3) + Remote", "(4) + Military")),
    vcov        = vcov_list,
    coef_map    = coef_labels_remote,
    coef_omit   = "quarter|year",
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

  # Fix note column width
  tbl_latex <- gsub(
    "\\multicolumn{5}{l}{\\rule{0pt}{1em}",
    "\\multicolumn{5}{p{14cm}}{\\footnotesize\\rule{0pt}{1em}",
    tbl_latex,
    fixed = TRUE
  )

  writeLines(tbl_latex, out_file)
  cat("Saved:", out_file, "\n")
  invisible(tbl_latex)
}

# Export fatalities table
export_remote_table(
  models         = list(m1_fat, m2_fat, m3_fat, m4_fat),
  conflict_var   = "log_fatalities",
  conflict_label = "Log(Fatalities)",
  title_str      = "Remote Work as a Mediating Channel: Digital Skill Demand and Fatalities",
  label_str      = "tab:remote_channel",
  out_file       = file.path(tables_dir, "table_remote_channel.tex")
)

# Export events table
export_remote_table(
  models         = list(m1_evt, m2_evt, m3_evt, m4_evt),
  conflict_var   = "log_events",
  conflict_label = "Log(Events)",
  title_str      = "Remote Work as a Mediating Channel: Digital Skill Demand and Events",
  label_str      = "tab:remote_channel_evt",
  out_file       = file.path(tables_dir, "table_remote_channel_events.tex")
)

cat("\nBoth remote channel tables saved.\n")

# -----------------------------------------------------------------------------
# 3B. First-stage table: remote_share ~ conflict intensity
# -----------------------------------------------------------------------------

fs_coef_labels <- c(
  "log_fatalities" = "Log(Fatalities)",
  "log_events"     = "Log(Events)",
  "vacancy_count"  = "Vacancy Count",
  "chatgpt_rollout" = "ChatGPT Rollout",
  "ai_wave2"       = "AI Wave 2",
  "(Intercept)"    = "Intercept"
)

fs_note <- paste(
  "Dependent variable: weekly remote work share (share of job postings",
  "explicitly mentioning remote or distance work).",
  "Columns (1) and (3): baseline specification with quarter fixed effects only.",
  "Columns (2) and (4): full controls.",
  "Columns (1)--(2) use Log(Fatalities); columns (3)--(4) use Log(Events).",
  "A significant positive coefficient confirms that remote work adoption",
  "is itself attack-induced, justifying the mediator classification.",
  "HAC standard errors (Newey-West, 4 lags) in parentheses.",
  "Quarter fixed effects included but not shown.",
  sep = " "
)

fs_vcov_list <- lapply(list(fs_fat, fs_fat_full, fs_evt, fs_evt_full), nw_vcov)

fs_latex <- modelsummary(
  list(
    "(1) Fatalities"       = fs_fat,
    "(2) Fatalities + Ctrls" = fs_fat_full,
    "(3) Events"           = fs_evt,
    "(4) Events + Ctrls"   = fs_evt_full
  ),
  vcov     = fs_vcov_list,
  coef_map = fs_coef_labels,
  gof_map  = c("nobs", "r.squared", "adj.r.squared"),
  stars    = c("*" = 0.10, "**" = 0.05, "***" = 0.01),
  title    = "First Stage: Remote Work Share and Attack Intensity",
  notes    = NULL,
  output   = "latex",
  escape   = FALSE
)

fs_latex <- sub(
  "(\\\\caption\\{[^}]*\\})",
  "\\1\n\\\\label{tab:first_stage_remote}",
  fs_latex
)

# Wrap tabular in \resizebox for width safety
fs_latex <- sub(
  "(\\\\begin\\{tabular\\})",
  "\\\\resizebox{\\\\textwidth}{!}{\\1",
  fs_latex
)
fs_latex <- sub(
  "(\\\\end\\{tabular\\})",
  "\\1}",
  fs_latex
)

# Add note outside resizebox as full-width minipage
fs_note_block <- paste0(
  "\n\\begin{minipage}{\\linewidth}\\footnotesize\n",
  "\\rule{0pt}{1em}* p $<$ 0.1, ** p $<$ 0.05, *** p $<$ 0.01\\\\\n",
  "\\rule{0pt}{1em}", fs_note, "\n",
  "\\end{minipage}"
)
fs_latex <- sub(
  "\\end{table}",
  paste0(fs_note_block, "\n\\end{table}"),
  fs_latex,
  fixed = TRUE
)

writeLines(fs_latex, file.path(tables_dir, "table_first_stage_remote.tex"))
cat("First-stage table saved.\n\n")

# =============================================================================
# 4. Console Summary
# =============================================================================

cat("=== 4. Summary ===\n\n")

cat("Key finding: does adding remote share attenuate the fatalities coef?\n\n")
ct2 <- hac_se(m2_fat)
ct3 <- hac_se(m3_fat)
cat(sprintf("  Without remote share (M2): coef = %+.4f  p = %.4f\n",
            ct2["log_fatalities", 1], ct2["log_fatalities", 4]))
cat(sprintf("  With remote share    (M3): coef = %+.4f  p = %.4f\n",
            ct3["log_fatalities", 1], ct3["log_fatalities", 4]))
cat(sprintf("  Attenuation: %.1f%%\n\n",
            (1 - ct3["log_fatalities", 1] / ct2["log_fatalities", 1]) * 100))

cat("Remote share ~ fatalities (first stage):\n")
ct_fs <- hac_se(fs_fat)
cat(sprintf("  Baseline:      coef = %+.4f  p = %.4f  R2 = %.3f\n",
            ct_fs["log_fatalities", 1], ct_fs["log_fatalities", 4],
            summary(fs_fat)$r.squared))
ct_fs_full <- hac_se(fs_fat_full)
cat(sprintf("  Full controls: coef = %+.4f  p = %.4f  R2 = %.3f\n",
            ct_fs_full["log_fatalities", 1], ct_fs_full["log_fatalities", 4],
            summary(fs_fat_full)$r.squared))

cat("\nTables saved to:", tables_dir, "\n")
cat("\n=== 12_mechanisms_remoteshare.R complete ===\n")
