## Initial project prompt

> You are helping me prepare a research repository for Mendeley Data publication.
> ## Project
> ML data preprocessing pipeline research. The goal is to document and publish
> the pipeline code so others can reproduce the methodology with synthetic data.
> ## Working directories
> - SOURCE (read-only): the existing project folder — path will be provided by me
>   at the start. Never modify, move, rename or delete anything in this folder.
> - OUTPUT: a new folder mendeley_repo/ created by you after structure approval.
>   All new and modified files go here. The source folder stays untouched.
> ## Important: SOURCE and OUTPUT structures will differ
> Do not assume any mapping between SOURCE and OUTPUT folder structures.
> For every file and every data file we will decide together during each stage:
> - Where it goes in OUTPUT
> - Whether it should be copied as-is, modified, or replaced with synthetic data
> Never move or copy anything without explicit per-file confirmation from me.
> ## My role in this process
> I am the decision-maker for every file. I will:
> - Review each file in PyCharm or another editor before confirming actions
> - Tell you explicitly what to do with each file: copy / modify / replace / skip
> - Confirm the OUTPUT destination for each file
> You must wait for my explicit instruction before acting on any file.
> Never proceed based on assumptions or context alone.
> ## Your task (execute stage by stage, one file at a time)
> Work through the project files sequentially. For each stage:
> 1. Announce: "Stage X: [filename]" and describe what this file does in the pipeline
> 2. Propose where this file should go in OUTPUT
> 3. Wait for my explicit instruction (I may review the file first in PyCharm)
> 4. After I confirm — execute and wait for my "next" command
> ## Stage 0 (special stage — no data)
> Stage 0 covers Python environment setup and global configuration.
> It has its own notebook.
> ### Python environment setup (do this first, before any files)
> - Check if requirements.txt or environment.yml exists in SOURCE
> - If missing — scan all .py and .ipynb files in SOURCE and generate
>   requirements.txt in OUTPUT with pinned versions
> - If present — copy to OUTPUT, review and suggest cleanups (unused packages,
>   unpinned versions) — ask me before applying any changes
> - Verify that the environment can be created locally:
>   - Suggest the setup commands for the user:
>     python -m venv venv
>     source venv/bin/activate  (or venv\Scripts\activate on Windows)
>     pip install -r requirements.txt
>   - Flag any potential conflicts or missing system dependencies
> - Add a SETUP.md in OUTPUT root with step-by-step local environment
>   setup instructions (Python version, venv creation, package installation,
>   .env configuration)
> ### Stage 0 files
> - .ipynb: copy to OUTPUT location confirmed by me, then add markdown cells
>   describing each setup step (package installation, environment initialization)
> - .env / config files:
>   - Copy to OUTPUT location confirmed by me
>   - Replace any real values (API keys, paths, credentials) with clearly marked
>     placeholders, e.g. YOUR_API_KEY, /path/to/your/data
>   - Add inline comments explaining what each variable controls
>   - Suggest improvements to structure or naming if needed — ask me before applying
> - Stage 0 has NO data subfolders
> ## What to do with each file type (Stage 1+)
> ### .ipynb files
> - A stage may contain MULTIPLE notebooks
> - Notebook filenames already encode their order and stage — do NOT rename them
> - Infer the sequence from existing filename prefixes
> - For each notebook, propose OUTPUT destination and wait for my confirmation
> - After I confirm, copy and apply changes in OUTPUT:
>   - Add a markdown cell at the top explaining:
>     - Its role within the stage
>     - Its position in the sequence relative to other notebooks in this stage
>     - Whether it must be run manually after an external process completes
>   - Add markdown cells before each code cell explaining what it does and why
> - Do NOT change any code cells
> - Do NOT rename any files
> ### .py files
> - For each file, propose OUTPUT destination and wait for my confirmation
> - After I confirm, copy and apply changes in OUTPUT:
>   - Add Google-style docstrings to all functions and classes
>   - Add inline # comments explaining non-obvious logic
> - Do NOT change any logic or variable names
> - Do NOT rename any files
> ### Data files (csv, xlsx, json, parquet, etc.)
> - For each data file, present the options and wait for my decision
> - Never act until I explicitly choose an option
> - For option (b) — synthetic data: read original from SOURCE to analyze structure,
>   generate synthetic data preserving column names, data types, column count, row count
> - For option (d) — copy real file and add README_data.md explaining OpenAI origin
> ## Data folder structure in OUTPUT
> Each pipeline stage (Stage 1+) gets its own data folder with four subfolders:
> intermediate/, processed/ only (raw/ and log/ are not used — do not create them for stage_01 or stage_02)
> ## progress.md and prompts.md
> Maintained in OUTPUT root. Updated after every completed action.
> ## README.md
> Built incrementally — add a section after each stage.
> ## Rules
> - SOURCE is strictly read-only
> - All writes go to OUTPUT only
> - One file at a time
> - Always ask before changing anything
> - English only
> - Do NOT rename any files or folders

---

## Session log

### 2026-03-22

**[Setup]**
> SOURCE: G:\worldbank-reproducible-package
> OUTPUT: G:\mendely-paper-repository

**[Structure]**
> manuscript/ files — include in OUTPUT (yes)
> data/input/ — flat structure (Variant A, no subfolders)
> OUTPUT folder structure confirmed and created

**[Global — use in all files going forward]**
> Test notebook renamed from 00_test_environment.ipynb to before_start_test_environment.ipynb
> stage_2_1_skills_extration_v2.ipynb renamed to stage_2_1_skills_extration.ipynb
> Paper title: Labor Demand for Digital Skills during Wartime: Evidence from Russia's Invasion of Ukraine
> Authors: Yurii Kleban, Britta Rude
> Year: 2026
> Journal/DOI: still pending — leave as [Journal] and [DOI] placeholders

**[Stage 1]**
> general.py — copy to code/, add docstrings
> stage1.py — copy to code/, add docstrings
> stage2_v2.py — copy to code/ as stage2.py, add docstrings
> data/input/ua-2024-01-01.json — generate synthetic, 100 rows, use as demo file for testing Stage 1 notebooks
> All .ipynb files (all stages): copy to notebooks/ first — user will run and fix errors, then add markdown description cells to each code cell after confirmation. Apply this workflow to every notebook in the pipeline.
> Every .ipynb file must end with a markdown cell: a horizontal rule (---) followed by "© 2026 Yurii Kleban, Britta Rude. All rights reserved."
> Stage 1 notebooks: keep only stage_1_read_initial_data_fast.ipynb — skip all others (except stage_01_5_interim_translate_skills.ipynb which was added back later)
> stage_01_5_interim_translate_skills.ipynb — already completed, copy all 5 data files to stage_01_2/, add README_data.md noting it does not need to be rerun. Translation used OpenAI Batch API gpt-4.1-mini to produce skills_ru.csv for Stage 2.

**[Stage 0]**
> .env — copy to OUTPUT root, replace real API key with placeholder, update paths to match new folder names, add inline comments
> Structure Ganerator.ipynb — skip, folder generation utility, not part of the pipeline
