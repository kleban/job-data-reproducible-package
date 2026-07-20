# Data-Pipeline Reviewer-Answer Data

Data used only for analyses requested by reviewers. These files are separate from the main data pipeline and do not use its `.env` configuration.

## Publication policy

- Original daily source files are not published.
- Computed datasets required to verify the reviewer answers are included.
- The non-published input is the restricted Jooble online-vacancy dataset described in `input/private_daily/README.md`.

## Included computed data

| File | Created by | Rows | Columns | Role |
|---|---|---:|---:|---|
| `interim/classification_validation_population.parquet` | `01_prepare_validation_dataset.ipynb` | 12,679 | 8 | Public starting population for classification-validation statistics and sampling |
| `interim/classification_validation_sample_200.parquet` | `02_create_stratified_validation_sample.ipynb` | 200 | 8 | Reproducible proportional sample used for manual validation |
| `interim/classification_validation_manual_review_template.csv` | `02_create_stratified_validation_sample.ipynb` | 200 | 3 | Identifier and cleaned-text template supplied for manual coding |
| `validation/classification_validation_manual_codes.csv` | Completed manual coding | 200 | 2 | Manually checked ESCO code for every sampled vacancy |
| `threshold-selection/threshold_accuracy_counts.csv` | Archived threshold-validation results | 30 | 5 | Analysis-ready correct and compared counts used to reproduce manuscript Table A6 |

The included Parquet file is identical in content to the earlier internal `shorted_dataset_07.pkl`; only the publication format and descriptive filename differ.

## Threshold-selection data limitation

The original Jooble vacancy records are not published. The historical vacancy-level predictions for threshold 0.7 were overwritten after the sensitivity table was produced. The threshold-selection file therefore contains only aggregate correct and compared counts. Counts for thresholds 0.5, 0.6, 0.8, and 0.9 were verified against retained computed threshold datasets. The threshold 0.7 counts were recovered from the archived two-decimal accuracy results and their common denominator of 137 non-missing prediction/manual-code pairs. These counts reproduce Table A6 but cannot be used to reconstruct or rerun the historical vacancy-level classifications.
