# Stage 5 Data: Final Daily and Monthly Files

## Purpose

Stage 5 joins the cleaning, skill, occupation, and region enrichments into final daily vacancy files and then aggregates those files by calendar month. Parquet is the canonical format for downstream paper-data preparation; JSON exports are retained for compatibility and inspection.

## Producers

| Notebook | Output |
|---|---|
| `stage_5_1_rejoin_daily_unique_files.ipynb` | Unique enriched daily Parquet/JSON files |
| `stage_5_2_to_monthly_unique.ipynb` | Unique monthly Parquet/JSON files |
| `stage_5_3_rejoin_full_files.ipynb` | Full enriched daily Parquet/JSON files |
| `stage_5_4_to_monthly_full.ipynb` | Full monthly Parquet/JSON files |

## Unique and full variants

| Variant | Unit |
|---|---|
| `unique` | Each vacancy ID is retained only for its first observed daily appearance |
| `full` | Repeated daily observations remain available for measures such as changing click counts |

## Files and folders

| Path | Role |
|---|---|
| `process_unique.pkl` | Resume tracker for the unique daily rejoin |
| `process_full.pkl` | Resume tracker for the full daily rejoin |
| `parquet_daily_unique/` | Enriched unique daily Parquet files |
| `parquet_daily_full/` | Enriched full daily Parquet files |
| `parquet_monthly_unique/` | Unique monthly Parquet files |
| `parquet_monthly_full/` | Full monthly Parquet files; input to Python paper-analytics notebook 01 |
| `json_daily_unique/`, `json_daily_full/` | JSON equivalents of daily outputs |
| `json_daily_ua_unique/`, `json_daily_ua_full/` | Daily subsets created by the existing workflow |
| `json_monthly_unique/` | Unique monthly JSON files |
| `json_monthly_ua_unique/`, `json_monthly_ua_full/` | Monthly Ukraine subsets created by the existing workflow |
| `log/` | Runtime logs when enabled |

Daily files follow `ua-YYYY-MM-DD.*`; monthly files follow `YYYY-M.*`.

## Core schema

The final files preserve source vacancy variables and add pipeline-derived fields, including:

- cleaned title and description plus detected languages;
- extracted multilingual and English skill labels;
- work-mode classification;
- raw and verified ESCO occupation classifications;
- occupation-linked ESCO skills and matching method;
- snapshot date and click count;
- original and standardised location fields, city, country, and coordinates.

The exact columns in a final file are the authoritative machine-readable schema. Downstream notebooks validate the subset they require.

## Filtering conventions

The `_ua_` suffix is historical and does not represent one universal filter:

| Producer | `_ua_` selection |
|---|---|
| Stage 5.1 daily unique JSON | `desc_lang == "uk"` |
| Stage 5.2 monthly unique JSON | `country == "Ukraine"` |
| Stage 5.3 daily full JSON | `country == "Ukraine"` |
| Stage 5.4 monthly full JSON | `country == "Ukraine"` |

These exports should not be treated as interchangeable. The canonical downstream paper-data handoff is the unfiltered monthly full Parquet collection.

## Public demonstration and paper handoff

This repository currently contains demonstration outputs for January 2024 derived from the synthetic input. The full 2021–2025 Stage 5 monthly collection is not included here.

`notebooks/paper-analytics/01_build_analysis_ready_vacancy_data.ipynb` requires the complete `parquet_monthly_full/` collection. Therefore the complete Python paper-data build cannot be reproduced from the included demonstration month alone. The R analysis has separate bundled analysis-ready datasets documented under `code/paper-analytics/reproducibility_package/data/`.

## Demonstration example

```python
import pandas as pd

demo = pd.read_parquet(
    "data/data-pipeline/stage_05/parquet_monthly_full/2024-1.parquet"
)
print(demo.shape)
print(demo.columns.tolist())
```
