# Prompt: Build a Reproducible Research Package for Mendeley Data

## Purpose

This prompt is for use with Claude (or another AI assistant) when preparing a research
code repository for publication on **Mendeley Data**, **Zenodo**, **OSF**, or any other
academic reproducibility platform. It captures the full workflow, conventions, and rules
developed during a real project. Adapt the paper-specific sections to your own project.

---

## Initial setup prompt (paste this at the start of a new session)

```
You are helping me prepare a research repository for Mendeley Data publication.

The repository should allow other researchers to reproduce the methodology described
in the paper using the provided code and a synthetic/demo dataset.

---

ROLES:
- SOURCE: [path to your working/original project] — READ ONLY, never modify
- OUTPUT: [path to the new clean repository] — all new/modified files go here

GLOBAL RULES:
1. Never modify SOURCE. Only read from it.
2. Always write new or modified files to OUTPUT.
3. Ask before doing anything to a file — I decide: copy / modify / replace / skip.
4. For all .ipynb files: copy first → I run and fix errors → then you add description cells.
5. Every .ipynb must end with a copyright footer markdown cell:
   --- (horizontal rule)
   © [YEAR] [Authors]. All rights reserved.
6. All .py files get Google-style docstrings on every function.
7. Add markdown annotation cells before every code cell in all notebooks.
8. Use only intermediate/ and processed/ subfolders in data/ — no raw/ or log/ unless needed.
9. Track all decisions in prompts.md (audit trail).
10. Track all progress in progress.md (completion checklist).

PAPER METADATA:
- Title: [Your paper title]
- Authors: [Author 1, Author 2]
- Year: [Year]
- Replace all placeholders [YEAR], [Authors], [Paper Title] with these values everywhere.

START:
1. Create progress.md — a checklist of all files to process (notebooks, py files, data folders).
2. Create prompts.md — audit trail, starting with this prompt.
3. Confirm the OUTPUT folder structure before doing anything else.
```

---

## Repository structure to establish

```
repository/
├── README.md                    ← full pipeline documentation with links
├── SETUP.md                     ← environment setup (Python version, venv, pip)
├── requirements.txt             ← pinned dependencies
├── notebooks/
│   ├── .env                     ← API keys + data paths (relative to notebooks/)
│   ├── before_start_test_environment.ipynb
│   └── [stage notebooks...]
├── code/
│   ├── general.py               ← shared utilities + Config class
│   └── [stage modules...]
├── data/
│   ├── input/                   ← raw demo/synthetic input data
│   │   └── README_data.md
│   └── stage_XX/
│       ├── intermediate/        ← process trackers, temp files
│       ├── processed/           ← final stage outputs
│       └── README_data.md
└── manuscript/                  ← paper PDF (optional)
```

**Key rule:** `.env` must be in `notebooks/` (not repo root) because modules load it
relative to the current working directory when called from notebooks.

---

## Workflow for each file type

### Python modules (.py files)

1. Read the SOURCE file.
2. Copy to `code/` in OUTPUT.
3. Add Google-style docstrings to every function:
   - Summary line
   - Args section with types and descriptions
   - Returns section
4. Add inline comments explaining non-obvious logic.
5. Fix any known API breaking changes (see Common Issues below).

### Jupyter notebooks (.ipynb files)

**Step 1 — Copy:** Copy the notebook from SOURCE to `notebooks/` in OUTPUT as-is.

**Step 2 — User runs:** The user runs the notebook and reports errors. Fix them.

**Step 3 — Annotate:** Add markdown cells before every code cell explaining:
- What the cell does
- Why (not just what)
- Any important parameters or thresholds

**Step 4 — Notebook header:** Insert a markdown cell after the title cell with:
- Stage number and name
- Purpose (1-2 sentences)
- Input paths
- Output paths
- Run instructions (API key needed? Skip?)

**Step 5 — Copyright footer:** Add as the last cell:
```markdown
---
© [YEAR] [Authors]. All rights reserved.
```

### Data folders

For each `data/stage_XX/` folder, create `README_data.md` with:
1. **What this stage produces** — plain-language description
2. **Folder structure** — full tree with file descriptions
3. **File-by-file documentation:**
   - Purpose of each file
   - Column schema for DataFrames (column name, type, description)
   - Example values where helpful
4. **Demo file section** — what the demo input produces

### README.md

Build incrementally as stages are completed. Must include:
1. **Quick navigation table** — links to SETUP.md, .env, all README_data.md files
2. **Repository structure** — full tree with descriptions
3. **Pipeline flow diagram** — ASCII art showing data flow between stages
4. **Per-stage sections** with:
   - Purpose paragraph
   - Table of notebooks with links
   - Numbered processing steps
   - Input / Output paths
   - Link to `README_data.md`
   - Notes on pre-completed steps (⚠️ skip unless extending)
5. **How to run** — numbered steps with exact commands
6. **Data section** — table linking all README_data.md files
7. **Code modules table** — one row per .py file with description
8. **Dependencies table** — package + purpose
9. **Citation** — BibTeX block
10. **Copyright footer**

---

## Tracking files

### progress.md

Create at session start. Checklist format:
```markdown
## Session [date]

### Code files
- [ ] general.py
- [ ] stage1.py
...

### Notebooks
- [ ] before_start_test_environment.ipynb
- [ ] stage_1_*.ipynb
...

### Data folders
- [ ] data/input/ — README_data.md
- [ ] data/stage_01/ — README_data.md
...

### Documentation
- [ ] README.md
- [ ] SETUP.md
- [ ] requirements.txt
```

### prompts.md

Append every significant decision:
```markdown
## [timestamp] Decision: [topic]
[what was decided and why]
```

---

## Common issues and fixes

### fast-langdetect v1.0.0 breaking change

```python
# OLD (broken in v1.0.0 — LangDetector/LangDetectConfig removed):
from fast_langdetect import LangDetector, LangDetectConfig

# FIXED:
from fast_langdetect import detect as _ft_detect

def detect_lang(text):
    result = _ft_detect(str(text)[:500])
    if isinstance(result, list):
        return result[0]["lang"]
    return result["lang"]
```

Move this import **inside the function** (lazy import) to prevent import failures
in stages that import the module but never call language detection:

```python
def detect_lang(text):
    from fast_langdetect import detect as _ft_detect
    result = _ft_detect(str(text)[:500])
    if isinstance(result, list):
        return result[0]["lang"]
    return result["lang"]
```

### pydantic/pydantic-core version mismatch (openai package)

```bash
pip uninstall pydantic pydantic-core -y
pip install pydantic   # pip resolves compatible pydantic-core automatically
```

### venv naming

Use `venv` (not `.venv`) as the virtual environment folder name. PyCharm
sometimes fails to locate `.venv` on first creation.

### .env location

Place `.env` in `notebooks/` not the repo root. The `Config` class uses
`dotenv_values(".env")` which resolves relative to the **current working directory**
(which is `notebooks/` when running from Jupyter).

### Stage tracker reset (reprocess a file)

If a stage tracker has a file marked `complete` from a failed run:
1. Delete the output pkl for that file
2. Delete the process tracker pkl
3. Re-run the notebook — it will rebuild the tracker from scratch

### Process tracker pattern

Every stage maintains a pickle DataFrame as a process tracker:
- One row per input file
- Status column (`extract_status`, `rejoin_status`, etc.) — value `"complete"` means skip
- Intermediate paths stored for chaining between stages
- Tracker is saved after every file so the loop is safely interruptible

### OpenAI Batch API pattern

Stages using the Batch API follow this async workflow:
1. **Notebook N.1** — build JSONL input file
2. **Notebook N.2** — upload file, submit job, save `job_id` — **re-run after API completes**
3. **Notebook N.3** — download output, extract results, save to pkl

The tracker for Batch API stages has columns for each async step:
`input_batch_path`, `input_batch_status`, `job_id`, `job_status`,
`output_batch_path`, `output_batch_status`, `result_path`, `result_status`

### Hardcoded old paths

When copying notebooks from a working project, search for and replace old
data folder names (e.g. `../data/stage1/` → `../data/stage_01/`). Run this
replacement across all notebooks at once:

```python
import json, os

replacements = [
    ('../data/stage1/', '../data/stage_01/'),
    ('../data/stage2/', '../data/stage_02/'),
    # add all your stage folder renames here
]

for nb_name in os.listdir('notebooks/'):
    if not nb_name.endswith('.ipynb'):
        continue
    with open(f'notebooks/{nb_name}', encoding='utf-8') as f:
        content = f.read()
    for old, new in replacements:
        content = content.replace(old, new)
    with open(f'notebooks/{nb_name}', 'w', encoding='utf-8') as f:
        f.write(content)
```

### Missing packages

Common packages not always pre-installed that should be in `requirements.txt`:
- `pyarrow` — for Parquet file support (pandas `read_parquet` / `to_parquet`)
- `rapidfuzz` — fuzzy string matching
- `matplotlib`, `seaborn` — visualisation

---

## Synthetic demo data

Create a synthetic demo input file that:
- Matches the exact schema of real data (same column names and types)
- Contains ~100 rows (enough to test all pipeline stages)
- Uses plausible but entirely fictional values
- Is documented in `data/input/README_data.md` with a clear disclaimer

Example disclaimer:
```markdown
> **This is a synthetic demo file.** All records are artificially generated
> and do not represent real job vacancies. It is provided to allow running
> the full pipeline without access to the original dataset.
```

---

## Mendeley Data checklist

Before publishing, verify:

- [ ] All notebooks run end-to-end on the demo data without errors
- [ ] All `.py` files have Google-style docstrings on every function
- [ ] Every notebook has markdown annotations before each code cell
- [ ] Every notebook ends with the copyright footer
- [ ] `README.md` has working links to all sections and files
- [ ] Each `data/stage_XX/` has a `README_data.md` with full column schemas
- [ ] `requirements.txt` has pinned versions for all packages
- [ ] `SETUP.md` specifies exact Python version
- [ ] `notebooks/.env` has placeholder values (no real API keys)
- [ ] Real data is not included — only demo/synthetic data
- [ ] `data/input/README_data.md` has synthetic data disclaimer
- [ ] Pre-completed stages (e.g. translations, region DB) are clearly marked ⚠️ SKIP
- [ ] Citation block in README.md has correct paper metadata
- [ ] Copyright footer present in README.md and all notebooks

---

## Session continuation prompt

When resuming a session after context limit, use:

```
Continue preparing the Mendeley Data reproducibility repository.

SOURCE (read-only): [path]
OUTPUT (write here): [path]

Rules from previous session:
- Copy → user runs → then add annotations (for .ipynb files)
- Google-style docstrings on all .py functions
- Markdown annotation before every code cell
- Copyright footer: --- / © [YEAR] [Authors]. All rights reserved.
- intermediate/ and processed/ only in data folders
- Track decisions in prompts.md, progress in progress.md

Current progress: [paste your progress.md checklist]

Next task: [what to do next]
```
