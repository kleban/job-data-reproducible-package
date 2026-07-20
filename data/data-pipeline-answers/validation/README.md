# Completed Manual Validation Data

## `classification_validation_manual_codes.csv`

Completed manual ESCO coding for the 200 records in `interim/classification_validation_sample_200.parquet`.

| Column | Description |
|---|---|
| `id` | Vacancy identifier matching the validation sample |
| `esco_code_checked` | Manually checked hierarchical ESCO occupation code |

The file contains 200 unique IDs, 200 non-missing checked codes, and no records outside the published sample. It is the final terminal manual-coding version used by `03_evaluate_classification_accuracy.ipynb`.

The file is the final manually verified ground-truth coding used in manuscript Tables A3-A5. The manuscript states that pipeline-assigned occupations were compared with manually verified occupations. The retained project materials do not identify individual coders or a separate adjudication protocol; those procedural details should be added if the journal requests coder-level documentation.
