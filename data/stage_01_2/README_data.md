# data/stage_01_2 — ESCO Skills Translation (English → Russian)

## What this stage does

The original ESCO taxonomy provides skill labels in many European languages
(English, German, French, Polish, Czech, etc.) but **does not include Russian**.
Since a significant share of Ukrainian job vacancies are written in Russian,
missing Russian-language skill labels would result in poor skill extraction
quality for those records.

This stage uses the **OpenAI Batch API (gpt-4.1-mini)** to translate all
~13,900 ESCO skill entries from English to Russian, producing `skills_ru.csv`
which is consumed by the Stage 2 skill extraction pipeline.

---

## ⚠ You do NOT need to rerun this stage

The translation has already been completed. All output files are included
in this repository. Simply proceed to Stage 2 — the `skills_ru.csv` file
will be picked up automatically.

**Only rerun this notebook if you want to improve or redo the translation.**
Rerunning will consume OpenAI API credits and may take up to 24 hours
(OpenAI Batch API processing time).

---

## Files

### `processed/`

| File | Description |
|------|-------------|
| `skills_en.csv` | Source ESCO skills in English (~13,900 rows). Input to the translation batch. Columns: `conceptUri`, `preferredLabel`, `altLabels`, `description` |
| `skills_ru.csv` | **Output — Russian translations** of all ESCO skills. Used by Stage 2 for Russian-language job records. Same columns as `skills_en.csv` |
| `translate_schema.json` | OpenAI function-calling schema that enforces the structure of each translated record |

### `intermediate/`

| File | Description |
|------|-------------|
| `batch_translate_en_ru.jsonl` | Batch API input file — one JSON line per skill, each containing the English text and translation instructions |
| `batch_output.jsonl` | Raw Batch API response from OpenAI — one JSON line per skill with the translated fields |

---

## Note on paths

The notebook (`stage_1_2_interim_translate_skills.ipynb`) uses hardcoded paths
pointing to `../data/stage1_2/`. If you want to rerun the translation, either:
- Create a `data/stage1_2/` folder and copy the source files there, or
- Update the path constants in Cell 7 of the notebook to point to
  `../data/stage_01_2/processed/` and `../data/stage_01_2/intermediate/`
