# Python Data-Pipeline Data

This directory contains the input, intermediate, reference, tracker, and output files used by the Python vacancy-data workflow.

## Availability and scope

The public pipeline starts from `input/ua-2024-01-01.json`, a 100-row synthetic file that preserves the expected input structure but contains no real vacancies. The original daily Jooble records are restricted and are not redistributed.

Consequently:

- the included files demonstrate processing and data contracts;
- the included demonstration outputs do not reproduce the full 2021–2025 paper dataset;
- any full-data rerun requires authorised access to the original daily snapshots;
- the bundled R analysis-ready datasets provide a separate route for reproducing the statistical analysis without publishing raw vacancy text.

## Stage map

| Folder | Stage | Contents | Primary producer |
|---|---|---|---|
| `input/` | Input | Synthetic example or authorised daily `ua-YYYY-MM-DD.json` snapshots | External source |
| `stage_01/` | Cleaning | Deduplicated daily records, language labels, ID database, region/click snapshots | Stage 1 notebook |
| `stage_01_2/` | ESCO translation | English and precomputed Russian ESCO skill labels plus Batch API records | Stage 1.2 notebook |
| `stage_02/` | Skill/work mode | Multilingual skill references, extracted skills, and work-mode fields | Stage 2 notebooks |
| `stage_03/` | Occupation classification | Prompts, schema, Batch API inputs/outputs, trackers, and ESCO classifications | Stage 3 notebooks |
| `stage_04/` | ESCO verification | ESCO occupation/skill relations and verified vacancy enrichments | Stage 4 notebook |
| `stage_04_5/` | Region enrichment | Geographic references, Batch API examples, and precomputed region lookup | Stage 4.5 notebook |
| `stage_05/` | Final aggregation | Joined daily and monthly Parquet/JSON demonstration outputs | Stage 5 notebooks |

Each stage has a `README_data.md` describing its inputs, transformations, outputs, schemas, and publication status.

## Format conventions

- Daily source files: `ua-YYYY-MM-DD.json`
- Daily intermediate files: `ua-YYYY-MM-DD.pkl`
- Daily final files: `ua-YYYY-MM-DD.parquet`
- Monthly final files: `YYYY-M.parquet`
- Process trackers: Pandas pickle files used to resume long workflows
- Batch inputs: JSONL files compatible with the OpenAI Batch API

Process trackers can contain paths from the machine that generated them. They document processing state but should not be treated as portable analysis datasets.

## Relationship to paper analytics

The Python paper-preparation notebook reads the complete `stage_05/parquet_monthly_full/` collection and creates one vacancy-level analysis dataset. The public repository currently contains only a demonstration month, so the complete Python paper-preparation workflow cannot yet be rerun from the published Stage 5 files alone.

The final R analysis instead reads its bundled weekly, monthly, and occupation-by-month Parquet datasets from `code/paper-analytics/reproducibility_package/data/`. Their provenance and equivalence to the Python outputs must be confirmed before the final release.

## Detailed documentation

- [Input data](input/README_data.md)
- [Stage 1](stage_01/README_data.md)
- [Stage 1.2](stage_01_2/README_data.md)
- [Stage 2](stage_02/README_data.md)
- [Stage 3](stage_03/README_data.md)
- [Stage 4](stage_04/README_data.md)
- [Stage 4.5](stage_04_5/README_data.md)
- [Stage 5](stage_05/README_data.md)
