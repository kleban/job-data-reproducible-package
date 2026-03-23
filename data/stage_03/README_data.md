# data/stage_03 — Stage 3 Outputs (ESCO Occupation Classification)

## What this stage produces

Stage 3 classifies each job vacancy with a 4-digit ESCO occupation code and English title using the **OpenAI Batch API** (`gpt-4o-mini`). The process runs asynchronously in two passes:

1. **First pass** — all vacancies are submitted. Records that receive a valid ESCO classification are saved to `processed/result/`.
2. **Second pass** — vacancies that were not classified in the first pass (missing records) are resubmitted. Results are merged back into the main result pickles.

Each daily result pickle at the end of Stage 3 contains all columns from Stage 2 plus `esco_code` and `esco_title`.

---

## Folder structure

```
data/stage_03/
├── raw/
│   ├── classify_schema.json            ← OpenAI function-calling schema
│   ├── classification_prompt.txt       ← System prompt for the LLM
│   └── input/
│       ├── ua-YYYY-MM-DD.jsonl         ← First-pass batch input files
│       └── missing/
│           └── ua-YYYY-MM-DD.jsonl     ← Second-pass input files (missing records)
├── intermediate/
│   └── process.pkl                     ← Stage 3 process tracker
└── processed/
    ├── output/
    │   ├── ua-YYYY-MM-DD.json          ← Raw Batch API output (first pass)
    │   └── missing/
    │       └── ua-YYYY-MM-DD.json      ← Raw Batch API output (second pass)
    └── result/
        ├── ua-YYYY-MM-DD.pkl           ← Final classified daily pickles
        └── missing/
            └── ua-YYYY-MM-DD.pkl       ← Temporary: unclassified records awaiting second pass
```

---

## Files

### `raw/classify_schema.json`

OpenAI function-calling schema for the `classifyPosting` function. Defines three required output fields: `id` (vacancy ID), `esco_code` (4-digit ESCO occupation code), `esco_title` (English occupation title). Passed to the API as the `functions` parameter in each batch request.

### `raw/classification_prompt.txt`

System prompt instructing the LLM to select the single best 4-digit ESCO occupation code and English title from the vacancy title and extracted skill labels (or description if no skills are available).

### `raw/input/ua-YYYY-MM-DD.jsonl`

One JSONL file per daily input. Each line is a single API request in OpenAI Batch API format:

```json
{
  "custom_id": "task-id-<row_index>",
  "method": "POST",
  "url": "/v1/chat/completions",
  "body": {
    "model": "gpt-4o-mini",
    "temperature": 0,
    "functions": [...],
    "messages": [
      {"role": "system", "content": "<classification_prompt>"},
      {"role": "user", "content": "{\"id\": ..., \"title\": ..., \"skills\": ...}"}
    ],
    "function_call": {"name": "classifyPosting"}
  }
}
```

### `raw/input/missing/ua-YYYY-MM-DD.jsonl`

Second-pass batch input files, created only for days that had unclassified vacancies after the first pass. Same format as the first-pass JSONL files.

### `intermediate/process.pkl`

Pandas DataFrame — one row per Stage 2 output file. Tracks all asynchronous Batch API steps across both passes.

| Column | Description |
|--------|-------------|
| `input_file` | Input filename stem (e.g. `ua-2024-01-01`) |
| `extract_path` | Path to the Stage 2 output pickle |
| `input_batch_path` | Path to the first-pass JSONL input file |
| `input_batch_status` | `created` once the JSONL file has been written |
| `job_id` | OpenAI Batch API job ID (first pass) |
| `job_status` | Job status: `in_progress`, `completed`, etc. |
| `output_batch_path` | Path to the downloaded first-pass output JSON |
| `output_batch_status` | `complete` once the output file has been downloaded |
| `result_path` | Path to the final result pickle |
| `result_status` | `complete` once ESCO codes have been merged |
| `missing_count` | Number of vacancies without a valid classification after first pass |
| `missing_path` | Path to the missing-records pickle (second pass input) |
| `missing_input_batch_status` | `created` or `empty` (no missing records) |
| `missing_input_batch_path` | Path to the second-pass JSONL input file |
| `missing_job_status` | Job status for the second-pass batch job |
| `missing_job_id` | OpenAI Batch API job ID (second pass) |
| `missing_output_batch_path` | Path to the downloaded second-pass output JSON |
| `missing_output_batch_status` | `complete` once second-pass output is downloaded |
| `complete_result_status` | `complete` once second-pass results have been merged |
| `missing_after` | Number of vacancies still unclassified after second pass |

### `processed/output/ua-YYYY-MM-DD.json`

Raw JSONL response downloaded from the OpenAI Batch API (first pass). Each line contains the full API response for one vacancy request, including the function-call arguments with `esco_code` and `esco_title`. Parsed by `extract_esco_codes()` in `code/stage3.py`.

### `processed/result/ua-YYYY-MM-DD.pkl`

Final Stage 3 output. Contains all Stage 2 columns plus two new columns:

| Column | Type | Description |
|--------|------|-------------|
| `esco_code` | str | 4-digit ESCO occupation code assigned by the LLM |
| `esco_title` | str | English ESCO occupation title assigned by the LLM |

After the second pass (notebook 3.7), each result pickle contains both successfully classified records and any records recovered in the second pass. Vacancies that could not be classified in either pass have `NaN` in both columns.

### `processed/result/missing/ua-YYYY-MM-DD.pkl`

Temporary file written during processing (notebook 3.4). Contains only the unclassified vacancies extracted from the first-pass result for a given day. After the second pass results are merged (notebook 3.7), these records are folded back into the main result pickle. These files are kept for audit/debugging purposes.

---

## Demo file

Running Stage 3 on the demo `ua-2024-01-01.pkl` produces:

- `raw/input/ua-2024-01-01.jsonl` — batch input with one request per vacancy
- `processed/output/ua-2024-01-01.json` — raw API response
- `processed/result/ua-2024-01-01.pkl` — final result with `esco_code` and `esco_title`

> **Requires an OpenAI API key.** Set `OPENAI_API_KEY` in `notebooks/.env` before running Stage 3 notebooks.
