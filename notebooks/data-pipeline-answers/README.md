# Data-Pipeline Reviewer-Answer Notebooks

Standalone notebooks supporting responses to reviewer questions about the data pipeline. These notebooks use explicit repository-relative paths and do not depend on `Config` or `.env`.

## Execution order

| Order | Notebook | Purpose | Public starting input | Output |
|---|---|---|---|---|
| 1 | `01_prepare_validation_dataset.ipynb` | Combines private daily files, deduplicates vacancies, and selects classification-validation variables | No; requires non-published daily Parquet files | `classification_validation_population.parquet` |

Notebook 01 is included to document the construction of the validation population. Public replication begins with its included computed output because the original daily inputs are not published.

Run these notebooks from `notebooks/data-pipeline-answers/`.
