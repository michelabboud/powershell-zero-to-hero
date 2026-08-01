# PowerShell: Zero to Hero

A comprehensive illustrated training guide for tech professionals.

## Quick Start

1. Read the chapters in `chapters/` (00-preface through 17)
2. Try the exercises at the end of each chapter
3. Check your work against `answers/`

## Building the Book

The standalone build requires Python 3, Pandoc 3.1 or later, Typst 0.14 or
later, and the Libertinus Serif font. Check the complete local toolchain and
manifest without generating files:

```bash
python3 scripts/build_book.py --check
```

Build the main guide and answer booklet as both PDF and HTML:

```bash
python3 scripts/build_book.py --edition all --format all
```

Use `--edition main|answers|all` and `--format pdf|html|all` to select a
subset. The generated Markdown and Typst bodies are written under `build/`;
final documents and their copied image assets are written under `dist/`.
Both directories are ignored by Git and exclusively managed by this command.
Each generating run safely clears stale contents, then leaves only the selected
edition/format outputs and their current image assets. The build refuses
symlinked managed roots or components and never writes the historical root PDF.

`book.json` is the only source for book metadata, source order, edition names,
cover assets, and output names. Markdown in `chapters/`, `appendices/`, and
`answers/` remains the canonical editable content. The tracked Typst
entrypoint and `book/template.typ` provide layout only.
Edition output names must be portable extensionless basenames. Local images may
use inline, full-reference, collapsed-reference, shortcut-reference, or
empty-alt Markdown forms, but every image must resolve under `assets/images/`;
external and escaping image targets are rejected.

Michel Abboud is the book author. Generated editions retain this exact creation
credit:

`Created by Visual Forge`

## Validating Contributions

Requires Python 3. Run the validator tests and then validate the repository from
its root:

```bash
python3 -m unittest tests/test_validate_repository.py
python3 scripts/validate_repository.py
```

## Running the Answer Tests

Requires PowerShell 7.4+ and Pester 5.7.1+; the guide is verified with
PowerShell 7.6.4 and Pester 6.0.1 while retaining Pester 5.7.1 compatibility.

```powershell
pwsh ./tests/Run-AllTests.ps1
```

## Structure

- `chapters/` -- 17 chapters + preface (the main guide)
- `appendices/` -- Cheat sheet, common errors, Bash-to-PS translation
- `answers/` -- Verified solutions for all exercises (separate booklet)
- `tests/` -- Pester tests proving every answer works
- `assets/images/` -- illustrations used throughout the guide
- `book.json` -- canonical build metadata and source order
- `book/` -- reusable Typst layout
- `scripts/` -- standalone assembly, build, and validation commands
- `docs/` -- source inventory and extraction provenance

The root `powershell-zero-to-hero.pdf` is the byte-preserved historical edition.
Never overwrite it; current local editions are generated under `dist/`.
