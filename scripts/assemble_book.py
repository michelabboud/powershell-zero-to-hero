#!/usr/bin/env python3
"""Assemble manifest-ordered guide sources into deterministic Markdown."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Literal


Edition = Literal['main', 'answers']


@dataclass(frozen=True, slots=True)
class BookConfig:
    """Editable book metadata and repository-relative source order."""

    title: str
    author: str
    version: str
    credit: str
    chapters: tuple[str, ...]
    appendices: tuple[str, ...]
    answers: tuple[str, ...]


def load_config(root: Path) -> BookConfig:
    """Load the canonical source order and metadata manifest."""
    data = json.loads((root / 'book.json').read_text(encoding='utf-8'))
    return BookConfig(
        title=data['title'],
        author=data['author'],
        version=data['version'],
        credit=data['credit'],
        chapters=tuple(data['chapters']),
        appendices=tuple(data['appendices']),
        answers=tuple(data['answers']),
    )


def _source_path(root: Path, relative: str) -> Path:
    path = PurePosixPath(relative)
    if not relative or path.is_absolute() or '..' in path.parts or '\\' in relative:
        raise ValueError(f'source path must be repository-relative: {relative!r}')
    return root.joinpath(*path.parts)


def _read_source(root: Path, relative: str) -> str:
    try:
        return _source_path(root, relative).read_text(encoding='utf-8').rstrip()
    except FileNotFoundError:
        raise FileNotFoundError(f'missing source file: {relative}') from None


def assemble(root: Path, config: BookConfig, edition: Edition) -> str:
    """Return one edition assembled exactly in manifest order."""
    ordered = (*config.chapters, *config.appendices)
    if edition == 'answers':
        ordered = (*ordered, *config.answers)
    sections = [_read_source(root, relative) for relative in ordered]
    return '\n\n\\newpage\n\n'.join(sections) + '\n'


def write_edition(root: Path, config: BookConfig, edition: Edition) -> Path:
    """Write an assembled edition beneath the ignored build directory."""
    output = root / 'build' / f'{edition}.md'
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(assemble(root, config, edition), encoding='utf-8')
    return output


def _editions(value: str) -> tuple[Edition, ...]:
    if value == 'all':
        return ('main', 'answers')
    if value == 'main':
        return ('main',)
    if value == 'answers':
        return ('answers',)
    raise ValueError(f'unsupported edition: {value}')


def main(argv: list[str] | None = None, *, root: Path | None = None) -> int:
    """Write selected manifest editions beneath ``build/``."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--edition', choices=('main', 'answers', 'all'), default='all')
    arguments = parser.parse_args(argv)
    repository_root = root if root is not None else Path(__file__).resolve().parents[1]
    try:
        config = load_config(repository_root)
        outputs = tuple(
            sorted(
                (
                    write_edition(repository_root, config, edition)
                    for edition in _editions(arguments.edition)
                ),
                key=lambda path: path.as_posix(),
            ),
        )
    except (FileNotFoundError, TypeError, UnicodeError, ValueError, json.JSONDecodeError) as error:
        parser.exit(1, f'error: {error}\n')
    for output in outputs:
        print(output.relative_to(repository_root).as_posix())
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
