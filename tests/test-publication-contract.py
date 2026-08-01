#!/usr/bin/env python3
"""Regression checks for the public extraction and build contracts."""

from __future__ import annotations

import hashlib
import json
import shutil
import subprocess
import sys
import unittest
from datetime import datetime
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SOURCE_INVENTORY = ROOT / 'docs' / 'source-inventory.json'
DESTINATION_INVENTORY = ROOT / 'docs' / 'destination-inventory.json'
INVENTORY_EXCLUSIONS = {
    'docs/destination-inventory.json',
    'docs/source-inventory.json',
}
FLOW_MARKER = 'PUBLICATION PIPELINE FLOW PROBE 7B3A9C'


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def load_inventory(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding='utf-8'))


class InventoryContractTests(unittest.TestCase):
    def assert_file_entries_are_well_formed(
        self,
        entries: list[dict[str, Any]],
    ) -> None:
        paths = [entry['path'] for entry in entries]
        self.assertEqual(paths, sorted(paths))
        self.assertEqual(len(paths), len(set(paths)))
        for entry in entries:
            self.assertEqual(set(entry), {'path', 'bytes', 'sha256'})
            self.assertIsInstance(entry['path'], str)
            self.assertIsInstance(entry['bytes'], int)
            self.assertGreaterEqual(entry['bytes'], 0)
            self.assertRegex(entry['sha256'], r'^[0-9a-f]{64}$')

    def test_source_inventory_preserves_original_capture(self) -> None:
        data = load_inventory(SOURCE_INVENTORY)
        self.assertEqual(
            set(data),
            {
                'schemaVersion',
                'sourceDescriptor',
                'sourceCommit',
                'capturedAt',
                'files',
            },
        )
        self.assertEqual(data['schemaVersion'], 1)
        entries = {entry['path']: entry for entry in data['files']}

        self.assertEqual(data['sourceDescriptor'], 'private-guide-working-tree')
        self.assertRegex(data['sourceCommit'], r'^[0-9a-f]{40}$')
        datetime.fromisoformat(data['capturedAt'].replace('Z', '+00:00'))
        self.assert_file_entries_are_well_formed(data['files'])
        self.assertEqual(len(entries), 199)
        self.assertEqual(sum(entry['bytes'] for entry in entries.values()), 66_997_018)
        self.assertEqual(
            {
                path: (entries[path]['bytes'], entries[path]['sha256'])
                for path in (
                    'README.md',
                    'assets/body.typ',
                    'assets/build-book.py',
                    'chapters/16-automation-recipes.md',
                )
            },
            {
                'README.md': (
                    845,
                    '18f5538d9c12f229accfc16309bac71b4ceac802f092d2fb79131b9f2f50f3db',
                ),
                'assets/body.typ': (
                    345_949,
                    '85145120473f09f7b309446aeb3bbe5859b2abe2166e37607a99ed7b63f0f943',
                ),
                'assets/build-book.py': (
                    2_510,
                    '74552b3591c388babba4cad6d1e1e46c0ccbaf92248ce2bc4cf1a67339774de7',
                ),
                'chapters/16-automation-recipes.md': (
                    21_204,
                    'ce67c3f4a9a4f6f226b476aaa66189b2f2f71952f685335db71b0c808994a14e',
                ),
            },
        )

    def test_destination_inventory_covers_tracked_public_files(self) -> None:
        data = load_inventory(DESTINATION_INVENTORY)
        self.assertEqual(
            set(data),
            {
                'schemaVersion',
                'destinationDescriptor',
                'capturedAt',
                'excludedPaths',
                'files',
            },
        )
        self.assertEqual(data['schemaVersion'], 1)
        self.assertEqual(data['destinationDescriptor'], 'public-standalone-working-tree')
        datetime.fromisoformat(data['capturedAt'].replace('Z', '+00:00'))
        self.assertEqual(set(data['excludedPaths']), INVENTORY_EXCLUSIONS)

        entries = data['files']
        self.assert_file_entries_are_well_formed(entries)
        paths = [entry['path'] for entry in entries]

        tracked = subprocess.check_output(
            ['git', 'ls-files', '-z'],
            cwd=ROOT,
        ).decode().split('\0')
        expected = sorted(
            path for path in tracked if path and path not in INVENTORY_EXCLUSIONS
        )
        self.assertEqual(paths, expected)

        for entry in entries:
            path = ROOT / entry['path']
            self.assertEqual(path.stat().st_size, entry['bytes'], entry['path'])
            self.assertEqual(sha256(path), entry['sha256'], entry['path'])


class BuildPipelineTests(unittest.TestCase):
    def test_readme_documents_connected_markdown_to_pdf_pipeline(self) -> None:
        readme = (ROOT / 'README.md').read_text(encoding='utf-8')
        self.assertIn('python3 scripts/build_book.py --check', readme)
        self.assertIn('python3 scripts/build_book.py --edition all --format all', readme)
        self.assertNotIn('python3 assets/build-book.py', readme)
        self.assertNotIn('typst compile assets/body.typ', readme)

    def test_pipeline_propagates_chapter_edits_and_author_metadata(self) -> None:
        required_tools = ('pandoc', 'typst', 'pdfinfo', 'pdftotext')
        missing = [tool for tool in required_tools if shutil.which(tool) is None]
        self.assertFalse(missing, f'missing build tools: {missing}')

        chapter = ROOT / 'chapters' / '00-preface.md'
        markdown = ROOT / 'build' / 'main.md'
        typst_body = ROOT / 'build' / 'main-body.typ'
        pdf = ROOT / 'dist' / 'powershell-zero-to-hero.pdf'
        historical_pdf = ROOT / 'powershell-zero-to-hero.pdf'
        source_inventory = load_inventory(SOURCE_INVENTORY)
        historical_entry = next(
            entry
            for entry in source_inventory['files']
            if entry['path'] == 'powershell-zero-to-hero.pdf'
        )
        historical_before = sha256(historical_pdf)
        original = chapter.read_text(encoding='utf-8')

        try:
            chapter.write_text(f'{original}\n\n{FLOW_MARKER}\n', encoding='utf-8')
            subprocess.run(
                [
                    sys.executable,
                    'scripts/build_book.py',
                    '--edition',
                    'main',
                    '--format',
                    'pdf',
                ],
                cwd=ROOT,
                check=True,
                stdout=subprocess.DEVNULL,
            )

            typst_text = typst_body.read_text(encoding='utf-8')
            pdf_info = subprocess.check_output(
                ['pdfinfo', pdf],
                text=True,
                stderr=subprocess.DEVNULL,
            )
            pdf_text = subprocess.check_output(['pdftotext', pdf, '-'], text=True)

            self.assertIn(FLOW_MARKER, typst_text)
            self.assertIn(FLOW_MARKER, pdf_text)
            self.assertIn('Author:          Michel Abboud', pdf_info)
            self.assertEqual(pdf_text.count('Created by Visual Forge'), 1)
            self.assertEqual(historical_before, historical_entry['sha256'])
            self.assertEqual(sha256(historical_pdf), historical_before)
        finally:
            chapter.write_text(original, encoding='utf-8')
            markdown.unlink(missing_ok=True)
            typst_body.unlink(missing_ok=True)
            pdf.unlink(missing_ok=True)


if __name__ == '__main__':
    unittest.main()
