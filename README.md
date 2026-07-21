# Replication Package: Labor Demand for Digital Skills in Post-2022 Ukraine

**Paper:** *Labor Demand for Digital Skills in Post-2022 Ukraine: Evidence from Online Job Vacancy Data*

**Authors:** Yurii Kleban and Britta Rude

**Journal/article DOI:** To be added after acceptance or publication

**Mendeley Data DOI:** To be added after the approved replication package is published

## Overview

This repository is the replication package for the paper. It documents the construction of the vacancy data, contains the validation analyses prepared in response to reviewers, and provides the Python and R code used to prepare and analyse the paper datasets.

The package has three connected components:

| Component | Software | Purpose | Public execution status |
|---|---|---|---|
| `data-pipeline` | Python/Jupyter | Converts daily vacancy snapshots into cleaned, enriched daily and monthly files | Executable with the included synthetic demonstration input; the restricted full Jooble source data are not published |
| `data-pipeline-answers` | Python/Jupyter | Reproduces classification-validation and threshold-selection results requested by reviewers | Public notebooks 02–04 and their computed inputs have been validated |
| `paper-analytics` | Python and R | Builds analysis datasets and reproduces the statistical tables and figures reported in the paper | R analysis-ready datasets are included; the ACLED workbook and full runtime validation remain pending |

There is no single command that runs the entire repository. The Python workflows consist of ordered notebooks. The R analysis has its own project, locked `renv` environment, and `run_all.R` entry point.

## Reproducibility status

This package is still being prepared and must not yet be treated as the final Mendeley Data release.

Completed:

- Python data-pipeline structure, configuration, notebooks, and synthetic demonstration files;
- reviewer-answer notebooks, computed validation data, and manuscript-ready Tables A2–A6;
- integration of the self-contained R project and replacement of machine-specific R data paths;
- inclusion and integrity verification of the ESCO digital- and green-skills collection CSV files;
- preparation of the two Python paper-analytics notebooks.

Still required:

- add `europe-central-asia_full_data_up_to-2025-07-25.xlsx` and document its redistribution status;
- confirm the provenance and equivalence of the Python-generated weekly/monthly datasets and the bundled R analysis datasets;
- execute and validate the Python paper-analytics notebooks on the complete Stage 5 data;
- restore the R environment and execute `run_all.R` on a machine with R 4.3.0;
- compare every retained table and figure with the current manuscript;
- finalize the data-availability statement, DOI information, and Mendeley release inventory.

Detailed internal status is recorded in [progress.md](progress.md), [progress-data-pipeline-answers.md](progress-data-pipeline-answers.md), and [progress-paper-analytics.md](progress-paper-analytics.md).

## Data availability

| Source or dataset | Role | Included? | Availability and notes |
|---|---|---:|---|
| Jooble daily online vacancy snapshots | Primary vacancy source for Stages 1–5 | No | Restricted proprietary vacancy text supplied to the authors. Researchers must request access from the provider. A 100-row synthetic structural example is included. |
| Synthetic vacancy file `ua-2024-01-01.json` | Demonstrates the Python pipeline schema | Yes | Synthetic data only; it cannot reproduce the paper’s substantive estimates. |
| ESCO v1.2.0 occupation, skill, and relation tables | Occupation and skill taxonomy | Yes, for the main pipeline | Public ESCO reference exports used by Stages 1.2, 2, and 4 are included. Source/version metadata are documented in the stage READMEs. |
| ESCO digital- and green-skills collections | Digital/green skill classification in Python paper analytics | Yes | Included unchanged from the supplied CSV files under `data/paper-analytics/reference/esco/`; checksums and structures are documented there. Exact ESCO release/source metadata still require confirmation. |
| OpenAI Batch API outputs | Russian skill translation, occupation classification, and region standardisation | Partly | Prompts, schemas, representative inputs, and permitted precomputed outputs are included. Rerunning API steps can incur costs and may not produce byte-identical results. |
| Classification-validation population and manual codes | Reviewer-answer Tables A2–A5 | Yes | Non-disclosive computed data and completed manual codes are included. Original daily records are restricted. |
| Threshold accuracy counts | Reviewer-answer Table A6 | Yes | Aggregate correct/compared counts are included; the historical vacancy-level predictions for threshold 0.7 are unavailable. |
| Bundled weekly, monthly, and occupation-by-month Parquet datasets | Direct inputs to the R paper analysis | Yes | Stored in the self-contained R project under `code/paper-analytics/reproducibility_package/data/`. Their relationship to the Python paper-analytics outputs must be confirmed before final release. |
| Electricity outage workbook | Robustness controls in the R analysis | Yes | Stored with the R project. Source and availability are documented in its data README. |
| Ministry of Energy combat-disconnection workbook | Robustness controls in the R analysis | Yes | Stored with the R project. Source and availability are documented in its data README. |
| ACLED Europe/Central Asia workbook | Conflict events and fatalities | Not yet | Canonical copy expected under `data/paper-analytics/reference/acled/`; the R project requires a byte-identical checksum-verified copy. Redistribution conditions must be confirmed before publication. |

See the component data guides for file-level schemas and restrictions:

- [Data inventory](data/README.md)
- [Python pipeline data](data/data-pipeline/README.md)
- [Reviewer-answer data](data/data-pipeline-answers/README.md)
- [Python paper-analytics data](data/paper-analytics/README.md)
- [R analysis data](code/paper-analytics/reproducibility_package/data/README_data.md)

## Repository structure

```text
mendely-paper-repository/
|-- README.md
|-- SETUP.md
|-- requirements.txt
|-- manuscript/
|-- code/
|   |-- data-pipeline/                 # Shared Python modules
|   `-- paper-analytics/
|       `-- reproducibility_package/   # Self-contained R project and bundled inputs
|-- notebooks/
|   |-- data-pipeline/                 # Ordered Python pipeline notebooks
|   |-- data-pipeline-answers/         # Reviewer-answer notebooks
|   `-- paper-analytics/               # Python preparation and descriptive analysis
|-- data/
|   |-- data-pipeline/                 # Pipeline inputs, intermediates, references, outputs
|   |-- data-pipeline-answers/         # Included validation and threshold data
|   `-- paper-analytics/               # Python paper-analysis inputs and outputs
`-- output/
    |-- data-pipeline-answers/         # Tables A2–A6 and supporting statistics
    `-- paper-analytics/               # Python-generated figures
```

Directory-level navigation is available in [code/README.md](code/README.md), [notebooks/README.md](notebooks/README.md), [data/README.md](data/README.md), and [output/README.md](output/README.md).

## Software environments

### Python

The repository-level Python dependencies are pinned in [requirements.txt](requirements.txt). Setup instructions are in [SETUP.md](SETUP.md).

The documented Python version is 3.13.12. The current local development environment must be rebuilt before final validation because its NumPy binary installation is incompatible with its Python interpreter.

### R

The R project is located at `code/paper-analytics/reproducibility_package/` and targets R 4.3.0. It has its own `.Rprofile`, `renv.lock`, and `renv/activate.R`; do not merge the R environment with the Python environment.

From the R project directory:

```r
renv::restore()
source("run_all.R")
```

Alternatively, open `ukraine_skills.Rproj` in RStudio and run `run_all.R`. The full run currently requires the missing ACLED workbook.

## Reproduction routes

### Route A: demonstrate the Python data pipeline

This route uses the synthetic input and demonstrates file structure and processing logic. It does not reproduce the paper estimates.

1. Follow [SETUP.md](SETUP.md).
2. Start Jupyter in `notebooks/data-pipeline/`.
3. Run `before_start_test_environment.ipynb`.
4. Follow the ordered notebook table in [the pipeline notebook guide](notebooks/data-pipeline/README.md).

The full pipeline is:

```text
restricted daily JSON or synthetic demo
    -> Stage 1: cleaning, deduplication, language detection
    -> Stage 1.2: Russian ESCO translation (precomputed)
    -> Stage 2: skill extraction and work-mode classification
    -> Stage 3: OpenAI occupation classification
    -> Stage 4: ESCO verification and skill mapping
    -> Stage 4.5: region standardisation (precomputed lookup available)
    -> Stage 5: daily rejoin and monthly Parquet aggregation
```

### Route B: reproduce the reviewer-answer results

Public execution begins with notebook 02 because notebook 01 requires restricted daily data.

1. Start Jupyter in `notebooks/data-pipeline-answers/`.
2. Run notebooks 02, 03, and 04 as described in [the reviewer-answer guide](notebooks/data-pipeline-answers/README.md).
3. Compare generated files with `output/data-pipeline-answers/`.

These notebooks reproduce manuscript Tables A2–A6. The retained public notebooks were previously run twice and generated byte-identical artifacts.

### Route C: prepare Python paper-analysis datasets

1. Add the complete Stage 5 monthly full Parquet files under `data/data-pipeline/stage_05/parquet_monthly_full/`.
2. Run `notebooks/paper-analytics/01_build_analysis_ready_vacancy_data.ipynb`.
3. Add the required ESCO and ACLED reference files.
4. Run `02_analyze_vacancy_skills_and_occupation_composition.ipynb`.

See [the Python paper-analytics guide](notebooks/paper-analytics/README.md). These notebooks are memory intensive and have not yet been executed in the public package environment.

### Route D: reproduce the R statistical analysis

The R project uses its bundled analysis-ready Parquet files, so it does not require rerunning the restricted vacancy pipeline.

1. Add the canonical ACLED workbook under `data/paper-analytics/reference/acled/`, copy it byte-for-byte to `code/paper-analytics/reproducibility_package/data/`, and verify matching SHA-256 checksums.
2. Open `code/paper-analytics/reproducibility_package/ukraine_skills.Rproj`.
3. Run `renv::restore()` once.
4. Run `run_all.R`.
5. Inspect the generated `output/tables/` and `output/figures/` directories inside the R project.

Detailed script order, dependencies, runtime notes, and output mappings are in the [R project README](code/paper-analytics/reproducibility_package/README.md).

## Manuscript output mapping

### Reviewer-answer tables

| Manuscript output | Script/notebook | Generated file |
|---|---|---|
| Table A2, Panels A–B | `02_create_stratified_validation_sample.ipynb` | `output/data-pipeline-answers/validation/table_a2_*.csv` |
| Table A3 | `03_evaluate_classification_accuracy.ipynb` | `table_a3_manual_validation_accuracy.csv` |
| Table A4 | `03_evaluate_classification_accuracy.ipynb` | `table_a4_error_rates_by_language.csv` |
| Table A5 | `03_evaluate_classification_accuracy.ipynb` | `table_a5_error_rates_by_matching_method.csv` |
| Table A6 | `04_compare_extraction_thresholds.ipynb` | `classification_accuracy_by_threshold.csv` |

### R-generated main and appendix results

| Manuscript labels | R script |
|---|---|
| `tab:ols_combined`, `tab:ols_events_combined` | `R/02_baseline_regression.R` |
| `fig:structuralbreakraw`, `fig:itsfitted`, `fig:cusum`, `fig:supf`, `tab:break_tests`, `tab:structural_break` | `R/03_structural_break.R` |
| `tab:unit_roots` | `R/04_stationarity.R` |
| `tab:cointegration`, `tab:ecm`, `tab:detrended` | `R/05_cointegration_ecm.R` |
| `tab:digital_count`, `tab:decomposition`, `fig:decomposition` | `R/06_decomposition.R` |
| `tab:its_robustness` | `R/07_robustness_ovb.R` |
| `tab:monthlyols`, `tab:monthlyols_events` | `R/08_robustness_monthly.R` |
| `tab:smoothing_ma`, `tab:almon`, `fig:smoothing`, `fig:almon` | `R/09_robustness_smoothing.R` |
| `tab:seasonality`, `fig:seasonal_means`, `fig:acf_raw`, `fig:acf_demeaned` | `R/10_seasonality_diagnostics.R` |
| `tab:decomp`, `fig:decomp_timeseries`, `fig:decomp_occ`, `fig:decomp_counterfactual` | `R/11_decomp_within_between.R` |
| `tab:remote_channel`, `tab:remote_channel_evt`, `tab:first_stage_remote` | `R/12_mechanisms_remoteshare.R` |

All R paths in this table are relative to `code/paper-analytics/reproducibility_package/`. The complete output-filename mapping is maintained in the R project README and must be checked against the final manuscript before publication.

## External services and computational requirements

- Stage 2 uses sentence-transformer models and may download model weights on first use.
- Stages 1.2, 3, and 4.5 use the OpenAI Batch API when rerun. API use requires a private key, can incur costs, and is asynchronous.
- Paper-analytics notebook 01 loads and collapses multiple years of monthly vacancy data and requires substantial memory.
- The R project contains 164 locked package records and may require system libraries needed by packages such as `arrow`.
- No credential should be committed. Copy `.env.example` to the ignored local `.env` file when API access is required.

## Citation and release

Before final journal resubmission:

1. complete the data-source and redistribution review;
2. run the final validation workflow in clean Python and R environments;
3. include the approved analysis data and manuscript outputs;
4. publish the approved package version in Mendeley Data;
5. add the Mendeley Data DOI above;
6. attach the DOI to the journal submission under **File Inventory** using item type **Research Data**.
