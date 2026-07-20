# Code Inventory

| Component | Guide | Execution model |
|---|---|---|
| Python data pipeline | [data-pipeline/README.md](data-pipeline/README.md) | Shared modules imported by ordered notebooks; no master runner |
| Paper analytics | [paper-analytics/README.md](paper-analytics/README.md) | Self-contained R project with `run_all.R`; Python preparation notebooks are documented separately |

Python notebooks are indexed in [the notebook inventory](../notebooks/README.md). The R project retains its own `.Rprofile`, `renv.lock`, project file, inputs, and generated-output directories.
