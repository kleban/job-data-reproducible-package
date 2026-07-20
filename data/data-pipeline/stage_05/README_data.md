# data/data-pipeline/stage_05 вЂ” Stage 5 Outputs (Final Monthly Datasets)

## What this stage produces

Stage 5 is the final stage of the pipeline. It combines all enriched per-day outputs
from Stages 1вЂ“4.5 into fully joined daily files, then aggregates them into monthly
Parquet and JSON files вЂ” the research-ready datasets used in the paper.

Two variants are produced at every level:

| Variant | Description |
|---------|-------------|
| **unique** | Deduplicated вЂ” each vacancy appears only once (on the day it was first published) |
| **full** | All records вЂ” vacancies re-posted on multiple days appear multiple times |

---

## Folder structure

The stage uses a flat layout: data files and named output directories are stored directly under this stage directory. The paths match `notebooks/data-pipeline/.env.example`.

---
## Files

### `process_unique.pkl` / `process_full.pkl`

Pandas DataFrame вЂ” one row per Stage 1 id/region/click daily file. Tracks rejoin status.

| Column | Description |
|--------|-------------|
| `input_path` | Filename stem (e.g. `ua-2024-01-01`) |
| `region_path` | Full path to the Stage 1 id/region/click pickle |
| `rejoin_path` | Full path to the daily Parquet output |
| `rejoin_status` | `complete` once the file has been processed |

### `parquet_daily_unique/ua-YYYY-MM-DD.parquet`
### `parquet_daily_full/ua-YYYY-MM-DD.parquet`

Fully enriched daily Parquet files. Stage 5.1 writes the unique dataset and Stage 5.3 writes the full dataset. Each row is one job vacancy with all pipeline columns joined together.

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

### `parquet_monthly_unique/YYYY-M.parquet`
### `parquet_monthly_full/YYYY-M.parquet`

**Primary research output.** Monthly aggregated Parquet files вЂ” the datasets used in the paper analysis. Each file contains all vacancies published in a given calendar month. Column schema is identical to the daily Parquet files above, with the same `selected_columns` subset applied.

Parquet format is used for efficient columnar storage and fast loading with `pandas.read_parquet()`.

### `json_monthly_unique/YYYY-M.json`
### `json_monthly_ua_unique/YYYY-M.json`
### `json_monthly_ua_full/YYYY-M.json`
### `json_daily_unique/ua-YYYY-MM-DD.json`
### `json_daily_ua_unique/ua-YYYY-MM-DD.json`
### `json_daily_full/ua-YYYY-MM-DD.json`
### `json_daily_ua_full/ua-YYYY-MM-DD.json`

JSON exports use records orientation. Stage 5.1 daily `_ua_` files contain Ukrainian-language descriptions (`desc_lang == 'uk'`). Monthly `_ua_` files created by Stages 5.2 and 5.4 retain vacancies where `country == 'Ukraine'`.

---

## Demo output

Running Stage 5 on the demo `ua-2024-01-01.pkl` produces:

- `parquet_daily_unique/ua-2024-01-01.parquet` вЂ” 100-row enriched Parquet file
- `json_daily_unique/ua-2024-01-01.json` вЂ” same as JSON
- `parquet_monthly_unique/2024-1.parquet` вЂ” January 2024 monthly aggregate

Load the final output:
```python
import pandas as pd
df = pd.read_parquet("data/data-pipeline/stage_05/parquet_monthly_unique/2024-1.parquet")
df.shape   # (100, 27) for the demo file
df.columns
```

