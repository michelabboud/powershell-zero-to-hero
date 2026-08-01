# PowerShell: Zero to Hero

A comprehensive illustrated training guide for tech professionals.

## Quick Start

1. Read the chapters in `chapters/` (00-preface through 17)
2. Try the exercises at the end of each chapter
3. Check your work against `answers/`

## Building the Book

Requires Python 3, Pandoc 3.1+, [Typst](https://typst.app/), and the
Libertinus Serif font.

```bash
# Assemble the chapter and appendix Markdown
python3 assets/build-book.py

# Convert that exact Markdown to a standalone Typst document
pandoc --from=gfm --to=typst --standalone \
  --metadata 'title=PowerShell: Zero to Hero' \
  --metadata 'author=Michel Abboud' \
  --variable 'mainfont=Libertinus Serif' \
  --include-before-body=assets/document-metadata.typ \
  --output=powershell-zero-to-hero.typ \
  powershell-zero-to-hero.md

# Compile the generated Typst document
mkdir -p dist
typst compile --root . powershell-zero-to-hero.typ \
  dist/powershell-zero-to-hero.pdf
```

Michel Abboud is the book author. Generated editions retain this exact creation
credit:

`Created by Visual Forge`

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
`assets/body.typ` is an extracted layout snapshot, not regenerated output.
New local builds flow through the assembled Markdown and should be written to
`dist/`.
