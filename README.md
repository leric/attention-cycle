# The Attention Cycle (Paper Source)

This repository contains the Quarto source for the paper:

**The Attention Cycle: Reducing Supervision Tax through Executable Documents**

## Files

- `attention-cycle.qmd`: main manuscript source (Quarto)
- `references.bib`: bibliography entries
- `_quarto.yml`: Quarto PDF format configuration
- `draft.md`: latest prose draft reference
- `scripts/build-arxiv.sh`: build and package script for arXiv submission

## Requirements

- [Quarto](https://quarto.org/) (with a working LaTeX engine, e.g. TeX Live)
- `python3` (used by the arXiv packaging script)

## Build PDF locally

```bash
quarto render attention-cycle.qmd
```

Output:

- `attention-cycle.pdf`
- `attention-cycle.tex` (kept via `keep-tex: true`)

## Build arXiv submission package

```bash
bash scripts/build-arxiv.sh
```

What it does:

1. Renders `attention-cycle.qmd` to refresh `attention-cycle.tex`
2. Collects the required TeX source and detected dependencies
3. Creates submission archives under `dist/arxiv/`

Outputs:

- `dist/arxiv/attention-cycle-arxiv.tar.gz`
- `dist/arxiv/attention-cycle-arxiv.zip`

## Notes

- Keep edits in `attention-cycle.qmd`; treat generated files as build artifacts.
- If you add figures or local TeX includes later, re-run the arXiv build script to ensure they are bundled.
