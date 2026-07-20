# Stage 4.5 Data: Region Standardisation

## Purpose

Stage 4.5 maps heterogeneous source location strings to standardised English Ukrainian administrative-region names. The lookup is consumed by Stage 5 when enriching daily vacancy records.

## Producer and handoff

- Producer: `notebooks/data-pipeline/stage_4_5_region_enrichment.ipynb`
- Source values: unique raw region strings collected in Stage 1
- Main output: `region_db.pkl`
- Next consumer: Stage 5 daily rejoin
- API model documented by the workflow: `gpt-4.1`

## Normal replication action

Use the included precomputed `region_db.pkl` for the standard replication workflow. Rerun Stage 4.5 only when new vacancy data contain previously unseen region strings. A rerun requires an OpenAI API key and can incur costs.

## Files

| Path | Role |
|---|---|
| `select_region_prompt.txt` | Instructions and allowed standard region labels |
| `select_region_schema.json` | Structured API output schema |
| `regions_initial.json` | Initial seed mappings |
| `region_db_PREV.pkl` | Previous lookup snapshot used to identify new values |
| `region_db.pkl` | Current raw-to-standardised region lookup |
| `input/sample_1_100.jsonl` | Representative API request sample |
| `output/` | Runtime API outputs; not required when using the included lookup |
| `log/` | Runtime logs when enabled |
| `geo/level0.json` | Country-level geographic reference |
| `geo/level1.json` | Oblast-level geographic reference |
| `geo/level2.json` | Raion-level geographic reference |

`region_db.pkl` contains at least the raw source label and its standardised English region. It was built for the full 2021–2025 workflow and is broader than the synthetic demonstration input.

## Publication notes

- The representative JSONL file documents request structure without publishing all historical API requests.
- API outputs may not be byte-identical when rerun.
- Geographic reference provenance and redistribution permissions must be retained in the final data inventory.
