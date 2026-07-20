# Python Data-Pipeline Data

This folder contains inputs, intermediate artifacts, reference files, process trackers, and outputs for the Python workflow.

## Data layers

| Folder | Role |
|---|---|
| `input/` | Raw-format input files; currently includes a 100-row synthetic demonstration file |
| `stage_01/` | Cleaned and deduplicated daily data plus identifier/region intermediates |
| `stage_01_2/` | Precomputed English-to-Russian ESCO skill translation artifacts |
| `stage_02/` | Skill-extraction and work-mode outputs |
| `stage_03/` | Batch inputs, raw LLM outputs, process state, and occupation classifications |
| `stage_04/` | ESCO reference data and verified occupation/skill outputs |
| `stage_04_5/` | Region reference files and the precomputed standardized-region database |
| `stage_05/` | Joined daily data and final monthly Python outputs |

Each stage folder contains a `README_data.md` with its files, schema, and relationship to adjacent stages.

## Availability warning

The included input is synthetic. The availability of the complete original raw data and the final analysis-ready data has not yet been finalized. Any restricted source must be documented in the root README, and any published pseudo-data must preserve the structure and summary properties required by the journal.

## Path ownership

Python notebooks read and write only within `data/data-pipeline/`. The future R paper-analytics workflow should consume explicitly selected Stage 5 outputs through its own documented data area rather than modifying pipeline intermediates.
