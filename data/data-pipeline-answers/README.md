# Data-Pipeline Reviewer-Answer Data

Data used only for analyses requested by reviewers. These files are separate from the main data pipeline and do not use its `.env` configuration.

## Publication policy

- Original daily source files are not published.
- Computed datasets required to verify the reviewer answers are included.
- The provenance and restriction of every non-published input will be documented in the relevant input README.

## Included computed data

| File | Created by | Rows | Columns | Role |
|---|---|---:|---:|---|
| `interim/classification_validation_population.parquet` | `01_prepare_validation_dataset.ipynb` | 12,679 | 8 | Public starting population for classification-validation statistics and sampling |

The included Parquet file is identical in content to the earlier internal `shorted_dataset_07.pkl`; only the publication format and descriptive filename differ.
