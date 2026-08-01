# PowerShell: Zero to Hero

A comprehensive illustrated training guide for tech professionals.

## Quick Start

1. Read the chapters in `chapters/` (00-preface through 17)
2. Try the exercises at the end of each chapter
3. Check your work against `answers/`

## Building the Book

Requires Python 3 and [Typst](https://typst.app/).

```bash
# Rebuild the combined Markdown source
python3 assets/build-book.py

# Build a PDF from the preserved Typst source
mkdir -p dist
typst compile assets/body.typ dist/powershell-zero-to-hero.pdf
```

## Running the Answer Tests

Requires PowerShell 7.4+ and Pester 5.5+.

```powershell
pwsh ./tests/run-all.ps1
```

## Structure

- `chapters/` -- 17 chapters + preface (the main guide)
- `appendices/` -- Cheat sheet, common errors, Bash-to-PS translation
- `answers/` -- Verified solutions for all exercises (separate booklet)
- `tests/` -- Pester tests proving every answer works
- `assets/images/` -- illustrations used throughout the guide
- `docs/` -- source inventory and extraction provenance

The root `powershell-zero-to-hero.pdf` is the byte-preserved historical edition.
New local builds should be written to `dist/`.
