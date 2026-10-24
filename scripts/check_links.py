#!/usr/bin/env python3
"""Verifica enlaces internos y anclas en los archivos Markdown del repositorio.

- Comprueba que existan los archivos/carpetas enlazados con rutas relativas.
- Comprueba que existan las anclas (#seccion), con el mismo algoritmo que usa
  GitHub para generar los IDs de los encabezados (github-slugger).
- Ignora enlaces externos (http/https/mailto) y el contenido de bloques de código.

Uso: python3 scripts/check_links.py [raíz]   (por defecto, el directorio actual)
"""
import re
import sys
import unicodedata
from pathlib import Path

LINK_RE = re.compile(r"(?<!\!)\[(?:[^\[\]]|\[[^\]]*\])*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
FENCE_RE = re.compile(r"^\s*(```|~~~)")
INLINE_CODE_RE = re.compile(r"`[^`]*`")
SKIP_DIRS = {".git", "node_modules", ".terraform"}


def slugify(text: str) -> str:
    """Equivalente a github-slugger: minúsculas, sin puntuación ni símbolos,
    espacios convertidos en guiones (sin colapsar)."""
    text = re.sub(r"!?\[([^\]]*)\]\([^)]*\)", r"\1", text)  # [texto](url) -> texto
    out = []
    for ch in text.lower():
        if ch == " ":
            out.append("-")
        elif ch in "-_" or ch.isalnum() or unicodedata.category(ch).startswith("M"):
            out.append(ch)
    return "".join(out)


def markdown_lines(path: Path):
    """Devuelve (número de línea, texto) fuera de bloques de código."""
    in_fence = False
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        if FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if not in_fence:
            yield number, line


def anchors(path: Path, cache: dict) -> set:
    if path not in cache:
        seen: dict = {}
        result = set()
        for _, line in markdown_lines(path):
            match = HEADING_RE.match(line)
            if not match:
                continue
            base = slugify(match.group(2))
            count = seen.get(base, 0)
            result.add(base if count == 0 else f"{base}-{count}")
            seen[base] = count + 1
        cache[path] = result
    return cache[path]


def main() -> int:
    root = Path(sys.argv[1] if len(sys.argv) > 1 else ".").resolve()
    files = sorted(p for p in root.rglob("*.md") if not SKIP_DIRS & set(p.relative_to(root).parts))
    cache: dict = {}
    errors = []
    checked = 0
    for md in files:
        for number, line in markdown_lines(md):
            for target in LINK_RE.findall(INLINE_CODE_RE.sub("", line)):
                if re.match(r"^(https?:|mailto:)", target):
                    continue
                checked += 1
                path_part, _, fragment = target.partition("#")
                dest = md if not path_part else (md.parent / path_part).resolve()
                where = f"{md.relative_to(root)}:{number}"
                if not dest.exists():
                    errors.append(f"{where}: no existe '{path_part}'")
                    continue
                if fragment and dest.suffix == ".md" and fragment not in anchors(dest, cache):
                    errors.append(f"{where}: ancla '#{fragment}' no encontrada en {dest.relative_to(root)}")
    for error in errors:
        print(f"ERROR {error}")
    print(f"{len(files)} archivos, {checked} enlaces internos revisados, {len(errors)} errores.")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
