# Source Provenance

This repository is a public extraction of a private guide working tree captured
on 2026-08-01. The source repository was at commit
`3440c9af86f5074864c82c99daf7fc9f634c2e6f` and contained unpublished working
tree changes. The snapshot therefore records the captured files themselves,
not merely the referenced commit.

The machine-local source location is intentionally omitted. The complete
path-sorted file evidence is recorded in `source-inventory.json`.

## Historical PDF

The root `powershell-zero-to-hero.pdf` is a historical artifact copied
byte-for-byte from the private working tree. Its SHA-256 digest is
`c42307c89db74498e94656b41cf03d7d0c42d292ac287ad4d8727f8e9595c12b`.
It was not regenerated or editorially altered during extraction, so embedded
historical credits and styling may differ from the standalone sources.

## Future Builds

The chapter and appendix Markdown files are the maintainable source of truth.
`python3 assets/build-book.py` assembles them into combined Markdown.
`typst compile assets/body.typ dist/powershell-zero-to-hero.pdf` provides the
current standalone PDF build path. Generated artifacts belong in `dist/` and
must not replace the historical root PDF.
