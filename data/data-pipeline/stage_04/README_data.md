# Stage 4 Data: ESCO Verification and Skill Mapping

## Purpose

Stage 4 verifies the occupation code/title assigned in Stage 3 against the official ESCO taxonomy and attaches the skills related to the resolved ESCO occupation.

## Producer and handoff

- Producer: `notebooks/data-pipeline/stage_4_esco_skills_extraction.ipynb`
- Input: `data/data-pipeline/stage_03/result/`
- Reference input: official ESCO v1.2.0 English CSV exports in `esco_data/`
- Main output: `output/ua-YYYY-MM-DD.pkl`
- Next consumer: Stage 5 final rejoin

## Reference files

| File | Role | Key fields |
|---|---|---|
| `esco_data/occupations_en.csv` | Occupation lookup | code, preferred label, alternative labels, concept URI |
| `esco_data/skills_en.csv` | Skill lookup | preferred label, alternative labels, skill type, concept URI |
| `esco_data/occupationSkillRelations_en.csv` | Occupation-to-skill links | occupation URI, skill URI, relation type |

The files originate from the ESCO v1.2.0 English classification export. Their original license/source information must remain with the final package.

## Matching logic

The notebook resolves Stage 3 classifications through ordered preferred-label, alternative-label, and fuzzy matching steps. `code/data-pipeline/stage4.py` also contains documented corrections for known formatting inconsistencies in the original full-data classifications.

## Main added fields

| Field | Description |
|---|---|
| `classified_code` | Raw occupation code assigned in Stage 3 |
| `classified_title` | Raw occupation title assigned in Stage 3 |
| `classified_title_clean` | Normalised raw assigned title |
| `esco_title` | Verified ESCO preferred occupation label |
| `esco_id` | Resolved ESCO occupation concept URI |
| `esco_code` | Verified ESCO occupation code |
| `esco_skills` | Skills linked to the resolved occupation |
| `extract_type` | Matching method that produced the verified occupation |

Unresolved records retain missing verified ESCO fields. The raw Stage 3 assignment remains available for audit.

## Public demonstration

The reference tables are included, but the complete Stage 4 outputs for the restricted 2021–2025 vacancy data are not published in this folder. Run the notebook to create demonstration output from the available Stage 3 example. Stage 4 itself does not call an external API.
