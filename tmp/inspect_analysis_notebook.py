import ast
import json
import re
from pathlib import Path


path = Path(r"C:\Users\Yura\Downloads\00.Analysis_skills_date_created_withpre2023_V4_with_occupation_composition_reproducibility_package.ipynb")
notebook = json.loads(path.read_text(encoding="utf-8"))
sources = ["".join(cell.get("source", [])) for cell in notebook["cells"]]
code = "\n".join(
    source
    for cell, source in zip(notebook["cells"], sources)
    if cell.get("cell_type") == "code"
)

patterns = (
    r"final_data\[['\"]([^'\"]+)['\"]\]",
    r"final_data\.([A-Za-z_][A-Za-z0-9_]*)",
)
columns = set()
for pattern in patterns:
    columns.update(re.findall(pattern, code))

print("FINAL_DATA_COLUMNS")
for column in sorted(columns):
    print(column)

print("\nREAD_CALLS")
for index, source in enumerate(sources):
    if re.search(r"read_(?:csv|excel|json|parquet|pickle)|ParquetFile", source):
        print(f"CELL {index}: {source.strip()}")

print("\nMARKDOWN_HEADINGS")
for index, cell in enumerate(notebook["cells"]):
    if cell.get("cell_type") == "markdown":
        for line in "".join(cell.get("source", [])).splitlines():
            if line.lstrip().startswith("#"):
                print(index, line)

print("\nSYNTAX")
bad = []
for index, cell in enumerate(notebook["cells"]):
    if cell.get("cell_type") != "code":
        continue
    source = "".join(cell.get("source", []))
    if not source.strip():
        continue
    try:
        ast.parse(source)
    except SyntaxError as error:
        bad.append((index, error.lineno, error.msg))
print("Invalid code cells:", bad)
