# Stage 2 Data: Skill Extraction and Work Mode

## Purpose

Stage 2 enriches the cleaned, globally unique daily vacancies with multilingual ESCO skill candidates and a work-mode classification.

## Producer and handoff

- Producers:
  - `stage_2_1_skills_extration.ipynb`
  - `stage_2_2_add_romote_jobs.ipynb`
- Input: `data/data-pipeline/stage_01/output/`
- Reference inputs: language-specific ESCO skill CSV files under `skills/`
- Main output: `output/ua-YYYY-MM-DD.pkl`
- Next consumer: Stage 3 occupation classification

## Transformations

### Skill extraction

Vacancy descriptions are divided into text units and encoded with a multilingual sentence-transformer. Candidate ESCO skills are retrieved from language-specific embedding indexes using semantic similarity.

### Work-mode classification

The second notebook combines multilingual text patterns and semantic similarity to classify vacancies into the workflow’s work-mode categories.

## Files

| Path | Role |
|---|---|
| `process.pkl` | Tracks skill-extraction and work-mode completion by daily input file |
| `skills/skills_*.csv` | ESCO skill references for supported languages, including the precomputed Russian translation |
| `output/ua-YYYY-MM-DD.pkl` | Stage 1 data plus extracted skill and work-mode fields |

## Added fields

| Field | Description |
|---|---|
| `skill_ids` | Matched ESCO skill concept identifiers |
| `skill_labels` | Matched skill labels in the vacancy language |
| `skill_labels_en` | English labels used by later analysis, where available |
| `job_type` | Work-mode category such as remote, in-office, combined, or undefined |
| `job_type_score` | Similarity/confidence measure used by the work-mode logic |

Exact storage types can differ between intermediate and Parquet outputs; later stages normalise list-like fields when writing Parquet.

## Public demonstration

The included files demonstrate Stage 2 on the synthetic vacancy day. Model weights may be downloaded on first use. The restricted complete 2021–2025 Stage 1 inputs and Stage 2 outputs are not included.
