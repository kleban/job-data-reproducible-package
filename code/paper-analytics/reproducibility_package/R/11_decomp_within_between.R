# =============================================================================
# Ukraine Research Working Paper
# Script: 11_decomp_within_between.R
# Purpose: Address reviewer comment:
#   "Rather than treating composition effects as a concern, the paper should
#    explicitly decompose the observed increase in digital skill shares into
#    within-occupation and between-occupation components and identify which
#    occupations drive the aggregate patterns."
#
# Methodology #
#   The aggregate digital skill share is the vacancy-weighted average:
#     S_t = S_j  w_{jt} #   where w_{jt} = occupation j's vacancy share in month t,
#         s_{jt} = avg. digital skill share of occupation j in month t.
#
#   For the two-period comparison (pre- vs. post-invasion averages), we use
#   midpoint weights so the decomposition is exact with no residual:
#
#     ?S = WITHIN + BETWEEN
#
#     WITHIN  = S_j  w#     BETWEEN = S_j  s#
#   where w#         ?s_j = s1_j - s0_j,     ?w_j = w1_j - w0_j.
#
#   For the rolling time-series figures we compare each month to the average
#   pre-invasion baseline (Laspeyres form), which adds a small cross term:
#
#     ?S_t = WITHIN_t + BETWEEN_t + CROSS_t
#
#     WITHIN_t  = S_j  w#     BETWEEN_t = S_j  s#     CROSS_t   = S_j  (s_{jt} - s#
# Exports:
#   table_decomp.tex               #   fig_decomp_timeseries.pdf/.png #   fig_decomp_occ.pdf/.png        # =============================================================================

# =============================================================================
# 0. Setup
# =============================================================================

packages_needed <- c(
  "here",
  "arrow", "tidyverse", "lubridate",
  "kableExtra", "janitor"
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
  library(kableExtra); library(janitor)
})

if (!exists("pkg_root")) pkg_root <- if (dir.exists(here::here("R"))) here::here() else here::here("code", "paper-analytics", "reproducibility_package")
tables_dir  <- file.path(pkg_root, "output", "tables")
figures_dir <- file.path(pkg_root, "output", "figures")
if (!dir.exists(tables_dir))  dir.create(tables_dir,  recursive = TRUE)
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

invasion_year  <- 2022L
invasion_month <- 2L      # February 2022

theme_paper <- theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(), strip.background = element_blank())

# =============================================================================
# 1. Load & Prepare Data
# =============================================================================

if (!exists("data_dir")) data_dir <- file.path(pkg_root, "data")
data_path <- file.path(data_dir, "final_dataset_occ_digital_month.parquet")
if (!file.exists(data_path)) stop("Data file not found: ", data_path)

df_raw <- arrow::read_parquet(data_path) |> janitor::clean_names()

cat("Columns in data:", paste(sort(names(df_raw)), collapse = ", "), "\n\n")

df <- df_raw |>
  # Remove unknown / armed-forces occupation (occ1d == "0", occupation_group NA)
  filter(!is.na(occupation_group), occ1d != "0") |>
  # Drop occupation-months with zero vacancies (unreliable digital share estimate)
  filter(vacancy_count > 0, !is.na(avg_digital_skill_share)) |>
  mutate(
    # Construct a proper date from year/month integers
    ym   = lubridate::ym(paste(year_created, month_created, sep = "-")),
    post = (year_created > invasion_year) |
           (year_created == invasion_year & month_created >= invasion_month)
  ) |>
  select(ym, year_created, month_created, post,
         occ1d, occupation_group, vacancy_count, avg_digital_skill_share) |>
  arrange(ym, occ1d)

# Vacancy share within each month (denominator = total vacancies that month,
# across the retained occupations only)
df <- df |>
  group_by(ym) |>
  mutate(vac_share = vacancy_count / sum(vacancy_count)) |>
  ungroup()

cat("Data loaded:", nrow(df), "occupation-months\n")
cat("Months     :", n_distinct(df$ym), "\n")
cat("Occupations:", n_distinct(df$occupation_group), "\n")
cat("Pre-invasion months :", n_distinct(df$ym[!df$post]), "\n")
cat("Post-invasion months:", n_distinct(df$ym[ df$post]), "\n\n")
cat("Overlap check\n")
print(
  df |>
    group_by(occupation_group) |>
    summarise(pre = sum(!post), post = sum(post)) |>
    as.data.frame()
)
cat("\n")

# =============================================================================
# 2. Pre-invasion Baseline Averages (for rolling decomposition)
# =============================================================================

ref <- df |>
  filter(!post) |>
  group_by(occ1d, occupation_group) |>
  summarise(
    s0 = mean(avg_digital_skill_share, na.rm = TRUE),
    w0 = mean(vac_share, na.rm = TRUE),
    .groups = "drop"
  )

S0_ref <- sum(ref$w0 * ref$s0)
cat(sprintf("Pre-invasion baseline aggregate digital share S0 = %.4f\n\n", S0_ref))

# =============================================================================
# 3. Rolling Monthly Decomposition (vs. baseline)
# =============================================================================

decomp <- df |>
  left_join(ref, by = c("occ1d", "occupation_group")) |>
  mutate(
    ds        = avg_digital_skill_share - s0,
    dw        = vac_share - w0,
    within_j  = w0 * ds,
    between_j = s0 * dw,
    cross_j   = ds * dw
  )

decomp_monthly <- decomp |>
  group_by(ym, post) |>
  summarise(
    S_t      = sum(vac_share * avg_digital_skill_share),
    within   = sum(within_j),
    between  = sum(between_j),
    cross    = sum(cross_j),
    .groups  = "drop"
  ) |>
  mutate(
    delta_S = S_t - S0_ref,
    check   = within + between + cross
  )

max_err <- max(abs(decomp_monthly$delta_S - decomp_monthly$check), na.rm = TRUE)
cat(sprintf("Rolling decomposition accounting identity check (max |?S - W - B - C|) = %.2e\n\n",
            max_err))

# =============================================================================
# 4. Two-Period Decomposition (pre vs post invasion) # =============================================================================

cat("=== Two-period decomposition (pre vs. post invasion) ===\n\n")

pre_avg <- df |>
  filter(!post) |>
  group_by(occ1d, occupation_group) |>
  summarise(
    s0 = mean(avg_digital_skill_share, na.rm = TRUE),
    w0 = mean(vac_share, na.rm = TRUE),
    .groups = "drop"
  )

post_avg <- df |>
  filter(post) |>
  group_by(occ1d, occupation_group) |>
  summarise(
    s1 = mean(avg_digital_skill_share, na.rm = TRUE),
    w1 = mean(vac_share, na.rm = TRUE),
    .groups = "drop"
  )

two_period <- full_join(pre_avg, post_avg, by = c("occ1d", "occupation_group")) |>
  mutate(
    ds    = s1 - s0,
    dw    = w1 - w0,
    # Midpoint weights
    w_mid = (w0 + w1) / 2,
    s_mid = (s0 + s1) / 2,
    within_j  = w_mid * ds,
    between_j = s_mid * dw,
    total_j   = within_j + between_j
  )

S0_2p <- sum(two_period$w0 * two_period$s0, na.rm = TRUE)
S1_2p <- sum(two_period$w1 * two_period$s1, na.rm = TRUE)
dS    <- S1_2p - S0_2p

within_total  <- sum(two_period$within_j,  na.rm = TRUE)
between_total <- sum(two_period$between_j, na.rm = TRUE)

cat(sprintf("  Pre-invasion avg.  S0 = %.4f  (%.2f%%)\n", S0_2p, S0_2p * 100))
cat(sprintf("  Post-invasion avg. S1 = %.4f  (%.2f%%)\n", S1_2p, S1_2p * 100))
cat(sprintf("  Total change       ?S = %.4f  (%.2f pp)\n\n", dS, dS * 100))
cat(sprintf("  Within-occupation      = %+.4f pp  (%+.1f%% of total)\n",
            within_total  * 100, 100 * within_total  / dS))
cat(sprintf("  Between-occupation     = %+.4f pp  (%+.1f%% of total)\n",
            between_total * 100, 100 * between_total / dS))
cat(sprintf("  Sum (check)            = %.4f pp  [should equal %.4f pp]\n\n",
            (within_total + between_total) * 100, dS * 100))

cat("--- Occupation-level contributions ---\n\n")
two_period |>
  arrange(desc(abs(total_j))) |>
  mutate(across(c(s0, s1, w0, w1, within_j, between_j, total_j),
                ~ sprintf("%+.4f", . * 100))) |>
  select(occupation_group, s0, s1, w0, w1, within_j, between_j, total_j) |>
  as.data.frame() |>
  print()
cat("\n")

# =============================================================================
# 5. Export LaTeX Table
# =============================================================================

cat("=== 5. Exporting LaTeX table ===\n\n")

tbl_data <- two_period |>
  arrange(desc(w_mid)) |>
  transmute(
    Occupation = occupation_group,
    s0_pct     = s0    * 100,
    s1_pct     = s1    * 100,
    w0_pct     = w0    * 100,
    w1_pct     = w1    * 100,
    within_pp  = within_j  * 100,
    between_pp = between_j * 100,
    total_pp   = total_j   * 100
  )

# Add a total row
total_row <- tibble(
  Occupation = "Total",
  s0_pct     = S0_2p          * 100,
  s1_pct     = S1_2p          * 100,
  w0_pct     = 100,
  w1_pct     = 100,
  within_pp  = within_total  * 100,
  between_pp = between_total * 100,
  total_pp   = dS             * 100
)

tbl_out <- bind_rows(tbl_data, total_row)

# Number of data rows (excluding total row), for row_spec
n_data_rows <- nrow(tbl_data)

# Format all numeric columns to 2 decimal places
tbl_fmt <- tbl_out |>
  mutate(across(where(is.numeric), \(x) sprintf("%.2f", x)))

decomp_tbl <- kbl(
  tbl_fmt,
  format    = "latex",
  booktabs  = TRUE,
  escape    = FALSE,
  linesep   = "",
  label     = "decomp",
  caption   = paste(
    "Within- and Between-Occupation Decomposition of Digital Skill Share",
    "\\label{tab:decomp}"
  ),
  col.names = c(
    "Occupation",
    "Pre", "Post",
    "Pre", "Post",
    "Within", "Between", "Total"
  )
) |>
  add_header_above(
    c(" " = 1,
      "Dig.\\\\  share (\\\\%)" = 2,
      "Vac.\\\\  share (\\\\%)" = 2,
      "Contribution (pp)" = 3),
    escape = FALSE
  ) |>
  # Horizontal rule before the Total row
  row_spec(n_data_rows, extra_latex_after = "\\midrule") |>
  row_spec(n_data_rows + 1L, bold = TRUE) |>
  footnote(
    general = paste(
      "Midpoint (Oaxaca-Blinder) shift-share decomposition.",
      "\\\\textit{Within} = change in aggregate digital skill share holding",
      "occupation vacancy shares fixed at their midpoint values;",
      "it captures occupations becoming more digital-skill-intensive.",
      "\\\\textit{Between} = change holding occupational digital content fixed;",
      "it captures demand shifting toward inherently more-digital occupations.",
      "Within + Between = Total (exact with midpoint weights).",
      "Occupation groups follow ISCO-08 1-digit classification.",
      "Pre-invasion reference: Jan 2021--Jan 2022;",
      "post-invasion: Feb 2022--latest available month.",
      "Figures in \\\\% are averages within the respective period."
    ),
    general_title = "",
    escape = FALSE,
    threeparttable = FALSE
  )

# Post-process: extract footnote from inside the tabular and place it outside
# the \resizebox in a \minipage so it stays at full, readable font size.
lines_d <- strsplit(decomp_tbl, "\n")[[1]]

bottomrule_idx_d  <- tail(which(lines_d == "\\bottomrule"), 1)
end_tabular_idx_d <- which(grepl("^\\\\end\\{tabular\\}", lines_d))

# Note lines sit between the last \bottomrule and \end{tabular}
note_idx_d   <- seq(bottomrule_idx_d + 1, end_tabular_idx_d - 1)
note_lines_d <- lines_d[note_idx_d]

# Strip \multicolumn{N}{l}{\rule{0pt}{1em}<text>}\\ wrapper to get plain text
note_texts_d <- gsub(
  "^\\\\multicolumn\\{[0-9]+\\}\\{l\\}\\{\\\\rule\\{0pt\\}\\{1em\\}(.*)\\}\\\\\\\\$",
  "\\1", note_lines_d, perl = TRUE
)
note_combined_d <- paste(note_texts_d, collapse = " ")

# Remove note rows from inside the tabular
lines_d <- lines_d[-note_idx_d]

# Reassemble: close tabular, close resizebox, then minipage for notes
lines_d <- c(
  lines_d[seq_len(which(grepl("^\\\\end\\{tabular\\}", lines_d)))],
  "}% end resizebox",
  "\\par\\vspace{0.5em}",
  "\\begin{minipage}{\\textwidth}",
  "\\footnotesize",
  note_combined_d,
  "\\end{minipage}",
  lines_d[seq(which(grepl("^\\\\end\\{tabular\\}", lines_d)) + 1, length(lines_d))]
)

# Insert \resizebox just before \begin{tabular}
begin_tab_idx_d <- which(grepl("^\\\\begin\\{tabular\\}", lines_d))
lines_d <- c(
  lines_d[seq_len(begin_tab_idx_d - 1)],
  "\\resizebox{\\textwidth}{!}{%",
  lines_d[begin_tab_idx_d:length(lines_d)]
)

decomp_tbl <- paste(lines_d, collapse = "\n")

decomp_path <- file.path(tables_dir, "table_decomp.tex")
writeLines(decomp_tbl, decomp_path)
cat("table_decomp.tex saved to:", decomp_path, "\n\n")

# =============================================================================
# 6. Figure A # =============================================================================

cat("=== 6. Figures ===\n\n")

invasion_date_ym <- lubridate::ym(paste(invasion_year, invasion_month, sep = "-"))

ts_long <- decomp_monthly |>
  select(ym, within, between, delta_S) |>
  pivot_longer(c(within, between, delta_S),
               names_to = "component", values_to = "value") |>
  mutate(
    component = case_when(
      component == "within"  ~ "Within-occupation",
      component == "between" ~ "Between-occupation",
      component == "delta_S" ~ "Total (actual)",
      TRUE ~ component
    ),
    value_pp = value * 100
  )

p_ts <- ggplot(ts_long,
               aes(x = ym, y = value_pp,
                   colour = component, linetype = component)) +
  geom_hline(yintercept = 0, colour = "grey70", linewidth = 0.4) +
  geom_vline(xintercept = invasion_date_ym,
             colour = "firebrick", linetype = "dotted", linewidth = 0.7) +
  annotate("text",
           x = invasion_date_ym, y = Inf,
           label = "Invasion (Feb 2022)",
           hjust = -0.05, vjust = 1.4,
           colour = "firebrick", size = 3) +
  geom_line(linewidth = 0.8) +
  scale_colour_manual(
    values = c("Total (actual)"      = "black",
               "Within-occupation"   = "#2166ac",
               "Between-occupation"  = "#d6604d"),
    name = NULL
  ) +
  scale_linetype_manual(
    values = c("Total (actual)"      = "solid",
               "Within-occupation"   = "dashed",
               "Between-occupation"  = "dotdash"),
    name = NULL
  ) +
  labs(
    x = NULL,
    y = "\u0394 Digital skill share vs. pre-invasion avg. (pp)"
  ) +
  theme_paper +
  theme(legend.position = "bottom")

ggsave(file.path(figures_dir, "fig_decomp_timeseries.pdf"),
       p_ts, width = 7, height = 4)
ggsave(file.path(figures_dir, "fig_decomp_timeseries.png"),
       p_ts, width = 7, height = 4, dpi = 300)
cat("fig_decomp_timeseries saved\n")

# =============================================================================
# 6B. Actual vs. composition-only counterfactual
# =============================================================================
# The composition-only counterfactual holds occupation weights at their
# pre-invasion average (w0_j) while letting skill intensities evolve freely:
#   S_counterfactual(t) = S0_ref + within(t) = sum_j w0_j * s_jt
# Any gap between the actual (S_t) and this counterfactual is attributable
# to changes in the occupational mix (between + cross components).

counterfactual_long <- decomp_monthly |>
  transmute(
    ym,
    `Actual aggregate digital skill share`                          = S_t,
    `Composition-only counterfactual (2021 occupation intensities)` = S0_ref + within
  ) |>
  pivot_longer(-ym, names_to = "series", values_to = "value")

p_counterfactual <- ggplot(counterfactual_long,
                           aes(x = ym, y = value, colour = series)) +
  geom_vline(xintercept = invasion_date_ym,
             colour = "firebrick", linetype = "dotted", linewidth = 0.7) +
  annotate("text",
           x = invasion_date_ym, y = Inf,
           label = "Invasion (Feb 2022)",
           hjust = -0.05, vjust = 1.4,
           colour = "firebrick", size = 3) +
  geom_line(linewidth = 0.8) +
  scale_colour_manual(
    values = c(
      "Actual aggregate digital skill share"                          = "#1f77b4",
      "Composition-only counterfactual (2021 occupation intensities)" = "#ff7f0e"
    ),
    name = NULL
  ) +
  scale_x_date(date_breaks = "6 months", date_labels = "%Y-%m") +
  labs(
    title = "Actual vs composition-only counterfactual digital skill share",
    x     = "Month",
    y     = "Digital skill share"
  ) +
  theme_paper +
  theme(
    legend.position   = "bottom",
    legend.background = element_rect(fill = "white", colour = NA),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )

ggsave(file.path(figures_dir, "fig_decomp_counterfactual.pdf"),
       p_counterfactual, width = 10, height = 4.5)
ggsave(file.path(figures_dir, "fig_decomp_counterfactual.png"),
       p_counterfactual, width = 10, height = 4.5, dpi = 300)
cat("fig_decomp_counterfactual saved\n")

# =============================================================================
# 7. Figure B # =============================================================================

occ_long <- two_period |>
  select(occupation_group, within_j, between_j, total_j) |>
  mutate(
    occupation_group = fct_reorder(occupation_group, total_j)
  ) |>
  pivot_longer(c(within_j, between_j),
               names_to = "component", values_to = "value") |>
  mutate(
    component = case_when(
      component == "within_j"  ~ "Within-occupation",
      component == "between_j" ~ "Between-occupation",
      TRUE ~ component
    ),
    value_pp = value * 100
  )

p_occ <- ggplot(occ_long,
                aes(x = occupation_group, y = value_pp, fill = component)) +
  geom_col(position = "stack", width = 0.7) +
  geom_hline(yintercept = 0, colour = "grey50", linewidth = 0.4) +
  coord_flip() +
  scale_fill_manual(
    values = c("Within-occupation"  = "#2166ac",
               "Between-occupation" = "#d6604d"),
    name = NULL
  ) +
  labs(
    x = NULL,
    y = "Contribution to \u0394 aggregate digital skill share (pp)"
  ) +
  theme_paper +
  theme(legend.position = "bottom")

ggsave(file.path(figures_dir, "fig_decomp_occ.pdf"),
       p_occ, width = 7, height = 4.5)
ggsave(file.path(figures_dir, "fig_decomp_occ.png"),
       p_occ, width = 7, height = 4.5, dpi = 300)
cat("fig_decomp_occ saved\n\n")

# =============================================================================
# 8. Console Summary
# =============================================================================

cat("=== Summary ===\n\n")
cat(sprintf("Aggregate change: %.2f pp  (%.4f ? %.4f)\n",
            dS * 100, S0_2p, S1_2p))
cat(sprintf("  Within-occ  : %+.2f pp  (%+.1f%% of total)\n",
            within_total  * 100, 100 * within_total  / dS))
cat(sprintf("  Between-occ : %+.2f pp  (%+.1f%% of total)\n",
            between_total * 100, 100 * between_total / dS))
cat("\nTop occupations by total contribution (pp):\n")
two_period |>
  arrange(desc(total_j)) |>
  mutate(total_pp = total_j * 100,
         within_pp = within_j * 100,
         between_pp = between_j * 100) |>
  select(occupation_group, total_pp, within_pp, between_pp) |>
  print()

cat("\nFigures saved to:", figures_dir, "\n")
cat("Tables  saved to:", tables_dir, "\n")
cat("\n=== 11_decomp_within_between.R complete ===\n")
