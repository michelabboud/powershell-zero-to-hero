# Source Provenance

This repository is a public extraction of a private guide working tree captured
on 2026-08-01. The source repository was at commit
`3440c9af86f5074864c82c99daf7fc9f634c2e6f` and contained unpublished working
tree changes. The snapshot therefore records the captured files themselves,
not merely the referenced commit.

The machine-local source location is intentionally omitted.
`source-inventory.json` records the original selected-source paths, byte
counts, and SHA-256 values before public sanitization. It is immutable capture
evidence and is not a checksum of the current public files.

`destination-inventory.json` separately records the current standalone
repository content. To avoid self-reference, it excludes exactly
`docs/source-inventory.json` and `docs/destination-inventory.json`; every
other tracked file is path-sorted and hashed.

## Historical PDF

The root `powershell-zero-to-hero.pdf` is a historical artifact copied
byte-for-byte from the private working tree. Its SHA-256 digest is
`c42307c89db74498e94656b41cf03d7d0c42d292ac287ad4d8727f8e9595c12b`.
It was not regenerated or editorially altered during extraction, so embedded
historical credits and styling may differ from the standalone sources.

## Future Builds

The chapter, appendix, and answer Markdown files are the maintainable content
source of truth. `book.json` is the sole order and build-metadata authority.
`python3 scripts/build_book.py --edition all --format all` assembles both
editions under `build/`, invokes Pandoc for HTML and Typst body generation,
and invokes Typst for PDF generation. Michel Abboud is set as the visible and
document-metadata author. Generated editions carry this exact creation credit:

`Created by Visual Forge`

The tracked `powershell-zero-to-hero.typ` entrypoint and `book/template.typ`
provide layout without duplicating manifest metadata. Generated Markdown and
Typst bodies belong in ignored `build/`; final documents and copied image
assets belong in ignored `dist/`. Neither location may replace the historical
root PDF. These two ignored directories are exclusively build-managed: each
generating run rejects symlinked roots/components, removes stale contents, and
retains only the requested outputs plus currently referenced local images.
Configured output names are safe extensionless basenames, and Markdown images
must resolve beneath `assets/images/` regardless of whether they use inline,
full-reference, collapsed-reference, shortcut-reference, or empty-alt syntax.
