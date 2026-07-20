"""Locate the repository code and configure notebook execution consistently."""

from pathlib import Path
import os
import sys


NOTEBOOK_DIR = Path(__file__).resolve().parent
REPOSITORY_ROOT = NOTEBOOK_DIR.parents[1]
PIPELINE_CODE_DIR = REPOSITORY_ROOT / "code" / "data-pipeline"


def configure_pipeline() -> None:
    """Use the notebook directory as CWD and expose shared pipeline modules."""
    general_module = PIPELINE_CODE_DIR / "general.py"
    if not general_module.is_file():
        raise FileNotFoundError(
            f"Cannot locate the pipeline code directory: {PIPELINE_CODE_DIR}"
        )

    os.chdir(NOTEBOOK_DIR)
    code_path = str(PIPELINE_CODE_DIR)
    if code_path not in sys.path:
        sys.path.insert(0, code_path)
