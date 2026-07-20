# Data-Pipeline Answers: Migration Progress

## Scope

This workstream records the completed migration of the reviewer-answer analyses from the former `Q3/` working folder into the replication repository. References to `Q3/` below are historical audit notes; that source folder has been removed after validation and approval.

Target locations:

- `notebooks/data-pipeline-answers/` — reviewer-answer notebooks;
- `data/data-pipeline-answers/` — required input, interim, validation, and supporting data;
- `output/data-pipeline-answers/` — final tables, figures, and validation outputs.

These analyses are separate from the main data pipeline. Their notebooks may use explicit repository-relative paths and will not use the main pipeline's `Config` or `.env`.

## Working Rules

- Work one notebook or one tightly related file group at a time.
- Obtain user approval before moving or rewriting each group.
- Compare duplicate notebook versions before selecting the canonical file.
- Preserve analytical logic unless a code correction is explicitly approved.
- Add comments and Markdown documentation to every retained notebook.
- Document every notebook's purpose, inputs, outputs, and execution order.
- Copy and validate files in their target locations before removing anything from `Q3/`.
- Do not migrate `.venv/`, `.idea/`, caches, or editor metadata.
- Do not automatically migrate `Q3/data/old/`; retain only files required by an approved notebook or required for audit provenance.
- Do not delete duplicate or obsolete source files until the user explicitly approves cleanup.
- Publish computed, derived, interim, validation, and final output files required to verify the reviewer answers.
- Do not publish the original source/input datasets used by these analyses.
- For every non-published input, document its provenance, role, access restriction, and the derived file that replaces it in the public package. The user will provide missing provenance explanations for inclusion in the relevant README.

## Initial Inventory

Status: **completed**

- Source folder: `Q3/`
- Research files excluding `.venv/` and `.idea/`: 5,195
- Approximate size: 5.9 GB
- Notebooks: 18
- Main size concentration: `Q3/data/` (approximately 5.8 GB, including `data/old/`)

Notebook groups found:

1. Main validation workflow:
   - `01_remove_columns.ipynb`
   - `02_stats_final.ipynb`
   - `03_check_classification.ipynb`
   - corresponding `__*` copies
   - newer-looking copies under `07_stats/notebooks/`
2. Threshold-selection workflow:
   - `02_stats_threshold_check.ipynb`
   - `03_check_classification_threshold.ipynb`
   - `03_check_classification_threshold_all.ipynb`
   - `notebooks/threshold_selection/03_check_classification_threshold_all.ipynb`
3. Q6 diagnostic workflow:
   - `04_Q6_for_stats.ipynb`
   - `04_Q6_for_stats_stage_3.ipynb`
   - `04_Q6_for_stats_stage_4.ipynb`
   - `05_Q6_problems_on_files.ipynb`
4. Supporting notebook:
   - `read_stats.ipynb`

## Step-by-Step Plan

### Step 1 — Establish the canonical main validation workflow

Status: **completed**

- [x] 1.1 Compare all versions of `01_remove_columns.ipynb` by executable code, modification date, inputs, and outputs.
- [x] 1.2 Present differences and recommend one canonical version.
- [x] 1.3 After approval, move/copy the canonical notebook to `notebooks/data-pipeline-answers/`.
- [x] 1.4 Include its computed publication input and document the non-published original daily files.
- [x] 1.5 Update explicit paths for the new repository structure.
- [x] 1.6 Add title, purpose, prerequisites, input/output documentation, and code comments.
- [x] 1.7 Validate syntax and all referenced paths.
- [x] 1.8a Compare the principal versions of `02_stats_final.ipynb` and verify their computed files.
- [x] 1.8b After approval, migrate and rename the canonical notebook.
- [x] 1.8c Include the computed sample, manual-review template, and six descriptive-statistics files.
- [x] 1.8d Update paths, add documentation/comments, and validate notebook 02.
- [x] 1.9a Compare the principal versions of `03_check_classification.ipynb`, identify the final manual-coding file, and verify the reported statistics.
- [x] 1.9b After approval, migrate and rename the canonical notebook and completed manual-coding file.
- [x] 1.9c Include the classification-accuracy and grouped error-rate outputs.
- [x] 1.9d Update paths, fix the extract-type index label, add documentation/comments, and validate notebook 03.
- [x] 1.10 Verify the complete 01 → 02 → 03 handoff. Notebook 01 documents the private-input construction; the public executable sequence begins with the included notebook 01 output and runs notebooks 02 → 03.

### Step 2 — Prepare threshold-selection analyses

Status: **completed**

- [x] 2.1 Compare the threshold notebooks and identify the final analytical version.
- [x] 2.2 Document how threshold selection relates to the reviewer question and manuscript Table A6.
- [x] 2.3 Migrate one cleaned canonical notebook as `04_compare_extraction_thresholds.ipynb`.
- [x] 2.4 Include only the non-disclosive aggregate correct/compared counts required to reproduce Table A6.
- [x] 2.5 Update explicit repository-relative paths.
- [x] 2.6 Add comments, provenance, and notebook-level limitation documentation.
- [x] 2.7 Validate the generated threshold table against every value reported in Table A6.

Historical-data note: the vacancy-level predictions used for the archived threshold 0.7 result were overwritten. The retained analysis-ready counts reproduce the published table without fabricating vacancy-level records. The limitation is stated in the notebook and data README.

### Step 3 — Prepare Q6 diagnostic analyses

Status: **completed — excluded from the replication package**

- [x] 3.1 Review the Stage 3, Stage 4, and file-problem diagnostic notebooks.
- [x] 3.2 Determine that the three stage-summary notebooks are related exploratory checks and that the file-problem notebook is a separate one-day ID-flow audit.
- [x] 3.3 Identify inconsistent variable state, overwritten duplicate filenames, unavailable Stage 5 daily-unique data, and outputs that are not manuscript results.
- [x] 3.4 Apply the approved retention rule: keep only notebooks whose calculations appear in the manuscript.
- [x] 3.5 Exclude all four Q6 diagnostic notebooks because none produces a table, figure, or reported statistic in the manuscript.
- [x] 3.6 Do not migrate their private inputs, intermediate files, or diagnostic outputs.
- [x] 3.7 Leave the source notebooks in `Q3/` until the separately approved cleanup stage.

### Step 4 — Review supporting and miscellaneous files

Status: **completed — no additional files retained**

- [x] 4.1 Exclude `read_stats.ipynb`: it contains only imports and produces no manuscript calculation or output.
- [x] 4.2 Exclude `yo.csv`: it is a preliminary merged validation file, and 149 of its 200 manual codes differ from the final manuscript-validation data.
- [x] 4.3 Review all root-level duplicate notebooks not selected in Steps 1–3.
- [x] 4.4 Classify old validation/threshold copies as superseded duplicates and all Q6 diagnostics as excluded non-manuscript analyses.
- [x] 4.5 Apply the approved rule that only notebooks whose calculations appear in the manuscript are retained.

No files were deleted from `Q3/`; excluded and superseded files remain available for the final explicitly approved cleanup decision.

### Step 5 — Organize data files

Status: **completed**

Proposed target structure:

```text
data/data-pipeline-answers/
├── input/
├── interim/
├── validation/
└── README.md
```

- [x] 5.1 Trace every retained notebook read operation to a source file or file pattern.
- [x] 5.2 Identify the minimal reproducible input set.
- [x] 5.3 Separate generated interim files from true inputs.
- [x] 5.4 Preserve manual-review datasets needed to reproduce validation statistics.
- [x] 5.5 Exclude original source inputs from the public package and document their provenance and restriction.
- [x] 5.6 Select the earliest publishable computed file as the public starting point for each workflow.
- [x] 5.7 Retain publication datasets in Parquet/CSV rather than internal Pickle formats.
- [x] 5.8 Document provenance, row counts, columns, and role of every retained dataset.
- [x] 5.9 Verify that no retained notebook depends on `Q3/` paths.

### Step 6 — Organize outputs

Status: **completed**

Proposed target structure:

```text
output/data-pipeline-answers/
├── tables/
├── figures/
├── validation/
└── README.md
```

- [x] 6.1 Map manuscript Tables A2-A6 to final CSV files.
- [x] 6.2 Generate approved outputs in the reviewer-answer output folders.
- [x] 6.3 Ensure notebooks write new outputs directly to the target folders.
- [x] 6.4 Use descriptive canonical output names without `final`, `new`, or numbered-copy suffixes.
- [x] 6.5 Document which notebook creates each output.

### Step 7 — Documentation and dependency review

Status: **completed**

- [x] 7.1 Rewrite `notebooks/data-pipeline-answers/README.md` with execution order and notebook/output mapping.
- [x] 7.2 Rewrite `data/data-pipeline-answers/README.md` with input, provenance, restriction, and validation-data documentation.
- [x] 7.3 Rewrite `output/data-pipeline-answers/README.md` with the Tables A2-A6 output inventory.
- [x] 7.4 Confirm that the retained notebooks require only packages already pinned in the repository requirements.
- [x] 7.5 Record and test `pandas==2.3.3`, `numpy==2.4.0`, and `pyarrow==21.0.0`.
- [x] 7.6 Confirm that no API keys, local usernames, absolute environment paths, or private credentials are present.

### Step 8 — Final reproducibility audit

Status: **completed**

- [x] 8.1 Parse every retained notebook and confirm that all code cells compile without saved execution errors.
- [x] 8.2 Check every public input path; document the intentionally unavailable private notebook 01 inputs.
- [x] 8.3 Check that every output path points inside `output/data-pipeline-answers/`.
- [x] 8.4 Run public notebooks 02-04 twice in documented order with pinned package versions.
- [x] 8.5 Match regenerated manuscript Tables A2-A6 exactly and confirm stable hashes across repeated runs.
- [x] 8.6 Confirm that the main `data-pipeline` remains unchanged and independent.
- [x] 8.7 Produce the final file inventory and completion summary.

Audit date: **2026-07-20**. Public execution begins with notebook 02. Notebook 01 is retained as data-management documentation for the restricted Jooble inputs. The coder/adjudication details not present in the retained project materials are disclosed in the validation README rather than inferred.

### Step 9 — Source-folder cleanup

Status: **completed**

- [x] 9.1 Confirm that every approved file has been copied and validated.
- [x] 9.2 Present the obsolete, duplicate, exploratory, and private source-folder contents for removal.
- [x] 9.3 Remove the untracked `Q3/` source folder after explicit user approval.
- [x] 9.4 Verify that `Q3/` is absent and that all required retained files still exist.

## Current Next Action

The `data-pipeline-answers` migration, audit, and source cleanup are complete.

Proceed to the next separately approved replication-package workstream.
