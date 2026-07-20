# R Paper-Analytics Project

The final statistical analysis is preserved as a self-contained R project under `reproducibility_package/`.

## Project contents

| Path | Role |
|---|---|
| `reproducibility_package/ukraine_skills.Rproj` | RStudio project entry point |
| `reproducibility_package/.Rprofile` | Activates the project-local `renv` workflow |
| `reproducibility_package/renv.lock` | Locked R 4.3.0 dependency environment |
| `reproducibility_package/renv/` | `renv` activation and settings files; package library/cache are not published |
| `reproducibility_package/R/` | Ordered analysis scripts |
| `reproducibility_package/run_all.R` | Master analysis runner |
| `reproducibility_package/data/` | Bundled weekly, monthly, occupation, and electricity-control inputs |
| `reproducibility_package/output/` | Tables and figures created at runtime |

The R environment is independent of the repository-level Python environment. Do not combine `renv.lock` with `requirements.txt` or publish a machine-specific `renv/library/`.

## Setup and execution

1. Install R 4.3.0 and RStudio or another suitable R interface.
2. Open `reproducibility_package/ukraine_skills.Rproj`.
3. Restore packages once:

   ```r
   renv::restore()
   ```

4. Add a byte-identical copy of the pending ACLED workbook to `reproducibility_package/data/`; the canonical copy belongs under the repository-level `data/paper-analytics/reference/acled/` directory.
5. Run:

   ```r
   source("run_all.R")
   ```

The project uses paths derived from its project root. Machine-specific `C:/Users/...` data paths have been removed.

## Bundled inputs

- `final_weekly.parquet`
- `final_monthly.parquet`
- `final_dataset_occ_digital_month.parquet`
- `2025_10_14_electricity_outages.xlsx`
- `2025_10_14_elektro_boiovi_dii_ukraina_minenergo.xlsx`

## Pending input

```text
europe-central-asia_full_data_up_to-2025-07-25.xlsx
```

Without this workbook, `R/00_acled_data_prep.R` and the complete `run_all.R` sequence cannot finish.

When the workbook is added, verify that its SHA-256 checksum matches the canonical Python-reference copy documented in `data/paper-analytics/reference/acled/README.md`.

## Documentation and validation status

The detailed [R project README](reproducibility_package/README.md) provides the script order, dependency list, expected runtime, known manual elements, and complete manuscript output mapping.

The project has not yet been executed in the current repository environment because `Rscript` is unavailable. Before release, restore `renv`, run the complete pipeline, retain required outputs, and compare them with the current manuscript.
