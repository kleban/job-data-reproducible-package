import json

def read_classification_schema(file_path: str) -> dict:
    """Read an OpenAI function-calling schema from a JSON file.

    The schema file is expected to contain a JSON array with one element —
    a single function definition object. Only the first element is returned,
    as the OpenAI API expects a single schema dict for the `functions` parameter.

    Note: This function is functionally identical to
    `stage3.read_classification_schema()` and is provided here so Stage 5
    notebooks can import it without depending on the Stage 3 module.

    Args:
        file_path (str): Path to the JSON schema file.

    Returns:
        dict: Function-calling schema dict to be passed to the OpenAI API
            as the `functions` parameter.
    """
    with open(file_path, 'r') as f:
        schema = json.loads(f.read())[0]
    return schema


def read_classification_prompt(file_path: str) -> str:
    """Read and normalise a classification or enrichment prompt from a text file.

    Reads the UTF-8 encoded prompt file, replaces non-breaking hyphens
    (U+2011) with standard ASCII hyphens, and collapses all whitespace to
    single spaces. This ensures the prompt string is clean and compact before
    being sent to the OpenAI API.

    Note: This function is functionally identical to
    `stage3.read_classification_prompt()` and is provided here so Stage 5
    notebooks can import it without depending on the Stage 3 module.

    Args:
        file_path (str): Path to the prompt text file (UTF-8 encoded).

    Returns:
        str: Normalised prompt string ready to use as a system message.
    """
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read().strip()
        # Replace non-breaking hyphens (U+2011) and collapse whitespace
        return ' '.join(content.replace('\u2011', '-').split())
