# Data Inventory

The repository separates data by workflow. Each component README documents file roles, schemas, public-availability restrictions, and handoffs to code.

| Component | Data guide | Role |
|---|---|---|
| Main Python pipeline | [data-pipeline/README.md](data-pipeline/README.md) | Restricted/synthetic inputs, ESCO references, stage intermediates, and Stage 5 aggregates |
| Reviewer answers | [data-pipeline-answers/README.md](data-pipeline-answers/README.md) | Included computed validation inputs and archived threshold counts |
| Python paper analytics | [paper-analytics/README.md](paper-analytics/README.md) | Python interim/analysis-ready files and external ESCO/ACLED references |
| R statistical analysis | [R data description](../code/paper-analytics/reproducibility_package/data/README_data.md) | Bundled R analysis-ready Parquet files and robustness-control workbooks |

The R inputs remain inside the self-contained R project so that its `.Rproj` and `renv` workflow can run without relocating files. The bundled R weekly/monthly datasets must not be assumed equivalent to the planned Python paper-analytics outputs until their provenance, schemas, coverage, and derived variables have been compared.

The original Jooble vacancy snapshots are restricted and are not published. The main pipeline includes a synthetic structural example; it cannot reproduce the paper estimates. See the root [README](../README.md#data-availability) for the package-wide availability statement.
