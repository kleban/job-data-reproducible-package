# data/stage_04_5 — Stage 4.5 Outputs (Region Enrichment)

## What this stage produces

Stage 4.5 standardises the raw Ukrainian region strings collected during
Stage 1 into consistent English oblast names using the **OpenAI Batch API**
(`gpt-4.1`). The raw strings come from the job board and vary widely:
they may be Cyrillic, transliterated, abbreviated, or use legacy spellings.

The output is a **region lookup database** (`processed/region_db.pkl`) that
maps every unique original region string encountered in the dataset to a
standardised English name (e.g. `"Київська обл."` → `"Kyiv Oblast"`).
This lookup table is used by Stage 5 to add a clean `region` column to
every vacancy record.

Because the full dataset contains ≈ 22 000 unique region strings, the Batch
API calls are split into numbered chunks and submitted incrementally. The
`region_db.pkl` included in this repository is the **complete pre-built
lookup table** for the 2021–2025 dataset — it does not need to be rebuilt
when running the demo pipeline on the synthetic `ua-2024-01-01.json` data.

---

## Folder structure

```
data/stage_04_5/
├── raw/
│   ├── select_region_schema.json    ← OpenAI function-calling schema
│   ├── select_region_prompt.txt     ← System prompt for region standardisation
│   ├── regions_initial.json         ← Seed list of initial known region names
│   ├── input/
│   │   └── sample_1_100.jsonl       ← Sample batch input file (first 100 regions)
│   └── geo/
│       ├── level0.json              ← Country-level GeoJSON reference
│       ├── level1.json              ← Oblast-level GeoJSON reference
│       └── level2.json              ← Raion-level GeoJSON reference
├── intermediate/
│   └── region_db_PREV.pkl           ← Previous region DB snapshot (audit trail)
└── processed/
    ├── output/                      ← Batch API output JSONL files (generated during run)
    └── region_db.pkl                ← Final merged region lookup table ✓ pre-built
```

---

## Files

### `raw/select_region_schema.json`

OpenAI function-calling schema for the `selectRegion` function. Defines
two output fields: `original` (the raw region string) and `region` (the
standardised English oblast name). Passed to the Batch API as the `functions`
parameter.

### `raw/select_region_prompt.txt`

System prompt instructing the LLM to map each raw Ukrainian region string
to a standardised English oblast name from a fixed allowed list. The list
is based on Ukraine's 25 oblasts plus Kyiv City.

### `raw/regions_initial.json`

Seed JSON file listing the initial set of known region strings used to
bootstrap the region DB before the first Batch API run.

### `raw/geo/level0.json`, `level1.json`, `level2.json`

GeoJSON reference files for Ukraine at country, oblast, and raion
administrative levels. Used during analysis and visualisation in Stage 5
notebooks.

### `intermediate/region_db_PREV.pkl`

Snapshot of the region database from the previous pipeline run. Loaded at
the start of each Stage 4.5 notebook run to identify which region strings
are new (not yet standardised) and need to be submitted to the Batch API.

### `processed/region_db.pkl`

**The key output of Stage 4.5.** A Pandas DataFrame mapping every unique
region string found in the 2021–2025 dataset to a standardised English
oblast name.

| Column | Type | Description |
|--------|------|-------------|
| `original` | str | Raw region string from the job board (Cyrillic or transliterated) |
| `region` | str | Standardised English oblast name (e.g. `"Kyiv Oblast"`) |

> **This file is pre-built and included in the repository.** You do not
> need to rerun Stage 4.5 unless you are adding new data with previously
> unseen region strings.
>
> **Requires an OpenAI API key** if you do rerun. Set `OPENAI_API_KEY`
> in `notebooks/.env`.

### `raw/input/sample_1_100.jsonl`

A representative sample of a Batch API input file covering the first 100
unique region strings from the original dataset. Each line is one API request
in OpenAI Batch API format:

```json
{
  "custom_id": "task-id-0",
  "method": "POST",
  "url": "/v1/chat/completions",
  "body": {
    "model": "gpt-4.1",
    "functions": [...],
    "messages": [
      {"role": "system", "content": "<region_prompt>"},
      {"role": "user", "content": "{\"original\": \"Київська обл.\"}"}
    ],
    "function_call": {"name": "selectRegion"}
  }
}
```

The full dataset was processed in ~70 batch files of varying sizes. Only this
sample is included for documentation purposes.

### `processed/output/`

Folder for raw Batch API output JSONL files downloaded from OpenAI during
a Stage 4.5 run. These files are generated at runtime and are not included
in the repository (the pre-built `region_db.pkl` makes rerunning unnecessary).
