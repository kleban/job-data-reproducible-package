# Pipeline Input Data

## Public file

| File | Records | Status | Purpose |
|---|---:|---|---|
| `ua-2024-01-01.json` | 100 | Synthetic | Demonstrates the daily input schema without disclosing original vacancy records |

The file contains no real job advertisements. It is designed for structural and code-path testing and cannot reproduce the paper estimates.

## Restricted source

The substantive analysis uses daily online vacancy snapshots supplied to the authors by Jooble. The original records cover 2021–2025 and contain proprietary vacancy text. They are not included because of access and redistribution restrictions. Researchers seeking the source records must request access from the data provider.

For an authorised full-data rerun, place one JSON array per day in this folder using the naming convention:

```text
ua-YYYY-MM-DD.json
```

Stage 1 processes files in date/filename order because the first observed appearance of a vacancy determines the global deduplication result.

## Expected record structure

| Field | Expected type | Description |
|---|---|---|
| `id` | integer/string identifier | Vacancy identifier |
| `title` | string | Original vacancy title |
| `description` | string | Original vacancy description |
| `region` | string | Source location text |
| `min_salary` | number or null | Minimum advertised salary |
| `max_salary` | number or null | Maximum advertised salary |
| `currency` | string or null | Salary currency |
| `salary_rate` | string or null | Salary period or rate |
| `date_created` | date/time value | Vacancy creation date |
| `date_expired` | date/time value or null | Vacancy expiry date |
| `number_of_clicks` | integer/number | Recorded click count |

Additional source fields may be retained by the pipeline. The included synthetic file should be treated as the machine-readable schema example.

## Consumer

`notebooks/data-pipeline/stage_1_read_initial_data_fast.ipynb` reads this directory and writes Stage 1 outputs to `../stage_01/`.
