# Computed Reviewer-Answer Data

## `classification_validation_population.parquet`

Computed by `notebooks/data-pipeline-answers/01_prepare_validation_dataset.ipynb` from non-published daily Parquet files.

Construction:

1. concatenate daily files in filename order;
2. remove duplicate `id` values, retaining the first occurrence;
3. retain eight classification-validation variables;
4. exclude rows with missing `extract_type`.

The publication file contains 12,679 rows, 8 columns, 12,679 unique vacancy IDs, and no missing `extract_type` values.

## `classification_validation_sample_200.parquet`

Created by `02_create_stratified_validation_sample.ipynb` using proportional allocation across the joint `(desc_lang, extract_type)` strata and `random_state=42`.

The file contains 200 rows, 8 columns, and 200 unique vacancy IDs. It is identical to the internal `sampled_02.parquet` and the earlier `sampled.pkl`.

## `classification_validation_manual_review_template.csv`

The same 200 sampled vacancy IDs with `clean_title` and `clean_desc`, prepared for the manual coding step. The file is semicolon-delimited and preserves the sample row order.
