# Notebook Inventory

| Component | Guide | Purpose |
|---|---|---|
| Main data pipeline | [data-pipeline/README.md](data-pipeline/README.md) | Ordered construction of cleaned and enriched daily/monthly vacancy files |
| Reviewer answers | [data-pipeline-answers/README.md](data-pipeline-answers/README.md) | Classification validation and Stage 4 threshold sensitivity |
| Python paper analytics | [paper-analytics/README.md](paper-analytics/README.md) | Construction and descriptive analysis of paper datasets |

The main pipeline notebooks load paths from `notebooks/data-pipeline/.env`. Reviewer-answer and paper-analytics notebooks intentionally use repository-relative paths and do not use that configuration.
