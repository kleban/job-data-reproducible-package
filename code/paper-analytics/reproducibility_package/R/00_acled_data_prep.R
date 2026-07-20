# =============================================================================
# Ukraine Research Working Paper
# Script: 00_acled_data_prep.R
# Purpose: Load ACLED conflict event data for Ukraine, aggregate to monthly
#          and weekly frequency, and export descriptive time-series figures.
#
# Input (placed in data/ folder of reproducibility_package):
#   europe-central-asia_full_data_up_to-*.xlsx  (ACLED download)
#
# Outputs (output/figures/):
#   acled_uk_monthly.pdf/.png   — monthly events and fatalities
#   acled_uk_weekly.pdf/.png    — weekly  events and fatalities
# =============================================================================

# =============================================================================
# 0. Setup
# =============================================================================

packages_needed <- c(
  "here", "readxl", "tidyverse", "lubridate"
)

packages_to_install <- packages_needed[
  !packages_needed %in% installed.packages()[, "Package"]
]
if (length(packages_to_install) > 0) {
  pkg_type <- if (.Platform$OS.type == "windows") "binary" else getOption("pkgType")
  install.packages(packages_to_install, type = pkg_type)
}

suppressPackageStartupMessages({
  library(readxl)
  library(tidyverse)
  library(lubridate)
})

if (!exists("pkg_root")) {
  pkg_root <- if (dir.exists(here::here("R"))) here::here() else here::here("reproducibility_package")
}
if (!exists("data_dir")) {
  data_dir <- file.path(pkg_root, "data")
}

figures_dir <- file.path(pkg_root, "output", "figures")
if (!dir.exists(figures_dir)) dir.create(figures_dir, recursive = TRUE)

theme_paper <- theme_bw(base_size = 11) +
  theme(panel.grid.minor = element_blank(), strip.background = element_blank())

# =============================================================================
# 1. Load ACLED Data
# =============================================================================

# Locate the ACLED file by pattern (filename includes the download date)
acled_files <- list.files(data_dir,
                          pattern = "europe-central-asia.*\\.xlsx",
                          full.names = TRUE)
if (length(acled_files) == 0) {
  stop("No ACLED file found in data_dir matching 'europe-central-asia*.xlsx': ", data_dir)
}
acled_path <- acled_files[1]
cat("Reading ACLED file:", basename(acled_path), "\n")

acled <- read_excel(acled_path)

cat("All countries in file:\n")
print(sort(unique(acled$COUNTRY)))
cat("\n")

# =============================================================================
# 2. Filter to Ukraine
# =============================================================================

acled_uk <- acled |>
  filter(COUNTRY == "Ukraine") |>
  mutate(event_date = as.Date(EVENT_DATE))

cat("Ukraine rows:", nrow(acled_uk), "\n")
cat("\nSub-event types:\n")
print(sort(table(acled_uk$SUB_EVENT_TYPE), decreasing = TRUE))
cat("\n")

# =============================================================================
# 3. Monthly Aggregation
# =============================================================================

monthly_stats <- acled_uk |>
  mutate(month = floor_date(event_date, "month")) |>
  group_by(month) |>
  summarise(
    num_events        = n(),
    total_fatalities  = sum(FATALITIES, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(month)

cat("Monthly stats (last 5 rows):\n")
print(tail(monthly_stats, 5))
cat("\n")

# =============================================================================
# 4. Monthly Figure
# =============================================================================

monthly_long <- monthly_stats |>
  pivot_longer(c(num_events, total_fatalities),
               names_to  = "series",
               values_to = "count") |>
  mutate(series = case_when(
    series == "num_events"       ~ "Number of Events",
    series == "total_fatalities" ~ "Total Fatalities"
  ))

p_monthly <- ggplot(monthly_long,
                    aes(x = month, y = count, colour = series, shape = series)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1.2) +
  scale_colour_manual(
    values = c("Number of Events" = "#1f77b4", "Total Fatalities" = "#d62728"),
    name = NULL
  ) +
  scale_shape_manual(
    values = c("Number of Events" = 16, "Total Fatalities" = 15),
    name = NULL
  ) +
  scale_x_date(date_breaks = "6 months", date_labels = "%Y-%m") +
  labs(
    title   = "Monthly War-Related Events and Fatalities",
    x       = "Month",
    y       = "Count",
    caption = "Source: ACLED (2020\u20132025)."
  ) +
  theme_paper +
  theme(
    legend.position = "bottom",
    axis.text.x     = element_text(angle = 45, hjust = 1)
  )

ggsave(file.path(figures_dir, "acled_uk_monthly.pdf"),
       p_monthly, width = 12, height = 6)
ggsave(file.path(figures_dir, "acled_uk_monthly.png"),
       p_monthly, width = 12, height = 6, dpi = 300)
cat("acled_uk_monthly saved\n")

# =============================================================================
# 5. Weekly Aggregation
# =============================================================================

# Week starting Monday (equivalent to Python's W-MON period)
weekly_stats <- acled_uk |>
  mutate(week = floor_date(event_date, "week", week_start = 1)) |>
  group_by(week) |>
  summarise(
    num_events       = n(),
    total_fatalities = sum(FATALITIES, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(week)

cat("Weekly stats (last 5 rows):\n")
print(tail(weekly_stats, 5))
cat("Distinct weeks:", n_distinct(weekly_stats$week), "\n")
cat("Rows          :", nrow(weekly_stats), "\n\n")

# =============================================================================
# 6. Weekly Figure
# =============================================================================

weekly_long <- weekly_stats |>
  pivot_longer(c(num_events, total_fatalities),
               names_to  = "series",
               values_to = "count") |>
  mutate(series = case_when(
    series == "num_events"       ~ "Number of Events",
    series == "total_fatalities" ~ "Total Fatalities"
  ))

p_weekly <- ggplot(weekly_long,
                   aes(x = week, y = count, colour = series, shape = series)) +
  geom_line(linewidth = 0.5) +
  geom_point(size = 0.8) +
  scale_colour_manual(
    values = c("Number of Events" = "#1f77b4", "Total Fatalities" = "#d62728"),
    name = NULL
  ) +
  scale_shape_manual(
    values = c("Number of Events" = 16, "Total Fatalities" = 15),
    name = NULL
  ) +
  scale_x_date(date_breaks = "6 months", date_labels = "%Y-%m") +
  labs(
    title   = "Weekly War-Related Events and Fatalities",
    x       = "Week",
    y       = "Count",
    caption = "Source: ACLED (2020\u20132025)."
  ) +
  theme_paper +
  theme(
    legend.position = "bottom",
    axis.text.x     = element_text(angle = 45, hjust = 1)
  )

ggsave(file.path(figures_dir, "acled_uk_weekly.pdf"),
       p_weekly, width = 12, height = 6)
ggsave(file.path(figures_dir, "acled_uk_weekly.png"),
       p_weekly, width = 12, height = 6, dpi = 300)
cat("acled_uk_weekly saved\n\n")

# =============================================================================
# 7. Export Aggregated Data for Downstream Use
# =============================================================================

# Make aggregates available to subsequent scripts in the same R session
acled_monthly <<- monthly_stats
acled_weekly  <<- weekly_stats

cat("Objects exported to session: acled_monthly, acled_weekly\n")
cat("\n=== 00_acled_data_prep.R complete ===\n")
