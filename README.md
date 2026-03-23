# Job Vacancy Data Pipeline — Reproducibility Repository

This repository contains the full data preprocessing pipeline accompanying the paper:

> **Labor Demand for Digital Skills during Wartime: Evidence from Russia's Invasion of Ukraine**
> Yurii Kleban, Britta Rude
> [Journal / Conference], 2026
> DOI: [doi]

The pipeline processes daily Ukrainian job vacancy snapshots into structured
monthly datasets enriched with skills, ESCO taxonomy mappings, and regional data.

---

## Quick navigation

| Document | Purpose |
|----------|---------|
| [SETUP.md](SETUP.md) | Environment setup — Python version, venv, dependencies |
| [requirements.txt](requirements.txt) | Pinned Python dependencies |
| [notebooks/.env](notebooks/.env) | Path and API key configuration |
| [data/input/README_data.md](data/input/README_data.md) | Demo input data format |
| [data/stage_01/README_data.md](data/stage_01/README_data.md) | Stage 1 output format |
| [data/stage_01_2/README_data.md](data/stage_01_2/README_data.md) | Stage 1.2 translation artefacts |
| [data/stage_02/README_data.md](data/stage_02/README_data.md) | Stage 2 skills + work-mode output |
| [data/stage_03/README_data.md](data/stage_03/README_data.md) | Stage 3 ESCO classification output |
| [data/stage_04/README_data.md](data/stage_04/README_data.md) | Stage 4 ESCO taxonomy output |
| [data/stage_04_5/README_data.md](data/stage_04_5/README_data.md) | Stage 4.5 region DB (pre-built) |
| [data/stage_05/README_data.md](data/stage_05/README_data.md) | Stage 5 final monthly datasets |

---

## Repository structure

```
mendely-paper-repository/
│
├── README.md               ← this file
├── SETUP.md                ← environment setup instructions
├── requirements.txt        ← Python dependencies with pinned versions
├── notebooks/.env          ← path and API key configuration (placeholders)
│
├── notebooks/              ← Jupyter notebooks, one per pipeline step
│   ├── before_start_test_environment.ipynb
│   ├── stage_1_read_initial_data_fast.ipynb
│   ├── stage_01_5_interim_translate_skills.ipynb
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
│   ├── stage_5_4_to_monthly_full.ipynb
│   └── local_esco_paraphrase_multilingual_mpnet_base_v2/  ← pre-downloaded model
│
├── code/                   ← shared Python modules imported by notebooks
│   ├── general.py          ← utility functions and Config class (.env loader)
│   ├── stage1.py           ← Stage 1: text cleaning, language detection
│   ├── stage2.py           ← Stage 2: skill extraction (SkillRetriever class)
│   ├── stage3.py           ← Stage 3: OpenAI Batch API helpers
│   ├── stage4.py           ← Stage 4: ESCO fuzzy matching, manual corrections
│   ├── stage5.py           ← Stage 5: schema helpers
│   └── stats.py            ← statistics and visualisation utilities
│
├── manuscript/             ← paper PDF
│   └── JobVacancy_Demand_DigitalSkills.pdf
│
└── data/
    ├── input/              ← raw input JSON files (demo: ua-2024-01-01.json)
    ├── stage_01/           ← Stage 1 outputs
    ├── stage_01_2/         ← Stage 1.2 translation artefacts (completed)
    ├── stage_02/           ← Stage 2 outputs
    ├── stage_03/           ← Stage 3 outputs
    ├── stage_04/           ← Stage 4 outputs
    ├── stage_04_5/         ← Stage 4.5 region DB (pre-built, skip rerun)
    └── stage_05/           ← Stage 5 final monthly datasets
```

---

## Pipeline overview

The pipeline transforms raw daily job vacancy JSON files into monthly aggregated
datasets enriched with skills, language labels, ESCO taxonomy codes, and regions.

```
data/input/
  ua-YYYY-MM-DD.json
       │
       ▼
  [Stage 1] Clean text, detect language, deduplicate
       │
       ▼ data/stage_01/processed/output/
  [Stage 1.2] Translate ESCO skills EN→RU  (already done — skip)
       │
       ▼ data/stage_01_2/processed/
  [Stage 2] Extract ESCO skill mentions, classify work mode
       │
       ▼ data/stage_02/processed/output/
  [Stage 3] LLM occupation classification via OpenAI Batch API
       │
       ▼ data/stage_03/processed/result/
  [Stage 4] Verify ESCO title via taxonomy, retrieve skill list
       │
       ▼ data/stage_04/processed/output/
  [Stage 4.5] Standardise region strings via OpenAI Batch API  (already done — skip)
       │
       ▼ data/stage_04_5/processed/region_db.pkl
  [Stage 5.1 / 5.3] Join all outputs → enriched daily pickles
       │
       ▼ data/stage_05/intermediate/pkl_daily_*/
  [Stage 5.2 / 5.4] Aggregate daily → monthly Parquet / JSON
       │
       ▼ data/stage_05/processed/parquet_monthly_*/
```

---

### Stage 0 — Environment setup

Configure the Python environment and verify all dependencies before running
any pipeline notebooks. See [SETUP.md](SETUP.md) for full instructions.

**Python version:** 3.13.12 — install from [python.org](https://www.python.org/downloads/).

**Quick start:**
```bash
python -m venv venv
venv\Scripts\activate           # Windows
# source venv/bin/activate      # macOS / Linux
pip install -r requirements.txt
```

Then open [`notebooks/before_start_test_environment.ipynb`](notebooks/before_start_test_environment.ipynb) and run all cells — all should show ✅.

---

### Stage 1 — Load and assemble raw data

Reads daily JSON snapshots from `data/input/`, deduplicates records using a
persistent ID database, cleans text (removes dates, salaries, emoji), and
detects the language of each vacancy title and description.

| Notebook | Description |
|----------|-------------|
| [`stage_1_read_initial_data_fast.ipynb`](notebooks/stage_1_read_initial_data_fast.ipynb) | Main loader — processes all input files, cleans text, detects languages, reconciles regional data |

**Processing steps:**
1. Scans `data/input/` and builds a process tracker (one row per file)
2. Deduplicates raw records by title, description, salary, and region
3. Saves per-file id/region/clicks snapshots → `data/stage_01/intermediate/id_region_click/`
4. Filters to only job IDs not seen in previous files (global unique ID database)
5. Cleans text — removes dates, salaries, emoji, normalises characters
6. Detects language of title and description; keeps: `en`, `uk`, `ru`, `cs`, `pl`
7. Reconciles regional snapshots against the deduplicated cleaned dataset

**Input:** `data/input/ua-YYYY-MM-DD.json` (demo: [`ua-2024-01-01.json`](data/input/ua-2024-01-01.json), 100 rows)

**Output:** cleaned daily pickles → `data/stage_01/processed/output/`

→ [Stage 1 data documentation](data/stage_01/README_data.md)

---

### Stage 1.2 — Translate ESCO skills to Russian (already completed)

The ESCO taxonomy does not natively include Russian-language skill labels.
Since a significant share of Ukrainian job vacancies are written in Russian,
this step uses the **OpenAI Batch API (`gpt-4.1-mini`)** to translate all
~13,900 ESCO skill entries from English to Russian.

| Notebook | Description |
|----------|-------------|
| [`stage_01_5_interim_translate_skills.ipynb`](notebooks/stage_01_5_interim_translate_skills.ipynb) | Builds Batch API input, submits translation job, polls for completion, downloads and merges results into `skills_ru.csv` |

> ⚠️ **This step has already been completed.** `skills_ru.csv` is included in
> [`data/stage_01_2/processed/`](data/stage_01_2/). Only rerun if you want to
> improve the translation — doing so requires an OpenAI API key and may take up to 24 hours.

**Input:** `data/stage_01_2/processed/skills_en.csv`

**Output:** `data/stage_01_2/processed/skills_ru.csv`

→ [Stage 1.2 data documentation](data/stage_01_2/README_data.md)

---

### Stage 2 — Skills extraction and work-mode classification

Extracts ESCO skill mentions from job descriptions using multilingual
sentence-transformer embeddings, then classifies each posting by work mode
(remote / in-office / combined / undefined).

| Notebook | Description |
|----------|-------------|
| [`stage_2_1_skills_extration.ipynb`](notebooks/stage_2_1_skills_extration.ipynb) | Encodes job descriptions and retrieves top-K matching ESCO skills via cosine similarity against a pre-encoded skill index |
| [`stage_2_2_add_romote_jobs.ipynb`](notebooks/stage_2_2_add_romote_jobs.ipynb) | Classifies each posting as `remote`, `in_office`, `combined`, or `undefined` using regex hints and semantic similarity |

**Processing steps — Notebook 2.1:**
1. Syncs Stage 2 process tracker with Stage 1 completed files
2. Loads multilingual model `paraphrase-multilingual-mpnet-base-v2` from `notebooks/local_esco_paraphrase_multilingual_mpnet_base_v2/`
3. Builds per-language skill embedding indexes from CSVs in `data/stage_02/processed/skills/`
4. For each posting: splits description into sentences, encodes, retrieves top-20 ESCO skills (cosine similarity ≥ 0.50)
5. Stores results as comma-separated `skill_ids` and `skill_labels` columns

**Processing steps — Notebook 2.2:**
1. Loads work-mode detection model `paraphrase-multilingual-MiniLM-L12-v2`
2. Applies regex hints and semantic scoring against 5-language templates
3. Adds `job_type` and `job_type_score` columns in-place

> **No internet required** — the sentence-transformer model is pre-downloaded in
> `notebooks/local_esco_paraphrase_multilingual_mpnet_base_v2/`.

**Input:** Stage 1 pickles from `data/stage_01/processed/output/`

**Output:** enriched pickles → `data/stage_02/processed/output/`

→ [Stage 2 data documentation](data/stage_02/README_data.md)

---

### Stage 3 — LLM occupation classification (OpenAI Batch API)

Classifies each job vacancy with a 4-digit ESCO occupation code and English title
using the **OpenAI Batch API (`gpt-4o-mini`)**. Runs asynchronously in two passes:
first pass classifies all records; second pass resubmits any records that were not
classified in the first pass.

> **Requires an OpenAI API key.** Set `OPENAI_API_KEY` in `notebooks/.env`.
> Notebooks `stage_3_2` and `stage_3_6` must be re-run **after the Batch API jobs
> complete** (typically within minutes to a few hours, up to 24h maximum).

| Notebook | Description |
|----------|-------------|
| [`stage_3_1_classification_create_input_files.ipynb`](notebooks/stage_3_1_classification_create_input_files.ipynb) | Builds JSONL batch input files from Stage 2 output |
| [`stage_3_2_classification_check_jobs.ipynb`](notebooks/stage_3_2_classification_check_jobs.ipynb) | Submits batch jobs, polls status *(re-run after API completes)* |
| [`stage_3_3_classification_extract_results.ipynb`](notebooks/stage_3_3_classification_extract_results.ipynb) | Downloads and extracts first-pass classification results |
| [`stage_3_4_split_missing_and_complete_cases.ipynb`](notebooks/stage_3_4_split_missing_and_complete_cases.ipynb) | Separates complete from unclassified records |
| [`stage_3_5_classification_missing_skills_create_input_files.ipynb`](notebooks/stage_3_5_classification_missing_skills_create_input_files.ipynb) | Builds second-pass JSONL for unclassified records |
| [`stage_3_6_classification_missing_check_jobs.ipynb`](notebooks/stage_3_6_classification_missing_check_jobs.ipynb) | Re-submits missing records *(re-run after API completes)* |
| [`stage_3_7_classification_missed_extract_results.ipynb`](notebooks/stage_3_7_classification_missed_extract_results.ipynb) | Extracts second-pass results and merges into final pickles |

**Input:** Stage 2 output pickles from `data/stage_02/processed/output/`

**Output:** classified daily pickles → `data/stage_03/processed/result/`

→ [Stage 3 data documentation](data/stage_03/README_data.md)

---

### Stage 4 — ESCO occupation verification and skill retrieval

Verifies the LLM-assigned occupation title from Stage 3 against the official
ESCO taxonomy and retrieves the full list of skills associated with each occupation.
Uses a 4-step matching pipeline so that minor LLM formatting variations are resolved
to a canonical ESCO entry.

| Notebook | Description |
|----------|-------------|
| [`stage_4_esco_skills_extraction.ipynb`](notebooks/stage_4_esco_skills_extraction.ipynb) | 4-step ESCO title verification + skill retrieval via occupation–skill relations table |

**Matching pipeline (applied per vacancy):**

| Step | Method | Description |
|------|--------|-------------|
| 1 | `preferredLabel` exact | Cleaned LLM title matched directly against ESCO preferred labels |
| 2 | `altLabels` exact | Checked against the exploded altLabel synonym index |
| 3 | `preferredLabel` fuzzy | `rapidfuzz.token_sort_ratio` (threshold 80) against preferred labels |
| 4 | `altLabels` fuzzy | Fuzzy match against all alternative labels, resolved to preferred label |

**Columns added:** `esco_title`, `esco_id`, `esco_code`, `esco_skills`, `extract_type`

> **No API calls required** — uses only local ESCO reference CSVs in `data/stage_04/raw/esco_data/`.

**Input:** Stage 3 result pickles from `data/stage_03/processed/result/`

**Reference data:** `data/stage_04/raw/esco_data/` — ESCO v1.2.0 (`occupations_en.csv`, `skills_en.csv`, `occupationSkillRelations_en.csv`)

**Output:** enriched pickles → `data/stage_04/processed/output/`

→ [Stage 4 data documentation](data/stage_04/README_data.md)

---

### Stage 4.5 — Region standardisation (already completed)

Standardises raw Ukrainian region strings (Cyrillic / transliterated / abbreviated)
collected during Stage 1 to consistent English oblast names with geographic coordinates,
using the **OpenAI Batch API**. The output lookup table is pre-built and included —
**you do not need to rerun this stage** unless you add new data with previously unseen region strings.

| Notebook | Description |
|----------|-------------|
| [`stage_4_5_region_enrichment.ipynb`](notebooks/stage_4_5_region_enrichment.ipynb) | Identifies new region strings, submits Batch API jobs, merges results into `region_db.pkl` |

> ⚠️ **This step has already been completed.** The pre-built `region_db.pkl` covers all
> ~22,000 unique region strings in the 2021–2025 dataset. Only rerun if you extend the dataset.

**Output columns in `region_db.pkl`:** `original`, `region`, `city`, `district`, `country`, `latitude`, `longitude`

→ [Stage 4.5 data documentation](data/stage_04_5/README_data.md)

---

### Stage 5 — Final aggregation (daily → monthly)

Combines all enriched Stage 1–4.5 outputs into fully joined daily pickles, then
aggregates them into monthly Parquet and JSON files — the research-ready datasets
used in the paper.

Two variants: **unique** (deduplicated — one entry per vacancy on first publication date)
and **full** (all records including re-postings across days).

| Notebook | Description |
|----------|-------------|
| [`stage_5_1_rejoin_daily_unique_files.ipynb`](notebooks/stage_5_1_rejoin_daily_unique_files.ipynb) | Merges Stage 4 + Stage 1 region/click + Stage 4.5 lat/lon → enriched daily unique pickles |
| [`stage_5_2_to_monthly_unique.ipynb`](notebooks/stage_5_2_to_monthly_unique.ipynb) | Concatenates daily unique pickles → monthly Parquet + JSON |
| [`stage_5_3_rejoin_full_files.ipynb`](notebooks/stage_5_3_rejoin_full_files.ipynb) | Same as 5.1 but for all records including re-postings |
| [`stage_5_4_to_monthly_full.ipynb`](notebooks/stage_5_4_to_monthly_full.ipynb) | Concatenates daily full pickles → monthly Parquet |

**Rejoin steps (5.1 / 5.3) per daily file:**
1. Load Stage 1 id/region/click pickle
2. Merge with `region_final_db` → adds `region`, `city`, `district`, `country`, `latitude`, `longitude`
3. Merge with Stage 4 ESCO output on `id`
4. Save `.pkl` + `.json` + `_ua.json` (Ukrainian-language only)

**Output:** `data/stage_05/processed/parquet_monthly_unique/` and `parquet_monthly_full/`

→ [Stage 5 data documentation](data/stage_05/README_data.md)

---

## How to run

### 1. Install Python and set up the environment

See [SETUP.md](SETUP.md) for detailed instructions. Quick version:

```bash
# Python 3.13.12 required — download from python.org
python -m venv venv
venv\Scripts\activate           # Windows
# source venv/bin/activate      # macOS / Linux
pip install -r requirements.txt
```

### 2. Configure paths and API key

Edit [`notebooks/.env`](notebooks/.env):
- Set `OPENAI_API_KEY` (required for Stages 3 and 4.5 only)
- All data paths are pre-configured — do not change unless you move folders

### 3. Test the environment

Open [`notebooks/before_start_test_environment.ipynb`](notebooks/before_start_test_environment.ipynb) and run all cells. All should show ✅ before proceeding.

### 4. Run the pipeline in order

```
before_start_test_environment.ipynb       ← verify setup first

Stage 1:   stage_1_read_initial_data_fast.ipynb
Stage 1.2: stage_01_5_interim_translate_skills.ipynb  ← SKIP (already done)

Stage 2:   stage_2_1_skills_extration.ipynb
           stage_2_2_add_romote_jobs.ipynb

Stage 3:   stage_3_1_classification_create_input_files.ipynb
           stage_3_2_classification_check_jobs.ipynb        ← wait for Batch API
           stage_3_3_classification_extract_results.ipynb
           stage_3_4_split_missing_and_complete_cases.ipynb
           stage_3_5_classification_missing_skills_create_input_files.ipynb
           stage_3_6_classification_missing_check_jobs.ipynb ← wait for Batch API
           stage_3_7_classification_missed_extract_results.ipynb

Stage 4:   stage_4_esco_skills_extraction.ipynb
Stage 4.5: stage_4_5_region_enrichment.ipynb              ← SKIP (already done)

Stage 5:   stage_5_1_rejoin_daily_unique_files.ipynb
           stage_5_2_to_monthly_unique.ipynb
           stage_5_3_rejoin_full_files.ipynb
           stage_5_4_to_monthly_full.ipynb
```

> **Batch API stages (3.2, 3.6):** Submit the job, then wait for completion (minutes to hours). Re-run the same notebook to check status and download results when `status == "completed"`.

> **Stages 1.2 and 4.5:** Pre-completed outputs are included in the repository. Only rerun if extending the dataset.

---

## Data

The `data/input/` folder contains one synthetic demo file
([`ua-2024-01-01.json`](data/input/ua-2024-01-01.json), 100 records) that allows
running the full pipeline end-to-end without the original dataset.

The original dataset consists of daily job vacancy snapshots scraped from a
Ukrainian job board covering 2021–2025. It is not included due to size and
licensing constraints.

### Data folder documentation

| Folder | Contents | Documentation |
|--------|----------|---------------|
| [`data/input/`](data/input/) | Raw input JSON files (demo: synthetic 100-row file) | [README_data.md](data/input/README_data.md) |
| [`data/stage_01/`](data/stage_01/) | Cleaned daily pickles, process tracker, unique ID database | [README_data.md](data/stage_01/README_data.md) |
| [`data/stage_01_2/`](data/stage_01_2/) | ESCO skill translation artefacts (EN→RU, completed) | [README_data.md](data/stage_01_2/README_data.md) |
| [`data/stage_02/`](data/stage_02/) | Skill-labelled pickles, work-mode columns, skill CSVs | [README_data.md](data/stage_02/README_data.md) |
| [`data/stage_03/`](data/stage_03/) | ESCO-classified daily pickles (Batch API) | [README_data.md](data/stage_03/README_data.md) |
| [`data/stage_04/`](data/stage_04/) | ESCO-verified pickles with skill lists | [README_data.md](data/stage_04/README_data.md) |
| [`data/stage_04_5/`](data/stage_04_5/) | Region lookup table with lat/lon (pre-built) | [README_data.md](data/stage_04_5/README_data.md) |
| [`data/stage_05/`](data/stage_05/) | Final monthly Parquet and JSON datasets | [README_data.md](data/stage_05/README_data.md) |

---

## Code modules

| File | Description |
|------|-------------|
| [`code/general.py`](code/general.py) | `Config` class (loads `.env`), `clean_memory()`, text utilities, `check_folder_exists()` |
| [`code/stage1.py`](code/stage1.py) | Text cleaning, language detection (`fast-langdetect`), process tracker management |
| [`code/stage2.py`](code/stage2.py) | `SkillRetriever` class — builds per-language embedding index, cosine similarity retrieval |
| [`code/stage3.py`](code/stage3.py) | OpenAI Batch API helpers — build JSONL, submit job, poll status, extract ESCO codes |
| [`code/stage4.py`](code/stage4.py) | ESCO fuzzy matching helpers (`rapidfuzz`), `manual_data_correction()` |
| [`code/stage5.py`](code/stage5.py) | Schema helpers for final aggregation |
| [`code/stats.py`](code/stats.py) | Statistics aggregation and visualisation utilities |

---

## Dependencies

Python 3.13.12. Full dependency list: [requirements.txt](requirements.txt).

| Package | Purpose |
|---------|---------|
| `pandas`, `numpy` | Data processing |
| `sentence-transformers`, `transformers`, `torch` | Multilingual embeddings (Stage 2) |
| `openai` | Batch API calls (Stages 3, 4.5) |
| `fast-langdetect` | Language detection (Stage 1) |
| `rapidfuzz` | Fuzzy string matching (Stage 4) |
| `pyarrow` | Parquet file support (Stage 5) |
| `python-dotenv` | `.env` loading |

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

---

© 2026 Yurii Kleban, Britta Rude. All rights reserved.
