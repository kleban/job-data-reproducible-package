# Stage 1.2 Data: Russian ESCO Skill Translation

## Purpose

ESCO does not provide the Russian-language skill collection required for extracting skills from Russian vacancy descriptions. Stage 1.2 translates the English ESCO skill table into Russian through the OpenAI Batch API.

## Producer and handoff

- Producer: `notebooks/data-pipeline/stage_01_5_interim_translate_skills.ipynb`
- Model documented by the workflow: `gpt-4.1-mini`
- Source: English ESCO skill collection
- Main output: `skills_ru.csv`
- Next consumer: Stage 2 multilingual skill retrieval

## Normal replication action

Do not rerun this stage for the standard replication workflow. The completed Russian translation and supporting Batch API artifacts are included. Rerunning requires an OpenAI API key, can incur costs, and may return text that is not byte-identical to the archived translation.

## Files

| File | Role |
|---|---|
| `skills_en.csv` | English ESCO skill records used as translation input |
| `skills_ru.csv` | Precomputed Russian translations used by Stage 2 |
| `translate_schema.json` | Structured output schema for translated records |
| `batch_translate_en_ru.jsonl` | Batch API request file |
| `batch_output.jsonl` | Archived raw Batch API response |

The main tables preserve ESCO concept identifiers and fields such as preferred label, alternative labels, and description.

## Configuration

The notebook obtains paths from `general.Config` and `notebooks/data-pipeline/.env`. No machine-specific path edits are required. A live API credential belongs only in the ignored local `.env` file.
