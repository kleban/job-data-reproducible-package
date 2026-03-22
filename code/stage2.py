import os, pathlib, re
from typing import Dict, List, Tuple

import numpy as np
import pandas as pd
from tqdm.auto import tqdm
from sentence_transformers import SentenceTransformer, util


def get_stage_process_df(stage1_path, stage2_path):
    """Load or create the Stage 2 process tracker, syncing it with Stage 1 output.

    Reads the Stage 1 process tracker to find files with clean_status == 'complete'
    and registers any that are not yet present in the Stage 2 tracker.
    Creates a fresh Stage 2 tracker if none exists yet.

    Args:
        stage1_path (str): Path to the Stage 1 process tracker pickle.
        stage2_path (str): Path to the Stage 2 process tracker pickle.

    Returns:
        pd.DataFrame: Up-to-date Stage 2 tracker with columns:
            input_file, clean_path, extract_path, extract_status.
    """
    is_updated: bool = False

    if not os.path.exists(stage2_path):
        # First run — initialise an empty tracker
        columns = ["input_file", "clean_path", "extract_path", "extract_status"]
        stage2_process = pd.DataFrame(columns=columns).astype(str)
        is_updated = True
    else:
        stage2_process = pd.read_pickle(stage2_path)

    stage1_process = pd.read_pickle(stage1_path)

    # Add any Stage 1 completed files not yet registered in the Stage 2 tracker
    for _, row in stage1_process.iterrows():
        if row["clean_status"] == "complete" and stage2_process.loc[stage2_process["input_file"] == row["input_file"]].empty:
            new_row = pd.DataFrame([{'input_file': row['input_file'], 'clean_path': row['clean_path']}])
            stage2_process = pd.concat([stage2_process, new_row], ignore_index=True)
            is_updated = True

    if is_updated:
        stage2_process.to_pickle(stage2_path)

    return stage2_process


# %% 2 ── language → model map ───────────────────────────────────────
# All supported languages share the same multilingual model.
# The dictionary is kept for extensibility — different models can be
# assigned per language if needed in future iterations.
LANG2_MODEL: Dict[str, str] = {
    "en": "sentence-transformers/paraphrase-multilingual-mpnet-base-v2",
    "uk": "sentence-transformers/paraphrase-multilingual-mpnet-base-v2",
    "cs": "sentence-transformers/paraphrase-multilingual-mpnet-base-v2",
    "pl": "sentence-transformers/paraphrase-multilingual-mpnet-base-v2",
    "ru": "sentence-transformers/paraphrase-multilingual-mpnet-base-v2"
}

# Regex to split text into sentences on sentence-ending punctuation
_SENT_SPLIT = re.compile(r"(?<=[.!?])\s+")


class SkillRetriever:
    """Retrieve relevant skills from a job description using sentence embeddings.

    Encodes a multilingual skills reference list (CSV per language) into dense
    vectors once and caches them. For each job description, encodes the text
    sentence-by-sentence and finds the top-K most similar skills using cosine
    similarity. Weak matches below a threshold are discarded.

    Attributes:
        dir (pathlib.Path): Folder containing skills CSV files (skills_en.csv,
            skills_uk.csv, etc.).
        k (int): Maximum number of top skills to return per document.
        vecs (Dict[str, np.ndarray]): Cached skill embedding matrices per language.
        ids (Dict[str, List[str]]): Cached skill concept URIs per language.
        labels (Dict[str, List[str]]): Cached skill preferred labels per language.
        embed (Dict[str, SentenceTransformer]): Cached SentenceTransformer models
            keyed by model ID.
    """

    def __init__(self, skills_dir: str, top_k: int = 25):
        """Initialise the SkillRetriever.

        Args:
            skills_dir (str): Path to the folder containing skills CSV files.
            top_k (int): Maximum number of skills to retrieve per document.
                Defaults to 25.
        """
        self.dir    = pathlib.Path(skills_dir)
        self.k      = top_k
        self.vecs   : Dict[str, np.ndarray] = {}
        self.ids    : Dict[str, List[str]]  = {}
        self.labels : Dict[str, List[str]]  = {}
        self.embed  : Dict[str, SentenceTransformer] = {}

    def _embedder(self, lang: str) -> SentenceTransformer:
        """Load and cache the SentenceTransformer model for a given language.

        Args:
            lang (str): ISO 639-1 language code.

        Returns:
            SentenceTransformer: Loaded model for the language.
        """
        mid = LANG2_MODEL.get(lang, LANG2_MODEL["en"])
        if mid not in self.embed:
            print(f"🔹 loading model {mid} for {lang}")
            self.embed[mid] = SentenceTransformer(mid)
        return self.embed[mid]

    def _skill_index(self, lang: str) -> Tuple[np.ndarray, List[str], List[str]]:
        """Build and cache the skill embedding index for a given language.

        Reads the skills CSV for the language, encodes all skill labels into
        dense vectors, and caches the result. Falls back to English if no
        language-specific CSV exists.

        Args:
            lang (str): ISO 639-1 language code.

        Returns:
            tuple: (V, ids, labels) where V is the (N, D) embedding matrix,
                ids is the list of ESCO concept URIs, and labels is the list
                of preferred skill labels.
        """
        if lang in self.vecs:
            return self.vecs[lang], self.ids[lang], self.labels[lang]

        csv = self.dir / f"skills_{lang}.csv"
        if not csv.exists():
            # Fall back to English skills list if language-specific file is missing
            csv = self.dir / "skills_en.csv"; lang = "en"

        df = pd.read_csv(csv, dtype=str)
        emb = self._embedder(lang)
        print(f"   ↳ encoding {len(df):,} skills for {lang}")

        # Encode all skill labels with L2 normalisation for cosine similarity via dot product
        V = emb.encode(df["preferredLabel"].tolist(), batch_size=128,
                       normalize_embeddings=True, convert_to_numpy=True,
                       show_progress_bar=True)
        self.vecs[lang], self.ids[lang], self.labels[lang] = (
            V, df["conceptUri"].tolist(), df["preferredLabel"].tolist()
        )
        return V, self.ids[lang], self.labels[lang]

    def retrieve(self, lang: str, text: str) -> pd.DataFrame:
        """Return a *pandas DataFrame* with columns `skill_id`, `skill_label`.

        Splits the input text into sentences, encodes each sentence, and
        computes cosine similarities against all skill embeddings. Aggregates
        the top-K unique skills across all sentences, discarding any with
        similarity below the threshold (0.50).

        Args:
            lang (str): ISO 639-1 language code of the input text.
            text (str): Job description text to extract skills from.

        Returns:
            pd.DataFrame: DataFrame with columns skill_id (ESCO URI) and
                skill_label (preferred label), sorted by similarity score.
                May be empty if no skills exceed the similarity threshold.
        """
        V, sids, slabels = self._skill_index(lang)
        emb = self._embedder(lang)

        # Encode each sentence of the description independently
        sent_vec = emb.encode(
            _SENT_SPLIT.split(text.strip()),
            normalize_embeddings=True,
            convert_to_numpy=True,
        )

        # Compute cosine similarities: (n_sentences, n_skills)
        sims = np.dot(sent_vec, V.T)
        # For each sentence, find the top-K candidate skill indices
        best_idx = np.argpartition(-sims, self.k, axis=1)[:, : self.k]

        # Flatten & de-duplicate preserving score order
        idx_score_pairs = []
        for row, idxs in zip(sims, best_idx):
            for j in idxs:
                idx_score_pairs.append((j, row[j]))

        # Sort globally by similarity and pick top-K unique skill IDs
        idx_score_pairs = sorted(idx_score_pairs, key=lambda x: -x[1])
        seen, rows = set(), []
        THRESH = 0.50  # minimum cosine-similarity to accept a skill match
        for j, score in idx_score_pairs:
            if score < THRESH:
                continue  # skip weak matches
            sid = sids[j]
            if sid not in seen:
                rows.append({"skill_id": sid, "skill_label": slabels[j]})
                seen.add(sid)
            if len(rows) == self.k:
                break
        return pd.DataFrame(rows)


def extract_skills(stage_process_file, row_index, retriever, output_path, stage_path):
    """Run skill extraction for a single Stage 1 output file.

    Loads the cleaned job posting DataFrame for the given row, runs
    SkillRetriever.retrieve() for each record, stores the resulting
    skill IDs and labels as comma-separated strings, saves the enriched
    DataFrame to disk, and updates the Stage 2 process tracker.

    Args:
        stage_process_file (pd.DataFrame): Stage 2 process tracker DataFrame.
        row_index (int): Index of the row in the tracker to process.
        retriever (SkillRetriever): Initialised SkillRetriever instance.
        output_path (str): Folder where the enriched output pickle will be saved.
        stage_path (str): Path to the Stage 2 process tracker pickle to update.

    Returns:
        pd.DataFrame: Updated Stage 2 process tracker with extract_path and
            extract_status filled in for the processed row.
    """
    process_df = pd.read_pickle(stage_process_file.loc[row_index, "clean_path"])
    print(f'🔸 loaded {len(process_df):,} postings from {stage_process_file.loc[row_index,"clean_path"]}')

    for _, row in tqdm(process_df.iterrows(), total=len(process_df), desc="retrieving"):
        extr_skills_df = retriever.retrieve(row["desc_lang"], row["clean_desc"]).copy()

        # Check if required columns exist
        if 'skill_id' not in extr_skills_df.columns or 'skill_label' not in extr_skills_df.columns:
            # Set empty values if retriever returned no results
            process_df.loc[_, "skill_ids"] = ''
            process_df.loc[_, "skill_labels"] = ''
            continue

        # Store skills as comma-separated strings; leave empty if no skills found
        if not extr_skills_df.empty:
            process_df.loc[_, "skill_ids"] = ','.join(extr_skills_df["skill_id"].astype(str))
            process_df.loc[_, "skill_labels"] = ','.join(extr_skills_df["skill_label"].astype(str))
        else:
            process_df.loc[_, "skill_ids"] = ''
            process_df.loc[_, "skill_labels"] = ''

    # Save enriched DataFrame and update the process tracker
    extract_skills_path = os.path.join(output_path, f"{stage_process_file.loc[row_index,'input_file']}.pkl")
    process_df.to_pickle(extract_skills_path)

    stage_process_file.loc[row_index, "extract_path"] = extract_skills_path
    stage_process_file.loc[row_index, "extract_status"] = "complete"
    stage_process_file.to_pickle(stage_path)
    return stage_process_file
