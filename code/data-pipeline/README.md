# Python Data-Pipeline Modules

This folder contains reusable Python functions and classes imported by the notebooks in `notebooks/data-pipeline/`. The modules are support code, not standalone entry points.

| Module | Used for |
|---|---|
| `general.py` | Environment loading, configuration paths, file/process tracking, and shared utilities |
| `stage1.py` | Raw-file loading, text cleaning, language detection, and Stage 1 transformations |
| `stage2.py` | Multilingual ESCO skill retrieval and Stage 2 helpers |
| `stage3.py` | OpenAI Batch API schemas, prompts, submissions, status checks, and result extraction |
| `stage4.py` | ESCO label matching, skill mapping, and documented manual-correction patterns |

The notebooks call the shared bootstrap before importing these modules:

```python
from pipeline_bootstrap import configure_pipeline
configure_pipeline()
```

The bootstrap resolves this directory from the repository layout and loads `.env` consistently without notebook-specific path literals.
