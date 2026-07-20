# Paper Analytics — Progress

Status: **paused; work will continue later**

This file records the preparation status of the datasets, Python notebooks, and forthcoming R project used to reproduce the analyses reported in the paper.

## Agreed repository structure

- `data/paper-analytics/` — interim, analysis-ready, and external reference data
- `notebooks/paper-analytics/` — Python data-preparation and analysis notebooks
- `code/paper-analytics/` — forthcoming R project and R analysis scripts
- `output/paper-analytics/` — generated tables and figures

## Completed work

### 1. Vacancy-level analysis dataset

Prepared notebook:

- `notebooks/paper-analytics/01_build_analysis_ready_vacancy_data.ipynb`

Decisions and changes:

- the Parquet implementation was selected instead of the JSON implementation;
- the notebook reads Stage 5 monthly data from `data/data-pipeline/stage_05/parquet_monthly_full/`;
- all paths are repository-relative and independent of `.env`;
- required directories are created automatically;
- monthly observations are collapsed within years and then across years;
- the final dataset contains one row per vacancy identifier;
- fields required by the downstream analysis are retained, including vacancy titles, ESCO classifications, regions, salary fields, coordinates, classified occupations, language, and skill labels;
- yearly intermediates are written to `data/paper-analytics/interim/`;
- the final file is written to `data/paper-analytics/analysis-ready/vacancies_2021_2025_collapsed_by_id.parquet`;
- the notebook was not executed because of its memory requirements;
- notebook JSON and Python syntax were checked statically.

### 2. Descriptive and composition analysis

Prepared notebook:

- `notebooks/paper-analytics/02_analyze_vacancy_skills_and_occupation_composition.ipynb`

Decisions and changes:

- the notebook reads the final Parquet file created by notebook 01 rather than JSON or the monthly Stage 5 files;
- machine-specific absolute paths were replaced with repository-relative paths;
- input files and required columns are validated before use;
- figures are written to `output/paper-analytics/figures/`;
- duplicate figure filenames were replaced with unique descriptive names to prevent overwriting;
- weekly output is written to `data/paper-analytics/analysis-ready/vacancy_skill_conflict_weekly.parquet`;
- monthly output is written to `data/paper-analytics/analysis-ready/vacancy_skill_conflict_monthly.parquet`;
- unused WordCloud and setup cells were removed;
- `scipy` and `openpyxl` were added to `requirements.txt`;
- the notebook was not executed;
- all 202 retained code cells passed static Python-syntax validation and contain no stored outputs or absolute paths.

## External reference files still required

The following files must be provided before notebook 02 can be run completely:

- `data/paper-analytics/reference/esco/digitalSkillsCollection_en.csv`
- `data/paper-analytics/reference/esco/greenSkillsCollection_en.csv`
- `data/paper-analytics/reference/acled/europe-central-asia_full_data_up_to-2025-07-25.xlsx`

The source, version, access date, redistribution permission, and public-availability status of each reference dataset must be documented before publication.

## Work remaining when this stage resumes

1. Add and document the ESCO and ACLED reference files.
2. Review notebook 02 section by section against the manuscript and retain only calculations that reproduce reported tables, figures, or required supplementary results.
3. Check analytical definitions, filters, dates, labels, and output filenames against the manuscript.
4. Run notebook 01 in a suitably provisioned environment and validate its row counts, date coverage, schemas, and unique identifiers.
5. Run notebook 02 after its inputs are available and compare all retained outputs with the manuscript.
6. Add the R project and connect its input paths to the analysis-ready Parquet datasets.
7. Document the final execution order, software environment, input provenance, and table/figure mapping in the main replication README.

This stage is **not complete** and should not yet be treated as publication-ready.
