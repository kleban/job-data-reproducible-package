# Python Analysis-Ready Data

This folder receives datasets created by the Python paper-analytics notebooks.

| Expected file | Producer | Unit |
|---|---|---|
| `vacancies_2021_2025_collapsed_by_id.parquet` | Notebook 01 | One row per vacancy ID |
| `vacancy_skill_conflict_weekly.parquet` | Notebook 02 | Weekly analytical panel |
| `vacancy_skill_conflict_monthly.parquet` | Notebook 02 | Monthly analytical panel |

The files are not currently present because the complete Stage 5 monthly data and external reference inputs have not yet been supplied and the notebooks have not been executed.

The R project currently reads separately bundled `final_weekly.parquet`, `final_monthly.parquet`, and `final_dataset_occ_digital_month.parquet`. Their provenance and equivalence to these planned Python outputs must be verified before the final release.
