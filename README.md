# Job Vacancy Data Pipeline — Reproducibility Repository

This repository contains the full data preprocessing pipeline accompanying the paper:

> **Labor Demand for Digital Skills during Wartime: Evidence from Russia's Invasion of Ukraine**
> Yurii Kleban, Britta Rude
> [Journal / Conference], 2026
> DOI: [doi]

The pipeline processes daily Ukrainian job vacancy snapshots into structured
monthly datasets enriched with skills, ESCO taxonomy mappings, and regional data.

---

## Repository structure

```
mendely-paper-repository/
│
├── README.md               ← this file
├── SETUP.md                ← environment setup instructions
├── requirements.txt        ← Python dependencies with pinned versions
├── .env                    ← path and API key configuration (placeholders)
│
├── notebooks/              ← Jupyter notebooks, one per pipeline step
│   ├── before_start_test_environment.ipynb
│   ├── stage_1_read_initial_data_fast.ipynb
│   ├── stage_2_1_skills_extration.ipynb
│   ├── stage_2_2_add_romote_jobs.ipynb
│   ├── stage_3_1_classification_create_input_files.ipynb
│   ├── stage_3_2_classification_check_jobs.ipynb
│   ├── stage_3_3_classification_extract_results.ipynb
│   ├── stage_3_4_split_missing_and_complete_cases.ipynb
│   ├── stage_3_5_classification_missing_skills_create_input_files.ipynb
│   ├── stage_3_6_classification_missing_check_jobs.ipynb
│   ├── stage_3_7_classification_missed_extract_results.ipynb
│   ├── stage_4_esco_skills_extraction.ipynb
│   ├── stage_4_5_region_enrichment.ipynb
│   ├── stage_5_1_rejoin_daily_unique_files.ipynb
│   ├── stage_5_2_to_monthly_unique.ipynb
│   ├── stage_5_3_rejoin_full_files.ipynb
│   └── stage_5_4_to_monthly_full.ipynb
│
├── code/                   ← shared Python modules imported by notebooks
│   ├── general.py          ← utility functions and Config class (.env loader)
│   ├── stage1.py           ← Stage 1 processing functions
│   ├── stage2.py           ← Stage 2 processing functions
│   ├── stage3.py           ← Stage 3 processing functions
│   ├── stage4.py           ← Stage 4 processing functions
│   ├── stage5.py           ← Stage 5 processing functions
│   └── stats.py            ← statistics and visualisation utilities
│
├── manuscript/             ← paper documents
│
└── data/
    ├── input/              ← raw input JSON files (demo: ua-2024-01-01.json)
    ├── stage_01/           ← Stage 1 outputs (intermediate, processed)
    ├── stage_01_2/         ← Stage 1.2 interim outputs
    ├── stage_02/           ← Stage 2 outputs (intermediate, processed)
    ├── stage_03/           ← Stage 3 outputs
    ├── stage_04/           ← Stage 4 outputs
    ├── stage_04_5/         ← Stage 4.5 outputs
    └── stage_05/           ← Stage 5 outputs (final monthly datasets)
```

---

## Pipeline overview

The pipeline transforms raw daily job vacancy JSON files into monthly aggregated
datasets enriched with skills, language labels, ESCO taxonomy codes, and regions.

### Stage 0 — Environment setup

Configure the Python environment and verify all dependencies before running
any pipeline notebooks. See [SETUP.md](SETUP.md) for full instructions.

### Stage 1 — Load and assemble raw data

Reads daily JSON snapshots from `data/input/`, deduplicates records using a
persistent ID database, cleans text (removes dates, salaries, emoji), and
detects the language of each vacancy title and description.

| Notebook | Description |
|----------|-------------|
| `stage_1_read_initial_data_fast.ipynb` | Main loader — processes all input files, cleans text, detects languages, reconciles regional data |

**Processing steps inside the notebook:**
1. Scans `data/input/` and builds a process tracker (one row per file)
2. Deduplicates raw records by title, description, salary, and region
3. Saves per-file id/region/clicks snapshots to `data/stage_01/intermediate/id_region_click/`
4. Filters to only job IDs not seen in previous files (global unique ID database)
5. Cleans text — removes dates, salaries, emoji, normalises characters
6. Detects language of title and description; keeps: `en`, `uk`, `ru`, `cs`, `pl`
7. Reconciles regional snapshots against the deduplicated cleaned dataset

**Input:** `data/input/ua-YYYY-MM-DD.json` (demo: `ua-2024-01-01.json`, 100 rows)

**Output:** cleaned daily pickle files in `data/stage_01/processed/output/`

### Stage 1.2 — Translate ESCO skills to Russian (already completed)

The ESCO taxonomy does not natively include Russian-language skill labels.
Since a significant share of Ukrainian job vacancies are written in Russian,
this step uses the **OpenAI Batch API (`gpt-4.1-mini`)** to translate all
~13,900 ESCO skill entries from English to Russian.

| Notebook | Description |
|----------|-------------|
| `stage_01_5_interim_translate_skills.ipynb` | Builds Batch API input, submits translation job, polls for completion, downloads and merges results into `skills_ru.csv` |

> **This step has already been completed.** `skills_ru.csv` is included in
> `data/stage_01_2/processed/` and will be picked up automatically by Stage 2.
> Only rerun if you want to improve the translation — doing so requires an
> OpenAI API key and may take up to 24 hours.

**Input:** `data/stage_01_2/processed/skills_en.csv` (ESCO skills in English)

**Output:** `data/stage_01_2/processed/skills_ru.csv` (Russian translations)

### Stage 2 — Skills extraction and work-mode classification

Extracts ESCO skill mentions from job descriptions using multilingual
sentence-transformer embeddings, then classifies each posting by work mode
(remote / in-office / combined / undefined).

| Notebook | Description |
|----------|-------------|
| `stage_2_1_skills_extration.ipynb` | Encodes job descriptions and retrieves top-K matching ESCO skills via cosine similarity against a pre-encoded skill index (preferredLabel + altLabels) |
| `stage_2_2_add_romote_jobs.ipynb` | Classifies each posting as `remote`, `in_office`, `combined`, or `undefined` using regex hints and semantic similarity to multilingual templates |

**Processing steps — Notebook 2.1:**
1. Syncs Stage 2 process tracker with Stage 1 completed files
2. Loads multilingual model `paraphrase-multilingual-mpnet-base-v2`
3. Builds per-language skill embedding indexes from CSV files in `data/stage_02/processed/skills/`
4. For each posting, splits description into sentences, encodes them, and retrieves top-20 ESCO skills (cosine similarity ≥ 0.50)
5. Stores results as comma-separated `skill_ids` and `skill_labels` columns

**Processing steps — Notebook 2.2:**
1. Loads the work-mode detection model `paraphrase-multilingual-MiniLM-L12-v2`
2. For each posting, applies regex hints and semantic scoring against 5-language templates
3. Adds `job_type` (label) and `job_type_score` (confidence) columns in-place

**Skills reference data:** `data/stage_02/processed/skills/` — ESCO skill CSVs in 5 languages (EN, UK, RU, CS, PL)

**Input:** Stage 1 output pickles from `data/stage_01/processed/output/`

**Output:** enriched pickles with skill and work-mode columns in `data/stage_02/processed/output/`

### Stage 3 — LLM-based job classification (OpenAI Batch API)

Classifies job vacancies using the OpenAI Batch API. The process is split into
multiple steps: creating batch input files, submitting and monitoring jobs,
extracting results, and handling records with missing classification.

> **Requires an OpenAI API key.** Set `OPENAI_API_KEY` in your `.env` file.
> Steps 2 and 6 must be run **after the Batch API jobs complete** (asynchronous).

| Notebook | Description |
|----------|-------------|
| `stage_3_1_classification_create_input_files.ipynb` | Creates JSONL batch input files |
| `stage_3_2_classification_check_jobs.ipynb` | Submits batches and monitors job status *(run after API completes)* |
| `stage_3_3_classification_extract_results.ipynb` | Downloads and extracts classification results |
| `stage_3_4_split_missing_and_complete_cases.ipynb` | Separates complete from missing classifications |
| `stage_3_5_classification_missing_skills_create_input_files.ipynb` | Re-creates inputs for missing records |
| `stage_3_6_classification_missing_check_jobs.ipynb` | Re-submits missing records *(run after API completes)* |
| `stage_3_7_classification_missed_extract_results.ipynb` | Extracts results for previously missing records |

**Output:** classified records in `data/stage_03/processed/`

### Stage 4 — ESCO skills mapping and region enrichment

Maps extracted skills to the ESCO taxonomy using fuzzy matching, then enriches
records with standardised regional data via the OpenAI Batch API.

> **Requires an OpenAI API key** for the region enrichment step (stage_4_5).

| Notebook | Description |
|----------|-------------|
| `stage_4_esco_skills_extraction.ipynb` | Maps skills to ESCO taxonomy via fuzzy matching |
| `stage_4_5_region_enrichment.ipynb` | Enriches records with standardised region labels |

**Output:** ESCO-enriched records in `data/stage_04/processed/`

### Stage 5 — Final aggregation (daily → monthly)

Rejoins all processed daily files and aggregates them into monthly datasets.
Produces both deduplicated (unique) and full versions in JSON and Parquet formats.

| Notebook | Description |
|----------|-------------|
| `stage_5_1_rejoin_daily_unique_files.ipynb` | Rejoins deduplicated daily files |
| `stage_5_2_to_monthly_unique.ipynb` | Aggregates unique records to monthly level |
| `stage_5_3_rejoin_full_files.ipynb` | Rejoins full (non-deduplicated) daily files |
| `stage_5_4_to_monthly_full.ipynb` | Aggregates full records to monthly level |

**Output:** monthly Parquet and JSON files in `data/stage_05/processed/`

---

## How to run

### 1. Set up the environment

Follow the instructions in [SETUP.md](SETUP.md):

```bash
python -m venv .venv
.venv\Scripts\activate          # Windows
# source .venv/bin/activate     # macOS / Linux
pip install -r requirements.txt
```

### 2. Configure paths and API key

Edit `.env` and set your `OPENAI_API_KEY` (required for Stages 3 and 4.5).
All data paths are pre-configured to match this repository's folder structure.

### 3. Test the environment

Open `notebooks/before_start_test_environment.ipynb` and run all cells.
All cells should show ✅ before proceeding.

### 4. Run the pipeline notebooks in order

Open Jupyter and run notebooks in the following sequence:

```
Stage 1:  stage_1_read_initial_data_fast.ipynb
Stage 1.2: stage_01_5_interim_translate_skills.ipynb  ← already done, skip unless redoing translation

Stage 2:  stage_2_1_skills_extration.ipynb
          stage_2_2_add_romote_jobs.ipynb

Stage 3:  stage_3_1_classification_create_input_files.ipynb
          stage_3_2_classification_check_jobs.ipynb        ← wait for Batch API
          stage_3_3_classification_extract_results.ipynb
          stage_3_4_split_missing_and_complete_cases.ipynb
          stage_3_5_classification_missing_skills_create_input_files.ipynb
          stage_3_6_classification_missing_check_jobs.ipynb ← wait for Batch API
          stage_3_7_classification_missed_extract_results.ipynb

Stage 4:  stage_4_esco_skills_extraction.ipynb
          stage_4_5_region_enrichment.ipynb

Stage 5:  stage_5_1_rejoin_daily_unique_files.ipynb
          stage_5_2_to_monthly_unique.ipynb
          stage_5_3_rejoin_full_files.ipynb
          stage_5_4_to_monthly_full.ipynb
```

> **Note on Batch API steps:** Notebooks `stage_3_2`, `stage_3_6` submit jobs
> to the OpenAI Batch API and must be re-run **after the jobs complete**
> (typically within 24 hours). Do not proceed to the next notebook until the
> batch status is `completed`.

---

## Data

The `data/input/` folder contains one synthetic demo file (`ua-2024-01-01.json`,
100 records) that allows running the full pipeline without the original dataset.
See [data/input/README_data.md](data/input/README_data.md) for details on the
data structure.

The original dataset consists of daily job vacancy snapshots scraped from a
Ukrainian job board covering 2021–2025. It is not included in this repository
due to size and licensing constraints.

---

## Dependencies

Python 3.13.12. Full list in [requirements.txt](requirements.txt).

Key packages: `pandas`, `numpy`, `sentence-transformers`, `transformers`,
`torch`, `openai`, `fast-langdetect`, `rapidfuzz`.

---

## Citation

If you use this code or dataset in your research, please cite:

```bibtex
@article{[citekey],
  title   = {Labor Demand for Digital Skills during Wartime: Evidence from Russia's Invasion of Ukraine},
  author  = {Kleban, Yurii and Rude, Britta},
  journal = {[Journal]},
  year    = {2026},
  doi     = {[DOI]}
}
```
