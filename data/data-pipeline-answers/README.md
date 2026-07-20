# Reviewer-Answer Data: Data Pipeline

This directory contains the restricted-input documentation and public computed data needed by the reviewer-answer notebooks. It is separate from the main Stages 1–5 data tree and does not use `.env` configuration.

## Publication policy

- Original daily Jooble vacancy files are not published.
- Notebook 01 documents how the validation population was constructed from those files.
- Public execution starts from the included computed validation population.
- Completed manual codes and non-disclosive aggregate threshold counts are included because they are direct inputs to manuscript Tables A3–A6.

## Directory map

| Directory | Contents |
|---|---|
| `input/private_daily/` | Documentation for the unavailable daily source files |
| `interim/` | Validation population, reproducible sample, and manual-review template |
| `validation/` | Completed manual ESCO codes |
| `threshold-selection/` | Aggregate correct/compared counts for threshold sensitivity |

## Included datasets

| File | Rows | Columns | Producer/source | Role |
|---|---:|---:|---|---|
| `interim/classification_validation_population.parquet` | 12,679 | 8 | Notebook 01 from restricted daily data | Public starting population |
| `interim/classification_validation_sample_200.parquet` | 200 | 8 | Notebook 02 | Stratified manual-validation sample |
| `interim/classification_validation_manual_review_template.csv` | 200 | 3 | Notebook 02 | IDs and cleaned text prepared for coding |
| `validation/classification_validation_manual_codes.csv` | 200 | 2 | Completed manual coding | Reference ESCO codes |
| `threshold-selection/threshold_accuracy_counts.csv` | 30 | 5 | Archived validation results | Input for Table A6 |

The publication Parquet population is content-equivalent to the earlier internal `shorted_dataset_07.pkl`; the public file uses an open, descriptive format and filename.

## Known limitation

Thresholds 0.5, 0.6, 0.8, and 0.9 were checked against retained computed datasets. The threshold 0.7 correct counts were recovered from archived two-decimal accuracies and the common denominator of 137 non-missing comparison pairs. This is sufficient to reproduce the reported aggregate table, not the historical vacancy-level classification records.

Subdirectory READMEs provide schema and provenance details for each data class.
