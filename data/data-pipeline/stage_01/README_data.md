# Stage 1 Data: Cleaning and Deduplication

## Purpose

Stage 1 reads daily vacancy JSON snapshots, derives the snapshot date from each filename, cleans vacancy titles and descriptions, detects text language, and separates globally unique vacancy records from repeated daily observations.

## Producer and handoff

- Producer: `notebooks/data-pipeline/stage_1_read_initial_data_fast.ipynb`
- Input: `data/data-pipeline/input/ua-YYYY-MM-DD.json`
- Main output: `output/ua-YYYY-MM-DD.pkl`
- Next consumer: Stage 2
- Additional consumer: Stage 5 uses the ID/region/click snapshots when rebuilding full daily files

## Transformations

1. discover input files in filename order;
2. read daily JSON arrays;
3. normalise and clean title/description text;
4. detect title and description language;
5. store ID, region, and click information for every daily snapshot;
6. retain only IDs not observed in an earlier processed file for the unique daily output;
7. update resumable process trackers.

## Files

| Path | Role |
|---|---|
| `process.pkl` | One tracker row per source file, including cleaning and snapshot status |
| `unic_id_db.pkl` | Global database of vacancy IDs already observed in earlier files |
| `id_region_click/ua-YYYY-MM-DD.pkl` | Daily ID, region, and click snapshot used in later rejoining |
| `output/ua-YYYY-MM-DD.pkl` | Cleaned, globally deduplicated daily vacancy records |

Tracker files can contain paths from the environment where they were generated. They support resuming work but are not portable research datasets.

## Main output fields

The Stage 1 output preserves source vacancy fields and adds:

| Field | Description |
|---|---|
| `date` | Snapshot date derived from the filename |
| `clean_title` | Normalised vacancy title |
| `clean_desc` | Normalised vacancy description |
| `title_lang` | Detected title language |
| `desc_lang` | Detected description language |

Typical language labels include `uk`, `ru`, `en`, `pl`, and `cs`.

## Public demonstration

The repository contains Stage 1 artifacts derived from the synthetic 100-row input day. The complete 2021–2025 daily source and outputs are not published. The demonstration validates structure only and does not preserve the full-data observation count or substantive distributions.
