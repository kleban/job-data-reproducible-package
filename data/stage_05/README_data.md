# data/stage_05 — Stage 5 Outputs (Final Monthly Datasets)

## What this stage produces

Stage 5 is the final stage of the pipeline. It combines all enriched per-day outputs
from Stages 1–4.5 into fully joined daily pickles, then aggregates them into monthly
Parquet and JSON files — the research-ready datasets used in the paper.

Two variants are produced at every level:

| Variant | Description |
|---------|-------------|
| **unique** | Deduplicated — each vacancy appears only once (on the day it was first published) |
| **full** | All records — vacancies re-posted on multiple days appear multiple times |

---

## Folder structure

```
data/stage_05/
├── intermediate/
│   ├── process_unique.pkl              ← Stage 5.1 process tracker
│   ├── process_full.pkl                ← Stage 5.3 process tracker
│   ├── pkl_daily_unique/
│   │   └── ua-YYYY-MM-DD.pkl           ← Fully enriched daily unique pickles
│   └── pkl_daily_full/
│       └── ua-YYYY-MM-DD.pkl           ← Fully enriched daily full pickles
└── processed/
    ├── json_daily_unique/
    │   └── ua-YYYY-MM-DD.json          ← Daily unique (all languages)
    ├── json_daily_ua_unique/
    │   └── ua-YYYY-MM-DD.json          ← Daily unique (Ukrainian descriptions only)
    ├── json_daily_full/
    │   └── ua-YYYY-MM-DD.json          ← Daily full (all languages)
    ├── json_daily_ua_full/
    │   └── ua-YYYY-MM-DD.json          ← Daily full (Ukrainian descriptions only)
    ├── parquet_monthly_unique/
    │   └── YYYY-M.parquet              ← Monthly unique (all languages)
    ├── json_monthly_unique/
    │   └── YYYY-M.json                 ← Monthly unique (all languages)
    ├── json_monthly_ua_unique/
    │   └── YYYY-M.json                 ← Monthly unique (Ukrainian only)
    ├── parquet_monthly_full/
    │   └── YYYY-M.parquet              ← Monthly full (all languages)
    └── json_monthly_ua_full/
        └── YYYY-M.parquet              ← Monthly full (Ukrainian only)
```

---

## Files

### `intermediate/process_unique.pkl` / `process_full.pkl`

Pandas DataFrame — one row per Stage 1 id/region/click daily file. Tracks rejoin status.

| Column | Description |
|--------|-------------|
| `input_path` | Filename stem (e.g. `ua-2024-01-01`) |
| `region_path` | Full path to the Stage 1 id/region/click pickle |
| `rejoin_path` | Full path to the output daily pickle (set after completion) |
| `rejoin_status` | `complete` once the file has been processed |

### `intermediate/pkl_daily_unique/ua-YYYY-MM-DD.pkl`
### `intermediate/pkl_daily_full/ua-YYYY-MM-DD.pkl`

Fully enriched daily pickles. Each row is one job vacancy with all pipeline columns joined together.

| Column | Source stage | Description |
|--------|-------------|-------------|
| `id` | Input | Vacancy ID |
| `title` | Input | Original job title |
| `description` | Input | Original job description |
| `min_salary` / `max_salary` | Input | Salary range |
| `currency` | Input | Salary currency |
| `salary_rate` | Input | Salary period (monthly, hourly, etc.) |
| `date_created` / `date_expired` | Input | Vacancy date range |
| `date` | Stage 1 | Publication date (derived from filename) |
| `clean_title` / `clean_desc` | Stage 1 | Cleaned text (no dates, salaries, emoji) |
| `title_lang` / `desc_lang` | Stage 1 | Detected language (`en`, `uk`, `ru`, `cs`, `pl`) |
| `skill_ids` | Stage 2 | Comma-separated ESCO skill concept URIs |
| `skill_labels` | Stage 2 | Comma-separated ESCO skill labels (original language) |
| `skill_labels_en` | Stage 2 | Comma-separated ESCO skill labels (English) |
| `job_type` | Stage 2 | Work mode: `remote`, `in_office`, `combined`, `undefined` |
| `classified_code` | Stage 3 | Raw LLM-assigned ESCO occupation code |
| `classified_title` | Stage 3 | Raw LLM-assigned ESCO occupation title |
| `classified_title_clean` | Stage 4 | Normalised lowercase version of `classified_title` |
| `esco_title` | Stage 4 | Verified ESCO preferred label |
| `esco_id` | Stage 4 | Full ESCO concept URI |
| `esco_code` | Stage 4 | 4-digit ESCO occupation code (verified) |
| `esco_skills` | Stage 4 | JSON list of all ESCO skills for this occupation |
| `extract_type` | Stage 4 | Which matching step resolved the title (`preferredLabel`, `altLabels`, `preferredLabel_fuzzy`, `altLabels_fuzzy`) |
| `number_of_clicks` | Stage 1 | Number of times the vacancy was viewed |
| `region_original` | Stage 4.5 | Raw region string from the job board (Cyrillic) |
| `region` | Stage 4.5 | Standardised English oblast name |
| `city` | Stage 4.5 | City name (English) |
| `district` | Stage 4.5 | District name |
| `country` | Stage 4.5 | Country name |
| `latitude` | Stage 4.5 | Latitude coordinate |
| `longitude` | Stage 4.5 | Longitude coordinate |

### `processed/parquet_monthly_unique/YYYY-M.parquet`
### `processed/parquet_monthly_full/YYYY-M.parquet`

**Primary research output.** Monthly aggregated Parquet files — the datasets used in the paper analysis. Each file contains all vacancies published in a given calendar month. Column schema is identical to the daily pickles above, with the same `selected_columns` subset applied.

Parquet format is used for efficient columnar storage and fast loading with `pandas.read_parquet()`.

### `processed/json_monthly_unique/YYYY-M.json`
### `processed/json_monthly_ua_unique/YYYY-M.json`
### `processed/json_daily_unique/ua-YYYY-MM-DD.json`
### `processed/json_daily_full/ua-YYYY-MM-DD.json`

JSON exports (records orientation). The `_ua_` variants contain only vacancies with Ukrainian-language descriptions (`desc_lang == 'uk'`), suitable for Ukrainian NLP analysis.

---

## Demo output

Running Stage 5 on the demo `ua-2024-01-01.pkl` produces:

- `intermediate/pkl_daily_unique/ua-2024-01-01.pkl` — 100-row enriched pickle
- `processed/json_daily_unique/ua-2024-01-01.json` — same as JSON
- `processed/parquet_monthly_unique/2024-1.parquet` — January 2024 monthly aggregate

Load the final output:
```python
import pandas as pd
df = pd.read_parquet("data/stage_05/processed/parquet_monthly_unique/2024-1.parquet")
df.shape   # (100, 27) for the demo file
df.columns
```
