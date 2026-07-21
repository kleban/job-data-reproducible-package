# Python Paper-Analytics Notebooks

These notebooks bridge the complete Stage 5 monthly vacancy data to descriptive paper-analysis datasets and figures. They are separate from the final R statistical project.

## Order and role

| Order | Notebook | Purpose | Status |
|---:|---|---|---|
| 1 | `01_build_analysis_ready_vacancy_data.ipynb` | Collapse complete monthly full Parquet files to one row per vacancy ID | Prepared and statically validated; not executed on full data |
| 2 | `02_analyze_vacancy_skills_and_occupation_composition.ipynb` | Produce vacancy, skill, occupation, remote-work, and conflict-related descriptive outputs; write weekly/monthly datasets | Prepared and statically validated; ESCO inputs included, ACLED input missing, and not executed |

Both notebooks locate the repository root automatically. They do not use the pipeline `.env` and contain no machine-specific paths.

## Notebook 01

Input:

```text
data/data-pipeline/stage_05/parquet_monthly_full/<year>-<month>.parquet
```

Outputs:

```text
data/paper-analytics/interim/vacancies_<year>_collapsed_by_id.parquet
data/paper-analytics/analysis-ready/vacancies_2021_2025_collapsed_by_id.parquet
```

The notebook validates required columns, filters Ukraine using the retained workflow definition, applies consistent vacancy-ID aggregation rules, preserves fields needed downstream, writes yearly intermediates, and removes cross-year duplicates.

The public Stage 5 folder currently contains only a synthetic demonstration month. A complete 2021–2025 monthly collection is required for the substantive output.

## Notebook 02

Primary input:

```text
data/paper-analytics/analysis-ready/vacancies_2021_2025_collapsed_by_id.parquet
```

Additional reference inputs:

```text
data/paper-analytics/reference/esco/digitalSkillsCollection_en.csv
data/paper-analytics/reference/esco/greenSkillsCollection_en.csv
data/paper-analytics/reference/acled/europe-central-asia_full_data_up_to-2025-07-25.xlsx
```

Outputs:

```text
data/paper-analytics/analysis-ready/vacancy_skill_conflict_weekly.parquet
data/paper-analytics/analysis-ready/vacancy_skill_conflict_monthly.parquet
output/paper-analytics/figures/
```

Alternative figures have unique filenames so later cells do not overwrite earlier outputs. The notebook contains no stored execution output.

## Computational warning

These notebooks load and aggregate large vacancy datasets and can require substantial RAM. They were intentionally not executed during repository preparation. Run them manually in a suitably provisioned environment after all inputs are available.

## Relationship to the R project

The R project currently reads its own bundled files named `final_weekly.parquet`, `final_monthly.parquet`, and `final_dataset_occ_digital_month.parquet`. Do not assume those files are identical to the planned Python outputs solely from their role. Compare schemas, coverage, row counts, and derived-variable definitions before replacing or deduplicating them.
