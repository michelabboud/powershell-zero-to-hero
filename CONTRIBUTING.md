# Contributing

Thank you for helping improve *PowerShell: Zero to Hero*.

## Requirements

- PowerShell 7.4 or later
- Pester 5.5 or later
- Python 3
- Pandoc 3.1 or later
- Typst and the Libertinus Serif font, when producing a PDF

## Workflow

1. Keep chapter sources in `chapters/`, appendix sources in `appendices/`, and
   exercise solutions in `answers/`.
2. Put guide images in `assets/images/` and use repository-relative paths.
3. Do not edit the historical root PDF. Write generated artifacts to `dist/`.
4. Run the standalone checks below before submitting a change.

Validate both provenance inventory files and their publication contracts:

```bash
python3 -m json.tool docs/source-inventory.json >/dev/null
python3 -m json.tool docs/destination-inventory.json >/dev/null
python3 tests/test-publication-contract.py
```

Run the answer tests:

```bash
pwsh ./tests/run-all.ps1
```

Rebuild the combined Markdown and PDF:

```bash
python3 assets/build-book.py
pandoc --from=gfm --to=typst --standalone \
  --metadata 'title=PowerShell: Zero to Hero' \
  --metadata 'author=Michel Abboud' \
  --variable 'mainfont=Libertinus Serif' \
  --include-before-body=assets/document-metadata.typ \
  --output=powershell-zero-to-hero.typ \
  powershell-zero-to-hero.md
mkdir -p dist
typst compile --root . powershell-zero-to-hero.typ \
  dist/powershell-zero-to-hero.pdf
```

Generated files and test results must remain untracked.
