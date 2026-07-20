# =============================================================================
# Ukraine Research Working Paper — Reproducibility Package
# Master Run Script: run_all.R
#
# Purpose : Sources all analysis scripts end-to-end in the correct order.
#           Run this from the project root (reproducibility_package/) or open
#           ukraine_skills.Rproj in RStudio first so that here::here() anchors
#           to the correct project directory.
#
# Prerequisite : Restore the renv environment once before running:
#   renv::restore()
#
# Data required:
#   Parquet files — located in data/ subfolder of this package:
#     data/final_weekly.parquet                          (main weekly panel)
#     data/final_monthly.parquet                         (monthly panel)
#     data/final_dataset_occ_digital_month.parquet       (occ × month)
#   Excel files — located in data/ subfolder of this package:
#     data/europe-central-asia_full_data_up_to-*.xlsx    (ACLED conflict data)
#     data/2025_10_14_electricity_outages.xlsx            (scripts 07, 02)
#     data/2025_10_14_elektro_boiovi_dii_ukraina_minenergo.xlsx  (scripts 07, 02)
#
# Output directories (created automatically if they do not exist):
#   output/tables/   — LaTeX table files (.tex)
#   output/figures/  — Figures (.pdf and .png)
# =============================================================================

library(here)

# Project root: the folder that contains the R/ subfolder.
# Works whether here() anchors to reproducibility_package/ (via .Rproj)
# or to the workspace root (when sourced from outside the project).
pkg_root <- normalizePath(
  if (dir.exists(here::here("R"))) {
    here::here()                          # .Rproj open → here() IS the pkg root
  } else {
    here::here("reproducibility_package") # running from workspace root
  },
  mustWork = FALSE
)

data_dir <- file.path(pkg_root, "data")

message("pkg_root : ", pkg_root)
message("data_dir : ", data_dir)

# Ensure output directories exist
dir.create(file.path(pkg_root, "output", "tables"),  recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(pkg_root, "output", "figures"), recursive = TRUE, showWarnings = FALSE)

message("\n", strrep("=", 70))
message("Ukraine Skills Paper — Full Pipeline")
message(strrep("=", 70), "\n")

# Helper: source and time each script
run_script <- function(script_name) {
  path <- file.path(pkg_root, "R", script_name)
  message(strrep("-", 60))
  message("Running: ", script_name, "  [", format(Sys.time(), "%H:%M:%S"), "]")
  message(strrep("-", 60))
  tryCatch(
    source(path, echo = FALSE, encoding = "unknown"),
    error = function(e) {
      message("\n!!! ERROR in ", script_name, " !!!")
      message(conditionMessage(e))
      message("Continuing to next script...\n")
    }
  )
}

# =============================================================================
# STAGE 0 — ACLED Conflict Data Preparation
# =============================================================================
# 00_acled_data_prep.R inputs:
#   data/europe-central-asia_full_data_up_to-*.xlsx  (ACLED download)
# Outputs:
#   Figures: acled_uk_monthly.pdf/.png  — monthly events & fatalities
#            acled_uk_weekly.pdf/.png   — weekly  events & fatalities
#   Session objects: acled_monthly, acled_weekly (available to later scripts)
run_script("00_acled_data_prep.R")

# =============================================================================
# STAGE 1 — Data Inspection (optional, exploratory only)
# =============================================================================
# run_script("01_load_data.R")   # Uncomment to run data QC / exploration

# =============================================================================
# STAGE 2 — Main Results (Tables 2 & 3 in the paper)
# =============================================================================
run_script("02_baseline_regression.R")

# =============================================================================
# STAGE 3 — Structural Break Analysis
# =============================================================================
# Outputs:
#   Tables : table_structural_break.tex  → Appendix Table B6  (tab:structural_break)
#            table_break_tests.tex       → Appendix Table B5  (tab:break_tests)
#   Figures: fig1_digital_share_structural_break.pdf/.png  → Figure 5, left panel  (fig:structuralbreakraw)
#            fig4_its_fitted_vs_actual.pdf/.png            → Figure 5, right panel (fig:itsfitted)
#            fig2_cusum_test.pdf/.png                      → Appendix Figure B6, left panel  (fig:cusum)
#            fig3_supF_breakpoints.pdf/.png                → Appendix Figure B6, right panel (fig:supf)
run_script("03_structural_break.R")

# =============================================================================
# STAGE 4 — Time Series Diagnostics (Stationarity, Cointegration)
# =============================================================================
# 04_stationarity.R outputs:
#   Tables : table_unit_roots.tex    → Appendix Table B7  (tab:unit_roots)
#
# 05_cointegration_ecm.R outputs:
#   Tables : table_cointegration.tex → Appendix Table B8  (tab:cointegration)
#            table_ecm.tex           → Appendix Table B9  (tab:ecm)
#            table_detrended.tex     → Appendix Table B10 (tab:detrended)
run_script("04_stationarity.R")
run_script("05_cointegration_ecm.R")

# =============================================================================
# STAGE 5 — Robustness Checks
# =============================================================================
# 06_decomposition.R outputs:
#   Tables : table_digital_count.tex  → Appendix Table B11 (tab:digital_count)
#            table_decomposition.tex  → Appendix Table B12 (tab:decomposition)
#   Figures: fig_decomposition.pdf/.png          → Appendix Figure B7 (fig:decomposition)
#            fig_decomposition_linear.pdf/.png   → not in published paper
#
# 07_robustness_ovb.R outputs:
#   Tables : table_its_robustness.tex → Table 6 in paper  (tab:its_robustness)
#
# 08_robustness_monthly.R outputs:
#   Tables : table_monthlyols.tex        → Appendix Table B3 (tab:monthlyols)
#            table_monthlyols_events.tex → Appendix Table B4 (tab:monthlyols_events)
#
# 09_robustness_smoothing.R outputs:
#   Tables : table_smoothing_ma.tex → Table 4 in paper    (tab:smoothing_ma)
#            table_almon.tex        → Table 5 in paper    (tab:almon)
#   Figures: smoothing_coefplot.pdf/.png → Figure 4, left panel  (fig:smoothing)
#            almond_coefplot.pdf/.png    → Figure 4, right panel (fig:almon)
#
# 10_seasonality_diagnostics.R outputs:
#   Tables : table_seasonality_tests.tex → Appendix Table B2  (tab:seasonality)
#   Figures: fig_seasonal_means.pdf/.png → Appendix Figure B3 (fig:seasonal_means)
#            fig_acf_raw.pdf/.png        → Appendix Figure B4 (fig:acf_raw)
#            fig_acf_demeaned.pdf/.png   → Appendix Figure B5 (fig:acf_demeaned)

run_script("06_decomposition.R")         # Ratio decomposition (numerator/denominator)
run_script("07_robustness_ovb.R")        # Omitted variable bias → table_its_robustness (paper)
run_script("08_robustness_monthly.R")    # Monthly-frequency replication
run_script("09_robustness_smoothing.R")  # Moving-average / Almon PDL
run_script("10_seasonality_diagnostics.R") # Seasonality figures and tests


# =============================================================================
# STAGE 6 — Decomposition & Mechanisms
# =============================================================================
# 11_decomp_within_between.R outputs:
#   Tables : table_decomp.tex              → Table 7 in paper    (tab:decomp)
#   Figures: fig_decomp_timeseries.pdf/.png → Figure 6 in paper  (fig:decomp_timeseries)
#            fig_decomp_occ.pdf/.png        → Figure 7 in paper  (fig:decomp_occ)
#
# 12_mechanisms_remoteshare.R outputs:
#   Tables : table_remote_channel.tex       → Table 8 in paper        (tab:remote_channel)
#            table_remote_channel_events.tex → Table 9 in paper       (tab:remote_channel_evt)
#            table_first_stage_remote.tex    → Table 10 in paper      (tab:first_stage_remote)
run_script("11_decomp_within_between.R") # Within/between occupation decomposition
run_script("12_mechanisms_remoteshare.R") # Causal mediation via remote share

# =============================================================================
# Done
# =============================================================================
message("\n", strrep("=", 70))
message("Pipeline complete.  [", format(Sys.time(), "%H:%M:%S"), "]")
message("Tables  -> ", file.path(pkg_root, "output", "tables"))
message("Figures -> ", file.path(pkg_root, "output", "figures"))
message(strrep("=", 70), "\n")
