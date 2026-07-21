# Python Paper-Analytics Data

This directory is the data workspace for the Python paper-analytics notebooks. It is distinct from the bundled input data inside the self-contained R project.

## Directory map

| Directory | Role | Current status |
|---|---|---|
| `interim/` | Year-specific vacancy-ID collapses created by notebook 01 | Not generated in the public workspace |
| `analysis-ready/` | Final vacancy-level, weekly, and monthly Python analysis datasets | Not generated in the public workspace |
| `reference/esco/` | ESCO digital- and green-skills collections | Both required CSV files included and integrity-checked |
| `reference/acled/` | ACLED conflict-event workbook | Included and integrity-checked; redistribution terms still require confirmation |

## Data flow

```text
data/data-pipeline/stage_05/parquet_monthly_full/
    -> notebook 01
    -> interim yearly vacancy files
    -> vacancies_2021_2025_collapsed_by_id.parquet
    -> notebook 02 + ESCO/ACLED references
    -> weekly/monthly analysis files and figures
```

The complete monthly Stage 5 input is restricted/not currently included, so the Python paper-data build cannot yet be reproduced from the public demonstration month.

## Relationship to bundled R data

The R project uses separate bundled Parquet files under:

```text
code/paper-analytics/reproducibility_package/data/
```

Those files are the current direct inputs to the R manuscript analysis. Before final publication, document how they were produced and verify whether they correspond exactly to the Python weekly/monthly outputs described here. Do not silently substitute one set for the other.

The ACLED workbook in `reference/acled/` is the canonical downloaded copy. The R project requires a byte-identical copy in its own `data/` directory; record matching SHA-256 checksums before release.

## Availability requirements

For every final file, the approved package must document:

- producing notebook or external source;
- observation unit and temporal coverage;
- required variables and transformations;
- public/restricted status and redistribution terms;
- relationship to the manuscript tables and figures.
