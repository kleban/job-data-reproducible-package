# data/data-pipeline/stage_02 — Stage 2 Outputs

## What this stage produces

Stage 2 takes the cleaned daily pickles from Stage 1 and adds two enrichment layers:

1. **Skill extraction** — splits each vacancy description into sentences, encodes them with a multilingual sentence-transformer, and retrieves the top-20 ESCO skill matches per vacancy using cosine similarity against language-specific skill embedding indexes.
2. **Work-mode classification** — classifies each vacancy as `remote`, `in_office`, `combined`, or `undefined` using a combination of regex hints and semantic similarity to multilingual template phrases.

The ESCO skill reference CSVs required for building the embedding indexes are included in `skills/` and do not need to be regenerated.

---

## Folder structure

The stage uses a flat layout: data files and named output directories are stored directly under this stage directory. The paths match `notebooks/data-pipeline/.env.example`.

---
## Files

### `process.pkl`

Pandas DataFrame — one row per Stage 1 output file. Tracks which files have been processed through Stage 2.

| Column | Description |
|--------|-------------|
| `input_file` | Input filename stem (e.g. `ua-2024-01-01`) |
| `clean_path` | Full path to the Stage 1 output pickle |
| `extract_path` | Full path to the Stage 2 output pickle |
| `extract_status` | Processing status: `complete` or blank |
| `remote_status` | Work-mode classification status: `complete` or blank |

### `skills/skills_*.csv`

Five CSV files — one per supported language. Each contains ESCO skill entries used to build the embedding indexes for skill extraction. These files are consumed by `SkillRetriever` in `code/data-pipeline/stage2.py`.

| Column | Description |
|--------|-------------|
| `conceptUri` | ESCO skill URI (unique identifier) |
| `preferredLabel` | Preferred skill label in the target language |
| `altLabels` | Pipe-separated alternative labels |
| `description` | Skill description (English only; blank in non-EN files) |

> `skills_ru.csv` was produced by the Stage 1.2 translation step using the OpenAI Batch API. See [`data/data-pipeline/stage_01_2/README_data.md`](../stage_01_2/README_data.md) for details.

### `output/ua-YYYY-MM-DD.pkl`

One file per input day. Extends the Stage 1 output with four additional columns.

All Stage 1 columns are preserved. Added columns:

| Column | Type | Description |
|--------|------|-------------|
| `skill_ids` | string | Comma-separated ESCO skill URIs matched for this vacancy |
| `skill_labels` | string | Comma-separated ESCO skill labels (in the vacancy's detected language) |
| `job_type` | string | Work-mode classification: `remote`, `in_office`, `combined`, or `undefined` |
| `job_type_score` | float | Confidence score for the work-mode classification (0–1) |

---

## Demo file

Running Stage 2 on the demo `ua-2024-01-01.pkl` from Stage 1 produces `output/ua-2024-01-01.pkl` with skill and work-mode columns populated.

The full original dataset (2021–2025) is not included due to size and licensing constraints.
