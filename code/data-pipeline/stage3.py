import os, json
import pandas as pd


def get_stage_process_df(stage2_path, stage3_path):
    """Load or create the Stage 3 process tracker, syncing it with Stage 2 output.

    Reads the Stage 2 tracker to find files with extract_status == 'complete'
    and registers any not yet present in the Stage 3 tracker.
    Creates a fresh Stage 3 tracker if none exists yet.

    The Stage 3 tracker has more columns than earlier stages because the
    OpenAI Batch API introduces asynchronous steps: input batch creation,
    job submission, job completion polling, and result extraction each have
    their own status column.

    Args:
        stage2_path (str): Path to the Stage 2 process tracker pickle.
        stage3_path (str): Path to the Stage 3 process tracker pickle.

    Returns:
        pd.DataFrame: Up-to-date Stage 3 tracker with columns:
            input_file, extract_path, input_batch_path, input_batch_status,
            job_id, job_status, output_batch_path, output_batch_status,
            result_path, result_status.
    """
    is_updated: bool = False

    if not os.path.exists(stage3_path):
        # First run — initialise an empty tracker with all Stage 3 status columns
        columns = ["input_file", "extract_path", "input_batch_path", "input_batch_status",
                   "job_id", "job_status", "output_batch_path", "output_batch_status",
                   "result_path", "result_status"]
        stage3_process = pd.DataFrame(columns=columns).astype(str)
        is_updated = True
    else:
        stage3_process = pd.read_pickle(stage3_path)

    stage2_process = pd.read_pickle(stage2_path)

    # Register Stage 2 completed files not yet present in the Stage 3 tracker
    for _, row in stage2_process.iterrows():
        if row["extract_status"] == "complete" and stage3_process.loc[stage3_process["input_file"] == row["input_file"]].empty:
            new_row = pd.DataFrame([{'input_file': row['input_file'], 'extract_path': row['extract_path']}])
            stage3_process = pd.concat([stage3_process, new_row], ignore_index=True)
            is_updated = True

    if is_updated:
        stage3_process.sort_values(by='input_file', inplace=True)
        stage3_process.reset_index(drop=True, inplace=True)
        stage3_process.to_pickle(stage3_path)

    return stage3_process


def get_extracted_skills_df(skills_file_path):
    """Load a Stage 2 output pickle and return a slim DataFrame for classification.

    Selects only the columns needed for the LLM classification prompt
    (id, cleaned title, cleaned description, extracted skill labels)
    and renames them to shorter, prompt-friendly names.

    Args:
        skills_file_path (str): Path to a Stage 2 output pickle file.

    Returns:
        pd.DataFrame: DataFrame with columns: id, title, desc, skills.
    """
    df = pd.read_pickle(skills_file_path)
    df = df[["id", "clean_title", "clean_desc", "skill_labels"]]
    df.rename(columns={"clean_title": "title", "clean_desc": "desc", "skill_labels": "skills"}, inplace=True)
    return df


def read_classification_schema(file_path: str) -> dict:
    """Read the OpenAI function-calling schema for job classification.

    The schema JSON file contains a list with a single schema object.
    Only the first element is returned, as the API expects a single function definition.

    Args:
        file_path (str): Path to the JSON schema file.

    Returns:
        dict: Function-calling schema dict passed to the OpenAI API
            as the `functions` parameter.
    """
    with open(file_path, 'r') as f:
        schema = json.loads(f.read())[0]
    return schema


def read_classification_prompt(file_path: str) -> str:
    """Read and normalise the classification system prompt from a text file.

    Reads the prompt, replaces non-breaking hyphens (U+2011) with standard
    hyphens, and collapses all whitespace to single spaces. This ensures
    the prompt is clean and compact before being sent to the API.

    Args:
        file_path (str): Path to the prompt text file (UTF-8 encoded).

    Returns:
        str: Normalised prompt string ready to use as the system message.
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read().strip()
        # Replace non-breaking hyphens and collapse whitespace for a clean prompt
        return ' '.join(content.replace('\u2011', '-').split())


def write_batch_file(batch_path, sk_df, response_schema, request_prompt, model):
    """Build and write the OpenAI Batch API input JSONL file.

    Iterates over all job postings in sk_df and writes one JSON line per record.
    Each line contains the API request payload including the model, system prompt,
    function-calling schema, and the job data (id, title, skills).

    If a posting has no extracted skills (empty or very short), the cleaned
    description is used instead as fallback input to the LLM.

    Args:
        batch_path (str): Output path for the JSONL batch input file.
        sk_df (pd.DataFrame): DataFrame with columns: id, title, desc, skills.
        response_schema (dict): OpenAI function-calling schema for classification.
        request_prompt (str): System prompt instructing the LLM how to classify.
        model (str): OpenAI model name to use (e.g. 'gpt-4.1-mini').

    Returns:
        str: Path to the written batch input file.
    """
    with open(batch_path, "w", encoding="utf-8") as fout:
        for _, row in sk_df.iterrows():

            # Use skill labels as primary input; fall back to description if skills are absent
            _skills = row.loc["skills"][:200]
            if row.loc["skills"] == "" or len(row.loc["skills"]) < 5:
                _skills = row.loc["desc"][:800]

            payload = {
                "id": row.loc["id"],
                "title": row.loc["title"],
                "skills": _skills
            }
            fout.write(json.dumps({
                "custom_id": "task-id-" + str(_),  # row index used as unique request ID
                "method": "POST",
                "url": "/v1/chat/completions",
                "body": {
                    "temperature": 0,  # deterministic output for consistent classification
                    "model": model,
                    "response_format": {"type": "json_object"},
                    "functions": [response_schema],
                    "messages": [
                        {"role": "system", "content": request_prompt},
                        {"role": "user", "content": json.dumps(payload, ensure_ascii=False)}
                    ],
                    "function_call": {"name": "classifyPosting"}
                }
            }, ensure_ascii=False) + "\n")
    print("\u2714 built batch input: ", batch_path)
    return batch_path


def create_batch_job(gpt_client, input_batch_path):
    """Upload a batch input file and submit it as an OpenAI Batch API job.

    Uploads the JSONL file to OpenAI Files API, then creates a batch job
    with a 24-hour completion window. The returned job object contains
    the job ID needed to poll for status and retrieve results.

    Args:
        gpt_client: Initialised OpenAI client instance.
        input_batch_path (str): Path to the JSONL batch input file to upload.

    Returns:
        openai.types.Batch: Batch job object with attributes including
            .id (job ID) and .status.
    """
    batch_file = gpt_client.files.create(
        file=open(input_batch_path, "rb"),
        purpose="batch"
    )
    job = gpt_client.batches.create(
        input_file_id=batch_file.id,
        endpoint="/v1/chat/completions",
        completion_window="24h"
    )
    return job


def get_model_from_jsonl(path):
    """Read the model name from the first line of a batch input JSONL file.

    Useful for verifying which model was used when inspecting existing
    batch files without reading the entire file.

    Args:
        path (str): Path to the JSONL batch input file.

    Returns:
        str: Model name string (e.g. 'gpt-4.1-mini').
    """
    with open(path, "r", encoding="utf-8") as f:
        first_line = f.readline()
    data = json.loads(first_line)
    return data["body"]["model"]


def extract_esco_codes(json_file_path):
    """Parse a Batch API output JSONL file and extract ESCO classification results.

    Reads each line of the batch output file, navigates the nested response
    structure to find the function-call arguments, and extracts the job
    vacancy ID, ESCO occupation code, and ESCO occupation title.

    Args:
        json_file_path (str): Path to the Batch API output JSONL file
            downloaded from OpenAI.

    Returns:
        pd.DataFrame: DataFrame with columns:
            - id (object): job vacancy ID matching the original posting
            - esco_code (str): ESCO occupation code assigned by the LLM
            - esco_title (str): ESCO occupation title assigned by the LLM
    """
    print(json_file_path)

    with open(json_file_path, 'r') as file:
        data = [json.loads(line) for line in file]

    records = []
    for entry in data:
        # Navigate the nested Batch API response structure
        choices = entry.get('response', {}).get('body', {}).get('choices', [])
        if choices:
            message = choices[0].get('message', {})
            function_call = message.get('function_call', {})
            arguments_json = function_call.get('arguments')

            if arguments_json:
                # The function-call arguments contain the structured classification result
                arguments = json.loads(arguments_json)
                records.append({
                    'id': arguments.get('id'),
                    'esco_code': arguments.get('esco_code'),
                    'esco_title': arguments.get('esco_title')
                })

    esco_df = pd.DataFrame(records)
    esco_df = esco_df.astype({
        'id': 'object',
        'esco_code': 'str',
        'esco_title': 'str'
    })
    return esco_df
