# Non-Published Daily Inputs

This directory represents the private daily Parquet inputs used by `01_prepare_validation_dataset.ipynb`. The source files are not included in the public replication package.

## Expected format

- File format: Parquet
- Unit: one daily vacancy snapshot per file
- Required columns: `id`, `clean_title`, `clean_desc`, `desc_lang`, `extract_type`, `classified_title_clean`, `esco_title`, and `esco_code`

## Provenance and access

The files are derived from online job-vacancy records supplied to the authors by Jooble. The validation population used here covers April 2024. The vacancy-level source records contain proprietary posting text and were provided under restricted access, so they cannot be redistributed in the public replication package. Researchers seeking the original records must request access from the data provider. Public replication begins with the non-disclosive computed file `../../interim/classification_validation_population.parquet`.
