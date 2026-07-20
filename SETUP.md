# Python Data-Pipeline Setup

## Requirements

- Python 3.13.12
- `pip`
- Jupyter Notebook or JupyterLab
- An OpenAI API key only when rerunning Stages 1.2, 3, or 4.5

## 1. Create and activate a virtual environment

From the repository root:

### Windows PowerShell

```powershell
python -m venv venv
venv\Scripts\activate
```

### macOS or Linux

```bash
python3 -m venv venv
source venv/bin/activate
```

## 2. Install pinned dependencies

```bash
pip install -r requirements.txt
```

PyTorch and sentence-transformers are large dependencies, so installation may take several minutes. The pinned environment uses the default CPU-compatible PyTorch distribution; GPU configuration is optional and platform-specific.

## 3. Create the local configuration

Copy the publishable template to the local `.env` file:

### Windows PowerShell

```powershell
Copy-Item notebooks\data-pipeline\.env.example notebooks\data-pipeline\.env
```

### macOS or Linux

```bash
cp notebooks/data-pipeline/.env.example notebooks/data-pipeline/.env
```

Edit `notebooks/data-pipeline/.env` and add `OPENAI_API_KEY` only if API-dependent stages will be rerun. The `.env` file is ignored by Git. Never place a live key in `.env.example`, a notebook, or committed documentation.

All configured paths are relative to `notebooks/data-pipeline/`. Do not change them unless the repository structure changes.

## 4. Start Jupyter from the notebook directory

```powershell
Set-Location notebooks\data-pipeline
jupyter notebook
```

Or on macOS/Linux:

```bash
cd notebooks/data-pipeline
jupyter notebook
```

This is the recommended launch location. Each processing notebook also calls `pipeline_bootstrap.py`, which locates the repository code and normalises the working directory before loading `.env`.

## 5. Test the environment

Open `before_start_test_environment.ipynb` and run all cells from top to bottom. Resolve any missing dependency before running a processing notebook.

The first use of `fast-langdetect` may download its language-detection model. Stage 2 downloads the sentence-transformer model on first use and reuses the standard Hugging Face cache.

## 6. Run the notebooks

There is no combined runner. Open and execute each notebook separately using the order in [README.md](README.md) or [the notebook guide](notebooks/data-pipeline/README.md).

Stages 1.2, 3, and 4.5 require an API key only when their OpenAI Batch API operations are rerun. Some API notebooks must be run once to submit jobs and again after remote processing completes.
