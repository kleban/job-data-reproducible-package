# Paper analytics notebooks

This folder contains the notebooks that prepare data and reproduce the analyses reported in the paper.

## Notebook order

1. `01_build_analysis_ready_vacancy_data.ipynb` reads the Stage 5 monthly full Parquet files, selects Ukrainian vacancies, and creates one analysis-ready observation per vacancy identifier.

## Running notebook 01

The notebook may be started from the repository root or from any folder inside the repository. It locates the repository root automatically and does not require `.env` configuration or machine-specific paths.

Input:

- `data/data-pipeline/stage_05/parquet_monthly_full/<year>-<month>.parquet`

Outputs:

- `data/paper-analytics/interim/vacancies_<year>_collapsed_by_id.parquet`
- `data/paper-analytics/analysis-ready/vacancies_2021_2025_collapsed_by_id.parquet`

This notebook processes large monthly files and can require substantial memory. Run it manually in a suitably provisioned environment. Notebook outputs are intentionally cleared in the published package.
