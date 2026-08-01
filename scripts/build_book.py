#!/usr/bin/env python3
"""Build standalone HTML and PDF editions from the canonical manifest."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import subprocess
from dataclasses import dataclass
from pathlib import Path
from pathlib import PurePosixPath
from typing import Literal

if __package__:
    from .assemble_book import (
        BookConfig,
        assemble,
        load_config,
        validate_source_manifest,
        write_edition,
    )
    from .managed_outputs import (
        ManagedPathError,
        managed_path,
        reset_managed_roots,
        validate_managed_tree,
    )
    from .validate_repository import markdown_target_parts, parse_markdown_targets
else:
    from assemble_book import (  # pyright: ignore[reportImplicitRelativeImport]
        BookConfig,
        assemble,
        load_config,
        validate_source_manifest,
        write_edition,
    )
    from managed_outputs import (  # pyright: ignore[reportImplicitRelativeImport]
        ManagedPathError,
        managed_path,
        reset_managed_roots,
        validate_managed_tree,
    )
    from validate_repository import (  # pyright: ignore[reportImplicitRelativeImport]
        markdown_target_parts,
        parse_markdown_targets,
    )


Edition = Literal['main', 'answers']
OutputFormat = Literal['pdf', 'html']
OUTPUT_BASENAME_RE = re.compile(r'^[A-Za-z0-9][A-Za-z0-9_-]*$')


class BuildError(RuntimeError):
    """A concise, actionable build failure."""


@dataclass(frozen=True, slots=True)
class EditionConfig:
    """Per-edition presentation and output metadata."""

    title: str
    output_name: str
    front_cover: str
    back_cover: str


@dataclass(frozen=True, slots=True)
class BuildManifest:
    """Canonical book metadata plus both configured editions."""

    book: BookConfig
    creation_timestamp: int
    main: EditionConfig
    answers: EditionConfig

    def edition(self, edition: Edition) -> EditionConfig:
        return self.main if edition == 'main' else self.answers


def _load_edition(data: object, edition: Edition) -> EditionConfig:
    if not isinstance(data, dict):
        raise BuildError(f"book.json edition '{edition}' must be an object.")
    try:
        config = EditionConfig(
            title=data['title'],
            output_name=data['output'],
            front_cover=data['frontCover'],
            back_cover=data['backCover'],
        )
    except KeyError as error:
        raise BuildError(
            f"book.json edition '{edition}' is missing '{error.args[0]}'.",
        ) from None
    if (
        not isinstance(config.output_name, str)
        or OUTPUT_BASENAME_RE.fullmatch(config.output_name) is None
    ):
        raise BuildError(
            f"book.json edition '{edition}' output must be a safe extensionless basename.",
        )
    return config


def load_manifest(root: Path) -> BuildManifest:
    """Load all build decisions from ``book.json``."""
    path = root / 'book.json'
    data = json.loads(path.read_text(encoding='utf-8'))
    book = load_config(root)
    validate_source_manifest(root, book)
    if book.author != 'Michel Abboud':
        raise BuildError('book.json author must be Michel Abboud.')
    if book.credit != 'Created by Visual Forge':
        raise BuildError('book.json credit must be exactly Created by Visual Forge.')
    version = (root / 'VERSION').read_text(encoding='utf-8').strip()
    if version != book.version:
        raise BuildError('book.json version must match VERSION.')
    editions = data.get('editions')
    if not isinstance(editions, dict):
        raise BuildError("book.json field 'editions' must be an object.")
    creation_timestamp = data.get('creationTimestamp')
    if (
        not isinstance(creation_timestamp, int)
        or isinstance(creation_timestamp, bool)
        or creation_timestamp < 0
    ):
        raise BuildError("book.json field 'creationTimestamp' must be a non-negative integer.")
    return BuildManifest(
        book=book,
        creation_timestamp=creation_timestamp,
        main=_load_edition(editions.get('main'), 'main'),
        answers=_load_edition(editions.get('answers'), 'answers'),
    )


def check_tools() -> None:
    """Require the two local document toolchain executables."""
    requirements = (
        ('pandoc', 'Pandoc 3.1+'),
        ('typst', 'Typst 0.14+'),
    )
    for executable, description in requirements:
        if shutil.which(executable) is None:
            raise BuildError(
                f"Required build tool '{executable}' was not found on PATH. "
                f'Install {description} and retry.',
            )


def run_checked(command: list[str], cwd: Path) -> None:
    """Run one build command and propagate a nonzero status."""
    subprocess.run(command, cwd=cwd, check=True)


def _canonical_image_path(raw_target: str) -> str:
    path_part, _fragment = markdown_target_parts(raw_target)
    path = PurePosixPath(path_part)
    if (
        not path_part
        or path.is_absolute()
        or '\\' in path_part
        or '..' in path.parts
        or len(path.parts) < 3
        or path.parts[:2] != ('assets', 'images')
    ):
        raise BuildError(f'image path must stay under assets/images: {raw_target}')
    return path.as_posix()


def _image_source(root: Path, relative: str) -> Path:
    source = root.joinpath(*PurePosixPath(relative).parts)
    current = root
    for part in PurePosixPath(relative).parts:
        current /= part
        if current.is_symlink():
            raise BuildError(f'missing build asset: {relative}')
    try:
        source.resolve(strict=True).relative_to(root.resolve(strict=True))
    except (OSError, ValueError):
        raise BuildError(f'missing build asset: {relative}') from None
    if not source.is_file():
        raise BuildError(f'missing build asset: {relative}')
    return source


def _copy_asset(root: Path, relative: str) -> None:
    canonical = _canonical_image_path(relative)
    source = _image_source(root, canonical)
    try:
        destination = managed_path(root, 'dist', canonical)
        destination.parent.mkdir(parents=True, exist_ok=True)
    except ManagedPathError as error:
        raise BuildError(str(error)) from None
    shutil.copyfile(source, destination)


def _copy_referenced_images(
    root: Path,
    markdown_paths: tuple[Path, ...],
    manifest: BuildManifest,
    editions: tuple[Edition, ...],
) -> None:
    referenced: set[str] = set()
    for markdown_path in markdown_paths:
        parsed = parse_markdown_targets(markdown_path.read_text(encoding='utf-8'))
        if parsed.duplicate_definition:
            raise BuildError('Markdown contains a duplicate reference definition.')
        if parsed.missing_definition:
            raise BuildError('Markdown reference definition is unavailable.')
        referenced.update(
            _canonical_image_path(target.raw)
            for target in parsed.targets
            if target.is_image
        )
    for edition in editions:
        edition_config = manifest.edition(edition)
        referenced.add(_canonical_image_path(edition_config.front_cover))
        referenced.add(_canonical_image_path(edition_config.back_cover))
    for relative in sorted(referenced):
        _copy_asset(root, relative)


def _rewrite_typst_body(path: Path) -> None:
    body = path.read_text(encoding='utf-8')
    body = body.replace('image("assets/images/', 'image("../assets/images/')
    body = body.replace('\\\\newpage', '#pagebreak()')
    body = body.replace('\\newpage', '#pagebreak()')
    body = (
        '#import "../book/template.typ": blockquote, horizontalrule\n\n'
        + body
    )
    path.write_text(body, encoding='utf-8')


def _pandoc_metadata(manifest: BuildManifest, edition: Edition) -> list[str]:
    edition_config = manifest.edition(edition)
    return [
        '--metadata',
        f'title={edition_config.title}',
        '--metadata',
        f'author={manifest.book.author}',
        '--metadata',
        f'subtitle=Version {manifest.book.version} — {manifest.book.credit}',
    ]


def _build_html(
    root: Path,
    manifest: BuildManifest,
    edition: Edition,
    markdown: Path,
) -> Path:
    output = Path('dist') / f'{manifest.edition(edition).output_name}.html'
    command = [
        'pandoc',
        '--from=gfm',
        '--to=html5',
        '--standalone',
        '--resource-path=.',
        *_pandoc_metadata(manifest, edition),
        f'--output={output.as_posix()}',
        markdown.relative_to(root).as_posix(),
    ]
    run_checked(command, root)
    return root / output


def _build_pdf(
    root: Path,
    manifest: BuildManifest,
    edition: Edition,
    markdown: Path,
) -> Path:
    body = Path('build') / f'{edition}-body.typ'
    run_checked(
        [
            'pandoc',
            '--from=gfm',
            '--to=typst',
            f'--output={body.as_posix()}',
            markdown.relative_to(root).as_posix(),
        ],
        root,
    )
    _rewrite_typst_body(root / body)
    edition_config = manifest.edition(edition)
    output = Path('dist') / f'{edition_config.output_name}.pdf'
    run_checked(
        [
            'typst',
            'compile',
            '--root',
            '.',
            '--creation-timestamp',
            str(manifest.creation_timestamp),
            '--input',
            f'edition={edition}',
            '--input',
            f'title={edition_config.title}',
            '--input',
            f'author={manifest.book.author}',
            '--input',
            f'version={manifest.book.version}',
            '--input',
            f'credit={manifest.book.credit}',
            '--input',
            f'front-cover={edition_config.front_cover}',
            '--input',
            f'back-cover={edition_config.back_cover}',
            'powershell-zero-to-hero.typ',
            output.as_posix(),
        ],
        root,
    )
    return root / output


def build(
    root: Path,
    editions: tuple[Edition, ...],
    formats: tuple[OutputFormat, ...],
) -> tuple[Path, ...]:
    """Build selected editions/formats and return path-sorted final outputs."""
    check_tools()
    manifest = load_manifest(root)
    try:
        reset_managed_roots(root, 'build', 'dist')
        markdown_paths = tuple(
            write_edition(root, manifest.book, edition)
            for edition in editions
        )
    except ManagedPathError as error:
        raise BuildError(str(error)) from None
    _copy_referenced_images(root, markdown_paths, manifest, editions)
    outputs: list[Path] = []
    for edition, markdown in zip(editions, markdown_paths, strict=True):
        if 'html' in formats:
            outputs.append(_build_html(root, manifest, edition, markdown))
        if 'pdf' in formats:
            outputs.append(_build_pdf(root, manifest, edition, markdown))
    return tuple(sorted(outputs, key=lambda path: path.as_posix()))


def validate_build(root: Path) -> None:
    """Validate tools, metadata, sources, and static build assets read-only."""
    check_tools()
    manifest = load_manifest(root)
    try:
        for directory in ('build', 'dist'):
            validate_managed_tree(root, directory)
    except ManagedPathError as error:
        raise BuildError(str(error)) from None
    assembled = (
        assemble(root, manifest.book, 'main'),
        assemble(root, manifest.book, 'answers'),
    )
    for markdown in assembled:
        parsed = parse_markdown_targets(markdown)
        if parsed.duplicate_definition:
            raise BuildError('Markdown contains a duplicate reference definition.')
        if parsed.missing_definition:
            raise BuildError('Markdown reference definition is unavailable.')
        for target in parsed.targets:
            if target.is_image:
                _copy_asset_check(root, target.raw)
    for edition in ('main', 'answers'):
        edition_config = manifest.edition(edition)
        _copy_asset_check(root, edition_config.front_cover)
        _copy_asset_check(root, edition_config.back_cover)
    for relative in ('book/template.typ', 'powershell-zero-to-hero.typ'):
        if not (root / relative).is_file():
            raise BuildError(f'missing build file: {relative}')


def _copy_asset_check(root: Path, relative: str) -> None:
    canonical = _canonical_image_path(relative)
    _image_source(root, canonical)


def _editions(value: str) -> tuple[Edition, ...]:
    if value == 'all':
        return ('main', 'answers')
    if value == 'main':
        return ('main',)
    if value == 'answers':
        return ('answers',)
    raise ValueError(f'unsupported edition: {value}')


def _formats(value: str) -> tuple[OutputFormat, ...]:
    if value == 'all':
        return ('pdf', 'html')
    if value == 'pdf':
        return ('pdf',)
    if value == 'html':
        return ('html',)
    raise ValueError(f'unsupported format: {value}')


def main(argv: list[str] | None = None, *, root: Path | None = None) -> int:
    """Parse build selections and emit the requested artifacts."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--edition', choices=('main', 'answers', 'all'), default='all')
    parser.add_argument('--format', choices=('pdf', 'html', 'all'), default='all')
    parser.add_argument('--check', action='store_true', help='validate without generating files')
    arguments = parser.parse_args(argv)
    repository_root = root if root is not None else Path(__file__).resolve().parents[1]
    try:
        if arguments.check:
            validate_build(repository_root)
            print('Build prerequisites and manifest are valid.')
            return 0
        outputs = build(
            repository_root,
            editions=_editions(arguments.edition),
            formats=_formats(arguments.format),
        )
    except (
        BuildError,
        FileNotFoundError,
        TypeError,
        UnicodeError,
        ValueError,
        json.JSONDecodeError,
        subprocess.CalledProcessError,
    ) as error:
        parser.exit(1, f'error: {error}\n')
    for output in outputs:
        print(output.relative_to(repository_root).as_posix())
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
