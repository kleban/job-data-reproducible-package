# Non-Published Daily Inputs

This directory represents the private daily Parquet inputs used by `01_prepare_validation_dataset.ipynb`. The source files are not included in the public replication package.

## Expected format

- File format: Parquet
- Unit: one daily vacancy snapshot per file
- Required columns: `id`, `clean_title`, `clean_desc`, `desc_lang`, `extract_type`, `classified_title_clean`, `esco_title`, and `esco_code`

## Provenance and access

The authors will provide the final description of the data source, access conditions, period covered, and reason the original files cannot be published. Public replication begins with the computed file `../../interim/classification_validation_population.parquet`.
