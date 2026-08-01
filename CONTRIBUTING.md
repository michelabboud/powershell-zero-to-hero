# Contributing

Thank you for helping improve *PowerShell: Zero to Hero*.

## Requirements

- PowerShell 7.4 or later
- Pester 5.7.1 or later
- Python 3
- Pandoc 3.1 or later
- Typst 0.14 or later and the Libertinus Serif font

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
pwsh ./tests/Run-AllTests.ps1
```

Validate the build inputs and toolchain, then build all four current artifacts:

```bash
python3 scripts/build_book.py --check
python3 scripts/build_book.py --edition all --format all
```

Update `book.json` when source order or edition metadata changes. Do not add a
second build workflow or edit generated files under `build/` or `dist/`.
Generated files and test results must remain untracked.
