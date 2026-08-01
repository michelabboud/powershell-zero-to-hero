#!/usr/bin/env python3
"""Combine the standalone guide sources into one Markdown document."""

import re
from pathlib import Path


CREATION_CREDIT = 'Created by Visual Forge'


def add_page_break() -> str:
    return '\n\n\\newpage\n\n'


def read_sources(paths: list[Path], guide_root: Path) -> list[str]:
    """Read ordered source files and add page breaks between them."""
    parts: list[str] = []
    for filepath in paths:
        parts.append(add_page_break())
        parts.append(filepath.read_text(encoding='utf-8'))
        print(f'  Added: {filepath.relative_to(guide_root)}')
    return parts


def main() -> None:
    guide_root = Path(__file__).resolve().parent.parent
    chapter_paths = sorted((guide_root / 'chapters').glob('*.md'))
    appendix_paths = sorted((guide_root / 'appendices').glob('*.md'))

    if not chapter_paths:
        raise SystemExit('No chapter sources found under chapters/.')
    if not appendix_paths:
        raise SystemExit('No appendix sources found under appendices/.')

    parts = [CREATION_CREDIT, '']
    parts.extend(read_sources(chapter_paths, guide_root))
    parts.extend((add_page_break(), '# Appendices\n'))
    parts.extend(read_sources(appendix_paths, guide_root))

    combined = '\n'.join(parts)

    output_path = guide_root / 'powershell-zero-to-hero.md'
    output_path.write_text(combined, encoding='utf-8')
    print(f'\nCombined book written to: {output_path}')
    print(f'Total size: {len(combined):,} characters')

    img_count = len(re.findall(r'!\[', combined))
    print(f'Image references: {img_count}')


if __name__ == '__main__':
    main()
