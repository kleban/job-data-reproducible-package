# Python Paper-Analytics Interim Data

Notebook `notebooks/paper-analytics/01_build_analysis_ready_vacancy_data.ipynb` writes one reproducible yearly file here:

```text
vacancies_<year>_collapsed_by_id.parquet
```

Each file collapses all available Stage 5 monthly full observations for that year to one row per vacancy identifier using the notebook’s documented aggregation rules. The yearly files limit peak memory use and are then combined into the final cross-year vacancy dataset.

These are generated intermediates, not independent sources. They are currently absent because notebook 01 has not been run on the complete 2021–2025 Stage 5 collection.
