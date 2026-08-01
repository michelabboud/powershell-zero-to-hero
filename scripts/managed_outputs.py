#!/usr/bin/env python3
"""Fail-closed helpers for ignored, repository-local build outputs."""

from __future__ import annotations

import os
from pathlib import Path, PurePosixPath


class ManagedPathError(ValueError):
    """A managed output path is unsafe to access."""


def _display(root: Path, path: Path) -> str:
    try:
        return path.relative_to(root).as_posix()
    except ValueError:
        return '<outside-repository>'


def validate_managed_tree(root: Path, directory: str) -> Path:
    """Validate one managed tree without creating or mutating it."""
    repository = root.resolve(strict=True)
    if root.is_symlink() or not repository.is_dir():
        raise ManagedPathError('repository root must be a non-symlink directory')
    candidate = root / directory
    if candidate.is_symlink():
        raise ManagedPathError(
            f'managed output path must not contain symlinks: {directory}',
        )
    if candidate.exists() and not candidate.is_dir():
        raise ManagedPathError(f'managed output root must be a directory: {directory}')
    if not candidate.exists():
        return candidate
    try:
        candidate.resolve(strict=True).relative_to(repository)
    except (OSError, ValueError):
        raise ManagedPathError(
            f'managed output path escapes the repository: {directory}',
        ) from None
    for current, directories, files in os.walk(candidate, followlinks=False):
        current_path = Path(current)
        for name in (*directories, *files):
            path = current_path / name
            if path.is_symlink():
                raise ManagedPathError(
                    'managed output path must not contain symlinks: '
                    f'{_display(root, path)}',
                )
    return candidate


def prepare_managed_roots(root: Path, *directories: str) -> tuple[Path, ...]:
    """Preflight every root before creating any of them."""
    roots = tuple(validate_managed_tree(root, directory) for directory in directories)
    for managed_root in roots:
        managed_root.mkdir(parents=False, exist_ok=True)
    return roots


def reset_managed_roots(root: Path, *directories: str) -> tuple[Path, ...]:
    """Remove all stale contents after a complete fail-closed preflight."""
    roots = tuple(validate_managed_tree(root, directory) for directory in directories)
    for managed_root in roots:
        if managed_root.exists():
            for current, child_directories, files in os.walk(
                managed_root,
                topdown=False,
                followlinks=False,
            ):
                current_path = Path(current)
                for name in files:
                    (current_path / name).unlink()
                for name in child_directories:
                    (current_path / name).rmdir()
        else:
            managed_root.mkdir(parents=False)
    return roots


def managed_path(root: Path, directory: str, relative: str) -> Path:
    """Resolve a portable relative path beneath a validated managed root."""
    pure = PurePosixPath(relative)
    if (
        not relative
        or pure.is_absolute()
        or '..' in pure.parts
        or '\\' in relative
    ):
        raise ManagedPathError(f'managed output path is invalid: {relative!r}')
    managed_root = validate_managed_tree(root, directory)
    destination = managed_root.joinpath(*pure.parts)
    current = managed_root
    for part in pure.parts[:-1]:
        current /= part
        if current.is_symlink():
            raise ManagedPathError(
                'managed output path must not contain symlinks: '
                f'{_display(root, current)}',
            )
        if current.exists() and not current.is_dir():
            raise ManagedPathError(
                f'managed output parent must be a directory: {_display(root, current)}',
            )
    return destination
