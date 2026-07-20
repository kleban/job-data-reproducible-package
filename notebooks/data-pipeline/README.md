# Python Data-Pipeline Notebooks

These notebooks implement the ordered vacancy-data workflow. There is intentionally no master notebook: run each selected notebook independently from top to bottom and complete it before proceeding.

## Start here

From the repository root:

```powershell
Set-Location notebooks\data-pipeline
Copy-Item .env.example .env
jupyter notebook
```

On macOS or Linux:

```bash
cd notebooks/data-pipeline
cp .env.example .env
jupyter notebook
```

Run `before_start_test_environment.ipynb` before processing data. Add `OPENAI_API_KEY` to the local ignored `.env` only when rerunning Stages 1.2, 3, or 4.5.

## Ordered workflow

| Order | Notebook | Purpose | Normal action |
|---:|---|---|---|
| 0 | `before_start_test_environment.ipynb` | Check configuration, imports, and required directories | Run |
| 1 | `stage_1_read_initial_data_fast.ipynb` | Read daily JSON, deduplicate vacancies, clean text, and detect language | Run |
| 1.2 | `stage_01_5_interim_translate_skills.ipynb` | Translate ESCO skill labels from English to Russian through the OpenAI Batch API | Skip; included output is precomputed |
| 2.1 | `stage_2_1_skills_extration.ipynb` | Extract multilingual candidate ESCO skills | Run |
| 2.2 | `stage_2_2_add_romote_jobs.ipynb` | Add work-mode classification | Run |
| 3.1 | `stage_3_1_classification_create_input_files.ipynb` | Create first-pass OpenAI Batch API JSONL files | Run when reproducing the API stage |
| 3.2 | `stage_3_2_classification_check_jobs.ipynb` | Select a file range, submit jobs, and check first-pass status | Run, wait, then rerun |
| 3.3 | `stage_3_3_classification_extract_results.ipynb` | Download and parse completed first-pass results | Run after completion |
| 3.4 | `stage_3_4_split_missing_and_complete_cases.ipynb` | Separate records without a usable first-pass classification | Run |
| 3.5 | `stage_3_5_classification_missing_skills_create_input_files.ipynb` | Create second-pass requests for missing cases | Run when missing cases exist |
| 3.6 | `stage_3_6_classification_missing_check_jobs.ipynb` | Select a file range, submit jobs, and check second-pass status | Run, wait, then rerun |
| 3.7 | `stage_3_7_classification_missed_extract_results.ipynb` | Download, parse, and merge second-pass results | Run |
| 4 | `stage_4_esco_skills_extraction.ipynb` | Verify ESCO occupations and attach taxonomy skills | Run |
| 4.5 | `stage_4_5_region_enrichment.ipynb` | Build/update the standardised region lookup through the Batch API | Skip for existing data; included lookup is precomputed |
| 5.1 | `stage_5_1_rejoin_daily_unique_files.ipynb` | Join enriched unique daily records and write Parquet | Run |
| 5.2 | `stage_5_2_to_monthly_unique.ipynb` | Aggregate unique daily Parquet files by month | Run |
| 5.3 | `stage_5_3_rejoin_full_files.ipynb` | Join enriched full daily snapshots and write Parquet | Run |
| 5.4 | `stage_5_4_to_monthly_full.ipynb` | Aggregate full daily Parquet files by month | Run |

The historical filenames contain spelling inconsistencies such as `extration` and `romote`; retain these filenames because notebook links and documentation refer to them.

## API-dependent stages

- Stage 3 uses `gpt-4o-mini`.
- Stage 1.2 uses the model documented in its notebook and data README.
- Stage 4.5 uses the model documented in its notebook and data README.
- Batch jobs are asynchronous. Notebooks 3.2 and 3.6 allow the researcher to set both the first and last file to avoid resubmitting earlier files.
- API outputs may vary when services or models change. Use included permitted precomputed outputs for the approved replication release where appropriate.

## Data handoffs

| Stage | Reads | Writes |
|---|---|---|
| 1 | `data/data-pipeline/input/` | `stage_01/` |
| 1.2 | ESCO English skills | `stage_01_2/skills_ru.csv` |
| 2 | `stage_01/output/` and multilingual ESCO skills | `stage_02/output/` |
| 3 | `stage_02/output/` | `stage_03/result/` |
| 4 | `stage_03/result/` and ESCO reference tables | `stage_04/output/` |
| 4.5 | unique raw region strings | `stage_04_5/region_db.pkl` |
| 5 | Stage 1 snapshots plus Stages 2–4.5 enrichments | `stage_05/` |

File-level schemas and availability notes are in [the pipeline data guide](../../data/data-pipeline/README.md).

## Public demonstration limitation

The repository includes only a 100-row synthetic daily input and derived demonstration files. This is sufficient to inspect schemas and exercise local processing, but it does not reproduce the paper’s substantive conclusions. The complete original Jooble daily snapshots are restricted and are not included.
