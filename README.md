# Replication Package: Labor Demand for Digital Skills in Post-2022 Ukraine

**Paper:** *Labor Demand for Digital Skills in Post-2022 Ukraine: Evidence from Online Job Vacancy Data*
**Authors:** Yurii Kleban and Britta Rude
**Journal and article DOI:** To be added after acceptance/publication
**Mendeley Data DOI:** To be added after the approved package is published

## Overview

This repository is being prepared as the replication package for the paper. It will contain two separate but connected workflows:

1. **Data pipeline (Python):** converts daily Ukrainian job-vacancy files into cleaned, enriched, monthly research datasets.
2. **Paper analytics (R):** will read the final Python outputs and reproduce the manuscript's statistical analysis, tables, and figures.

The current preparation stage covers the **Python data pipeline only**. The R paper-analytics folders and scripts have not yet been added.

There is intentionally no single pipeline entry point. Each Jupyter notebook represents a separate processing step and must be run manually in the documented order.

## Data availability

The repository currently includes a **100-row synthetic input file**, `ua-2024-01-01.json`, so that the structure and notebook workflow can be inspected without exposing original vacancy records. The synthetic file preserves the expected fields and formats but does not contain real vacancies.

The public-sharing status of the complete raw and analysis data is still to be finalized. Before publication, the README must identify every source, document any restriction, and distinguish clearly between original, pseudo, intermediate, and analysis-ready data. The current synthetic file must not be treated as sufficient to reproduce the paper's substantive conclusions.

See [the input-data documentation](data/data-pipeline/input/README_data.md) for the demonstrated schema.

## Repository structure

```text
mendely-paper-repository/
|-- README.md
|-- SETUP.md
|-- requirements.txt
|-- progress.md
|-- code/
|   `-- data-pipeline/
|       |-- README.md
|       |-- general.py
|       |-- stage1.py
|       |-- stage2.py
|       |-- stage3.py
|       `-- stage4.py
|-- notebooks/
|   `-- data-pipeline/
|       |-- README.md
|       |-- .env.example
|       |-- before_start_test_environment.ipynb
|       `-- stage_*.ipynb
|-- data/
|   `-- data-pipeline/
|       |-- README.md
|       |-- input/
|       |-- stage_01/
|       |-- stage_01_2/
|       |-- stage_02/
|       |-- stage_03/
|       |-- stage_04/
|       |-- stage_04_5/
|       `-- stage_05/
`-- manuscript/
```

The future R workflow will use parallel `paper-analytics` folders under `code/`, `notebooks/` if notebooks are needed, and `data/`. It will not be mixed into the Python data-pipeline folders.

## Documentation map

| Document | Purpose |
|---|---|
| [SETUP.md](SETUP.md) | Python environment and local configuration |
| [Notebook guide](notebooks/data-pipeline/README.md) | Required notebook order and execution rules |
| [Python module guide](code/data-pipeline/README.md) | Shared modules imported by the notebooks |
| [Data guide](data/data-pipeline/README.md) | Data layers, stages, and detailed data dictionaries |
| [requirements.txt](requirements.txt) | Pinned Python dependencies |
| [progress.md](progress.md) | Preparation progress and journal checklist |

## Data-pipeline flow

```text
data/data-pipeline/input/
        |
        v
Stage 1: clean, deduplicate, and detect language
        |
        v
Stage 2: extract skills and classify work mode
        |
        v
Stage 3: classify occupations with the OpenAI Batch API
        |
        v
Stage 4: verify ESCO occupations and attach ESCO skills
        |
        v
Stage 4.5: standardize regions using the included lookup database
        |
        v
Stage 5: join daily data and aggregate monthly datasets
        |
        v
data/data-pipeline/stage_05/
```

## How to run the Python data pipeline

### 1. Prepare the environment

Follow [SETUP.md](SETUP.md). In brief:

```powershell
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
Copy-Item notebooks\data-pipeline\.env.example notebooks\data-pipeline\.env
```

Add an OpenAI API key to the local `.env` only if rerunning API-dependent stages. Never publish or commit a live credential.

### 2. Start Jupyter from the notebook folder

Start Jupyter from the notebook folder:

```powershell
Set-Location notebooks\data-pipeline
jupyter notebook
```

The processing notebooks call `pipeline_bootstrap.py`, which locates the shared code and sets the working directory used by `.env` before the pipeline modules are imported.

### 3. Verify the environment

Open `before_start_test_environment.ipynb` and run its cells from top to bottom.

### 4. Run notebooks separately in this order

| Order | Notebook | Role | Normal replication action |
|---:|---|---|---|
| 0 | `before_start_test_environment.ipynb` | Verify dependencies and configuration | Run |
| 1 | `stage_1_read_initial_data_fast.ipynb` | Load, deduplicate, clean, and identify language | Run |
| 1.2 | `stage_01_5_interim_translate_skills.ipynb` | Translate ESCO skill labels to Russian | Skip; included output is precomputed |
| 2.1 | `stage_2_1_skills_extration.ipynb` | Extract candidate ESCO skills | Run |
| 2.2 | `stage_2_2_add_romote_jobs.ipynb` | Add work-mode classification | Run |
| 3.1 | `stage_3_1_classification_create_input_files.ipynb` | Build first-pass Batch API input | Run if API stage is being reproduced |
| 3.2 | `stage_3_2_classification_check_jobs.ipynb` | Submit/check first-pass jobs | Run, wait, and rerun after completion |
| 3.3 | `stage_3_3_classification_extract_results.ipynb` | Download/extract first-pass results | Run |
| 3.4 | `stage_3_4_split_missing_and_complete_cases.ipynb` | Separate missing classifications | Run |
| 3.5 | `stage_3_5_classification_missing_skills_create_input_files.ipynb` | Build second-pass input | Run when missing cases exist |
| 3.6 | `stage_3_6_classification_missing_check_jobs.ipynb` | Submit/check second-pass jobs | Run, wait, and rerun after completion |
| 3.7 | `stage_3_7_classification_missed_extract_results.ipynb` | Extract and merge second-pass results | Run |
| 4 | `stage_4_esco_skills_extraction.ipynb` | Verify ESCO titles and retrieve skills | Run |
| 4.5 | `stage_4_5_region_enrichment.ipynb` | Rebuild region lookup data | Skip; included lookup is precomputed |
| 5.1 | `stage_5_1_rejoin_daily_unique_files.ipynb` | Join enriched unique daily data | Run |
| 5.2 | `stage_5_2_to_monthly_unique.ipynb` | Aggregate unique data by month | Run |
| 5.3 | `stage_5_3_rejoin_full_files.ipynb` | Join enriched full daily data | Run |
| 5.4 | `stage_5_4_to_monthly_full.ipynb` | Aggregate full data by month | Run |

Run every selected notebook from its first cell to its last cell before moving to the next notebook. Batch API notebooks are asynchronous and may require a pause and a later rerun.

## Dependencies and external services

Pinned Python packages are listed in `requirements.txt`. Major dependencies include pandas, NumPy, PyTorch, sentence-transformers, fast-langdetect, OpenAI, and RapidFuzz.

Stages 3 and 4.5 use the OpenAI Batch API when rerun. API calls may incur costs and may not reproduce byte-identical outputs if the service or model changes. The approved replication package should therefore include the permitted precomputed outputs and document the model/version used.

## Expected Python outputs

Stage 5 writes the final monthly data-pipeline outputs under:

- `data/data-pipeline/stage_05/parquet_monthly_unique/`
- `data/data-pipeline/stage_05/parquet_monthly_full/`
- corresponding JSON folders under the same `stage_05/` directory

These files will become inputs to the future R paper-analytics workflow. At the present stage, this repository does not yet map R scripts to manuscript tables or figures.

## Reproducibility status

The package remains under preparation. An unchecked item in [progress.md](progress.md) must not be interpreted as complete. In particular, the final data-availability statement, Mendeley Data DOI, paper-analysis code, and table/figure mapping remain pending.
