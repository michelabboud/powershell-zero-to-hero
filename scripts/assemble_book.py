#!/usr/bin/env python3
"""Assemble manifest-ordered guide sources into deterministic Markdown."""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Literal

if __package__:
    from .managed_outputs import managed_path, prepare_managed_roots
else:
    from managed_outputs import (  # pyright: ignore[reportImplicitRelativeImport]
        managed_path,
        prepare_managed_roots,
    )


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


@dataclass(frozen=True, slots=True, order=True)
class SourceManifestIssue:
    """One declared/discovered Markdown source mismatch."""

    kind: str
    status: str
    path: str


def _required_string(data: dict[str, object], field: str) -> str:
    value = data.get(field)
    if not isinstance(value, str) or not value:
        raise ValueError(f"book.json field '{field}' must be a non-empty string")
    return value


def _source_list(
    data: dict[str, object],
    field: str,
    directory: str,
) -> tuple[str, ...]:
    value = data.get(field)
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        raise ValueError(f"book.json field '{field}' must be a string array")
    sources = tuple(value)
    if len(sources) != len(set(sources)):
        raise ValueError(f"book.json field '{field}' contains a duplicate source")
    for relative in sources:
        path = PurePosixPath(relative)
        if (
            not relative
            or path.is_absolute()
            or '\\' in relative
            or '..' in path.parts
            or len(path.parts) != 2
            or path.parts[0] != directory
            or path.suffix.casefold() != '.md'
        ):
            raise ValueError(
                f"book.json field '{field}' contains an invalid source path: {relative!r}",
            )
    return sources


def load_config(root: Path) -> BookConfig:
    """Load the canonical source order and metadata manifest."""
    data = json.loads((root / 'book.json').read_text(encoding='utf-8'))
    if not isinstance(data, dict):
        raise ValueError('book.json must contain an object')
    return BookConfig(
        title=_required_string(data, 'title'),
        author=_required_string(data, 'author'),
        version=_required_string(data, 'version'),
        credit=_required_string(data, 'credit'),
        chapters=_source_list(data, 'chapters', 'chapters'),
        appendices=_source_list(data, 'appendices', 'appendices'),
        answers=_source_list(data, 'answers', 'answers'),
    )


def source_manifest_issues(
    root: Path,
    config: BookConfig,
) -> tuple[SourceManifestIssue, ...]:
    """Compare manifest membership with discovered canonical Markdown files."""
    groups = (
        ('chapter', 'chapters', config.chapters),
        ('appendix', 'appendices', config.appendices),
        ('answer', 'answers', config.answers),
    )
    issues: list[SourceManifestIssue] = []
    for kind, directory, declared in groups:
        expected = set(declared)
        source_directory = root / directory
        actual = {
            f'{directory}/{path.name}'
            for path in source_directory.glob('*.md')
            if path.is_file() and not path.is_symlink()
        } if source_directory.is_dir() and not source_directory.is_symlink() else set()
        issues.extend(
            SourceManifestIssue(kind, 'missing', path)
            for path in sorted(expected - actual)
        )
        issues.extend(
            SourceManifestIssue(kind, 'unexpected', path)
            for path in sorted(actual - expected)
        )
    return tuple(sorted(issues))


def validate_source_manifest(root: Path, config: BookConfig) -> None:
    """Reject the first deterministic source membership mismatch."""
    issues = source_manifest_issues(root, config)
    if issues:
        issue = issues[0]
        raise ValueError(
            f'manifest {issue.kind} source is {issue.status}: {issue.path}',
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
    prepare_managed_roots(root, 'build')
    output = managed_path(root, 'build', f'{edition}.md')
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
