# Paper analytics data

This directory stores data created specifically for the statistical analyses reported in the paper.

- `interim/` contains yearly files created while assembling the analysis-ready dataset.
- `analysis-ready/` contains the final datasets read by the paper-analysis notebooks and R project.

The first preparation notebook reads monthly Parquet inputs directly from `data/data-pipeline/stage_05/parquet_monthly_full/`; those Stage 5 files are documented as part of the data pipeline.
