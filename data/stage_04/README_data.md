# data/stage_04 — Stage 4 Outputs (ESCO Skills Mapping)

## What this stage produces

Stage 4 enriches each job vacancy with a full set of ESCO skill requirements.
Using the ESCO occupation code assigned in Stage 3, the pipeline looks up all
skills associated with that occupation in the official ESCO taxonomy tables.
For each vacancy, the notebook computes a fuzzy-matched preferred label from
the LLM-generated occupation title, then joins the occupation–skill relations
to build a structured skill profile.

The `manual_data_correction()` function in `code/stage4.py` also applies
targeted row-level corrections for records where the LLM output had minor
formatting inconsistencies (relevant to the original 2021–2025 dataset only).

---

## Folder structure

```
data/stage_04/
├── raw/
│   └── esco_data/
│       ├── occupations_en.csv             ← ESCO occupation reference table
│       ├── skills_en.csv                  ← ESCO skill reference table
│       └── occupationSkillRelations_en.csv ← ESCO occupation–skill links
└── processed/
    └── output/
        └── ua-YYYY-MM-DD.pkl              ← Stage 4 output files (one per day)
```

---

## Reference files (`raw/esco_data/`)

All three files are sourced from the official [ESCO API](https://esco.ec.europa.eu/)
(version 1.2.0, English language export). They are static reference data and
do not change between pipeline runs.

### `occupations_en.csv`

ESCO occupation reference table. Key columns used by the pipeline:

| Column | Description |
|--------|-------------|
| `code` | 4-digit ESCO occupation code |
| `preferredLabel` | English preferred occupation title |
| `altLabels` | Newline-separated list of alternative labels |
| `conceptUri` | Full ESCO URI for the occupation concept |

### `skills_en.csv`

ESCO skill reference table. Key columns used by the pipeline:

| Column | Description |
|--------|-------------|
| `skillType` | `skill/competence` or `knowledge` |
| `preferredLabel` | English preferred skill label |
| `altLabels` | Newline-separated alternative labels |
| `conceptUri` | Full ESCO URI for the skill concept |

### `occupationSkillRelations_en.csv`

Maps ESCO occupations to their required/optional skills. Key columns:

| Column | Description |
|--------|-------------|
| `occupationUri` | URI of the occupation |
| `skillUri` | URI of the linked skill |
| `relationType` | `essential` or `optional` |

---

## Output files (`processed/output/`)

One pickle file per daily input (`ua-YYYY-MM-DD.pkl`). Contains all Stage 3
columns plus the following columns added in Stage 4:

| Column | Type | Description |
|--------|------|-------------|
| `classified_code` | str | Raw ESCO code from Stage 3 LLM output (renamed from `esco_code`) |
| `classified_title` | str | Raw ESCO title from Stage 3 LLM output (renamed from `esco_title`) |
| `classified_title_clean` | str | Lowercased, whitespace-collapsed version of `classified_title` |
| `esco_title` | str | Verified ESCO preferred label after 4-step matching |
| `esco_id` | str | Full ESCO concept URI (e.g. `http://data.europa.eu/esco/occupation/...`) |
| `esco_code` | str | 4-digit ESCO occupation code resolved from `esco_title` |
| `esco_skills` | str | JSON list of ESCO skill preferred labels associated with this occupation |
| `extract_type` | str | Which matching step resolved the title: `preferredLabel`, `altLabels`, `preferredLabel_fuzzy`, or `altLabels_fuzzy` |

Records that could not be matched in any step have `None` in `esco_title`, `esco_id`, `esco_code`, `esco_skills`, and `extract_type`.

> **Note:** The `processed/output/` folder is empty in this repository.
> Run `stage_4_esco_skills_extraction.ipynb` to generate the output files
> from the demo input `ua-2024-01-01.pkl`. No API key required.
