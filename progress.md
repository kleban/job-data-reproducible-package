## Progress log

## Journal replication-package requirements

Status: authoritative requirements supplied by the journal; compliance is not yet verified.

### Package-level requirements

- [ ] The package allows an independent observer to understand the data, run the code, and reproduce every published conclusion.
- [ ] The complete, approved, and published replication package is deposited in Mendeley Data before final acceptance.
- [ ] A Mendeley Data DOI link is available.
- [ ] The DOI is attached to the journal submission under **File Inventory** as an external item with item type **Research Data**.
- [ ] The repository version and the approved, published Mendeley Data version are consistent.
- Journal sample package: https://data.mendeley.com/datasets/25nymr7878/2

### 1. README checklist

#### 1.1 Title and overview

- [ ] State the paper title.
- [ ] List the authors' names.
- [ ] Provide a brief overview of the replication package.

#### 1.2 Data information

- [ ] State clearly whether the data are publicly available.
- [ ] Describe every data source in sufficient detail.

#### 1.3 Instructions to replicators

- [ ] List every required dependency, package, and library.
- [ ] Provide clear, step-by-step reproduction instructions.
- [ ] List every table and figure reported in the manuscript.
- [ ] Map each reported table and figure to the script that generates it.

### 2. Data sharing

#### 2.1 Raw data

- [ ] Include primary data collected by the authors unless a non-public-data exception applies.
- [ ] Include secondary data that are not otherwise available unless a non-public-data exception applies.
- [ ] When multiple sources are used, include the original raw files from every source rather than only one final combined dataset.

#### 2.2 Analysis data

- [ ] Include analysis-ready data unless a non-public-data exception applies.
- [ ] Ensure analysis-ready files correspond directly to the datasets read by the scripts that reproduce the reported tables and figures.

#### 2.3 Non-public data and pseudo-data

- [ ] Document every public-sharing restriction clearly in the README.
- [ ] For data that cannot be shared, include a pseudo-dataset illustrating the structure and format expected by the code.
- [ ] Preserve in pseudo-data the original variable names, identifiers, number of observations, and approximate means and standard deviations of key variables.

### 3. Code sharing

#### 3.1 Data-management code

- [ ] Include all scripts required to clean, merge, and transform raw data into analysis data.
- [ ] Make clear how each raw file is processed and how each final analysis dataset is constructed.

#### 3.2 Analysis code

- [ ] Include all scripts required to produce manuscript results, including regressions, statistical tests, tables, figures, appendices, and all other reported outputs.

#### 3.3 Script format

- [ ] Provide code in a well-commented, executable source format suitable for the required software.
- [ ] Use clear file paths.
- [ ] Use readable comments.
- [ ] Refer explicitly to the corresponding manuscript tables and figures.

### Repository preparation

- [x] Python assets reorganized under `code/data-pipeline/`, `notebooks/data-pipeline/`, and `data/data-pipeline/`.
- [x] Root, setup, code, notebook, and data documentation updated for the notebook-driven Python workflow.
- [x] Publishable `.env.example` added and local API credentials replaced with placeholders.
- [ ] R paper-analytics structure and files pending a later stage.
- [ ] Runtime notebook validation pending: the current environment uses Python 3.14 with NumPy binaries built for Python 3.13.

- [x] Stage 0 — environment setup
  - [x] requirements.txt generated
  - [x] SETUP.md created
  - [x] Structure Ganerator.ipynb — skipped (folder generation utility, not part of pipeline)
  - [x] .env — placeholders applied
- [ ] Stage 1 — load & assemble raw job vacancy data
  - [x] stage_1_read_initial_data_fast.ipynb — markdown descriptions added, README updated
  - [x] stage_1_0_1_adding_lost_data_2023-2025.ipynb — skipped
  - [x] stage_1_0_2_adding_lost_data_2024_sep-dec.ipynb — skipped
  - [x] stage_1_0_3_add_2021-22__daily_data.ipynb — skipped
  - [x] stage_1_0_4_add_2021-22_monthly_data.ipynb — skipped
  - [x] stage_01_5_interim_translate_skills.ipynb — descriptions added, already completed (no rerun needed)
  - [x] data/data-pipeline/stage_01_2/ — all 5 files copied (skills_en.csv, skills_ru.csv, translate_schema.json, batch files), README_data.md added
  - [x] general.py — docstrings added → code/data-pipeline/general.py
  - [x] stage1.py — docstrings added → code/data-pipeline/stage1.py
  - [x] data/data-pipeline/input/ua-2024-01-01.json — synthetic, 100 rows
  - [x] data/data-pipeline/stage_01/ — README_data.md added
  - [ ] data/data-pipeline/stage_01_2/ — pending
- [ ] Stage 2 — skills extraction
  - [x] stage_2_1_skills_extration.ipynb — descriptions added
  - [x] stage_2_2_add_romote_jobs.ipynb — descriptions added
  - [x] stage2_v2.py — docstrings added → code/data-pipeline/stage2.py
  - [x] data/data-pipeline/stage_02/ — README_data.md added
- [ ] Stage 3 — LLM-based job classification (Batch API)
  - [x] stage_3_1_classification_create_input_files.ipynb — descriptions added, stage2_v2→stage2 fixed
  - [x] stage_3_2_classification_check_jobs.ipynb — descriptions added, stage2_v2→stage2 fixed
  - [x] stage_3_3_classification_extract_results.ipynb — descriptions added, stage2_v2→stage2 fixed
  - [x] stage_3_4_split_missing_and_complete_cases.ipynb — descriptions added
  - [x] stage_3_5_classification_missing_skills_create_input_files.ipynb — descriptions added
  - [x] stage_3_6_classification_missing_check_jobs.ipynb — descriptions added
  - [x] stage_3_7_classification_missed_extract_results.ipynb — descriptions added
  - [x] stage3.py — docstrings added → code/data-pipeline/stage3.py
  - [x] data/data-pipeline/stage_03/ — README_data.md added, all subfolders created, classify_schema.json and classification_prompt.txt copied
- [ ] Stage 4 — ESCO skills mapping + region enrichment
  - [x] stage_4_esco_skills_extraction.ipynb — upgraded with the cleaned v5 matching algorithm, deterministic ESCO-code fallback, full-file processing, and Pickle output compatible with Stage 5
  - [x] stage_4_5_region_enrichment.ipynb — annotated, skip warning added, copyright footer
  - [x] stage4.py — docstrings added, manual_data_correction() shortened with samples
  - [x] data/data-pipeline/stage_04/ — ESCO CSVs copied, output schema documented, README_data.md added
  - [x] data/data-pipeline/stage_04_5/ — reference files + region_db.pkl + sample_1_100.jsonl copied, README_data.md added
- [ ] Stage 5 — final aggregation (daily → monthly)
  - [x] Unused `stage5.py` removed; Stage 5 notebooks do not import it and its helpers duplicate `stage3.py`.
  - [x] stage_5_1_rejoin_daily_unique_files.ipynb — daily unique output changed to Parquet; tracker and statistics use Parquet paths
  - [x] stage_5_2_to_monthly_unique.ipynb — finalized: automatic month discovery, daily Parquet validation, robust schema alignment, and monthly Parquet/JSON outputs
  - [x] stage_5_3_rejoin_full_files.ipynb — finalized as one full-data rejoin pipeline; reads Stage 4 Pickle and writes daily full Parquet/JSON without dropping unresolved rows
  - [x] stage_5_4_to_monthly_full.ipynb — finalized with automatic month discovery, streaming Zstandard Parquet aggregation, safe temporary output, and Ukraine-country JSON
  - [ ] data/data-pipeline/stage_05/ — pending
- [ ] Shared modules
  - [ ] general.py — docstrings added
  - [ ] stats.py — docstrings added
- [x] README.md — initial version created (citation placeholder pending)
- [x] `manuscript/JobVacancy_Demand_DigitalSkills.pdf` updated to the July 19, 2026 manuscript (81 pages).
