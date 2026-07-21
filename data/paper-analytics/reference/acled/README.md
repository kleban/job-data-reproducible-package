# ACLED Conflict Data

The Python paper-analysis notebook reads:

```text
europe-central-asia_full_data_up_to-2025-07-25.xlsx
```

The workbook is used to derive monthly and weekly measures of conflict events and fatalities for Ukraine.

## Included-file inventory

| Property | Value |
|---|---|
| Size | 95,716,495 bytes |
| SHA-256 | `875C78457FCD1B53CA6E4CB3DFA7D78E4FBAE16E6DEBE99964A535203FE50317` |
| Worksheet | `Sheet1` |
| Data rows | 471,924, excluding the header |
| Columns | 31 |
| Formula cells | 0 |
| Package-supply date | 2026-07-21 |

The workbook passed ZIP/Open XML integrity validation. Its columns include the fields required by both analysis implementations: `EVENT_DATE`, `COUNTRY`, `SUB_EVENT_TYPE`, and `FATALITIES`.

This directory contains the canonical copy used by the Python workflow. A byte-identical copy is included at `code/paper-analytics/reproducibility_package/data/europe-central-asia_full_data_up_to-2025-07-25.xlsx` for the self-contained R project. Both copies have the SHA-256 checksum shown above.

Before publication, confirm the original ACLED download/access date, exact geographic and temporal coverage used in the paper, and license/redistribution conditions. The package-supply date is not necessarily the original ACLED download date.
