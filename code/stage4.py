import pandas as pd
from difflib import get_close_matches


def find_closest_occupation_title(input_title, occupations):
    """Find the closest matching ESCO occupation title using fuzzy string matching.

    Uses Python's difflib.get_close_matches to compare the input title against
    all preferred labels in the ESCO occupation reference table. Returns the
    single best match above a similarity cutoff of 0.6, or None if no match
    meets the threshold.

    Args:
        input_title (str): The occupation title to look up (e.g. from LLM output).
        occupations (pd.DataFrame): ESCO occupation reference table with at least
            a 'preferredLabel' column.

    Returns:
        str or None: The closest matching preferred label, or None if no match
            exceeds the cutoff.
    """
    titles = occupations['preferredLabel'].dropna().tolist()
    matches = get_close_matches(input_title, titles, n=1, cutoff=0.6)
    return matches[0] if matches else None


def find_closest_occupation_code(input_code, occupations):
    """Find the closest matching ESCO occupation code using fuzzy string matching.

    Uses Python's difflib.get_close_matches to compare the input code (as a string)
    against all codes in the ESCO occupation reference table. Returns the single
    best match above a similarity cutoff of 0.6, or None if no match meets the
    threshold.

    Args:
        input_code (str or int): The occupation code to look up (e.g. from LLM output).
        occupations (pd.DataFrame): ESCO occupation reference table with at least
            a 'code' column.

    Returns:
        str or None: The closest matching code string, or None if no match exceeds
            the cutoff.
    """
    codes = occupations['code'].dropna().tolist()
    matches = get_close_matches(str(input_code), codes, n=1, cutoff=0.6)
    return matches[0] if matches else None


def manual_data_correction(stage3_data, index):
    test_code = 0
    """Apply hardcoded row-level corrections to Stage 3 classification results.

    After the two-pass LLM classification in Stage 3, a small number of vacancies
    across the full 2021–2025 dataset remained without a valid ESCO code or were
    assigned an incorrect one. These cases were identified during manual data
    quality review and corrected here.

    Two correction patterns are used:

    1. **Copy from a neighbouring row** — when a nearby vacancy in the same daily
       file has an identical or very similar title and was correctly classified,
       its code and title are copied across:

           stage3_data.loc[ROW, "esco_code"]  = stage3_data.loc[NEIGHBOUR, "esco_code"]
           stage3_data.loc[ROW, "esco_title"] = stage3_data.loc[NEIGHBOUR, "esco_title"]

    2. **Assign a hardcoded value** — when no good neighbour exists, the correct
       ESCO code and English title are set directly based on manual lookup:

           stage3_data.loc[ROW, "esco_code"]  = "XXXX"
           stage3_data.loc[ROW, "esco_title"] = "Occupation title"

    Each `elif index ==` branch targets one specific daily file, identified by
    its zero-based position in the Stage 3 process tracker. Row indices refer to
    the DataFrame index of that daily file after it has been loaded and
    reset_index(drop=True) applied.

    This function is specific to the original 2021–2025 dataset. It has no
    effect on the demo synthetic data (row indices in the demo file do not
    match those in the branches below).

    Args:
        stage3_data (pd.DataFrame): Stage 3 result DataFrame for a single daily
            file, with columns 'esco_code' and 'esco_title'. Modified in place.
        index (int): Zero-based position of the current daily file in the Stage 3
            process tracker — used to select the correct correction branch.

    Returns:
        None: All corrections are applied in place on stage3_data.
    """

    # ------------------------------------------------------------------
    # Pattern 1 — copy from a neighbouring correctly classified row
    # Used when a nearby vacancy has the same title and a valid ESCO code.
    # ------------------------------------------------------------------
    #if index == 0:
    #    stage3_data.loc[2747, "esco_code"]  = stage3_data.loc[2748, "esco_code"]
    #    stage3_data.loc[2747, "esco_title"] = stage3_data.loc[2748, "esco_title"]

    # ------------------------------------------------------------------
    # Pattern 2 — assign a hardcoded ESCO code and title
    # Used when no suitable neighbour exists; values confirmed via manual
    # lookup in the ESCO taxonomy (https://esco.ec.europa.eu/).
    # ------------------------------------------------------------------
    #elif index == 29:
    #    stage3_data.loc[61, "esco_code"]  = "3422"
    #    stage3_data.loc[61, "esco_title"] = "Outdoor activity instructor"

   # NOTE: The full correction table for all 900+ daily files in the
    # original 2021–2025 dataset is available in the SOURCE repository.
    # Only representative samples are shown here for documentation purposes.
