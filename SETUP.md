# Local Environment Setup

## Requirements

- **Python 3.13.12** (recommended — all dependencies are compatible; Python 3.14 is not recommended as `sentence-transformers` and `fast-langdetect` do not yet officially support it)
- `pip` (bundled with Python)
- An **OpenAI API key** (required for Stage 3 — LLM-based classification, and Stage 4 — region enrichment)

---

## 1. Clone or download the repository

```bash
git clone <repository-url>
cd mendely-paper-repository
```

Or download and unzip the archive from Mendeley Data, then navigate into the folder.

---

## 2. Create a virtual environment

**Windows:**
```bash
python -m venv venv
venv\Scripts\activate
```

**macOS / Linux:**
```bash
python3 -m venv venv
source venv/bin/activate
```

You should see `(venv)` in your terminal prompt once the environment is active.

---

## 3. Install dependencies

```bash
pip install -r requirements.txt
```

> **Note:** `torch` and `sentence-transformers` are large packages (~2 GB).
> Installation may take several minutes depending on your connection speed.

> **GPU support (optional):** The default `torch` version in `requirements.txt`
> targets CPU. For GPU acceleration, replace it with the appropriate CUDA build
> from [https://pytorch.org/get-started/locally/](https://pytorch.org/get-started/locally/).

---

## 4. Configure environment variables

The `.env` file lives in the `notebooks/` folder — this is where the notebooks
look for it at runtime (paths are relative to that folder).

Open `notebooks/.env` and replace `YOUR_OPENAI_API_KEY` with your actual key:

```
OPENAI_API_KEY = "sk-..."
```

All data paths are pre-configured to match this repository's folder structure
and do not need to be changed. See inline comments inside `notebooks/.env`
for an explanation of each variable.

> **Important:** Never commit your `.env` file with a real API key to version control.

---

## 5. Test the environment

Before running the pipeline, verify that all packages are installed correctly:

```bash
jupyter notebook
```

Open `notebooks/before_start_test_environment.ipynb` and run all cells top to bottom.

Every cell should print a ✅ line. If you see a ❌, re-run `pip install -r requirements.txt` and check the error message for the failing package.

> **Note on `fast-langdetect`:** The first run will automatically download a ~125 MB language detection model (`lid.176.bin`). This is expected — it only happens once.

> **Note on `OPENAI_API_KEY`:** If you have not yet filled in your API key in `.env`, the dotenv cell will show `OPENAI_API_KEY = YOUR_OPENAI_API_KEY`. This is fine for now — the key is only required for Stage 3 and Stage 4.5.

---

## 6. Run the pipeline

Once all cells in `before_start_test_environment.ipynb` show ✅, open the remaining notebooks in the `notebooks/` folder and run them in stage order (Stage 1 → Stage 2 → ... → Stage 5).

See `README.md` for the full pipeline description and stage-by-stage instructions.

---

## Dependency notes

| Package | Version | Purpose |
|---------|---------|---------|
| pandas | 2.3.3 | Data manipulation throughout the pipeline |
| numpy | 2.4.0 | Numerical operations |
| matplotlib | 3.10.1 | Visualisation (stats.py) |
| seaborn | 0.13.2 | Visualisation (stats.py) |
| python-dotenv | 1.2.1 | Loading API keys from .env |
| fast-langdetect | 1.0.0 | Language detection (Stage 1) |
| tqdm | 4.67.1 | Progress bars |
| sentence-transformers | 5.2.0 | Embedding-based skills extraction (Stage 2) |
| transformers | 4.57.3 | Transformer models (Stage 2) |
| torch | 2.9.1 | Deep learning backend for transformers |
| openai | 2.14.0 | OpenAI Batch API (Stages 3–4) |
| rapidfuzz | 3.13.0 | Fuzzy string matching for ESCO mapping (Stage 4) |
