#!/usr/bin/env python3
"""Validate the standalone guide repository using only the standard library."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import sys
import unicodedata
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path, PurePosixPath
from typing import Any, Iterable
from urllib.parse import unquote

if __package__:
    from .assemble_book import BookConfig, load_config, source_manifest_issues
else:
    _SCRIPT_DIRECTORY = str(Path(__file__).resolve().parent)
    if _SCRIPT_DIRECTORY not in sys.path:
        sys.path.insert(0, _SCRIPT_DIRECTORY)
    from assemble_book import (  # pyright: ignore[reportImplicitRelativeImport]
        BookConfig,
        load_config,
        source_manifest_issues,
    )


@dataclass(frozen=True, slots=True, order=True)
class ValidationIssue:
    code: str
    path: str
    message: str


@dataclass(frozen=True, slots=True, order=True)
class MarkdownTarget:
    """One parsed inline or reference-style Markdown target."""

    raw: str
    is_image: bool


@dataclass(frozen=True, slots=True)
class MarkdownParse:
    """Deterministic Markdown targets plus reference-definition diagnostics."""

    targets: tuple[MarkdownTarget, ...]
    duplicate_definition: bool
    missing_definition: bool


DEFAULT_DESTINATION_INVENTORY = 'docs/destination-inventory.json'
SOURCE_INVENTORY = 'docs/source-inventory.json'
HISTORICAL_PDF = 'powershell-zero-to-hero.pdf'
IGNORED_ROOTS = frozenset(
    {
        '.git',
        '.mypy_cache',
        '.pytest_cache',
        '.ruff_cache',
        '__pycache__',
        'build',
        'dist',
        'test-results',
    },
)
TEXT_SUFFIXES = frozenset(
    {'.json', '.md', '.ps1', '.py', '.toml', '.typ', '.txt', '.yaml', '.yml'},
)
TEXT_NAMES = frozenset({'.gitignore', 'LICENSE', 'VERSION'})
DESTINATION_KEYS = frozenset(
    {
        'schemaVersion',
        'destinationDescriptor',
        'capturedAt',
        'excludedPaths',
        'files',
    },
)
SOURCE_KEYS = frozenset(
    {'schemaVersion', 'sourceDescriptor', 'sourceCommit', 'capturedAt', 'files'},
)
ENTRY_KEYS = frozenset({'path', 'bytes', 'sha256'})
SHA256_RE = re.compile(r'^[0-9a-f]{64}$')
COMMIT_RE = re.compile(r'^[0-9a-f]{40}$')
HEADING_RE = re.compile(r'^ {0,3}(#{1,6})[ \t]+(.+?)[ \t]*#*[ \t]*$')
HTML_ANCHOR_RE = re.compile(
    r'<a\s+(?:name|id)=["\']([^"\']+)["\'][^>]*>',
    re.IGNORECASE,
)
MARKDOWN_LINK_RE = re.compile(
    r'(?P<image>!)?\[[^\]]*\]\(\s*(?P<target><[^>]+>|[^)\s]+)(?:\s+[^)]*)?\)',
)
REFERENCE_DEFINITION_RE = re.compile(
    r'^ {0,3}\[(?P<label>[^\]\n]+)\]:[ \t]*'
    r'(?P<target><[^>\n]+>|[^ \t\n]+)'
    r'(?:[ \t]+(?:"[^"\n]*"|\'[^\'\n]*\'|\([^\)\n]*\)))?[ \t]*$',
)
REFERENCE_USE_RE = re.compile(
    r'(?P<image>!)?\[(?P<text>[^\]\n]*)\]\[(?P<label>[^\]\n]*)\]',
)
SHORTCUT_REFERENCE_RE = re.compile(
    r'(?P<image>!)?\[(?P<label>[^\]\n]+)\](?![\[(])',
)
EXERCISE_RE = re.compile(r'\[Ch-(\d{2}),\s*Ex-(\d+)\]')
ANSWER_RE = re.compile(r'^##\s+Ch-(\d{2}),\s*Ex-(\d+)\b', re.MULTILINE)
TEST_RE = re.compile(r'\bIt\s+["\']Ex-(\d+)\b', re.IGNORECASE)
EXTERNAL_SCHEMES = frozenset({'data', 'ftp', 'http', 'https', 'mailto', 'tel'})
WINDOWS_ABSOLUTE_RE = re.compile(r'^[A-Za-z]:[\\/]')
HOME_PATH_PATTERN = (
    r'(?<![A-Za-z0-9])(?:/(?:home|Users)/[A-Za-z0-9._-]+(?:/|\b)'
    r'|[A-Za-z]:[\\/]Users[\\/][^\\/\s]+(?:[\\/]|\b)|~'
    + '/'
    + r')'
)
HOME_PATH_RE = re.compile(HOME_PATH_PATTERN)


def _joined(*parts: str, separator: str = '') -> str:
    return separator.join(parts)


BRAND = _joined('Visual', ' Forge')
CREATION_CREDIT = _joined('Created by ', BRAND)
RUNTIME_MARKERS = tuple(
    marker.casefold()
    for marker in (
        _joined('visual', 'forge', 'mcp', separator='-'),
        _joined('visual', 'forge', 'projects', separator='-'),
        _joined('global', 'context', separator='-'),
        _joined('vf', 'mcp', separator='_'),
        _joined('vf', 'guides', separator='_'),
        _joined('anthropic', 'api', 'key', separator='_'),
        _joined('gemini', 'api', 'key', separator='_'),
    )
)
FORBIDDEN_NAMES = frozenset(
    {
        _joined('global', 'context.json', separator='-'),
        '.env',
        'id_rsa',
    },
)
FORBIDDEN_PATHS = frozenset(
    {
        _joined('assets/convert', 'placeholders.py', separator='-'),
        _joined('assets/replace', 'placeholders.py', separator='-'),
        _joined('assets/character', 'bootstrap.md', separator='-'),
        'assets/covers.md',
    },
)
FORBIDDEN_SUFFIXES = (
    _joined('.', _joined('vf', 'bak', separator='-')),
    '.pem',
)
FORBIDDEN_SUFFIXES_CASEFOLDED = tuple(suffix.casefold() for suffix in FORBIDDEN_SUFFIXES)


def _has_forbidden_suffix(component: str) -> bool:
    folded = component.casefold()
    return any(folded.endswith(suffix) for suffix in FORBIDDEN_SUFFIXES_CASEFOLDED)


def _issue(code: str, path: str, message: str) -> ValidationIssue:
    return ValidationIssue(code=code, path=path, message=message)


def _serialize_issue(issue: ValidationIssue) -> str:
    serialized = json.dumps(
        {'code': issue.code, 'message': issue.message, 'path': issue.path},
        ensure_ascii=True,
        separators=(',', ':'),
        sort_keys=True,
    )
    return serialized.replace('|', '\\u007c')


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def _is_ignored(relative: PurePosixPath) -> bool:
    return bool(relative.parts and relative.parts[0] in IGNORED_ROOTS) or any(
        part in {'.git', '__pycache__'} for part in relative.parts
    )


def _repository_paths(root: Path) -> tuple[Path, ...]:
    paths: list[Path] = []
    for current, directory_names, file_names in os.walk(root, followlinks=False):
        current_path = Path(current)
        relative_directory = current_path.relative_to(root)
        directory_names[:] = sorted(
            name
            for name in directory_names
            if not _is_ignored(
                PurePosixPath(*(relative_directory.parts + (name,))),
            )
        )
        for name in sorted(file_names):
            path = current_path / name
            relative = PurePosixPath(*path.relative_to(root).parts)
            if not _is_ignored(relative):
                paths.append(path)
    return tuple(sorted(paths, key=lambda path: path.relative_to(root).as_posix()))


def _relative_path(root: Path, path: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return '<outside-repository>'


def _safe_repository_path(root: Path, raw_path: str) -> Path | None:
    if not raw_path or '\\' in raw_path:
        return None
    relative = PurePosixPath(raw_path)
    if relative.is_absolute() or '..' in relative.parts or relative.as_posix() != raw_path:
        return None
    candidate = root.joinpath(*relative.parts)
    try:
        candidate.resolve(strict=False).relative_to(root.resolve(strict=True))
    except (OSError, ValueError):
        return None
    return candidate


def _read_text(path: Path) -> str | None:
    try:
        if path.is_symlink():
            return None
        return path.read_text(encoding='utf-8')
    except (OSError, UnicodeError):
        return None


def _load_json(
    root: Path,
    path: Path,
    role: str,
    issues: list[ValidationIssue],
) -> dict[str, Any] | None:
    display_path = _relative_path(root, path)
    text = _read_text(path)
    if text is None:
        issues.append(_issue(f'{role}-missing', display_path, 'Required inventory is unavailable.'))
        return None
    try:
        data = json.loads(text)
    except json.JSONDecodeError:
        issues.append(_issue(f'{role}-invalid', display_path, 'Inventory is not valid JSON.'))
        return None
    if not isinstance(data, dict):
        issues.append(_issue(f'{role}-invalid', display_path, 'Inventory root must be an object.'))
        return None
    return data


def _valid_timestamp(value: object) -> bool:
    if not isinstance(value, str):
        return False
    try:
        datetime.fromisoformat(value.replace('Z', '+00:00'))
    except ValueError:
        return False
    return True


def _inventory_entries(
    root: Path,
    inventory_path: Path,
    data: dict[str, Any],
    role: str,
    issues: list[ValidationIssue],
) -> dict[str, dict[str, Any]]:
    display_path = _relative_path(root, inventory_path)
    raw_entries = data.get('files')
    if not isinstance(raw_entries, list):
        issues.append(_issue(f'{role}-invalid', display_path, 'Inventory files must be an array.'))
        return {}

    entries: dict[str, dict[str, Any]] = {}
    ordered_paths: list[str] = []
    malformed = False
    for raw_entry in raw_entries:
        if not isinstance(raw_entry, dict) or frozenset(raw_entry) != ENTRY_KEYS:
            malformed = True
            continue
        raw_path = raw_entry.get('path')
        byte_count = raw_entry.get('bytes')
        digest = raw_entry.get('sha256')
        if (
            not isinstance(raw_path, str)
            or _safe_repository_path(root, raw_path) is None
            or not isinstance(byte_count, int)
            or isinstance(byte_count, bool)
            or byte_count < 0
            or not isinstance(digest, str)
            or SHA256_RE.fullmatch(digest) is None
        ):
            malformed = True
            continue
        ordered_paths.append(raw_path)
        if raw_path in entries:
            malformed = True
            continue
        entries[raw_path] = raw_entry

    if ordered_paths != sorted(ordered_paths) or malformed:
        issues.append(
            _issue(
                f'{role}-invalid',
                display_path,
                'Inventory entries must be unique, path-sorted, and well formed.',
            ),
        )
    return entries


def _validate_destination_inventory(
    root: Path,
    manifest_path: Path,
    issues: list[ValidationIssue],
) -> None:
    data = _load_json(root, manifest_path, 'inventory', issues)
    if data is None:
        return
    display_path = _relative_path(root, manifest_path)
    if (
        frozenset(data) != DESTINATION_KEYS
        or data.get('schemaVersion') != 1
        or data.get('destinationDescriptor') != 'public-standalone-working-tree'
        or not _valid_timestamp(data.get('capturedAt'))
    ):
        issues.append(_issue('inventory-invalid', display_path, 'Destination inventory metadata is invalid.'))

    raw_exclusions = data.get('excludedPaths')
    exclusions: set[str] = set()
    if isinstance(raw_exclusions, list) and all(
        isinstance(path, str) and _safe_repository_path(root, path) is not None
        for path in raw_exclusions
    ):
        exclusions = set(raw_exclusions)
        if len(exclusions) != len(raw_exclusions) or raw_exclusions != sorted(raw_exclusions):
            issues.append(_issue('inventory-invalid', display_path, 'Inventory exclusions are invalid.'))
    else:
        issues.append(_issue('inventory-invalid', display_path, 'Inventory exclusions are invalid.'))

    required_exclusions = {SOURCE_INVENTORY, _relative_path(root, manifest_path)}
    if exclusions != required_exclusions:
        issues.append(_issue('inventory-invalid', display_path, 'Inventory self-exclusions are invalid.'))

    entries = _inventory_entries(root, manifest_path, data, 'inventory', issues)
    actual_paths = {
        _relative_path(root, path)
        for path in _repository_paths(root)
        if _relative_path(root, path) not in exclusions
    }
    expected_paths = set(entries)
    for path in sorted(expected_paths - actual_paths):
        issues.append(_issue('inventory-missing', path, 'Inventoried file is missing.'))
    for path in sorted(actual_paths - expected_paths):
        issues.append(_issue('inventory-unexpected', path, 'File is not covered by the destination inventory.'))

    for relative in sorted(expected_paths & actual_paths):
        path = _safe_repository_path(root, relative)
        if path is None or path.is_symlink() or not path.is_file():
            continue
        entry = entries[relative]
        try:
            byte_count = path.stat().st_size
            digest = _sha256(path)
        except OSError:
            issues.append(_issue('inventory-unreadable', relative, 'Inventoried file cannot be read.'))
            continue
        if byte_count != entry['bytes']:
            issues.append(_issue('inventory-size', relative, 'Inventoried byte count does not match.'))
        if digest != entry['sha256']:
            issues.append(_issue('inventory-hash', relative, 'Inventoried checksum does not match.'))


def _validate_source_inventory(root: Path, issues: list[ValidationIssue]) -> None:
    inventory_path = root / SOURCE_INVENTORY
    data = _load_json(root, inventory_path, 'source-inventory', issues)
    if data is None:
        return
    if (
        frozenset(data) != SOURCE_KEYS
        or data.get('schemaVersion') != 1
        or data.get('sourceDescriptor') != 'private-guide-working-tree'
        or not isinstance(data.get('sourceCommit'), str)
        or COMMIT_RE.fullmatch(data['sourceCommit']) is None
        or not _valid_timestamp(data.get('capturedAt'))
    ):
        issues.append(
            _issue('source-inventory-invalid', SOURCE_INVENTORY, 'Source inventory metadata is invalid.'),
        )
    entries = _inventory_entries(
        root,
        inventory_path,
        data,
        'source-inventory',
        issues,
    )
    pdf_entry = entries.get(HISTORICAL_PDF)
    if pdf_entry is None:
        issues.append(
            _issue('historical-pdf-evidence', SOURCE_INVENTORY, 'Historical PDF evidence is missing.'),
        )
        return
    pdf_path = root / HISTORICAL_PDF
    if pdf_path.is_symlink() or not pdf_path.is_file():
        issues.append(_issue('historical-pdf-missing', HISTORICAL_PDF, 'Historical PDF is unavailable.'))
        return
    try:
        matches = (
            pdf_path.stat().st_size == pdf_entry['bytes']
            and _sha256(pdf_path) == pdf_entry['sha256']
        )
    except OSError:
        matches = False
    if not matches:
        issues.append(
            _issue(
                'historical-pdf-hash',
                HISTORICAL_PDF,
                'Historical PDF does not match captured source evidence.',
            ),
        )


def _load_book_config(root: Path, issues: list[ValidationIssue]) -> BookConfig | None:
    try:
        return load_config(root)
    except (FileNotFoundError, KeyError, TypeError, UnicodeError, ValueError, json.JSONDecodeError):
        issues.append(
            _issue('book-manifest-invalid', 'book.json', 'Book manifest is unavailable or invalid.'),
        )
        return None


def _validate_declared_sources(
    root: Path,
    config: BookConfig,
    issues: list[ValidationIssue],
) -> None:
    for source_issue in source_manifest_issues(root, config):
        issues.append(
            _issue(
                f'{source_issue.kind}-{source_issue.status}',
                source_issue.path,
                f'Manifest {source_issue.kind} source is {source_issue.status}.',
            ),
        )


def _content_without_fences(text: str) -> str:
    output: list[str] = []
    fence_character: str | None = None
    fence_length = 0
    for line in text.splitlines():
        match = re.match(r'^ {0,3}(`{3,}|~{3,})', line)
        if match:
            marker = match.group(1)
            if fence_character is None:
                fence_character = marker[0]
                fence_length = len(marker)
            elif marker[0] == fence_character and len(marker) >= fence_length:
                fence_character = None
                fence_length = 0
            output.append('')
        elif fence_character is None:
            output.append(line)
        else:
            output.append('')
    return '\n'.join(output)


def _content_without_inline_code(text: str) -> str:
    output = list(text)
    cursor = 0
    while cursor < len(text):
        if text[cursor] != '`':
            cursor += 1
            continue
        end = cursor + 1
        while end < len(text) and text[end] == '`':
            end += 1
        marker = text[cursor:end]
        closing = re.search(
            rf'(?<!`){re.escape(marker)}(?!`)',
            text[end:],
        )
        if closing is None:
            cursor = end
            continue
        closing_end = end + closing.end()
        for index in range(cursor, closing_end):
            if output[index] not in {'\n', '\r'}:
                output[index] = ' '
        cursor = closing_end
    return ''.join(output)


def _heading_anchor(heading: str) -> str:
    plain = re.sub(r'!\[([^\]]*)\]\([^)]*\)', r'\1', heading)
    plain = re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', plain)
    plain = re.sub(r'<[^>]+>', '', plain)
    normalized = unicodedata.normalize('NFKC', plain).casefold()
    normalized = ''.join(
        character
        for character in normalized
        if character == '-'
        or character.isspace()
        or character == '_'
        or character.isalnum()
    )
    return re.sub(r'\s+', '-', normalized.strip())


def _anchors(text: str) -> tuple[str, ...]:
    visible = _content_without_fences(text)
    anchors = [
        _heading_anchor(match.group(2))
        for line in visible.splitlines()
        if (match := HEADING_RE.match(line)) is not None
    ]
    anchors.extend(match.group(1) for match in HTML_ANCHOR_RE.finditer(visible))
    return tuple(anchor for anchor in anchors if anchor)


def _validate_anchors(root: Path, markdown: dict[str, str], issues: list[ValidationIssue]) -> None:
    for relative, text in sorted(markdown.items()):
        visible = _content_without_fences(text)
        strict_anchors = [
            _heading_anchor(match.group(2))
            for line in visible.splitlines()
            if (match := HEADING_RE.match(line)) is not None and len(match.group(1)) <= 2
        ]
        strict_anchors.extend(
            match.group(1) for match in HTML_ANCHOR_RE.finditer(visible)
        )
        seen: set[str] = set()
        duplicate = False
        for anchor in strict_anchors:
            if anchor in seen:
                duplicate = True
            seen.add(anchor)
        if duplicate:
            issues.append(
                _issue('anchor-duplicate', relative, 'Markdown document defines duplicate anchors.'),
            )


def markdown_target_parts(target: str) -> tuple[str, str]:
    target = target[1:-1] if target.startswith('<') and target.endswith('>') else target
    without_fragment, separator, fragment = target.partition('#')
    path = without_fragment.split('?', 1)[0]
    return unquote(path), unquote(fragment) if separator else ''


def _normalize_reference_label(label: str) -> str:
    return re.sub(r'\s+', ' ', label.strip()).casefold()


def _reference_definitions(
    visible: str,
) -> tuple[dict[str, str], str, bool]:
    definitions: dict[str, str] = {}
    content_lines: list[str] = []
    duplicate = False
    for line in visible.splitlines():
        match = REFERENCE_DEFINITION_RE.match(line)
        if match is None:
            content_lines.append(line)
            continue
        label = _normalize_reference_label(match.group('label'))
        if label in definitions:
            duplicate = True
        else:
            definitions[label] = match.group('target')
        content_lines.append('')
    return definitions, '\n'.join(content_lines), duplicate


def _overlaps(span: tuple[int, int], occupied: list[tuple[int, int]]) -> bool:
    return any(span[0] < existing[1] and existing[0] < span[1] for existing in occupied)


def parse_markdown_targets(text: str) -> MarkdownParse:
    """Parse supported inline, full, collapsed, and shortcut Markdown targets."""
    visible = _content_without_fences(text)
    definitions, reference_content, duplicate_definition = _reference_definitions(visible)
    link_content = _content_without_inline_code(reference_content)
    targets = {
        MarkdownTarget(match.group('target'), match.group('image') is not None)
        for match in MARKDOWN_LINK_RE.finditer(link_content)
    }
    occupied: list[tuple[int, int]] = []
    missing_definition = False
    for match in REFERENCE_USE_RE.finditer(link_content):
        occupied.append(match.span())
        link_text = match.group('text')
        label = match.group('label')
        if not link_text and not label:
            continue
        normalized = _normalize_reference_label(label or link_text)
        target = definitions.get(normalized)
        if target is None:
            missing_definition = True
            continue
        targets.add(MarkdownTarget(target, match.group('image') is not None))
    for match in SHORTCUT_REFERENCE_RE.finditer(link_content):
        if _overlaps(match.span(), occupied):
            continue
        target = definitions.get(_normalize_reference_label(match.group('label')))
        if target is not None:
            targets.add(MarkdownTarget(target, match.group('image') is not None))
    return MarkdownParse(
        targets=tuple(sorted(targets)),
        duplicate_definition=duplicate_definition,
        missing_definition=missing_definition,
    )


def _validate_markdown_target(
    root: Path,
    source: Path,
    relative: str,
    raw_target: str,
    is_image: bool,
    image_root: Path,
    anchors_by_path: dict[str, set[str]],
    issues: list[ValidationIssue],
) -> None:
    path_part, fragment = markdown_target_parts(raw_target)
    lowered = path_part.casefold()
    if any(lowered.startswith(f'{scheme}:') for scheme in EXTERNAL_SCHEMES):
        if is_image:
            issues.append(_issue('image-path', relative, 'Markdown images must be repository-local.'))
        return
    if path_part.startswith(('/', '\\', '~')) or WINDOWS_ABSOLUTE_RE.match(path_part):
        issues.append(_issue('absolute-path', relative, 'Markdown target must be repository-relative.'))
        return
    canonical_image_path = PurePosixPath(path_part)
    if (
        is_image
        and len(canonical_image_path.parts) >= 2
        and canonical_image_path.parts[:2] == ('assets', 'images')
    ):
        target = root.joinpath(*canonical_image_path.parts)
    else:
        target = source if not path_part else source.parent / Path(path_part)
    try:
        resolved = target.resolve(strict=False)
        resolved.relative_to(root)
    except (OSError, ValueError):
        issues.append(_issue('path-escape', relative, 'Markdown target escapes the repository.'))
        return
    if is_image:
        try:
            resolved.relative_to(image_root)
        except ValueError:
            issues.append(_issue('image-path', relative, 'Image target must be under assets/images.'))
            return
        if not resolved.is_file() or resolved.is_symlink():
            issues.append(_issue('image-missing', relative, 'Markdown image target is unavailable.'))
            return
    elif path_part and (not resolved.exists() or resolved.is_symlink()):
        issues.append(_issue('link-missing', relative, 'Local Markdown target is unavailable.'))
        return
    if fragment and resolved.suffix.casefold() == '.md':
        target_relative = _relative_path(root, resolved)
        if fragment not in anchors_by_path.get(target_relative, set()):
            issues.append(_issue('anchor-missing', relative, 'Markdown anchor target is unavailable.'))


def _validate_links(root: Path, markdown: dict[str, str], issues: list[ValidationIssue]) -> None:
    anchors_by_path = {path: set(_anchors(text)) for path, text in markdown.items()}
    image_root = (root / 'assets' / 'images').resolve(strict=False)
    for relative, text in sorted(markdown.items()):
        source = root / relative
        parsed = parse_markdown_targets(text)
        if parsed.duplicate_definition:
            issues.append(
                _issue(
                    'reference-definition-duplicate',
                    relative,
                    'Markdown document defines a reference label more than once.',
                ),
            )
        if parsed.missing_definition:
            issues.append(
                _issue(
                    'reference-definition-missing',
                    relative,
                    'Markdown reference definition is unavailable.',
                ),
            )
        for target in parsed.targets:
            _validate_markdown_target(
                root,
                source,
                relative,
                target.raw,
                target.is_image,
                image_root,
                anchors_by_path,
                issues,
            )


def _validate_answer_coverage(
    root: Path,
    config: BookConfig,
    issues: list[ValidationIssue],
) -> None:
    chapter_exercises: dict[str, set[tuple[str, str]]] = {}
    for chapter_relative in config.chapters:
        chapter_text = _read_text(root / chapter_relative)
        if chapter_text is None:
            continue
        exercises = set(EXERCISE_RE.findall(_content_without_fences(chapter_text)))
        for chapter_id, exercise in exercises:
            chapter_exercises.setdefault(chapter_id, set()).add((chapter_id, exercise))

    answer_sets: dict[str, set[tuple[str, str]]] = {}
    answer_owner: dict[str, str] = {}
    for answer_relative in config.answers:
        answer_text = _read_text(root / answer_relative)
        if answer_text is None:
            continue
        visible = _content_without_fences(answer_text)
        parsed = set(ANSWER_RE.findall(visible))
        answer_sets[answer_relative] = parsed
        for chapter_id, _exercise in parsed:
            answer_owner.setdefault(chapter_id, answer_relative)
        title = re.search(r'^#\s+Chapter\s+(\d{2})\b', visible, re.MULTILINE)
        if title is not None:
            answer_owner[title.group(1)] = answer_relative

    expected_tests = {'run-all.ps1'} | {
        f'ch-{chapter_id}.tests.ps1' for chapter_id in chapter_exercises
    }
    test_directory = root / 'tests'
    actual_tests = {
        path.name for path in test_directory.glob('*.ps1') if path.is_file() and not path.is_symlink()
    } if test_directory.is_dir() else set()
    for name in sorted(actual_tests - expected_tests):
        issues.append(_issue('test-unexpected', f'tests/{name}', 'Unmapped test file is present.'))

    all_answers = set().union(*answer_sets.values()) if answer_sets else set()
    for chapter_id, exercises in sorted(chapter_exercises.items()):
        answer_relative = answer_owner.get(chapter_id, 'book.json')
        test_relative = f'tests/ch-{chapter_id}.tests.ps1'
        test_path = root / test_relative
        test_text = _read_text(test_path)
        if test_text is None:
            issues.append(_issue('test-missing', test_relative, 'Chapter test mapping is missing.'))
        for _exercise in sorted(exercises - all_answers):
            issues.append(
                _issue('answer-exercise-missing', answer_relative, 'Answer coverage is incomplete.'),
            )
        if test_text is not None:
            tests = {(chapter_id, exercise) for exercise in TEST_RE.findall(test_text)}
            for _exercise in sorted(exercises - tests):
                issues.append(
                    _issue('test-exercise-missing', test_relative, 'Test coverage is incomplete.'),
                )
            for _exercise in sorted(tests - exercises):
                issues.append(
                    _issue('test-exercise-unexpected', test_relative, 'Test has no chapter exercise.'),
                )
    all_exercises = set().union(
        *chapter_exercises.values(),
    ) if chapter_exercises else set()
    for answer_relative, answers in sorted(answer_sets.items()):
        for _answer in sorted(answers - all_exercises):
            issues.append(
                _issue('answer-exercise-unexpected', answer_relative, 'Answer has no chapter exercise.'),
            )


def _text_candidates(root: Path) -> Iterable[tuple[str, str]]:
    for path in _repository_paths(root):
        relative = _relative_path(root, path)
        if path.suffix.casefold() not in TEXT_SUFFIXES and path.name not in TEXT_NAMES:
            continue
        text = _read_text(path)
        if text is not None:
            yield relative, text


def _is_repository_metadata(relative: str) -> bool:
    first = PurePosixPath(relative).parts[0]
    return first not in {'answers', 'appendices', 'chapters'}


def _validate_publication_policy(root: Path, issues: list[ValidationIssue]) -> None:
    for current, directory_names, _ in os.walk(root, followlinks=False):
        current_path = Path(current)
        for name in sorted(directory_names):
            path = current_path / name
            relative = _relative_path(root, path)
            if (
                path.is_symlink()
                or (name == '.git' and current_path != root)
                or _has_forbidden_suffix(name)
            ):
                issues.append(_issue('forbidden-file', relative, 'Forbidden repository path is present.'))
        relative_directory = current_path.relative_to(root)
        directory_names[:] = [
            name
            for name in directory_names
            if not _is_ignored(PurePosixPath(*(relative_directory.parts + (name,))))
        ]

    for path in _repository_paths(root):
        relative = _relative_path(root, path)
        if path.is_symlink():
            issues.append(_issue('forbidden-file', relative, 'Symbolic links are not allowed.'))
            continue
        if (
            path.name in FORBIDDEN_NAMES
            or relative in FORBIDDEN_PATHS
            or _has_forbidden_suffix(path.name)
        ):
            issues.append(_issue('forbidden-file', relative, 'Forbidden repository file is present.'))

    brand_folded = BRAND.casefold()
    credit_folded = CREATION_CREDIT.casefold()
    for relative, text in _text_candidates(root):
        folded = text.casefold()
        if any(marker in folded for marker in RUNTIME_MARKERS):
            issues.append(_issue('runtime-reference', relative, 'Private runtime reference is not allowed.'))
        search_from = 0
        while (brand_at := folded.find(brand_folded, search_from)) != -1:
            credit_at = brand_at - (len(credit_folded) - len(brand_folded))
            is_exact_credit = (
                credit_at >= 0
                and folded[credit_at:brand_at + len(brand_folded)] == credit_folded
                and (
                    brand_at + len(brand_folded) == len(folded)
                    or not folded[brand_at + len(brand_folded)].isalnum()
                )
            )
            if not is_exact_credit:
                issues.append(_issue('runtime-reference', relative, 'Unapproved branding reference is not allowed.'))
                break
            search_from = brand_at + len(brand_folded)
        if _is_repository_metadata(relative) and HOME_PATH_RE.search(text):
            issues.append(_issue('absolute-path', relative, 'Machine-local absolute path is not allowed.'))


def _validate_license(root: Path, issues: list[ValidationIssue]) -> None:
    license_path = root / 'LICENSE'
    text = _read_text(license_path)
    if text is None:
        issues.append(_issue('license-missing', 'LICENSE', 'Required license is unavailable.'))
    elif 'MIT License' not in text or 'Michel Abboud' not in text:
        issues.append(_issue('license-invalid', 'LICENSE', 'Required MIT license attribution is invalid.'))


def validate_repository(
    root: Path,
    manifest_path: Path | None = None,
) -> tuple[ValidationIssue, ...]:
    """Return deterministically sorted validation issues without mutating root."""
    issues: list[ValidationIssue] = []
    try:
        resolved_root = root.expanduser().resolve(strict=True)
    except OSError:
        return tuple(sorted((_issue('root-missing', '.', 'Repository root is unavailable.'),)))
    if not resolved_root.is_dir():
        return tuple(sorted((_issue('root-invalid', '.', 'Repository root is not a directory.'),)))

    if manifest_path is None:
        resolved_manifest = resolved_root / DEFAULT_DESTINATION_INVENTORY
    else:
        candidate = manifest_path if manifest_path.is_absolute() else resolved_root / manifest_path
        try:
            resolved_manifest = candidate.resolve(strict=False)
            resolved_manifest.relative_to(resolved_root)
        except (OSError, ValueError):
            issues.append(
                _issue('manifest-path', '<outside-repository>', 'Manifest must be inside the repository.'),
            )
            return tuple(sorted(issues))

    _validate_destination_inventory(resolved_root, resolved_manifest, issues)
    _validate_source_inventory(resolved_root, issues)
    config = _load_book_config(resolved_root, issues)
    if config is not None:
        _validate_declared_sources(resolved_root, config, issues)
        _validate_answer_coverage(resolved_root, config, issues)
    markdown = {
        relative: text
        for relative, text in _text_candidates(resolved_root)
        if relative.endswith('.md')
    }
    _validate_anchors(resolved_root, markdown, issues)
    _validate_links(resolved_root, markdown, issues)
    _validate_publication_policy(resolved_root, issues)
    _validate_license(resolved_root, issues)
    return tuple(sorted(issues))


def main(argv: list[str] | None = None) -> int:
    """Print one issue per line and return 0 when valid, otherwise 1."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        'root',
        nargs='?',
        type=Path,
        default=Path(__file__).resolve().parents[1],
        help='repository root (defaults to the validator parent repository)',
    )
    parser.add_argument('--manifest', type=Path, help='destination inventory path override')
    arguments = parser.parse_args(argv)
    issues = validate_repository(arguments.root, arguments.manifest)
    for issue in issues:
        print(_serialize_issue(issue))
    return 1 if issues else 0


if __name__ == '__main__':
    raise SystemExit(main())
