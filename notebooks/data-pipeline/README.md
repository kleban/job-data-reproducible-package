# Python Data-Pipeline Notebooks

These notebooks form a manual, ordered workflow. There is no master notebook or command that runs the full pipeline.

## Execution rule

Start Jupyter from this directory:

```powershell
Set-Location notebooks\data-pipeline
jupyter notebook
```

Each selected notebook must be run independently from top to bottom. Complete one notebook before opening the next processing step.

## Configuration

Copy `.env.example` to `.env`. The `.env` file contains paths relative to this directory and an optional local OpenAI credential. It is excluded from version control.

## Notebook order

1. `before_start_test_environment.ipynb`
2. `stage_1_read_initial_data_fast.ipynb`
3. `stage_01_5_interim_translate_skills.ipynb` — normally skip; output is included
4. `stage_2_1_skills_extration.ipynb`
5. `stage_2_2_add_romote_jobs.ipynb`
6. `stage_3_1_classification_create_input_files.ipynb`
7. `stage_3_2_classification_check_jobs.ipynb`
8. `stage_3_3_classification_extract_results.ipynb`
9. `stage_3_4_split_missing_and_complete_cases.ipynb`
10. `stage_3_5_classification_missing_skills_create_input_files.ipynb`
11. `stage_3_6_classification_missing_check_jobs.ipynb`
12. `stage_3_7_classification_missed_extract_results.ipynb`
13. `stage_4_esco_skills_extraction.ipynb`
14. `stage_4_5_region_enrichment.ipynb` — normally skip; lookup database is included
15. `stage_5_1_rejoin_daily_unique_files.ipynb`
16. `stage_5_2_to_monthly_unique.ipynb`
17. `stage_5_3_rejoin_full_files.ipynb`
18. `stage_5_4_to_monthly_full.ipynb`

Notebooks 3.2 and 3.6 interact with asynchronous Batch API jobs. They may need to be closed and rerun after the submitted jobs finish. See the root [README](../../README.md) for the stage descriptions and normal run/skip decisions.
