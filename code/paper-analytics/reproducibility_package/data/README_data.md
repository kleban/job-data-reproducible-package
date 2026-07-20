# R Analysis Data

This directory contains the direct inputs to the self-contained R statistical project. The Parquet files are analysis-ready derived data, not the original vacancy snapshots. The two energy workbooks are supporting control-data sources. One ACLED workbook is still pending.

## Required files

| File | Role | Used by | Included? |
|---|---|---|---:|
| `final_weekly.parquet` | Main weekly analytical panel | Scripts 01–07, 09–10, and 12–13 | Yes |
| `final_monthly.parquet` | Monthly analytical panel | Script 08 | Yes |
| `final_dataset_occ_digital_month.parquet` | Occupation-by-month analytical panel | Script 11 | Yes |
| `2025_10_14_electricity_outages.xlsx` | Electricity-outage controls | Scripts 02, 07, and 13 | Yes |
| `2025_10_14_elektro_boiovi_dii_ukraina_minenergo.xlsx` | Combat-related power-disconnection controls | Scripts 02, 07, and 13 | Yes |
| `europe-central-asia_full_data_up_to-2025-07-25.xlsx` | ACLED conflict events used by script 00 | Script 00 | No; pending |

Script numbers refer to files under `../R/`. Script 13 is retained but is not called by the current `../run_all.R`; script 02 is the baseline-regression implementation used by the master runner.

## Key weekly variables

| Variable | Description |
|---|---|
| `week` | Week start date (POSIXct, UTC) |
| `avg_digital_skill_share` | Vacancy-count-weighted share of postings requiring at least one digital skill |
| `total_fatalities` | Conflict fatalities in Ukraine during the week |
| `num_events` | Number of conflict events during the week |
| `vacancy_count` | Total vacancy postings during the week |
| `total_digital_skills` | Count used as the numerator of the digital-skill share |
| `avg_military_skill_share` | Vacancy-count-weighted share of postings requiring military skills |
| `remote_share` | Share of postings explicitly mentioning remote work |

## Provenance and availability

- The Parquet files were derived from the restricted Jooble vacancy data used by the authors and are included as direct R-analysis inputs. Their derivation and equivalence to the planned Python paper-analytics weekly/monthly outputs still require confirmation before release.
- The electricity-outage workbook is associated with [energy-map.info](https://energy-map.info/).
- The combat-disconnection workbook is associated with the [Ministry of Energy of Ukraine](https://www.mev.gov.ua/).
- The pending ACLED workbook must use the exact filename above. Its download date, coverage, checksum, and redistribution conditions must be recorded when it is added.

Do not move these files to the repository-level `data/paper-analytics/` directory unless all R paths and the project documentation are deliberately revised. Keeping them here preserves the autonomous `.Rproj`/`renv` workflow.
