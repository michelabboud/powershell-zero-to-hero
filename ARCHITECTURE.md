# Architecture

## Source of truth

The editable book sources live in `chapters/`, `appendices/`, and `answers/`.
`book.json` is the sole authority for metadata, source order, editions, covers,
and output names. Layout is defined by `powershell-zero-to-hero.typ` and
`book/template.typ`; images live under `assets/images/`.

The tracked root PDF is an immutable historical artifact. Current outputs are
always generated under ignored `build/` and `dist/` directories.

## Validation and build flow

1. `scripts/validate_repository.py` verifies inventories, source membership,
   answer/test coverage, links, image containment, licensing, and publication
   boundaries.
2. `tests/Run-AllTests.ps1` executes the Pester answer suite.
3. `scripts/assemble_book.py` assembles repository-relative Markdown in the
   order declared by `book.json`.
4. `scripts/build_book.py` invokes Pandoc and Typst to create main and answer
   editions in PDF and HTML.
5. GitHub Actions repeats validation and exact-toolchain builds. A `v*` tag
   publishes only the four generated books and their `SHA256SUMS` manifest to a
   GitHub Release.

Build-managed directories reject symlinks and escaping paths. Generated output
names are validated as portable basenames, and local image references must
remain beneath `assets/images/`.

## Ownership and distribution

Michel Abboud is the author. Generated editions include the exact creation
credit `Created by Visual Forge`. The repository is MIT licensed, and GitHub is
its only publication and release destination.
