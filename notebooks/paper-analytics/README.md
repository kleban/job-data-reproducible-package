# Paper analytics notebooks

This folder contains the notebooks that prepare data and reproduce the analyses reported in the paper.

## Notebook order

1. `01_build_analysis_ready_vacancy_data.ipynb` reads the Stage 5 monthly full Parquet files, selects Ukrainian vacancies, and creates one analysis-ready observation per vacancy identifier.
2. `02_analyze_vacancy_skills_and_occupation_composition.ipynb` produces the vacancy, occupation, skill, remote-work, and ACLED-related analyses and creates weekly and monthly analytical datasets.

## Running notebook 01

The notebook may be started from the repository root or from any folder inside the repository. It locates the repository root automatically and does not require `.env` configuration or machine-specific paths.

Input:

- `data/data-pipeline/stage_05/parquet_monthly_full/<year>-<month>.parquet`

Outputs:

- `data/paper-analytics/interim/vacancies_<year>_collapsed_by_id.parquet`
- `data/paper-analytics/analysis-ready/vacancies_2021_2025_collapsed_by_id.parquet`

This notebook processes large monthly files and can require substantial memory. Run it manually in a suitably provisioned environment. Notebook outputs are intentionally cleared in the published package.

## Running notebook 02

Notebook 02 reads the final Parquet file created by notebook 01; it does not reread or convert the Stage 5 JSON files.

Additional reference inputs:

- `data/paper-analytics/reference/esco/digitalSkillsCollection_en.csv`
- `data/paper-analytics/reference/esco/greenSkillsCollection_en.csv`
- `data/paper-analytics/reference/acled/europe-central-asia_full_data_up_to-2025-07-25.xlsx`

Outputs:

- figures in `output/paper-analytics/figures/`
- `data/paper-analytics/analysis-ready/vacancy_skill_conflict_weekly.parquet`
- `data/paper-analytics/analysis-ready/vacancy_skill_conflict_monthly.parquet`

The notebook locates the repository root automatically. All input and output paths are repository-relative.
