import os
import pandas as pd
import re
import general as g
from general import extract_date_from_file_name  # re-exported so notebooks can call st1.extract_date_from_file_name


# reading initial data files

def get_file_names_without_ext(files):
    """Strip extensions from a list of filenames.

    Args:
        files (list[str]): List of filenames, e.g. ['2024-01-01.json', '2024-01-02.json'].

    Returns:
        list[str]: Filenames without their extensions, e.g. ['2024-01-01', '2024-01-02'].
    """
    file_names = []
    for file in files:
        root, ext = os.path.splitext(file)
        file_names.append(root)
    return file_names


def create_stage1_process_df(input_path, files):
    """Build an initial processing tracker DataFrame for Stage 1.

    Creates one row per input file with empty status columns that are
    filled in as each file is processed.

    Args:
        input_path (str): Folder containing the input JSON files.
        files (list[str]): List of JSON filenames to process.

    Returns:
        pd.DataFrame: Sorted DataFrame with columns:
            input_file, input_path, clean_path, clean_status,
            id_region_path, id_region_status.

    Raises:
        ValueError: If the files list is empty.
    """
    if len(files) > 0:
        file_names = get_file_names_without_ext(files)
        df = pd.DataFrame({'input_file': file_names,
                           'input_path': [os.path.join(input_path, filename) for filename in files],
                           'clean_path': None,
                           'clean_status': None,
                           'id_region_path': None,
                           'id_region_status': None})
        df = df.sort_values("input_file").reset_index(drop=True)
        return df
    else:
        raise ValueError("No files for processing...")


def get_next_process_file(process_df):
    """Return the first unprocessed file from the process tracker.

    Looks for rows where clean_status is NaN (not yet processed).

    Args:
        process_df (pd.DataFrame): Process tracker DataFrame.

    Returns:
        tuple[str | None, str | None]: (filename_without_ext, full_path)
            of the next pending file, or (None, None) if all files are done.
    """
    pending = process_df[process_df['clean_status'].isna()]
    if pending.empty:
        return None, None
    f_name = process_df[process_df['clean_status'].isna()].iloc[0]['input_file']
    f_path = process_df[process_df['clean_status'].isna()].iloc[0]['input_path']
    return f_name, f_path


def get_not_processed_files(process_df):
    """Return a list of all unprocessed filenames from the process tracker.

    Args:
        process_df (pd.DataFrame): Process tracker DataFrame.

    Returns:
        list[str] | tuple[None, None]: List of filenames (without extension)
            that have not yet been processed, or (None, None) if all are done.
    """
    pending = process_df[process_df['clean_status'].isna()]['input_file']
    if pending.empty:
        return None, None
    files = []
    for file in pending:
        files.append(file)
    return files


## read data, update processing files list, save data
def update_stage1_process_data(input_path, process_path):
    """Load or create the Stage 1 process tracker, adding any new input files.

    If the tracker pickle already exists, only files not yet registered are
    appended. If it does not exist, a fresh tracker is created from all JSON
    files found in input_path. The updated tracker is saved back to disk.

    Args:
        input_path (str): Folder containing raw input JSON files.
        process_path (str): Path to the process tracker pickle file.

    Returns:
        pd.DataFrame: Up-to-date process tracker DataFrame.
    """
    files = [f for f in os.listdir(input_path) if f.endswith('.json')]

    if os.path.exists(process_path):
        process_df = pd.read_pickle(process_path)
        # Identify files present on disk but not yet in the tracker
        new_values = [value for value in get_file_names_without_ext(files) if
                      value not in process_df['input_file'].values]

        if len(new_values) > 0:
            file_names = [item + ".json" for item in new_values]
            try:
                add_clean_df = create_stage1_process_df(input_path, file_names)
                process_df = pd.concat([process_df, add_clean_df], ignore_index=True)
                process_df = process_df.sort_values(by='input_file')
            except Exception as e:
                print(f"Error: {e}")

    else:
        # First run — create a fresh tracker for all available files
        process_df = create_stage1_process_df(input_path, files)

    process_df.to_pickle(process_path)
    return process_df


def read_init_file(f_path):
    """Read a raw input JSON file and normalise date columns.

    Args:
        f_path (str): Full path to the JSON file.

    Returns:
        pd.DataFrame: DataFrame with date_created and date_expired columns
            converted to 'YYYY-MM-DD' string format.
    """
    df = pd.read_json(f_path)
    df["date_created"] = df["date_created"].apply(g.convert_dates_to_yyyy_mm_dd)
    df["date_expired"] = df["date_expired"].apply(g.convert_dates_to_yyyy_mm_dd)
    return df


def create_id_region_df(id_region_path, f_name, df):
    """Save a per-file snapshot of job id, region, and click count.

    Extracts the date from the filename and stores id/region/clicks as a
    pickle file in the id_region folder. Used later to reconstruct regional
    engagement metrics without keeping the full dataset in memory.

    Args:
        id_region_path (str): Folder where the snapshot pickle will be saved.
        f_name (str): Filename (without extension) used to derive the date
            and as the output filename.
        df (pd.DataFrame): DataFrame containing at least id, region,
            and number_of_clicks columns.

    Returns:
        str | None: Full path to the saved pickle file, or None if the
            id_region_path folder does not exist.
    """
    if os.path.exists(id_region_path):
        id_db_region_new = df[["id", "region", "number_of_clicks"]].reset_index(drop=True)
        # Attach the date extracted from the filename for time-series tracking
        id_db_region_new["date"] = g.extract_date_from_file_name(f_name)
        f_path = os.path.join(id_region_path, f_name + ".pkl")
        id_db_region_new.to_pickle(f_path)
        return f_path
    return None


def read_id_db(id_db_path):
    """Load the unique job ID database, creating an empty one if needed.

    The ID database is used throughout Stage 1 to avoid processing the same
    job vacancy twice across different daily snapshot files.

    Args:
        id_db_path (str): Path to the unique ID database pickle file.

    Returns:
        pd.DataFrame: DataFrame with a single 'id' column containing all
            previously seen job IDs.
    """
    if os.path.exists(id_db_path):
        id_db = pd.read_pickle(id_db_path)
    else:
        # First run — initialise an empty ID database and persist it
        id_db = pd.DataFrame(columns=["id"])
        id_db.to_pickle(id_db_path)
    return id_db


# -------------- CLEAN TEXT -----------------#

def clean_text(text, remove_digits=True, remove_urls=True) -> str:
    """Normalise and clean raw job vacancy text.

    Applies a sequence of regex substitutions to remove noise:
    lowercases, optionally removes URLs and digits, strips social media
    handles and emoji, and collapses whitespace.

    Retained characters: Latin, Cyrillic (Ukrainian/Russian), Czech, Polish,
    apostrophes, hyphens, and whitespace.

    Args:
        text (str): Raw text to clean.
        remove_digits (bool): If True, all digit sequences are removed.
            Defaults to True.
        remove_urls (bool): If True, http/https/www URLs are removed.
            Defaults to True.

    Returns:
        str: Cleaned, lowercased text with collapsed whitespace.
    """
    text = text.lower()
    if remove_urls:
        text = re.sub(r"http\S+|www\S+|https\S+", "", text, flags=re.MULTILINE)
    # Remove @mentions and #hashtags
    text = re.sub(r"[@#]\w+", "", text)
    # Remove characters outside the supplementary multilingual plane (emoji, etc.)
    text = re.sub(r"[\U00010000-\U0010ffff]", "", text)
    # Keep only Latin, Cyrillic (UA/RU), Czech, Polish characters plus apostrophe, plus, hyphen
    text = re.sub(r"[^0-9a-zа-яёїієґąćęłńóśźżčďěňřšťůž''+\s-]", "", text, flags=re.IGNORECASE)
    if remove_digits:
        text = re.sub(r"\d+", "", text)
    # Collapse multiple spaces to one
    text = re.sub(r"\s+", " ", text)
    text = text.strip()
    return text


def remove_dates_and_salaries(text: str) -> str:
    """Remove date and salary mentions from job vacancy text.

    Strips common date formats (DD/MM/YYYY, YYYY-MM-DD, textual months)
    and salary figures with currency symbols across multiple languages
    (English, Ukrainian, Russian, Czech, Polish).

    Args:
        text (str): Raw job vacancy text.

    Returns:
        str: Text with date and salary patterns removed and whitespace normalised.
    """
    # Remove common date patterns (day-month-year, month-year, etc.)
    date_patterns = [
        r'\b\d{1,2}[./-]\d{1,2}[./-]\d{2,4}\b',           # 12/05/2023 or 12.05.2023
        r'\b\d{4}[./-]\d{1,2}[./-]\d{1,2}\b',              # 2023-05-12
        r'\b\d{1,2} [a-zA-Zа-яА-ЯёЁіІїЇґҐ]+ \d{4}\b',     # 12 May 2023 or 12 травня 2023
        r'\b[a-zA-Zа-яА-ЯёЁіІїЇґҐ]+ \d{4}\b',              # May 2023 or травень 2023
        r'\b\d{4}\b',                                        # Standalone year
    ]

    for pattern in date_patterns:
        text = re.sub(pattern, '', text)

    # Remove salary ranges and mentions (across multiple languages and formats)
    salary_patterns = [
        r'\b\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)? ?(?:USD|EUR|CZK|PLN|UAH|Kč|zł|₴|руб\.?|₽|грн)\b',
        r'\b(?:USD|EUR|CZK|PLN|UAH|Kč|zł|₴|руб\.?|₽|грн) ?\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?\b',
        r'\b\d+[ -]?(?:to|до|do|до|до|по|na|від|od) ?\d+ ?(?:USD|EUR|CZK|PLN|UAH|₴|₽|Kč|zł|грн|руб\.?)\b',
        r'\b(?:зарплата|salary|оплата|ставка|wypłata|плата|з/п)\s*[:\-]?\s*\d+(?:[.,]\d+)? ?(?:USD|EUR|CZK|PLN|UAH|₴|₽|грн|zł|Kč|руб\.?)?\b',
    ]

    for pattern in salary_patterns:
        text = re.sub(pattern, '', text, flags=re.IGNORECASE)

    # Clean up extra spaces left by removals
    text = re.sub(r'\s{2,}', ' ', text)
    text = re.sub(r'\s+([.,;:!?])', r'\1', text)

    return text.strip()


# -------------- LANGUAGE DETECTION ---------------- #
# 100+ times faster than lang_detect
def detect_lang(df, column_to_detect, batch=3000, max_len=100):
    """Detect the language of text in a DataFrame column using fast-langdetect.

    Processes texts in batches for efficiency. Only the first max_len
    characters of each text are used for detection to speed up inference.

    Args:
        df (pd.DataFrame): DataFrame containing the text column.
        column_to_detect (str): Name of the column with text to analyse.
        batch (int): Number of rows to process per batch. Defaults to 3000.
        max_len (int): Maximum number of characters per text used for
            detection. Defaults to 100.

    Returns:
        list[str] | None: List of ISO 639-1 language codes (one per row),
            or None if detection fails.
    """
    try:
        # Lazy import — fast_langdetect requires fasttext (C extension).
        # Importing at the top level would break all other stages on systems
        # where fasttext_pybind is not installed (e.g. Python 3.13 on Windows).
        from fast_langdetect import detect as _ft_detect
        langs = []
        for start in range(0, len(df), batch):
            chunk = df[column_to_detect].iloc[start:start + batch]
            for t in chunk:
                result = _ft_detect(str(t)[:max_len])
                # fast_langdetect >= 1.0.0 returns a list of dicts; older versions return a dict
                if isinstance(result, list):
                    langs.append(result[0]["lang"])
                else:
                    langs.append(result["lang"])
        return langs
    except:
        return None


ALLOWED_LANGS = {"en": "English", "uk": "Ukrainian", "cs": "Czech", "pl": "Polish", "ru": "Russian"}


def detect_langs_in_column(df, column_to_detect, column_to_save):
    """Detect language for one text column and store results in a new column.

    Args:
        df (pd.DataFrame): DataFrame containing the source text column.
        column_to_detect (str): Column name with text to analyse.
        column_to_save (str): Column name where detected language codes
            will be stored.

    Returns:
        pd.DataFrame: DataFrame with the new language column added.
    """
    df[column_to_save] = detect_lang(df, column_to_detect)
    return df


def detect_langs(df):
    """Detect languages for both title and description columns and reconcile conflicts.

    Runs language detection on clean_title and clean_desc. Where the title
    language differs from the description language (and neither is English),
    the description language is treated as more reliable and used for both.

    Args:
        df (pd.DataFrame): DataFrame with clean_title and clean_desc columns.

    Returns:
        pd.DataFrame: DataFrame with title_lang and desc_lang columns added
            and conflicts resolved.
    """
    df = detect_langs_in_column(df, "clean_title", "title_lang")
    df = detect_langs_in_column(df, "clean_desc", "desc_lang")
    for _, r in df.iterrows():
        # If title and description disagree and neither is English, trust description
        if r["title_lang"] != "en" and r["desc_lang"] != "en" and r["title_lang"] != r["desc_lang"]:
            df.loc[_, "title_lang"] = r["desc_lang"]
        # If description is English but title language is not in allowed set, use description language
        if r["title_lang"] != "en" and r["desc_lang"] == "en" and r["title_lang"] not in ALLOWED_LANGS.keys():
            df.loc[_, "title_lang"] = r["desc_lang"]
    return df


def clean_data_duplicates(dtx):
    """Remove duplicate job records by grouping on key fields.

    Groups records by title, description, salary, and region to collapse
    duplicates. The first id and dates are kept; click counts are averaged
    across duplicates.

    Args:
        dtx (pd.DataFrame): Raw job vacancy DataFrame.

    Returns:
        pd.DataFrame: Deduplicated DataFrame with the same column order
            as the input.
    """
    aggregated_by_few_cols = dtx.groupby(['title', 'description', 'min_salary', 'max_salary', 'region'],
                                         dropna=False).agg(
        {
            'id': 'first',
            'date_created': 'first',
            'date_expired': 'first',
            'salary_rate': 'first',
            'currency': 'first',
            'number_of_clicks': 'mean'  # Average clicks across duplicate listings
        }).reset_index()

    # Restore original column order
    aggregated_by_few_cols = aggregated_by_few_cols[dtx.columns]

    return aggregated_by_few_cols


def upgrade_stage1_process_data(process_df, f_name, clean_path, id_region_path, process_clean_file_path, empty=False):
    """Update the process tracker after a file has been processed.

    Marks the file as complete (or empty if no new records were found)
    and saves the updated tracker to disk.

    Args:
        process_df (pd.DataFrame): Process tracker DataFrame to update.
        f_name (str): Filename (without extension) of the processed file.
        clean_path (str): Path where the cleaned output pickle was saved.
        id_region_path (str): Path to the id/region/clicks snapshot pickle.
        process_clean_file_path (str): Path to save the updated tracker.
        empty (bool): If True, marks the file as 'empty' (no new unique IDs
            found). Defaults to False.
    """
    process_df.loc[process_df['input_file'] == f_name, 'id_region_path'] = id_region_path
    process_df.loc[process_df['input_file'] == f_name, 'id_region_status'] = 'complete'

    if empty:
        # File contained no new unique job IDs — mark as empty rather than complete
        process_df.loc[process_df['input_file'] == f_name, 'clean_path'] = "-"
        process_df.loc[process_df['input_file'] == f_name, 'clean_status'] = 'empty'
    else:
        process_df.loc[process_df['input_file'] == f_name, 'clean_path'] = clean_path
        process_df.loc[process_df['input_file'] == f_name, 'clean_status'] = 'complete'

        #process_df = process_df.drop_duplicates(subset=('input_file', 'clean_path'), keep='first')
    process_df.to_pickle(process_clean_file_path)


def preprocess_file(process_df, file_name, cfg):
    """Run the full Stage 1 preprocessing pipeline for a single input file.

    Steps performed:
    1. Read the raw JSON file and normalise dates.
    2. Deduplicate records by key fields.
    3. Save id/region/clicks snapshot.
    4. Filter to only new job IDs not seen in previous files.
    5. Clean text (remove dates, salaries, noise).
    6. Detect and filter by language.
    7. Update the unique ID database.
    8. Save the cleaned output and update the process tracker.

    Args:
        process_df (pd.DataFrame): Process tracker DataFrame.
        file_name (str): Filename (without extension) to process.
        cfg (Config): Configuration object with all path settings.
    """
    wd = os.getcwd()
    file_path = process_df.loc[process_df['input_file'] == file_name].iloc[0]['input_path']
    print("---------------- Preprocessing file: {}".format(file_path))

    # Load raw JSON and normalise date columns
    ua_df = read_init_file(file_path)

    if ua_df.empty:
        raise Exception("No data found")

    # Ensure the click count column exists (absent in some older files)
    n_of_clicks_col = "number_of_clicks"
    if n_of_clicks_col not in ua_df.columns:
        ua_df[n_of_clicks_col] = 0

    ua_df = clean_data_duplicates(ua_df)

    print("> initial rows: " + str(ua_df.shape[0]))

    # Save per-file id/region/clicks snapshot for later regional analysis
    id_region_file_path = create_id_region_df(cfg.STAGE1_ID_REGION_NCLICK_PATH, file_name, ua_df)
    # Drop region and clicks — not needed for the text processing pipeline
    ua_df = ua_df.drop(columns=["region", "number_of_clicks"])
    ua_df = ua_df.drop_duplicates(subset="id", keep="last")
    print("> unique rows: " + str(ua_df.shape[0]))

    # Compare against the global unique ID database to find truly new records
    id_only_db = read_id_db(cfg.STAGE1_UNIQ_ID_DB)
    print("> unique rows: " + str(id_only_db.shape[0]))
    new_id_only = set(ua_df["id"]).difference(id_only_db["id"])
    print("> new unique ids: " + str(len(new_id_only)))

    ua_df_path = os.path.join(cfg.STAGE1_OUTPUT_PATH, file_name + ".pkl")

    if len(new_id_only) > 0:
        # Keep only job records with IDs not seen before
        ua_df_new = ua_df[ua_df["id"].isin(new_id_only)].copy()

        # Step 1: remove dates and salary figures from text fields
        ua_df_new["clean_title"] = ua_df_new["title"].apply(remove_dates_and_salaries)
        ua_df_new["clean_desc"] = ua_df_new["description"].apply(remove_dates_and_salaries)
        # Step 2: normalise characters, remove emoji and irrelevant symbols
        ua_df_new["clean_title"] = ua_df_new["title"].apply(clean_text, remove_digits=False)
        ua_df_new["clean_desc"] = ua_df_new["description"].apply(clean_text, remove_digits=False)
        print("> data cleaned:" + str(ua_df_new.shape[0]))

        # Detect title and description languages; keep only allowed languages
        allowed_langs = ["en", "uk", "ru", "cs", "pl"]
        ua_df_new = detect_langs(ua_df_new)
        ua_df_new = ua_df_new[ua_df_new['title_lang'].isin(allowed_langs)]
        ua_df_new = ua_df_new[ua_df_new['desc_lang'].isin(allowed_langs)]
        print("> detecting languages + removed not allowed: " + str(ua_df_new.shape[0]))

        # Append newly seen IDs to the global unique ID database
        print("> unique rows before: " + str(id_only_db.shape[0]))
        id_only_db = pd.concat([id_only_db, pd.DataFrame(list(new_id_only), columns=["id"])], ignore_index=True)
        id_only_db = id_only_db.drop_duplicates(subset="id", keep="last")
        id_only_db.to_pickle(cfg.STAGE1_UNIQ_ID_DB)
        print("> unique rows after: " + str(id_only_db.shape[0]))

        # Persist cleaned records and update the process tracker
        ua_df_new.to_pickle(ua_df_path)
        print("> id_region file path:" + id_region_file_path)

        upgrade_stage1_process_data(process_df, file_name, ua_df_path, id_region_file_path, cfg.STAGE1_PROCESS_PATH)
    else:
        # No new unique IDs — mark file as empty in the tracker
        upgrade_stage1_process_data(process_df, file_name, ua_df_path, id_region_file_path, cfg.STAGE1_PROCESS_PATH,
                                    empty=True)
