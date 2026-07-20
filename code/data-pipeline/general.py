import gc
import re
import pandas as pd
from dotenv import dotenv_values
from pathlib import Path
import os


# clean memory
def clean_memory():
    """Release all global variables and trigger garbage collection.

    Iterates over all names in the current scope and deletes any that do
    not start with an underscore, then calls gc.collect() to free memory.
    Useful between heavy processing steps to reduce RAM usage.
    """
    for name in dir():
        if not name.startswith('_'):
            del globals()[name]
    gc.collect()


def get_file_name_without_ext_from_path(file_path):
    """Extract the filename (without extension) from a full file path.

    Args:
        file_path (str): Full or relative path to a file,
            e.g. '/data/input/jobs_2024-01-01.json'.

    Returns:
        str: Filename without its extension, e.g. 'jobs_2024-01-01'.
    """
    return os.path.splitext(os.path.basename(file_path))[0]


def get_file_name_without_ext(file_path):
    """Strip the extension from a filename or path.

    Unlike get_file_name_without_ext_from_path, this does not strip
    the directory component — it only removes the extension suffix.

    Args:
        file_path (str): Filename or path, e.g. 'jobs_2024-01-01.json'.

    Returns:
        str: Path or filename without extension, e.g. 'jobs_2024-01-01'.
    """
    root, ext = os.path.splitext(file_path)
    return root


def extract_date_from_file_name(f_name):
    """Parse a date string in YYYY-MM-DD format from a filename.

    Args:
        f_name (str): Filename containing a date, e.g. 'jobs_2024-01-15.json'.

    Returns:
        str: Extracted date string in 'YYYY-MM-DD' format.

    Raises:
        ValueError: If no date matching YYYY-MM-DD is found in the filename.
    """
    m = re.search(r'(\d{4}-\d{2}-\d{2})', f_name)
    if m:
        date_str = m.group(1)
    else:
        raise ValueError("No date found in filename")
    return date_str


def convert_dates_to_yyyy_mm_dd(date):
    """Normalise a date value to a 'YYYY-MM-DD' string.

    Handles three input types:
    - NaN / None: returned as-is.
    - int or float: treated as a Unix timestamp in milliseconds.
    - str or datetime-like: parsed by pandas.

    Args:
        date: Date value to convert. May be NaN, int, float, str, or datetime.

    Returns:
        str | NaN: Date formatted as 'YYYY-MM-DD', or the original NaN value
            if the input is missing.
    """
    if pd.isna(date):
        return date
    if isinstance(date, (int, float)):
        # Numeric values are Unix timestamps in milliseconds
        return pd.to_datetime(date, unit='ms').strftime('%Y-%m-%d')
    else:
        return pd.to_datetime(date).strftime('%Y-%m-%d')


def check_folder_exists(folder_path):
    """Create a folder if it does not already exist.

    Args:
        folder_path (str): Path to the folder to create. Intermediate
            directories are created as needed (equivalent to mkdir -p).
    """
    if not os.path.exists(folder_path):
        os.makedirs(folder_path)


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Load all variables from the .env file located in the working directory.
# The notebooks are expected to be run from the notebooks/data-pipeline/ folder, so .env
# is resolved relative to that location.
dotenv_path = Path(".env")
config = dotenv_values(dotenv_path=dotenv_path)


class Config:
    """Central configuration object populated from the .env file.

    All pipeline path variables and the OpenAI API key are read once at
    import time and exposed as class-level string attributes. Every stage
    module and notebook imports this class to resolve file paths without
    hard-coding them.

    Attributes:
        INPUT_PATH (str): Root folder containing raw input JSON files.
        STAGE1_PROCESS_PATH (str): Pickle tracking Stage 1 processed records.
        STAGE1_OUTPUT_PATH (str): Output folder for Stage 1 results.
        STAGE1_ID_REGION_NCLICK_PATH (str): Folder for id/region/click data.
        STAGE1_UNIQ_ID_DB (str): Pickle with the unique job ID database.
        STAGE2_PROCESS_PATH (str): Pickle tracking Stage 2 processed records.
        STAGE2_OUTPUT_PATH (str): Output folder for Stage 2 results.
        SKILLS_PATH (str): Folder for extracted skills data.
        STAGE3_PROCESS_PATH (str): Pickle tracking Stage 3 processed records.
        STAGE3_INPUT_PATH (str): Folder for Batch API input JSONL files.
        STAGE3_OUTPUT_PATH (str): Folder for Batch API output files.
        STAGE3_RESULT_PATH (str): Folder for final classification results.
        STAGE3_CLASSIFY_SCHEME (str): Path to the classification JSON schema.
        STAGE3_CLASSIFY_PROMPT (str): Path to the classification prompt file.
        OPENAI_API_KEY (str): OpenAI API key for Batch API calls.
        STAGE4_ESCO_DATA_PATH (str): Folder with ESCO taxonomy reference data.
        STAGE4_OUTPUT_PATH (str): Output folder for Stage 4 results.
        STAGE4_5_SELECT_REGION_SCHEME (str): Path to region selection schema.
        STAGE4_5_SELECT_REGION_PROMPT (str): Path to region enrichment prompt.
        STAGE4_5_INPUT_BATCH_PATH (str): Folder for region Batch API inputs.
        STAGE4_5_OUTPUT_BATCH_PATH (str): Folder for region Batch API outputs.
        STAGE4_5_REGION_DB_PATH (str): Path to the final merged region DB.
        STAGE4_5_REGION_PREV_DB_PATH (str): Path to the previous region DB.
        STAGE4_5_REGION_NEW_DB_PATH (str): Path to the newly built region DB.
        STAGE5_PROCESS_UNIQUE_PATH (str): Pickle tracking unique Stage 5 records.
        STAGE5_PROCESS_FULL_PATH (str): Pickle tracking full Stage 5 records.
        STAGE5_DAILY_UNIQUE_PARQUET_PATH (str): Daily unique records (Parquet).
        STAGE5_DAILY_UNIQUE_JSON_PATH (str): Daily unique records (JSON).
        STAGE5_DAILY_UNIQUE_JSON_UA_PATH (str): Daily unique records, UA only (JSON).
        STAGE5_MONTHLY_UNIQUE_PARQUET_PATH (str): Monthly unique records (Parquet).
        STAGE5_MONTHLY_UNIQUE_JSON_PATH (str): Monthly unique records (JSON).
        STAGE5_MONTHLY_UNIQUE_JSON_UA_PATH (str): Monthly unique records, UA only (JSON).
        STAGE5_DAILY_FULL_PARQUET_PATH (str): Daily full records (Parquet).
        STAGE5_DAILY_FULL_JSON_PATH (str): Daily full records (JSON).
        STAGE5_DAILY_FULL_JSON_UA_PATH (str): Daily full records, UA only (JSON).
        STAGE5_MONTHLY_FULL_PARQUET_PATH (str): Monthly full records (Parquet).
        STAGE5_MONTHLY_FULL_JSON_UA_PATH (str): Monthly full records, UA only (JSON).
    """

    INPUT_PATH: str = config["INPUT_PATH"]

    STAGE1_PROCESS_PATH: str = config["STAGE1_PROCESS_PATH"]
    STAGE1_OUTPUT_PATH: str = config["STAGE1_OUTPUT_PATH"]
    STAGE1_ID_REGION_NCLICK_PATH: str = config["STAGE1_ID_REGION_NCLICK_PATH"]
    STAGE1_UNIQ_ID_DB: str = config["STAGE1_UNIQ_ID_DB"]

    STAGE1_2_SOURCE_SKILLS_PATH: str = config["STAGE1_2_SOURCE_SKILLS_PATH"]
    STAGE1_2_BATCH_INPUT_PATH: str = config["STAGE1_2_BATCH_INPUT_PATH"]
    STAGE1_2_BATCH_OUTPUT_PATH: str = config["STAGE1_2_BATCH_OUTPUT_PATH"]
    STAGE1_2_TRANSLATE_SCHEME: str = config["STAGE1_2_TRANSLATE_SCHEME"]
    STAGE1_2_TRANSLATED_SKILLS_PATH: str = config["STAGE1_2_TRANSLATED_SKILLS_PATH"]

    STAGE2_PROCESS_PATH: str = config["STAGE2_PROCESS_PATH"]
    STAGE2_OUTPUT_PATH: str = config["STAGE2_OUTPUT_PATH"]
    SKILLS_PATH: str = config["SKILLS_PATH"]

    STAGE3_PROCESS_PATH: str = config["STAGE3_PROCESS_PATH"]
    STAGE3_INPUT_PATH: str = config["STAGE3_INPUT_PATH"]
    STAGE3_OUTPUT_PATH: str = config["STAGE3_OUTPUT_PATH"]
    STAGE3_RESULT_PATH: str = config["STAGE3_RESULT_PATH"]
    STAGE3_CLASSIFY_SCHEME: str = config["STAGE3_CLASSIFY_SCHEME"]
    STAGE3_CLASSIFY_PROMPT: str = config["STAGE3_CLASSIFY_PROMPT"]
    OPENAI_API_KEY: str = config["OPENAI_API_KEY"]

    STAGE4_ESCO_DATA_PATH: str = config["STAGE4_ESCO_DATA_PATH"]
    STAGE4_OUTPUT_PATH: str = config["STAGE4_OUTPUT_PATH"]

    STAGE4_5_SELECT_REGION_SCHEME: str = config["STAGE4_5_SELECT_REGION_SCHEME"]
    STAGE4_5_SELECT_REGION_PROMPT: str = config["STAGE4_5_SELECT_REGION_PROMPT"]
    STAGE4_5_INPUT_BATCH_PATH: str = config["STAGE4_5_INPUT_BATCH_PATH"]
    STAGE4_5_OUTPUT_BATCH_PATH: str = config["STAGE4_5_OUTPUT_BATCH_PATH"]
    STAGE4_5_REGION_DB_PATH: str = config["STAGE4_5_REGION_DB_PATH"]
    STAGE4_5_REGION_PREV_DB_PATH: str = config["STAGE4_5_REGION_PREV_DB_PATH"]
    STAGE4_5_REGION_NEW_DB_PATH: str = config["STAGE4_5_REGION_NEW_DB_PATH"]
    STAGE4_5_COMBINED_OUTPUT_PATH: str = config["STAGE4_5_COMBINED_OUTPUT_PATH"]

    STAGE5_PROCESS_UNIQUE_PATH: str = config["STAGE5_PROCESS_UNIQUE_PATH"]
    STAGE5_PROCESS_FULL_PATH: str = config["STAGE5_PROCESS_FULL_PATH"]
    STAGE5_DAILY_UNIQUE_PARQUET_PATH: str = config["STAGE5_DAILY_UNIQUE_PARQUET_PATH"]
    STAGE5_DAILY_UNIQUE_JSON_PATH: str = config["STAGE5_DAILY_UNIQUE_JSON_PATH"]
    STAGE5_DAILY_UNIQUE_JSON_UA_PATH: str = config["STAGE5_DAILY_UNIQUE_JSON_UA_PATH"]

    STAGE5_MONTHLY_UNIQUE_PARQUET_PATH: str = config["STAGE5_MONTHLY_UNIQUE_PARQUET_PATH"]
    STAGE5_MONTHLY_UNIQUE_JSON_PATH: str = config["STAGE5_MONTHLY_UNIQUE_JSON_PATH"]
    STAGE5_MONTHLY_UNIQUE_JSON_UA_PATH: str = config["STAGE5_MONTHLY_UNIQUE_JSON_UA_PATH"]

    STAGE5_DAILY_FULL_PARQUET_PATH: str = config["STAGE5_DAILY_FULL_PARQUET_PATH"]
    STAGE5_DAILY_FULL_JSON_PATH: str = config["STAGE5_DAILY_FULL_JSON_PATH"]
    STAGE5_DAILY_FULL_JSON_UA_PATH: str = config["STAGE5_DAILY_FULL_JSON_UA_PATH"]

    STAGE5_MONTHLY_FULL_PARQUET_PATH: str = config["STAGE5_MONTHLY_FULL_PARQUET_PATH"]
    STAGE5_MONTHLY_FULL_JSON_UA_PATH: str = config["STAGE5_MONTHLY_FULL_JSON_UA_PATH"]

    @classmethod
    def ensure_directories(cls):
        """Create every configured input/output directory needed by the notebooks."""
        directory_paths = (
            cls.INPUT_PATH,
            cls.STAGE1_OUTPUT_PATH,
            cls.STAGE1_ID_REGION_NCLICK_PATH,
            cls.STAGE2_OUTPUT_PATH,
            cls.SKILLS_PATH,
            cls.STAGE3_INPUT_PATH,
            cls.STAGE3_OUTPUT_PATH,
            cls.STAGE3_RESULT_PATH,
            cls.STAGE4_ESCO_DATA_PATH,
            cls.STAGE4_OUTPUT_PATH,
            cls.STAGE4_5_INPUT_BATCH_PATH,
            cls.STAGE4_5_OUTPUT_BATCH_PATH,
            cls.STAGE5_DAILY_UNIQUE_PARQUET_PATH,
            cls.STAGE5_DAILY_UNIQUE_JSON_PATH,
            cls.STAGE5_DAILY_UNIQUE_JSON_UA_PATH,
            cls.STAGE5_MONTHLY_UNIQUE_PARQUET_PATH,
            cls.STAGE5_MONTHLY_UNIQUE_JSON_PATH,
            cls.STAGE5_MONTHLY_UNIQUE_JSON_UA_PATH,
            cls.STAGE5_DAILY_FULL_PARQUET_PATH,
            cls.STAGE5_DAILY_FULL_JSON_PATH,
            cls.STAGE5_DAILY_FULL_JSON_UA_PATH,
            cls.STAGE5_MONTHLY_FULL_PARQUET_PATH,
            cls.STAGE5_MONTHLY_FULL_JSON_UA_PATH,
        )
        file_paths = (
            cls.STAGE1_PROCESS_PATH,
            cls.STAGE1_UNIQ_ID_DB,
            cls.STAGE1_2_SOURCE_SKILLS_PATH,
            cls.STAGE1_2_BATCH_INPUT_PATH,
            cls.STAGE1_2_BATCH_OUTPUT_PATH,
            cls.STAGE1_2_TRANSLATE_SCHEME,
            cls.STAGE1_2_TRANSLATED_SKILLS_PATH,
            cls.STAGE2_PROCESS_PATH,
            cls.STAGE3_PROCESS_PATH,
            cls.STAGE3_CLASSIFY_SCHEME,
            cls.STAGE3_CLASSIFY_PROMPT,
            cls.STAGE4_5_SELECT_REGION_SCHEME,
            cls.STAGE4_5_SELECT_REGION_PROMPT,
            cls.STAGE4_5_REGION_PREV_DB_PATH,
            cls.STAGE4_5_REGION_NEW_DB_PATH,
            cls.STAGE4_5_REGION_DB_PATH,
            cls.STAGE4_5_COMBINED_OUTPUT_PATH,
            cls.STAGE5_PROCESS_UNIQUE_PATH,
            cls.STAGE5_PROCESS_FULL_PATH,
        )
        for path in directory_paths:
            Path(path).mkdir(parents=True, exist_ok=True)
        for path in (
            Path(cls.STAGE3_INPUT_PATH) / "missing",
            Path(cls.STAGE3_OUTPUT_PATH) / "missing",
            Path(cls.STAGE3_RESULT_PATH) / "missing",
        ):
            path.mkdir(parents=True, exist_ok=True)
        for path in file_paths:
            Path(path).parent.mkdir(parents=True, exist_ok=True)


Config.ensure_directories()
