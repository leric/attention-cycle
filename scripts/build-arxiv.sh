#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

QMD_FILE="${1:-attention-cycle.qmd}"
if [[ ! -f "$QMD_FILE" ]]; then
  echo "Error: Quarto source not found: $QMD_FILE" >&2
  exit 1
fi

BASENAME="$(basename "$QMD_FILE" .qmd)"
TEX_FILE="${BASENAME}.tex"

if ! command -v quarto >/dev/null 2>&1; then
  echo "Error: 'quarto' command not found in PATH." >&2
  exit 1
fi

echo "==> Rendering $QMD_FILE"
quarto render "$QMD_FILE"

if [[ ! -f "$TEX_FILE" ]]; then
  echo "Error: expected TeX output not found: $TEX_FILE" >&2
  exit 1
fi

OUT_DIR="$ROOT_DIR/dist/arxiv"
STAGE_DIR="$OUT_DIR/${BASENAME}"
mkdir -p "$OUT_DIR"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"

cp "$TEX_FILE" "$STAGE_DIR/"
[[ -f "references.bib" ]] && cp "references.bib" "$STAGE_DIR/"

echo "==> Collecting TeX dependencies"
python3 - "$ROOT_DIR" "$TEX_FILE" "$STAGE_DIR" <<'PY'
from __future__ import annotations
import re
import shutil
import sys
from pathlib import Path

root = Path(sys.argv[1]).resolve()
tex_file = root / sys.argv[2]
stage = Path(sys.argv[3]).resolve()
content = tex_file.read_text(encoding="utf-8")

def add_if_exists(src: Path):
    src = src.resolve()
    if not src.exists() or not src.is_file():
        return
    try:
        rel = src.relative_to(root)
    except ValueError:
        return
    if rel.parts and rel.parts[0] in {".git", ".quarto", "dist"}:
        return
    dst = stage / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)

patterns = {
    "graphics": re.compile(r"\\includegraphics(?:\[[^\]]*\])?\{([^}]+)\}"),
    "input": re.compile(r"\\(?:input|include)\{([^}]+)\}"),
    "bibliography": re.compile(r"\\bibliography\{([^}]+)\}"),
}

for name, pattern in patterns.items():
    for match in pattern.findall(content):
        for raw_item in match.split(","):
            item = raw_item.strip()
            if not item:
                continue
            candidates = []
            p = Path(item)
            if p.suffix:
                candidates.append(root / p)
            else:
                candidates.append(root / p)
                if name == "input":
                    candidates.append(root / f"{item}.tex")
                elif name == "bibliography":
                    candidates.append(root / f"{item}.bib")
                else:
                    for ext in [".pdf", ".png", ".jpg", ".jpeg", ".eps"]:
                        candidates.append(root / f"{item}{ext}")
            for c in candidates:
                add_if_exists(c)

for ext in ("*.cls", "*.sty", "*.bst", "*.bbx", "*.cbx"):
    for f in root.glob(ext):
        add_if_exists(f)
PY

TAR_PATH="$OUT_DIR/${BASENAME}-arxiv.tar.gz"
ZIP_PATH="$OUT_DIR/${BASENAME}-arxiv.zip"

echo "==> Creating archives"
tar -czf "$TAR_PATH" -C "$STAGE_DIR" .
(
  cd "$STAGE_DIR"
  zip -rq "$ZIP_PATH" .
)

echo "==> Done"
echo "TAR: $TAR_PATH"
echo "ZIP: $ZIP_PATH"
