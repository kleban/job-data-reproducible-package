# Data-Pipeline Answers: Migration Progress

## Scope

This workstream prepares the reviewer-answer analyses currently stored in `Q3/` for inclusion in the replication repository.

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

Status: **in progress**

- [x] 1.1 Compare all versions of `01_remove_columns.ipynb` by executable code, modification date, inputs, and outputs.
- [x] 1.2 Present differences and recommend one canonical version.
- [x] 1.3 After approval, move/copy the canonical notebook to `notebooks/data-pipeline-answers/`.
- [x] 1.4 Include its computed publication input and document the non-published original daily files.
- [x] 1.5 Update explicit paths for the new repository structure.
- [x] 1.6 Add title, purpose, prerequisites, input/output documentation, and code comments.
- [x] 1.7 Validate syntax and all referenced paths.
- [ ] 1.8 Repeat items 1.1–1.7 for `02_stats_final.ipynb`.
- [ ] 1.9 Repeat items 1.1–1.7 for `03_check_classification.ipynb`.
- [ ] 1.10 Verify the complete 01 → 02 → 03 handoff.

### Step 2 — Prepare threshold-selection analyses

Status: **pending**

- [ ] 2.1 Compare the threshold notebooks and identify the final analytical version.
- [ ] 2.2 Document how threshold selection relates to the reviewer question.
- [ ] 2.3 After approval, migrate the selected notebook(s).
- [ ] 2.4 Migrate only the required threshold input and validation files.
- [ ] 2.5 Update explicit repository-relative paths.
- [ ] 2.6 Add comments and notebook-level documentation.
- [ ] 2.7 Validate generated threshold statistics and output files.

### Step 3 — Prepare Q6 diagnostic analyses

Status: **pending**

- [ ] 3.1 Review the Stage 3, Stage 4, and file-problem diagnostic notebooks.
- [ ] 3.2 Determine whether they form one sequential workflow or independent checks.
- [ ] 3.3 Identify duplicate, exploratory, or unused cells.
- [ ] 3.4 Present the proposed retained notebook set for approval.
- [ ] 3.5 Migrate approved notebooks and their required data.
- [ ] 3.6 Add comments, purpose statements, inputs, outputs, and execution instructions.
- [ ] 3.7 Validate each diagnostic output.

### Step 4 — Review supporting and miscellaneous files

Status: **pending**

- [ ] 4.1 Determine whether `read_stats.ipynb` is required.
- [ ] 4.2 Determine whether `yo.csv` is a genuine input/output or a temporary file.
- [ ] 4.3 Review root-level duplicate notebooks not selected in Steps 1–3.
- [ ] 4.4 Classify each remaining file as retained, archived, duplicate, temporary, or excluded.
- [ ] 4.5 Obtain approval for the classification.

### Step 5 — Organize data files

Status: **pending**

Proposed target structure:

```text
data/data-pipeline-answers/
├── input/
├── interim/
├── validation/
└── README.md
```

- [ ] 5.1 Trace every retained notebook read operation to a source file or file pattern.
- [ ] 5.2 Identify the minimal reproducible input set.
- [ ] 5.3 Separate generated interim files from true inputs.
- [ ] 5.4 Preserve manual-review datasets needed to reproduce validation statistics.
- [ ] 5.5 Exclude original source inputs from the public package and document their provenance and restriction.
- [ ] 5.6 Select the earliest publishable computed file as the public starting point for each workflow.
- [ ] 5.7 Convert formats only when needed and only after approval.
- [ ] 5.8 Document provenance, row counts, columns, and role of every retained dataset.
- [ ] 5.9 Verify that no retained notebook depends on `Q3/` paths.

### Step 6 — Organize outputs

Status: **pending**

Proposed target structure:

```text
output/data-pipeline-answers/
├── tables/
├── figures/
├── validation/
└── README.md
```

- [ ] 6.1 Map each reviewer answer to its final table, figure, or validation statistic.
- [ ] 6.2 Move approved existing outputs.
- [ ] 6.3 Ensure notebooks write new outputs directly to the target folders.
- [ ] 6.4 Remove ambiguous names such as `final`, `new`, numbered copies, or terminal-export suffixes from canonical outputs.
- [ ] 6.5 Document which notebook creates each output.

### Step 7 — Documentation and dependency review

Status: **pending**

- [ ] 7.1 Rewrite `notebooks/data-pipeline-answers/README.md` with execution order and notebook/output mapping.
- [ ] 7.2 Rewrite `data/data-pipeline-answers/README.md` with input and validation-data documentation.
- [ ] 7.3 Rewrite `output/data-pipeline-answers/README.md` with the final output inventory.
- [ ] 7.4 Review `Q3/requirements.txt` and merge only required packages into the repository dependency documentation.
- [ ] 7.5 Record the Python version and package versions used by the retained notebooks.
- [ ] 7.6 Confirm that no API keys, local usernames, environment paths, or private credentials are present.

### Step 8 — Final reproducibility audit

Status: **pending**

- [ ] 8.1 Parse every retained notebook and clear obsolete execution errors.
- [ ] 8.2 Check that every input path exists.
- [ ] 8.3 Check that every output path points inside `output/data-pipeline-answers/`.
- [ ] 8.4 Run notebooks in documented order where feasible.
- [ ] 8.5 Compare regenerated statistics with the approved reviewer-answer values.
- [ ] 8.6 Confirm that the main `data-pipeline` remains unchanged and independent.
- [ ] 8.7 Produce the final file inventory and completion summary.

### Step 9 — Source-folder cleanup

Status: **blocked until explicit approval**

- [ ] 9.1 Confirm that every approved file has been copied and validated.
- [ ] 9.2 Present the list of obsolete/duplicate files proposed for removal.
- [ ] 9.3 Remove `Q3/.venv`, `Q3/.idea`, duplicates, and migrated source files only after explicit approval.
- [ ] 9.4 Remove the empty `Q3/` folder only after final confirmation.

## Current Next Action

Begin Step 1.8: compare the principal versions of `02_stats_final.ipynb`:

- `Q3/02_stats_final.ipynb`
- `Q3/__02_stats_final.ipynb`
- `Q3/07_stats/notebooks/02_stats_final.ipynb`

No migration or source cleanup will occur until the comparison is reviewed and approved.
