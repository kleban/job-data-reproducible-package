# data/data-pipeline/stage_01 — Stage 1 Outputs

## What this stage produces

Stage 1 reads daily job vacancy JSON files from `data/data-pipeline/input/`, deduplicates records, cleans text (removes dates, salaries, and emoji), detects the language of each vacancy's title and description, and saves one cleaned pickle file per input day.

Two kinds of intermediate artefacts are kept alongside the main output: a per-file id/region/clicks snapshot used for regional reconciliation, and the global unique-ID database that tracks which vacancy IDs have already been seen across all processed days.

---

## Folder structure

The stage uses a flat layout: data files and named output directories are stored directly under this stage directory. The paths match `notebooks/data-pipeline/.env.example`.

---
## Files

### `process.pkl`

Pandas DataFrame — one row per input file. Tracks processing status across runs so that already-processed files are skipped on subsequent runs.

| Column | Description |
|--------|-------------|
| `input_file` | Input filename stem (e.g. `ua-2024-01-01`) |
| `input_path` | Full path to the source JSON file |
| `clean_path` | Full path to the cleaned output pickle |
| `clean_status` | Cleaning status: `complete` or blank |
| `id_region_path` | Full path to the id/region/click snapshot |
| `id_region_status` | Snapshot status: `complete` or blank |

### `unic_id_db.pkl`

Pandas DataFrame — accumulates all vacancy IDs seen so far across the entire dataset. Used to deduplicate across daily files: a vacancy that first appeared on 2024-01-01 is excluded from all later files, ensuring each record appears only once in the pipeline.

| Column | Description |
|--------|-------------|
| `id` | Vacancy ID (integer, hashed) |

### `id_region_click/ua-YYYY-MM-DD.pkl`

One file per input day. Each file is a slim Pandas DataFrame recording which vacancy IDs appeared in that day's snapshot along with their region and click count. Used in the regional reconciliation step after deduplication.

| Column | Description |
|--------|-------------|
| `id` | Vacancy ID |
| `region` | Region string as provided in the source data |
| `number_of_clicks` | Click count recorded on that day |

### `output/ua-YYYY-MM-DD.pkl`

One file per input day. The main Stage 1 output. Contains only vacancies whose IDs were not seen in any earlier file (global unique records for that day).

| Column | Type | Description |
|--------|------|-------------|
| `id` | int64 | Vacancy ID |
| `title` | string | Original job title |
| `description` | string | Original job description |
| `region` | string | Region string |
| `min_salary` | float | Minimum salary (if provided) |
| `max_salary` | float | Maximum salary (if provided) |
| `currency` | string | Salary currency (UAH / USD / EUR) |
| `salary_rate` | string | Payment frequency (month / hour) |
| `date_created` | string | Vacancy publication date |
| `date_expired` | string | Vacancy expiry date |
| `clean_title` | string | Cleaned, normalised title (lowercase, no special chars) |
| `clean_desc` | string | Cleaned, normalised description |
| `title_lang` | string | Detected language of the title (`en`, `uk`, `ru`, `cs`, `pl`) |
| `desc_lang` | string | Detected language of the description |

---

## Demo file

This repository includes one demo input day (`ua-2024-01-01.json`, 100 synthetic rows in `data/data-pipeline/input/`). Running Stage 1 on the demo file produces:

- `id_region_click/ua-2024-01-01.pkl`
- `process.pkl` (updated)
- `unic_id_db.pkl` (updated)
- `output/ua-2024-01-01.pkl`

The full original dataset (2021–2025, ~1,600 daily files) is not included due to size and licensing constraints.
