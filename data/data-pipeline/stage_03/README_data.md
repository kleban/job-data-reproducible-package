# Stage 3 Data: ESCO Occupation Classification

## Purpose

Stage 3 assigns an ESCO occupation code and English occupation title to each vacancy through the OpenAI Batch API. The workflow uses `gpt-4o-mini` and runs in two passes so that records missing a usable first-pass classification can be resubmitted.

## Producer and handoff

- Producers: notebooks 3.1–3.7 in `notebooks/data-pipeline/`
- Input: `data/data-pipeline/stage_02/output/`
- Main output: `result/ua-YYYY-MM-DD.pkl`
- Next consumer: Stage 4 ESCO verification and skill mapping

## Two-pass workflow

1. Notebook 3.1 creates first-pass request files.
2. Notebook 3.2 submits/checks a researcher-selected range of files.
3. Notebook 3.3 downloads and parses completed responses.
4. Notebook 3.4 separates records without valid results.
5. Notebook 3.5 creates second-pass requests for those missing records.
6. Notebook 3.6 submits/checks the selected second-pass file range.
7. Notebook 3.7 parses the second-pass output and merges recovered classifications.

Because Batch API jobs are asynchronous, status notebooks must be rerun after remote processing completes.

## Static request resources

| File | Role |
|---|---|
| `classification_prompt.txt` | System instructions for choosing the best ESCO occupation |
| `classify_schema.json` | Structured function/output schema requiring vacancy ID, ESCO code, and title |

## Generated files

| Path | Role |
|---|---|
| `input/ua-YYYY-MM-DD.jsonl` | First-pass Batch API requests |
| `input/missing/ua-YYYY-MM-DD.jsonl` | Second-pass requests for records missing after pass one |
| `output/ua-YYYY-MM-DD.json` | Downloaded first-pass raw API response |
| `output/missing/ua-YYYY-MM-DD.json` | Downloaded second-pass raw API response, where generated |
| `result/ua-YYYY-MM-DD.pkl` | Stage 2 records plus the merged classification result |
| `result/missing/ua-YYYY-MM-DD.pkl` | Temporary/audit subset of first-pass missing cases |
| `process.pkl` | Job IDs, statuses, paths, missing counts, and completion state |
| `log/` | Runtime logs when enabled |

## Output fields

The main result preserves Stage 2 fields and adds the LLM-assigned occupation code and title. Stage 4 later retains the raw values as `classified_code` and `classified_title` and creates separately verified ESCO fields.

## Reproducibility and publication notes

- Rerunning requires `OPENAI_API_KEY` in the ignored local `.env`.
- Batch calls can incur costs.
- Service/model changes can prevent byte-identical regeneration.
- API identifiers and process trackers should be reviewed for sensitive or non-portable metadata before final publication.
- The included demonstration artifacts do not represent the complete 2021–2025 classification run.
