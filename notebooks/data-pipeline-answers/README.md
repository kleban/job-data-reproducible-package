# Data-Pipeline Reviewer-Answer Notebooks

Standalone notebooks supporting responses to reviewer questions about the data pipeline. These notebooks use explicit repository-relative paths and do not depend on `Config` or `.env`.

## Execution order

| Order | Notebook | Purpose | Public starting input | Output |
|---|---|---|---|---|
| 1 | `01_prepare_validation_dataset.ipynb` | Combines private daily files, deduplicates vacancies, and selects classification-validation variables | No; requires non-published daily Parquet files | `classification_validation_population.parquet` |
| 2 | `02_create_stratified_validation_sample.ipynb` | Describes the validation population and draws a reproducible 200-record stratified sample | `classification_validation_population.parquet` | Sample Parquet, manual-review template, supporting statistics, and both panels of Table A2 |
| 3 | `03_evaluate_classification_accuracy.ipynb` | Compares pipeline-assigned and manually checked ESCO codes | Sample Parquet and completed manual codes | Supporting statistics and manuscript Tables A3-A5 |
| 4 | `04_compare_extraction_thresholds.ipynb` | Reproduces manuscript Table A6 from archived aggregate correct/compared counts | `threshold_accuracy_counts.csv` | `classification_accuracy_by_threshold.csv` |

Notebook 01 is included to document the construction of the validation population. Public executable replication begins with notebook 02 and the included computed population because the original daily inputs are not published.

Notebook 04 is independent of notebooks 01-03. It reproduces the archived threshold-sensitivity table from non-disclosive aggregate counts. The historical vacancy-level predictions for threshold 0.7 were overwritten and are not represented as if they were still available; the limitation and count reconstruction are documented in the notebook and data README.

Run these notebooks from `notebooks/data-pipeline-answers/`.

## Dependencies

The retained notebooks require `pandas==2.3.3`, `numpy==2.4.0`, and `pyarrow==21.0.0`, pinned in the repository-level `requirements.txt`. The final audit executed notebooks 02-04 twice with these versions and obtained byte-identical generated artifacts. Notebook 01 additionally requires access to the non-published Jooble daily Parquet files; public execution begins with notebook 02 and the included computed validation population.
