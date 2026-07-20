# Reviewer-Answer Notebooks: Data Pipeline

These standalone notebooks reproduce classification-validation and threshold-selection results prepared in response to reviewer questions about the data pipeline. They use explicit repository-relative paths and do not load the main pipeline `.env` or `general.Config`.

## Scope and execution order

| Order | Notebook | Input | Main outputs | Publicly executable? |
|---:|---|---|---|---:|
| 1 | `01_prepare_validation_dataset.ipynb` | Restricted daily vacancy Parquet files | `classification_validation_population.parquet` | No; documentation of private-input construction |
| 2 | `02_create_stratified_validation_sample.ipynb` | Included validation population | Reproducible 200-record sample, review template, supporting statistics, Table A2 | Yes |
| 3 | `03_evaluate_classification_accuracy.ipynb` | Included sample and completed manual codes | Supporting agreement/error statistics and Tables A3–A5 | Yes |
| 4 | `04_compare_extraction_thresholds.ipynb` | Included archived aggregate counts | Table A6 | Yes; independent of notebooks 01–03 |

Run the notebooks from `notebooks/data-pipeline-answers/`. Public replication begins with notebook 02 because the proprietary daily vacancy records consumed by notebook 01 cannot be redistributed.

## Validation design

- Validation population: 12,679 April 2024 vacancies with a non-missing Stage 4 extraction method.
- Sample: 200 vacancies allocated proportionally across joint `(desc_lang, extract_type)` strata.
- Sampling seed: `random_state=42`.
- Manual reference: completed ESCO coding for all 200 sampled vacancy IDs.
- Accuracy outputs: full hierarchical ESCO-code agreement and error rates by language and matching method.

## Threshold-selection limitation

Notebook 04 works from non-disclosive archived correct/compared counts. Historical vacancy-level predictions at threshold 0.7 were overwritten and are not presented as recoverable. The included aggregate counts reproduce Table A6 but cannot reconstruct the original record-level predictions.

## Dependencies and validation status

Required packages are pinned in the repository-level `requirements.txt`, principally pandas, NumPy, and PyArrow.

During the completed audit, notebooks 02–04 were executed twice with the pinned versions and produced byte-identical generated artifacts. Notebook 01 remains documentation-only for public users because its input is restricted.

See:

- [Reviewer-answer data](../../data/data-pipeline-answers/README.md)
- [Reviewer-answer outputs](../../output/data-pipeline-answers/README.md)
