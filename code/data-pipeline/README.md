# Python Data-Pipeline Modules

This directory contains reusable Python modules imported by the ordered notebooks in `notebooks/data-pipeline/`. The modules are not standalone entry points.

## Module map

| Module | Responsibility | Primary consumers |
|---|---|---|
| `general.py` | Loads `.env`, exposes repository paths, manages process trackers, and provides shared file utilities | All pipeline notebooks |
| `stage1.py` | Reads daily JSON, deduplicates vacancy IDs, cleans text, detects language, and creates ID/region/click snapshots | Stage 1 notebooks |
| `stage2.py` | Builds multilingual ESCO skill retrievers, extracts candidate skills, and supports work-mode classification | Stage 2 notebooks |
| `stage3.py` | Creates OpenAI Batch API requests, submits/checks jobs, downloads responses, and merges ESCO occupation classifications | Stage 3 notebooks |
| `stage4.py` | Verifies ESCO occupation titles/codes, maps occupations to skills, and applies documented corrections | Stage 4 notebook |

## Import mechanism

Each processing notebook first loads the bootstrap located beside the notebooks:

```python
from pipeline_bootstrap import configure_pipeline

configure_pipeline()
```

The bootstrap locates `code/data-pipeline/`, adds it to `sys.path`, and normalises the working directory before `general.Config` loads `.env`. This avoids machine-specific absolute paths.

## Configuration contract

- Publishable configuration template: `notebooks/data-pipeline/.env.example`
- Local ignored configuration: `notebooks/data-pipeline/.env`
- Data root: `data/data-pipeline/`
- Optional credential: `OPENAI_API_KEY`, required only for API-dependent reruns

Do not place credentials in source files, notebooks, `.env.example`, or committed outputs.

## Execution and testing

Use the notebooks rather than calling module functions manually. The required order, normal run/skip decisions, and API pause points are documented in [the notebook guide](../../notebooks/data-pipeline/README.md).

The included synthetic vacancy file exercises the repository structure but does not establish equivalence to the restricted full Jooble dataset. Full runtime validation remains required before publication.
