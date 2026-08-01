# Contributing

Thank you for helping improve *PowerShell: Zero to Hero*.

## Requirements

- PowerShell 7.4 or later
- Pester 5.5 or later
- Python 3
- Typst, when producing a PDF

## Workflow

1. Keep chapter sources in `chapters/`, appendix sources in `appendices/`, and
   exercise solutions in `answers/`.
2. Put guide images in `assets/images/` and use repository-relative paths.
3. Do not edit the historical root PDF. Write generated artifacts to `dist/`.
4. Run the standalone checks below before submitting a change.

Validate the provenance inventory JSON:

```bash
python3 -m json.tool docs/source-inventory.json >/dev/null
```

Run the answer tests:

```bash
pwsh ./tests/run-all.ps1
```

Rebuild the combined Markdown and PDF:

```bash
python3 assets/build-book.py
mkdir -p dist
typst compile assets/body.typ dist/powershell-zero-to-hero.pdf
```

Generated files and test results must remain untracked.
