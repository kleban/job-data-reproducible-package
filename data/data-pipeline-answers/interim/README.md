# Computed Reviewer-Answer Data

## `classification_validation_population.parquet`

Computed by `notebooks/data-pipeline-answers/01_prepare_validation_dataset.ipynb` from non-published daily Parquet files.

Construction:

1. concatenate daily files in filename order;
2. remove duplicate `id` values, retaining the first occurrence;
3. retain eight classification-validation variables;
4. exclude rows with missing `extract_type`.

The publication file contains 12,679 rows, 8 columns, 12,679 unique vacancy IDs, and no missing `extract_type` values.
