# Paper Analytics — Progress

Status: **structure and documentation aligned; data completion and runtime validation remain pending**

This file records the preparation status of the datasets, Python notebooks, and integrated R project used to reproduce the analyses reported in the paper.

## Agreed repository structure

- `data/paper-analytics/` — interim, analysis-ready, and external reference data
- `notebooks/paper-analytics/` — Python data-preparation and analysis notebooks
- `code/paper-analytics/` — integrated self-contained R project and R analysis scripts
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

## External reference files

Included and structurally validated on 2026-07-21:

- `data/paper-analytics/reference/esco/digitalSkillsCollection_en.csv`
- `data/paper-analytics/reference/esco/greenSkillsCollection_en.csv`

Their row counts, schemas, sizes, and SHA-256 checksums are documented in `data/paper-analytics/reference/esco/README.md`. Exact ESCO release, source URL, access date, and license metadata still require confirmation.

Still required before notebook 02 can run completely:

- `data/paper-analytics/reference/acled/europe-central-asia_full_data_up_to-2025-07-25.xlsx`

The same ACLED source is also required by the integrated R project. The canonical downloaded copy will be stored under `data/paper-analytics/reference/acled/`; a byte-identical copy with the same SHA-256 checksum must be placed in the R project's `data/` directory.

## Integrated R project

The prepared R reproducibility project has been moved to:

- `code/paper-analytics/reproducibility_package/`

The `.Rproj`, `.Rprofile`, `renv.lock`, `renv/`, `DESCRIPTION`, R scripts, bundled analysis datasets, and Excel inputs were retained together. Machine-specific absolute paths were replaced with paths resolved from the R project root. No analytical specifications were changed.

Bundled inputs currently present in the R project:

- `data/final_weekly.parquet`
- `data/final_monthly.parquet`
- `data/final_dataset_occ_digital_month.parquet`
- `data/2025_10_14_electricity_outages.xlsx`
- `data/2025_10_14_elektro_boiovi_dii_ukraina_minenergo.xlsx`

Pending R input:

- `data/europe-central-asia_full_data_up_to-2025-07-25.xlsx`

The source, version, access date, redistribution permission, and public-availability status of each reference dataset must be documented before publication.

## Work remaining when this stage resumes

1. Complete the ESCO source/license metadata and add/document the ACLED reference file.
2. Review notebook 02 section by section against the manuscript and retain only calculations that reproduce reported tables, figures, or required supplementary results.
3. Check analytical definitions, filters, dates, labels, and output filenames against the manuscript.
4. Run notebook 01 in a suitably provisioned environment and validate its row counts, date coverage, schemas, and unique identifiers.
5. Run notebook 02 after its inputs are available and compare all retained outputs with the manuscript.
6. Confirm the provenance and analytical equivalence of the bundled R Parquet inputs and the planned Python weekly/monthly outputs before replacing or deduplicating either set.
7. Update the final execution inventory, table/figure mapping, and availability statements after runtime validation and manuscript comparison.

This stage is **not complete** and should not yet be treated as publication-ready.
