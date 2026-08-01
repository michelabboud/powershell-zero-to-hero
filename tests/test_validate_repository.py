#!/usr/bin/env python3
"""Behavior tests for the standalone repository validator."""

from __future__ import annotations

import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
VALIDATOR = ROOT / 'scripts' / 'validate_repository.py'
INVENTORY_EXCLUSIONS = {
    'docs/destination-inventory.json',
    'docs/source-inventory.json',
}
CHAPTERS = (
    '00-preface.md',
    '01-what-is-powershell.md',
    '02-the-console.md',
    '03-commands-and-cmdlets.md',
    '04-variables-and-types.md',
    '05-operators-and-expressions.md',
    '06-control-flow.md',
    '07-functions-and-scripts.md',
    '08-the-pipeline-deep-dive.md',
    '09-working-with-files.md',
    '10-error-handling.md',
    '11-regex-and-text.md',
    '12-modules-and-packages.md',
    '13-objects-and-dotnet.md',
    '14-remote-and-jobs.md',
    '15-active-directory.md',
    '16-automation-recipes.md',
    '17-devops-and-cicd.md',
)
APPENDICES = (
    'A-cheat-sheet.md',
    'B-common-errors.md',
    'C-from-bash-to-powershell.md',
)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def file_entry(root: Path, path: Path) -> dict[str, Any]:
    return {
        'path': path.relative_to(root).as_posix(),
        'bytes': path.stat().st_size,
        'sha256': sha256(path),
    }


class RepositoryFixture:
    """Create a minimal repository satisfying every validation contract."""

    def __init__(self, root: Path) -> None:
        self.root = root
        self._write_sources()
        self.refresh_destination_inventory()

    def _write(self, relative: str, content: str | bytes) -> Path:
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(content, bytes):
            path.write_bytes(content)
        else:
            path.write_text(content, encoding='utf-8')
        return path

    def _write_sources(self) -> None:
        self._write('README.md', '# Guide\n\n[License](LICENSE)\n')
        self._write('LICENSE', 'MIT License\n\nCopyright (c) 2026 Michel Abboud\n')
        self._write('VERSION', '1.1.0\n')
        self._write('assets/images/example.png', b'fixture image')
        pdf = self._write('powershell-zero-to-hero.pdf', b'historical pdf')

        for number, name in enumerate(CHAPTERS):
            heading = 'Preface' if number == 0 else f'Chapter {number:02d}'
            exercise = ''
            if number:
                exercise = (
                    f'\n## Exercises\n\n'
                    f'### [Ch-{number:02d}, Ex-1] Exercise\n\n'
                    'Complete the exercise.\n'
                )
            image = (
                '\n![Example](assets/images/example.png)\n'
                if number == 1
                else ''
            )
            self._write(
                f'chapters/{name}',
                f'# {heading}\n{exercise}{image}',
            )

        for name in APPENDICES:
            self._write(f'appendices/{name}', f'# Appendix {name[0]}\n')

        self._write(
            'answers/00-how-to-use-answers.md',
            '# How to Use the Answers\n',
        )
        for number in range(1, 18):
            self._write(
                f'answers/{number:02d}-answers.md',
                (
                    f'# Chapter {number:02d} -- Answers\n\n'
                    f'## Ch-{number:02d}, Ex-1 (Simple)\n'
                ),
            )
            self._write(
                f'tests/ch-{number:02d}.tests.ps1',
                (
                    f'Describe "Chapter {number:02d}" {{\n'
                    '    It "Ex-1: works" { $true | Should -BeTrue }\n'
                    '}\n'
                ),
            )
        self._write('tests/run-all.ps1', '# Run the chapter tests.\n')

        source_inventory = {
            'schemaVersion': 1,
            'sourceDescriptor': 'private-guide-working-tree',
            'sourceCommit': 'a' * 40,
            'capturedAt': '2026-08-01T00:00:00Z',
            'files': [file_entry(self.root, pdf)],
        }
        self._write(
            'docs/source-inventory.json',
            json.dumps(source_inventory, indent=2) + '\n',
        )

    def refresh_destination_inventory(self, relative: str = 'docs/destination-inventory.json') -> Path:
        files = sorted(
            (
                path
                for path in self.root.rglob('*')
                if path.is_file()
                and path.relative_to(self.root).as_posix() not in INVENTORY_EXCLUSIONS
            ),
            key=lambda path: path.relative_to(self.root).as_posix(),
        )
        inventory = {
            'schemaVersion': 1,
            'destinationDescriptor': 'public-standalone-working-tree',
            'capturedAt': '2026-08-01T00:00:00Z',
            'excludedPaths': sorted(INVENTORY_EXCLUSIONS),
            'files': [file_entry(self.root, path) for path in files],
        }
        return self._write(relative, json.dumps(inventory, indent=2) + '\n')


class ValidatorTests(unittest.TestCase):
    _temporary_directory: tempfile.TemporaryDirectory[str] | None = None
    _fixture: RepositoryFixture | None = None

    @property
    def fixture(self) -> RepositoryFixture:
        if self._fixture is None:
            raise RuntimeError('test fixture is not initialized')
        return self._fixture

    def setUp(self) -> None:
        temporary_directory = tempfile.TemporaryDirectory()
        self._temporary_directory = temporary_directory
        self.addCleanup(temporary_directory.cleanup)
        self._fixture = RepositoryFixture(Path(temporary_directory.name))

    def run_validator(self, *extra: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [sys.executable, str(VALIDATOR), str(self.fixture.root), *extra],
            text=True,
            capture_output=True,
            check=False,
        )

    def assert_issue(
        self,
        result: subprocess.CompletedProcess[str],
        code: str,
        path: str,
    ) -> None:
        prefix = f'{code}|{path}|'
        self.assertTrue(
            any(line.startswith(prefix) for line in result.stdout.splitlines()),
            f'missing diagnostic {prefix!r}; stdout={result.stdout!r}; stderr={result.stderr!r}',
        )
        self.assertEqual(result.returncode, 1)

    def test_valid_repository_returns_success_without_mutation(self) -> None:
        before = sorted(
            (path.relative_to(self.fixture.root).as_posix(), sha256(path))
            for path in self.fixture.root.rglob('*')
            if path.is_file()
        )

        result = self.run_validator()

        after = sorted(
            (path.relative_to(self.fixture.root).as_posix(), sha256(path))
            for path in self.fixture.root.rglob('*')
            if path.is_file()
        )
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout, '')
        self.assertEqual(before, after)

    def test_ignores_generated_tool_cache_directories(self) -> None:
        cache = self.fixture.root / '.ruff_cache' / 'CACHEDIR.TAG'
        cache.parent.mkdir(parents=True)
        cache.write_text('generated cache', encoding='utf-8')

        result = self.run_validator()

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_reports_missing_chapter(self) -> None:
        missing = 'chapters/05-operators-and-expressions.md'
        (self.fixture.root / missing).unlink()

        result = self.run_validator()

        self.assert_issue(result, 'chapter-missing', missing)

    def test_reports_missing_appendix(self) -> None:
        missing = 'appendices/B-common-errors.md'
        (self.fixture.root / missing).unlink()

        result = self.run_validator()

        self.assert_issue(result, 'appendix-missing', missing)

    def test_reports_broken_markdown_image_link(self) -> None:
        chapter = self.fixture.root / 'chapters/01-what-is-powershell.md'
        chapter.write_text(
            chapter.read_text(encoding='utf-8').replace(
                'assets/images/example.png',
                'assets/images/missing.png',
            ),
            encoding='utf-8',
        )

        result = self.run_validator()

        self.assert_issue(result, 'image-missing', 'chapters/01-what-is-powershell.md')

    def test_rejects_escaping_image_path_without_reading_it(self) -> None:
        chapter = self.fixture.root / 'chapters/01-what-is-powershell.md'
        chapter.write_text(
            chapter.read_text(encoding='utf-8').replace(
                'assets/images/example.png',
                '../../../outside.png',
            ),
            encoding='utf-8',
        )

        result = self.run_validator()

        self.assert_issue(result, 'path-escape', 'chapters/01-what-is-powershell.md')

    def test_reports_broken_local_link_without_echoing_target(self) -> None:
        marker = 'sensitive-missing-target'
        readme = self.fixture.root / 'README.md'
        readme.write_text(
            readme.read_text(encoding='utf-8') + f'\n[Private]({marker}.md)\n',
            encoding='utf-8',
        )

        result = self.run_validator()

        self.assert_issue(result, 'link-missing', 'README.md')
        self.assertNotIn(marker, result.stdout)
        self.assertNotIn(marker, result.stderr)

    def test_reports_duplicate_heading_anchor(self) -> None:
        chapter = self.fixture.root / 'chapters/03-commands-and-cmdlets.md'
        chapter.write_text(
            chapter.read_text(encoding='utf-8') + '\n## Repeated\n\n## Repeated\n',
            encoding='utf-8',
        )

        result = self.run_validator()

        self.assert_issue(result, 'anchor-duplicate', 'chapters/03-commands-and-cmdlets.md')

    def test_allows_repeated_nested_answer_headings(self) -> None:
        answer = self.fixture.root / 'answers/03-answers.md'
        answer.write_text(
            answer.read_text(encoding='utf-8') + '\n### Solution\n\n### Solution\n',
            encoding='utf-8',
        )
        self.fixture.refresh_destination_inventory()

        result = self.run_validator()

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_reports_missing_answer_and_test_mappings(self) -> None:
        answer = 'answers/07-answers.md'
        test = 'tests/ch-11.tests.ps1'
        (self.fixture.root / answer).unlink()
        (self.fixture.root / test).unlink()

        result = self.run_validator()

        self.assert_issue(result, 'answer-missing', answer)
        self.assert_issue(result, 'test-missing', test)

    def test_reports_forbidden_file(self) -> None:
        suffix = '.' + 'vf' + '-' + 'bak'
        forbidden = f'assets/legacy{suffix}'
        path = self.fixture.root / forbidden
        path.write_text('not inspected', encoding='utf-8')

        result = self.run_validator()

        self.assert_issue(result, 'forbidden-file', forbidden)

    def test_reports_nested_repository_metadata(self) -> None:
        forbidden = 'assets/vendor/.git'
        metadata = self.fixture.root / forbidden / 'HEAD'
        metadata.parent.mkdir(parents=True, exist_ok=True)
        metadata.write_text('ref only', encoding='utf-8')

        result = self.run_validator()

        self.assert_issue(result, 'forbidden-file', forbidden)

    def test_reports_machine_local_absolute_path_without_echoing_it(self) -> None:
        home_path = '/' + 'home' + '/someone/private-guide'
        readme = self.fixture.root / 'README.md'
        readme.write_text(
            readme.read_text(encoding='utf-8') + f'\nPrivate source: {home_path}\n',
            encoding='utf-8',
        )

        result = self.run_validator()

        self.assert_issue(result, 'absolute-path', 'README.md')
        self.assertNotIn(home_path, result.stdout)
        self.assertNotIn(home_path, result.stderr)

    def test_validator_policy_source_does_not_trigger_its_own_scan(self) -> None:
        policy = self.fixture.root / 'scripts/validate_repository.py'
        policy.parent.mkdir(parents=True, exist_ok=True)
        policy.write_text(VALIDATOR.read_text(encoding='utf-8'), encoding='utf-8')
        self.fixture.refresh_destination_inventory()

        result = self.run_validator()

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_reports_runtime_reference_but_allows_exact_creation_credit(self) -> None:
        brand = 'Visual' + ' Forge'
        runtime_name = '-'.join(('visual', 'forge', 'mcp'))
        readme = self.fixture.root / 'README.md'
        readme.write_text(
            (
                readme.read_text(encoding='utf-8')
                + f'\nCreated by {brand}\n'
                + f'\nRuntime: {runtime_name}\n'
            ),
            encoding='utf-8',
        )

        result = self.run_validator()

        self.assert_issue(result, 'runtime-reference', 'README.md')
        self.assertNotIn(runtime_name, result.stdout)
        self.assertNotIn(runtime_name, result.stderr)

    def test_reports_missing_license(self) -> None:
        (self.fixture.root / 'LICENSE').unlink()

        result = self.run_validator()

        self.assert_issue(result, 'license-missing', 'LICENSE')

    def test_reports_altered_historical_pdf_hash(self) -> None:
        pdf = self.fixture.root / 'powershell-zero-to-hero.pdf'
        pdf.write_bytes(b'altered historical pdf')

        result = self.run_validator()

        self.assert_issue(result, 'historical-pdf-hash', 'powershell-zero-to-hero.pdf')

    def test_reports_current_file_hash_drift_from_destination_inventory(self) -> None:
        readme = self.fixture.root / 'README.md'
        readme.write_text('# Changed\n', encoding='utf-8')

        result = self.run_validator()

        self.assert_issue(result, 'inventory-hash', 'README.md')

    def test_rejects_destination_inventory_with_extra_self_exclusion(self) -> None:
        manifest = self.fixture.root / 'docs/destination-inventory.json'
        data = json.loads(manifest.read_text(encoding='utf-8'))
        data['excludedPaths'].append('README.md')
        data['excludedPaths'].sort()
        manifest.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')

        result = self.run_validator()

        self.assert_issue(result, 'inventory-invalid', 'docs/destination-inventory.json')

    def test_manifest_override_and_public_api_return_sorted_tuple(self) -> None:
        default_manifest = self.fixture.root / 'docs/destination-inventory.json'
        custom_manifest = self.fixture.root / 'docs/custom-inventory.json'
        default_manifest.rename(custom_manifest)
        data = json.loads(custom_manifest.read_text(encoding='utf-8'))
        data['excludedPaths'] = sorted(
            {'docs/source-inventory.json', 'docs/custom-inventory.json'},
        )
        custom_manifest.write_text(json.dumps(data, indent=2) + '\n', encoding='utf-8')

        probe = (
            'import importlib.util, pathlib, sys; '
            'module_path, root, manifest = map(pathlib.Path, sys.argv[1:]); '
            'spec = importlib.util.spec_from_file_location("repository_validator", module_path); '
            'module = importlib.util.module_from_spec(spec); '
            'sys.modules[spec.name] = module; '
            'spec.loader.exec_module(module); '
            'issues = module.validate_repository(root, manifest); '
            'assert isinstance(issues, tuple); '
            'assert issues == tuple(sorted(issues)); '
            'assert module.ValidationIssue.__dataclass_params__.frozen'
        )
        result = subprocess.run(
            [
                sys.executable,
                '-c',
                probe,
                str(VALIDATOR),
                str(self.fixture.root),
                str(custom_manifest),
            ],
            text=True,
            capture_output=True,
            check=False,
        )

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_repository_chapter_navigation_uses_current_targets(self) -> None:
        targets = {
            '04-variables-and-types.md': '05-operators-and-expressions.md',
            '06-control-flow.md': '07-functions-and-scripts.md',
            '07-functions-and-scripts.md': '08-the-pipeline-deep-dive.md',
            '08-the-pipeline-deep-dive.md': '09-working-with-files.md',
            '09-working-with-files.md': '10-error-handling.md',
            '10-error-handling.md': '11-regex-and-text.md',
            '11-regex-and-text.md': '12-modules-and-packages.md',
            '12-modules-and-packages.md': '13-objects-and-dotnet.md',
            '13-objects-and-dotnet.md': '14-remote-and-jobs.md',
            '14-remote-and-jobs.md': '15-active-directory.md',
            '16-automation-recipes.md': '17-devops-and-cicd.md',
            '17-devops-and-cicd.md': '../appendices/A-cheat-sheet.md',
        }
        for source, target in targets.items():
            with self.subTest(source=source):
                text = (ROOT / 'chapters' / source).read_text(encoding='utf-8')
                self.assertIn(f']({target})', text)

    def test_readme_documents_standalone_validation_command(self) -> None:
        readme = (ROOT / 'README.md').read_text(encoding='utf-8')

        self.assertIn('python3 scripts/validate_repository.py', readme)


if __name__ == '__main__':
    unittest.main()
