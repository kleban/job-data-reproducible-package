# Reproducibility Package
## "Labor Demand for Digital Skills in Post-2022 Ukraine: Evidence from Online Job Vacancy Data"

**Authors:** Yurii Kleban, Britta Rude
**R version:** 4.3.0  
**Last updated:** July 2026

---

## Overview

This package contains the complete R code to replicate all tables and figures in
the paper. Starting from the analysis-ready Parquet and supporting Excel files described below, running
`run_all.R` reproduces every table (`output/tables/*.tex`) and figure
(`output/figures/*.pdf` and `*.png`) in the paper.

---

## Folder structure

```
reproducibility_package/
├── R/                          ← Analysis scripts (see pipeline map below)
│   ├── 00_acled_data_prep.R    ← ACLED conflict data aggregation
│   ├── 01_load_data.R          ← Data QC / exploration (optional)
│   ├── 02_baseline_regression.R
│   ├── 03_structural_break.R
│   ├── 04_stationarity.R
│   ├── 05_cointegration_ecm.R
│   ├── 06_decomposition.R
│   ├── 07_robustness_ovb.R
│   ├── 08_robustness_monthly.R
│   ├── 09_robustness_smoothing.R
│   ├── 10_seasonality_diagnostics.R
│   ├── 11_decomp_within_between.R
│   ├── 12_mechanisms_remoteshare.R
│   └── 13_baseline_regression.R
├── data/                       ← Analysis-ready and supporting input files
├── output/
│   ├── figures/                ← Generated figures (.pdf, .png)
│   └── tables/                 ← Generated LaTeX tables (.tex)
├── renv/                       ← renv package library (auto-managed)
├── renv.lock                   ← Locked package versions
├── run_all.R                   ← Master run script
├── ukraine_skills.Rproj        ← RStudio project file (sets working directory)
└── README.md                   ← This file
```

---

## Setup instructions

### 1. Install R

Download and install **R 4.3.0** (or a compatible version ≥ 4.2.0) from
[CRAN](https://cran.r-project.org/).  
We recommend using [RStudio](https://posit.co/download/rstudio-desktop/) as the IDE.

### 2. Open the project

Open `ukraine_skills.Rproj` in RStudio.  
This anchors all relative paths via the `here` package so that scripts run
correctly regardless of where the project folder is located on your machine.

### 3. Restore the package environment

In the R console (inside the project), run:

```r
renv::restore()
```

This reads `renv.lock` and installs every package at the exact version used by the
authors. An internet connection is required on first restore.  
Accept any prompts to activate the renv environment.

> **Tip:** If `renv` itself is not yet installed, run
> `install.packages("renv")` first.

### 4. Check the input files

The five bundled inputs are stored in `data/`. Add the pending ACLED workbook to
that same directory. See [the data description](data/README_data.md) for roles,
provenance notes, and availability status.

### 5. Run the full pipeline

```r
source("run_all.R")
```

Or open `run_all.R` in RStudio and click **Source**.  
The script runs the 12 production scripts (`00` and `02`–`12`) in order and saves outputs to
`output/tables/` and `output/figures/`.  
Total runtime: approximately 10–30 minutes depending on hardware.

> After `renv::restore()` has completed and every input is present, the analysis run itself does not require an external API. Individual scripts can still attempt a CRAN installation if a required R package is missing.

---

## Script pipeline map

The table below documents what each script does, its inputs, and its outputs.

| # | Script | Purpose | Inputs | Key Outputs |
|---|--------|---------|--------|-------------|
| 00 | `00_acled_data_prep.R` | Load ACLED conflict event data, filter to Ukraine, aggregate to monthly and weekly frequency | `data/europe-central-asia_full_data_up_to-*.xlsx` | `acled_uk_monthly.pdf/png`, `acled_uk_weekly.pdf/png` |
| 01 | `01_load_data.R` | Data QC / exploration (optional) | `final_weekly.parquet` | Console output; `final_weekly_clean.rds` |
| 02 | `02_baseline_regression.R` | **Main results** — weekly OLS (Log Fatalities and Log Events) with progressive controls | `final_weekly.parquet`, `2025_10_14_electricity_outages.xlsx`, `2025_10_14_elektro_boiovi_dii_ukraina_minenergo.xlsx` | `table_ols_combined.tex`, `table_ols_events_combined.tex` |
| 03 | `03_structural_break.R` | Structural break tests (Chow, CUSUM, Bai-Perron) + ITS regressions | `final_weekly.parquet` | `table_structural_break.tex`, `table_break_tests.tex`, `fig1_digital_share_structural_break.pdf/png`, `fig3_supF_breakpoints.pdf/png`, `fig4_its_fitted_vs_actual.pdf/png` |
| 04 | `04_stationarity.R` | Unit root tests (ADF, PP, KPSS) + first-difference regressions | `final_weekly.parquet` | `table_unit_roots.tex`, `table_fd_robustness.tex` |
| 05 | `05_cointegration_ecm.R` | Engle-Granger cointegration test + ECM + detrended regressions | `final_weekly.parquet` | `table_cointegration.tex`, `table_ecm.tex`, `table_detrended.tex`, `table_lagged_fd.tex` |
| 06 | `06_decomposition.R` | Decompose digital skill share into numerator (digital postings) vs denominator (total vacancies) | `final_weekly.parquet` | `table_decomposition.tex`, `table_digital_count.tex`, `fig_decomposition.pdf/png` |
| 07 | `07_robustness_ovb.R` | Omitted variable bias robustness — progressive control addition; loads energy Excel files | `final_weekly.parquet`, `2025_10_14_electricity_outages.xlsx`, `2025_10_14_elektro_boiovi_dii_ukraina_minenergo.xlsx` | `table_coef_stability.tex`, `table_its_robustness.tex` |
| 08 | `08_robustness_monthly.R` | Monthly-frequency replication of main OLS models | `final_monthly.parquet` | `table_monthlyols.tex`, `table_monthlyols_events.tex` |
| 09 | `09_robustness_smoothing.R` | Moving-average distributed lag (MADL) + Almon polynomial distributed lag | `final_weekly.parquet` | `table_smoothing_ma.tex`, `table_almon.tex`, `smoothing_coefplot.pdf/png`, `almond_coefplot.pdf/png` |
| 10 | `10_seasonality_diagnostics.R` | Seasonal diagnostics (quarterly mean plots, ACF/PACF, Kruskal-Wallis, Friedman tests) | `final_weekly.parquet` | `fig_seasonal_means.pdf/png`, `fig_acf_*.pdf/png`, `table_seasonality_tests.tex` |
| 11 | `11_decomp_within_between.R` | Within/between occupation Oaxaca-Blinder decomposition | `final_dataset_occ_digital_month.parquet` | `table_decomp.tex`, `fig_decomp_timeseries.pdf/png`, `fig_decomp_occ.pdf/png`, `fig_decomp_counterfactual.pdf/png` |
| 12 | `12_mechanisms_remoteshare.R` | Causal mediation via remote work share (direct/indirect/total effect decomposition) | `final_weekly.parquet` | `table_remote_channel.tex`, `table_remote_channel_events.tex`, `table_first_stage_remote.tex` |

---

## Figure and table mapping (paper → output file)

All `\input{}` and `\includegraphics{}` calls in the Overleaf project have been
audited.  The tables below list every R-generated output that appears in the paper.

### Main text — tables

| LaTeX label | Output file | Script |
|-------------|-------------|--------|
| `tab:ols_combined` | `output/tables/table_ols_combined.tex` | `02_baseline_regression.R` |
| `tab:ols_events_combined` | `output/tables/table_ols_events_combined.tex` | `02_baseline_regression.R` |
| `tab:smoothing_ma` | `output/tables/table_smoothing_ma.tex` | `09_robustness_smoothing.R` |
| `tab:almon` | `output/tables/table_almon.tex` | `09_robustness_smoothing.R` |
| `tab:its_robustness` | `output/tables/table_its_robustness.tex` | `07_robustness_ovb.R` |

### Main text — figures

| LaTeX label | Output file | Script |
|-------------|-------------|--------|
| `fig:structuralbreakraw` | `output/figures/fig1_digital_share_structural_break.pdf` | `03_structural_break.R` |
| `fig:itsfitted` | `output/figures/fig4_its_fitted_vs_actual.pdf` | `03_structural_break.R` |
| `fig:smoothing` | `output/figures/smoothing_coefplot.pdf` | `09_robustness_smoothing.R` |
| `fig:almon` | `output/figures/almond_coefplot.pdf` | `09_robustness_smoothing.R` |

### Robustness section — tables (in appendix)

| LaTeX label | Output file | Script |
|-------------|-------------|--------|
| `tab:monthlyols` | `output/tables/table_monthlyols.tex` | `08_robustness_monthly.R` |
| `tab:monthlyols_events` | `output/tables/table_monthlyols_events.tex` | `08_robustness_monthly.R` |
| `tab:unit_roots` | `output/tables/table_unit_roots.tex` | `04_stationarity.R` |
| `tab:cointegration` | `output/tables/table_cointegration.tex` | `05_cointegration_ecm.R` |
| `tab:ecm` | `output/tables/table_ecm.tex` | `05_cointegration_ecm.R` |
| `tab:detrended` | `output/tables/table_detrended.tex` | `05_cointegration_ecm.R` |

### Mechanisms section — tables and figures

| LaTeX label | Output file | Script |
|-------------|-------------|--------|
| `tab:remote_channel` | `output/tables/table_remote_channel.tex` | `12_mechanisms_remoteshare.R` |
| `tab:remote_channel_evt` | `output/tables/table_remote_channel_events.tex` | `12_mechanisms_remoteshare.R` |
| `tab:decomp` | `output/tables/table_decomp.tex` | `11_decomp_within_between.R` |
| `fig:decomp_timeseries` | `output/figures/fig_decomp_timeseries.pdf` | `11_decomp_within_between.R` |
| `fig:decomp_occ` | `output/figures/fig_decomp_occ.pdf` | `11_decomp_within_between.R` |
| `fig:decomp_counterfactual` | `output/figures/fig_decomp_counterfactual.pdf` | `11_decomp_within_between.R` |

### Appendix — tables and figures

| LaTeX label | Output file | Script |
|-------------|-------------|--------|
| `fig:cusum` | `output/figures/fig2_cusum_test.png` | `03_structural_break.R` |
| `fig:supf` | `output/figures/fig3_supF_breakpoints.pdf` | `03_structural_break.R` |
| `tab:break_tests` | `output/tables/table_break_tests.tex` | `03_structural_break.R` |
| `tab:structural_break` | `output/tables/table_structural_break.tex` | `03_structural_break.R` |
| `tab:digital_count` | `output/tables/table_digital_count.tex` | `06_decomposition.R` |
| `tab:decomposition` | `output/tables/table_decomposition.tex` | `06_decomposition.R` |
| `fig:decomposition` | `output/figures/fig_decomposition.pdf` | `06_decomposition.R` |
| `tab:seasonality` | `output/tables/table_seasonality_tests.tex` | `10_seasonality_diagnostics.R` |
| `fig:seasonal_means` | `output/figures/fig_seasonal_means.pdf` | `10_seasonality_diagnostics.R` |
| `fig:acf_raw` | `output/figures/fig_acf_raw.pdf` | `10_seasonality_diagnostics.R` |
| `fig:acf_demeaned` | `output/figures/fig_acf_demeaned.pdf` | `10_seasonality_diagnostics.R` |
| `tab:first_stage_remote` | `output/tables/table_first_stage_remote.tex` | `12_mechanisms_remoteshare.R` |

### Outputs not referenced in the paper

Some scripts produce additional outputs not cited in the paper:

| Script | Extra output |
|--------|-------------|
| `03_structural_break.R` | `fig1b_digital_share_loess.pdf/png` |
| `04_stationarity.R` | `table_fd_robustness.tex` |
| `05_cointegration_ecm.R` | `table_lagged_fd.tex` |
| `07_robustness_ovb.R` | `table_coef_stability.tex` |

---

## Package dependencies

All R packages are managed with [`renv`](https://rstudio.github.io/renv/).
`renv.lock` records the exact package versions used by the authors.

**Core packages used:**

| Package | Version | Purpose |
|---------|---------|---------|
| `arrow` | 19.0.1.1 | Read Parquet files |
| `tidyverse` | 2.0.0 | Data manipulation and ggplot2 |
| `here` | 1.0.2 | Relative file paths |
| `janitor` | 2.2.1 | Column name cleaning |
| `lubridate` | 1.9.4 | Date arithmetic |
| `strucchange` | 1.5.4 | Chow / CUSUM / Bai-Perron tests |
| `sandwich` | 3.1.1 | Newey-West HAC standard errors |
| `lmtest` | 0.9.40 | Robust coefficient tests |
| `modelsummary` | 2.3.0 | Regression tables |
| `kableExtra` | 1.4.0 | LaTeX table formatting |
| `tseries` | 0.10.58 | ADF, PP, KPSS unit root tests |
| `readxl` | 1.4.5 | Read Excel energy data files |
| `httr` + `jsonlite` | 1.4.7 / 2.0.0 | HTTP utilities (unused in active scripts) |
| `zoo` | 1.8.13 | Moving-average smoothing |
| `msm` | 1.8.2 | Delta-method SEs for Almon PDL |
| `car` | 3.1.3 | F-tests for seasonal dummies |
| `forecast` | 8.24.0 | ACF/PACF plots |
| `patchwork` | 1.3.0 | Combine ggplot panels |
| `skimr` | 2.2.2 | Summary statistics (script 01) |

---

## Known non-reproducible elements and manual steps

1. **Energy data (Scripts 02, 07, and retained alternative script 13):** The electricity outage files
   (`2025_10_14_electricity_outages.xlsx` and
   `2025_10_14_elektro_boiovi_dii_ukraina_minenergo.xlsx`) are bundled in
   `data/`. Their sources are
   [energy-map.info](https://energy-map.info/) and the Ukrainian Ministry of
   Energy respectively.

2. **Job posting data:** The bundled analysis-ready files (`final_weekly.parquet`,
   `final_monthly.parquet`, `final_dataset_occ_digital_month.parquet`) were
   compiled from the restricted Jooble vacancy snapshots. The original snapshots
   are not included; see the repository-level data-availability statement.

3. **ACLED data:** The ACLED data is publicly available and can be downloaded from [the official ACLED website](https://acleddata.com/conflict-data/download-data)

4. **LaTeX compilation:** The `.tex` table files use the `booktabs`, `siunitx`,
   `graphicx`, and `array` LaTeX packages.  Ensure your Overleaf preamble
   includes:
   ```latex
   \usepackage{booktabs}
   \usepackage{siunitx}
   \usepackage{graphicx}
   \usepackage{array}
   ```

---

## Notes on library loading style

Each script follows a self-contained pattern:

1. Declares `packages_needed` at the top.
2. Auto-installs any missing packages before loading.
3. Loads all libraries in a single `suppressPackageStartupMessages({...})` block.

This means each script can be run **independently** (not just via `run_all.R`),
which is convenient for debugging or partial re-runs.

---

## Reproducibility checklist before sharing

- [x] Five bundled Parquet/energy input files are present in `data/`
- [ ] ACLED workbook added to `data/` and its redistribution status documented
- [ ] `renv::restore()` runs without errors
- [ ] `run_all.R` completes end-to-end
- [x] Temporary environment-setup scripts and logs are absent from the published project

---

## Citation

If you use this code, please cite the paper:

> [Yurii Kleban and Britta Rude]. (2026). *Labor Demand for Digital Skills in Post-2022 Ukraine: Evidence from Online Job Vacancy Data*. [World Bank Research Working Paper Series].
