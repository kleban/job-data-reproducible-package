# data/data-pipeline/input — Demo Data Notice

This folder contains the raw input data for the pipeline.

## Synthetic demo file

| File | Rows | Description |
|------|------|-------------|
| `ua-2024-01-01.json` | 100 | **Synthetic demo data** — generated for testing and reproducibility purposes |

`ua-2024-01-01.json` was generated synthetically to allow users to run the full
pipeline without access to the original dataset. It preserves the exact structure
of real input files (column names, data types, value ranges) but contains no real
job vacancy records.

## Real data structure

Each input file is a JSON array of job vacancy records with the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `id` | integer | Unique job vacancy identifier |
| `title` | string | Job title |
| `description` | string | Full job description text |
| `region` | string | Ukrainian region where the job is located |
| `min_salary` | number \| null | Minimum salary (if specified) |
| `max_salary` | number \| null | Maximum salary (if specified) |
| `currency` | string \| null | Salary currency (UAH, USD, EUR) |
| `salary_rate` | string \| null | Payment frequency (monthly, hourly) |
| `date_created` | string | Vacancy publication date (YYYY-MM-DD HH:MM:SS) |
| `date_expired` | string \| null | Vacancy expiry date (YYYY-MM-DD HH:MM:SS) |
| `number_of_clicks` | integer | Number of times the vacancy was viewed |

## Reproducing with real data

The original dataset consists of daily JSON snapshots of job vacancies scraped
from a Ukrainian job board. To run the pipeline on real data, place your JSON
files in this folder using the naming convention `ua-YYYY-MM-DD.json` and
re-run the Stage 1 notebooks.
