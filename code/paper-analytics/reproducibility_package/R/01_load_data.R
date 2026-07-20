# =============================================================================
# Ukraine Research Working Paper
# Script: 01_load_data.R
# Purpose: Load and explore final_weekly.parquet data
# Author: Britta Rude
# Date: 2026-03-09
# Last adapted: 2026-06-09
# =============================================================================

# -----------------------------------------------------------------------------
# 0. Setup
# -----------------------------------------------------------------------------

# Install required packages if not already installed
packages_needed <- c("arrow", "tidyverse", "skimr", "janitor", "here")
packages_to_install <- packages_needed[!packages_needed %in% installed.packages()[, "Package"]]
if (length(packages_to_install) > 0) {
  install.packages(packages_to_install)
}

# Load libraries
library(arrow)       # Parquet file I/O
library(tidyverse)   # Data manipulation and visualization
library(skimr)       # Comprehensive summary statistics
library(janitor)     # Clean column names
library(here)        # Robust relative file paths

# -----------------------------------------------------------------------------
# 1. Define Paths
# -----------------------------------------------------------------------------

# Data files are stored in the data/ folder of this R project.

if (!exists("pkg_root")) pkg_root <- if (dir.exists(here::here("R"))) here::here() else here::here("code", "paper-analytics", "reproducibility_package")
if (!exists("data_dir")) data_dir <- file.path(pkg_root, "data")
data_path <- file.path(data_dir, "final_weekly.parquet")

# Verify the file exists before proceeding
if (!file.exists(data_path)) {
  stop(
    "Data file not found. Expected path:\n  ", data_path,
    "\nPlease verify the project directory structure."
  )
}

cat("Data file found:", data_path, "\n\n")

# -----------------------------------------------------------------------------
# 2. Load Data
# -----------------------------------------------------------------------------

cat("Loading data...\n")
df <- arrow::read_parquet(data_path)
cat("Data loaded successfully.\n\n")

# Optionally clean column names (snake_case, no spaces)
df <- janitor::clean_names(df)

# -----------------------------------------------------------------------------
# 3. Basic Inspection
# -----------------------------------------------------------------------------

cat("=== Dimensions ===\n")
cat("Rows:", nrow(df), "| Columns:", ncol(df), "\n\n")

cat("=== Column Names & Types ===\n")
print(glimpse(df))

cat("\n=== First 6 Rows ===\n")
print(head(df))

cat("\n=== Last 6 Rows ===\n")
print(tail(df))

# -----------------------------------------------------------------------------
# 4. Summary Statistics
# -----------------------------------------------------------------------------

cat("\n=== Summary Statistics (skimr) ===\n")
print(skim(df))

# -----------------------------------------------------------------------------
# 5. Missing Values
# -----------------------------------------------------------------------------

cat("\n=== Missing Values per Column ===\n")
missing_summary <- df |>
  summarise(across(everything(), ~ sum(is.na(.)))) |>
  pivot_longer(everything(), names_to = "column", values_to = "n_missing") |>
  mutate(pct_missing = round(n_missing / nrow(df) * 100, 2)) |>
  arrange(desc(n_missing))

print(missing_summary)

# Flag columns with >10% missing
high_missing <- missing_summary |> filter(pct_missing > 10)
if (nrow(high_missing) > 0) {
  cat("\nWARNING: The following columns have >10% missing values:\n")
  print(high_missing)
} else {
  cat("\nNo columns exceed 10% missing values.\n")
}

# -----------------------------------------------------------------------------
# 6. Date / Time Coverage (if applicable)
# -----------------------------------------------------------------------------

# Detect date-like columns automatically
date_cols <- df |>
  select(where(~ inherits(., c("Date", "POSIXct", "POSIXlt")))) |>
  names()

if (length(date_cols) > 0) {
  cat("\n=== Date Coverage ===\n")
  for (col in date_cols) {
    cat(sprintf("Column '%s': %s  to  %s\n",
                col,
                as.character(min(df[[col]], na.rm = TRUE)),
                as.character(max(df[[col]], na.rm = TRUE))))
  }
} else {
  cat("\nNo date/time columns detected. Check column types if dates are expected.\n")
}

# -----------------------------------------------------------------------------
# 7. Save Cleaned Object for Downstream Scripts
# -----------------------------------------------------------------------------

output_rds <- file.path(data_dir, "final_weekly_clean.rds")
saveRDS(df, output_rds)
cat("\nCleaned data saved to:", output_rds, "\n")

cat("\n=== Data loading complete. Proceed to 02_analysis.R ===\n")
