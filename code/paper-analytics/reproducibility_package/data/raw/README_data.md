# Data Directory

Place the following raw data files here before running the pipeline.

## Required files

| File | Description | Used by |
|------|-------------|---------|
| `final_weekly.parquet` | Main weekly panel (job postings × week, Ukraine) | Scripts 02–07, 09–11, 13–14 |
| `final_monthly.parquet` | Monthly-aggregated panel | Script 08 |
| `final_dataset_occ_digital_month.parquet` | Occupation × month panel | Script 12 |
| `2025_10_14_electricity_outages.xlsx` | Hourly electricity outage schedule (energy-map.info, Jan 2023 onwards) | Scripts 06, 07, 13 |
| `2025_10_14_elektro_boiovi_dii_ukraina_minenergo.xlsx` | Combat-related power disconnections (MinEnergo, Mar 2022 onwards) | Scripts 06, 07, 13 |

## Variable codebook (key columns in `final_weekly.parquet`)

| Variable | Description |
|----------|-------------|
| `week` | Week start date (POSIXct, UTC) |
| `avg_digital_skill_share` | **Outcome** — vacancy-count-weighted average share of job postings requiring at least one digital skill |
| `total_fatalities` | Conflict fatalities in Ukraine that week (ACLED) |
| `num_events` | Number of conflict events that week (ACLED) |
| `vacancy_count` | Total job postings that week |
| `total_digital_skills` | Raw count of digital skill postings (numerator of `avg_digital_skill_share`) |
| `avg_military_skill_share` | Vacancy-count-weighted share of postings requiring military skills |
| `remote_share` | Share of postings explicitly mentioning remote work |

## Notes on data availability

- The parquet files are derived from Ukrainian job posting data (Work.ua / similar platform).
  Contact the corresponding author for access arrangements.
- The energy outage files are publicly available from
  [energy-map.info](https://energy-map.info/) (outages) and
  [Ministry of Energy Ukraine](https://www.mev.gov.ua/) (combat disconnections).
- `final_monthly.parquet` and `final_dataset_occ_digital_month.parquet` are
  pre-aggregated from the same underlying posting data.
