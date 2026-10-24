#!/usr/bin/env python3
"""Valida YAML de Azure Pipelines contra el JSON Schema publicado por Microsoft.

El esquema es el de la extensión de VS Code (microsoft/azure-pipelines-vscode,
service-schema.json). Ajustes para evitar falsos positivos:
  * El YAML se carga como texto (BaseLoader), igual que el servicio, que acepta
    expresiones $( ) y ${{ }} en casi cualquier campo; los booleanos de los
    "inputs" de tareas se convierten, porque el esquema sí los tipa.
  * Las tareas que el esquema no conoce (p. ej. versiones más nuevas que el
    esquema) sólo se validan estructuralmente.

El validador definitivo sigue siendo el servicio (botón Validate del editor o
la API Runs con previewRun: true).

Uso: python3 scripts/validate_azure_pipelines.py <service-schema.json> <archivo.yml>...
Requiere: pip install pyyaml jsonschema
"""
import json
import re
import sys

import yaml
from jsonschema import Draft7Validator


def load_validator(schema_path: str) -> Draft7Validator:
    schema = json.load(open(schema_path, encoding="utf-8"))
    task = schema["definitions"]["task"]
    known = sorted({re.sub(r"^\^|\$$", "", alt["properties"]["task"]["pattern"])
                    for alt in task["anyOf"]
                    if "pattern" in alt.get("properties", {}).get("task", {})})
    task["properties"]["task"]["anyOf"].append(
        {"type": "string", "pattern": r"^[A-Za-z0-9_.-]+@[0-9]+$"})
    task["anyOf"].append({
        "properties": {"task": {"not": {"pattern": "^(" + "|".join(map(re.escape, known)) + ")$"}}},
        "required": ["task"],
    })
    return Draft7Validator(schema)


def typed_inputs(node):
    """En los 'inputs' de una tarea el esquema tipa los booleanos."""
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "inputs" and isinstance(value, dict) and "task" in node:
                node[key] = {k: (v.lower() == "true") if isinstance(v, str) and v.lower() in ("true", "false") else v
                             for k, v in value.items()}
            else:
                typed_inputs(value)
    elif isinstance(node, list):
        for item in node:
            typed_inputs(item)
    return node


def leaves(error):
    if not error.context:
        yield error
        return
    for sub in error.context:
        yield from leaves(sub)


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 2
    validator = load_validator(sys.argv[1])
    failed = 0
    for path in sys.argv[2:]:
        with open(path, encoding="utf-8") as handle:
            document = typed_inputs(yaml.load(handle, Loader=yaml.BaseLoader))
        errors = list(validator.iter_errors(document))
        if not errors:
            print(f"OK    {path}")
            continue
        failed += 1
        print(f"FALLA {path}")
        found = [leaf for error in errors for leaf in leaves(error)]
        deepest = max(len(list(leaf.absolute_path)) for leaf in found)
        shown = set()
        for leaf in sorted(found, key=lambda e: -len(list(e.absolute_path))):
            if len(list(leaf.absolute_path)) < deepest - 1 or len(shown) >= 10:
                break
            message = ("/".join(map(str, leaf.absolute_path)), leaf.message[:200])
            if message not in shown:
                shown.add(message)
                print(f"      en '{message[0]}': {message[1]}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
