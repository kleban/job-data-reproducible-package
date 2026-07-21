# ESCO Digital and Green Skill Collections

The Python paper-analysis notebook reads these included files:

```text
digitalSkillsCollection_en.csv
greenSkillsCollection_en.csv
```

They identify which extracted English skill labels belong to ESCO’s digital and green collections. They are distinct from the general occupation/skill tables used by Stages 1.2, 2, and 4.

## Included-file inventory

| File | Data rows | Columns | Size (bytes) | SHA-256 |
|---|---:|---:|---:|---|
| `digitalSkillsCollection_en.csv` | 1,284 | 10 | 794,266 | `869F8F9772194E1850048867FF717941B653753194CD8AA7F8F4AD2AF2166F32` |
| `greenSkillsCollection_en.csv` | 591 | 10 | 423,824 | `0A1D3399B4EC44C4CA55EFE66576AC7123E36397E79D649672165F3AF981EDA6` |

Both files are UTF-8 comma-delimited CSVs without a byte-order mark. Every parsed record has the expected 10 columns:

```text
conceptType, conceptUri, preferredLabel, status, skillType,
reuseLevel, altLabels, description, broaderConceptUri, broaderConceptPT
```

The repository copies are byte-identical to the files supplied by the authors on 2026-07-21. No rows, values, filenames, encodings, or delimiters were changed.

## Provenance still to confirm

Before publication, add the exact ESCO release/version, original download URL, original download/access date, license and redistribution terms, and confirmation that the supplied files are unchanged official exports. The checksums above identify the copies currently used by the analysis.
