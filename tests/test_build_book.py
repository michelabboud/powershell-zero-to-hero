#!/usr/bin/env python3
"""Behavior tests for the reproducible standalone book build."""

from __future__ import annotations

import hashlib
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import ModuleType
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
ASSEMBLER = ROOT / 'scripts' / 'assemble_book.py'
BUILDER = ROOT / 'scripts' / 'build_book.py'


def write_build_fixture(
    root: Path,
    *,
    chapter_markdown: str = '# Chapter\n',
    main_output: str = 'fixture-main',
    answers_output: str = 'fixture-answers',
) -> dict[str, object]:
    """Write the smallest complete manifest-backed build fixture."""
    manifest: dict[str, object] = {
        'title': 'Fixture Book',
        'author': 'Michel Abboud',
        'version': '1.1.0',
        'credit': 'Created by Visual Forge',
        'creationTimestamp': 1785542400,
        'chapters': ['chapters/01.md'],
        'appendices': ['appendices/A.md'],
        'answers': ['answers/01.md'],
        'editions': {
            'main': {
                'title': 'Fixture Book',
                'output': main_output,
                'frontCover': 'assets/images/front.webp',
                'backCover': 'assets/images/back.webp',
            },
            'answers': {
                'title': 'Fixture Answers',
                'output': answers_output,
                'frontCover': 'assets/images/front.webp',
                'backCover': 'assets/images/back.webp',
            },
        },
    }
    files: dict[str, str | bytes] = {
        'book.json': json.dumps(manifest),
        'VERSION': '1.1.0\n',
        'chapters/01.md': chapter_markdown,
        'appendices/A.md': '# Appendix\n',
        'answers/01.md': '# Answers\n',
        'assets/images/front.webp': b'front cover',
        'assets/images/back.webp': b'back cover',
        'powershell-zero-to-hero.typ': '#let placeholder = none\n',
        'book/template.typ': '#let placeholder = none\n',
    }
    for relative, content in files.items():
        path = root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(content, bytes):
            path.write_bytes(content)
        else:
            path.write_text(content, encoding='utf-8')
    return manifest


def load_module(name: str, path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f'cannot load module from {path}')
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    sys.path.insert(0, str(path.parent))
    try:
        spec.loader.exec_module(module)
    finally:
        sys.path.pop(0)
    return module


class AssembleBookTests(unittest.TestCase):
    def test_repository_relative_main_assembly_follows_manifest_order(self) -> None:
        self.assertTrue(ASSEMBLER.is_file(), 'assemble_book.py must exist')
        module = load_module('assemble_book_order_test', ASSEMBLER)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            sources = {
                'chapters/02.md': '# Chapter Two\n\nSecond.\n',
                'chapters/01.md': '# Chapter One\n\nFirst.\n',
                'appendices/B.md': '# Appendix B\n',
                'answers/01.md': '# Answers\n',
            }
            for relative, content in sources.items():
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding='utf-8')
            config = module.BookConfig(
                title='Fixture',
                author='Author',
                version='1.0.0',
                credit='Created by Visual Forge',
                chapters=('chapters/02.md', 'chapters/01.md'),
                appendices=('appendices/B.md',),
                answers=('answers/01.md',),
            )

            result = module.assemble(root, config, 'main')

            self.assertEqual(
                result,
                (
                    '# Chapter Two\n\nSecond.\n\n'
                    '\\newpage\n\n'
                    '# Chapter One\n\nFirst.\n\n'
                    '\\newpage\n\n'
                    '# Appendix B\n'
                ),
            )

    def test_answer_edition_appends_answers_after_main_sources(self) -> None:
        module = load_module('assemble_book_answers_test', ASSEMBLER)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            sources = {
                'chapters/01.md': '# Chapter\n',
                'appendices/A.md': '# Appendix\n',
                'answers/00.md': '# Answer Guide\n',
                'answers/01.md': '# Answers\n',
            }
            for relative, content in sources.items():
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(content, encoding='utf-8')
            config = module.BookConfig(
                title='Fixture',
                author='Author',
                version='1.0.0',
                credit='Created by Visual Forge',
                chapters=('chapters/01.md',),
                appendices=('appendices/A.md',),
                answers=('answers/00.md', 'answers/01.md'),
            )

            main = module.assemble(root, config, 'main')
            answers = module.assemble(root, config, 'answers')

            self.assertNotIn('# Answer Guide', main)
            self.assertEqual(
                answers,
                (
                    '# Chapter\n\n\\newpage\n\n'
                    '# Appendix\n\n\\newpage\n\n'
                    '# Answer Guide\n\n\\newpage\n\n'
                    '# Answers\n'
                ),
            )

    def test_missing_source_fails_with_repository_relative_path(self) -> None:
        module = load_module('assemble_book_missing_test', ASSEMBLER)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            config = module.BookConfig(
                title='Fixture',
                author='Author',
                version='1.0.0',
                credit='Created by Visual Forge',
                chapters=('chapters/missing.md',),
                appendices=(),
                answers=(),
            )

            with self.assertRaisesRegex(
                FileNotFoundError,
                r'^missing source file: chapters/missing\.md$',
            ):
                module.assemble(root, config, 'main')

    def test_generated_markdown_is_deterministic_and_stays_under_build(self) -> None:
        module = load_module('assemble_book_write_test', ASSEMBLER)
        self.assertTrue(hasattr(module, 'write_edition'), 'write_edition must exist')
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            chapter = root / 'chapters' / '01.md'
            chapter.parent.mkdir(parents=True)
            chapter.write_text('# Chapter\n', encoding='utf-8')
            config = module.BookConfig(
                title='Fixture',
                author='Author',
                version='1.0.0',
                credit='Created by Visual Forge',
                chapters=('chapters/01.md',),
                appendices=(),
                answers=(),
            )

            first = module.write_edition(root, config, 'main')
            first_hash = hashlib.sha256(first.read_bytes()).hexdigest()
            second = module.write_edition(root, config, 'main')
            second_hash = hashlib.sha256(second.read_bytes()).hexdigest()

            self.assertEqual(first, root / 'build' / 'main.md')
            self.assertEqual(second, first)
            self.assertEqual(first_hash, second_hash)
            self.assertEqual(first.read_text(encoding='utf-8'), '# Chapter\n')

    def test_cli_emits_both_manifest_editions_under_build(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            write_build_fixture(root)
            outputs = (root / 'build' / 'main.md', root / 'build' / 'answers.md')
            probe = (
                'from pathlib import Path; import sys; '
                'sys.path.insert(0, sys.argv[1]); '
                'import assemble_book; '
                'raise SystemExit(assemble_book.main(["--edition", "all"], root=Path(sys.argv[2])))'
            )
            result = subprocess.run(
                [
                    sys.executable,
                    '-c',
                    probe,
                    str(ROOT / 'scripts'),
                    str(root),
                ],
                cwd=root,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertTrue(all(output.is_file() for output in outputs))
            self.assertEqual(
                result.stdout.splitlines(),
                ['build/answers.md', 'build/main.md'],
            )


class BuildBookTests(unittest.TestCase):
    def test_missing_tool_failure_names_tool_and_install_action(self) -> None:
        self.assertTrue(BUILDER.is_file(), 'build_book.py must exist')
        module = load_module('build_book_missing_tool_test', BUILDER)
        with mock.patch.object(module.shutil, 'which', return_value=None):
            with self.assertRaisesRegex(
                module.BuildError,
                r"Required build tool 'pandoc' was not found on PATH\. Install Pandoc 3\.1\+ and retry\.",
            ):
                module.check_tools()

    def test_run_checked_executes_in_requested_repository_root(self) -> None:
        module = load_module('build_book_run_checked_test', BUILDER)
        self.assertTrue(hasattr(module, 'run_checked'), 'run_checked must exist')
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)

            module.run_checked(
                [
                    sys.executable,
                    '-c',
                    "from pathlib import Path; Path('probe.txt').write_text('ok', encoding='utf-8')",
                ],
                root,
            )

            self.assertEqual((root / 'probe.txt').read_text(encoding='utf-8'), 'ok')

    def test_typst_image_rewrite_handles_current_pandoc_wrappers(self) -> None:
        module = load_module('build_book_typst_image_rewrite_test', BUILDER)
        with tempfile.TemporaryDirectory() as temporary_directory:
            body = Path(temporary_directory) / 'main-body.typ'
            body.write_text(
                '#box(image("assets/images/wrapped.png", alt: "wrapped"))\n'
                '#image("assets/images/direct.png")\n',
                encoding='utf-8',
            )

            module._rewrite_typst_body(body)

            rewritten = body.read_text(encoding='utf-8')
            self.assertIn('image("../assets/images/wrapped.png"', rewritten)
            self.assertIn('image("../assets/images/direct.png"', rewritten)
            self.assertNotIn('image("assets/images/', rewritten)

    def test_manifest_is_the_only_edition_and_output_metadata_source(self) -> None:
        module = load_module('build_book_manifest_test', BUILDER)
        self.assertTrue(hasattr(module, 'load_manifest'), 'load_manifest must exist')
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            manifest = {
                'title': 'Fixture Book',
                'author': 'Michel Abboud',
                'version': '1.1.0',
                'credit': 'Created by Visual Forge',
                'creationTimestamp': 1785542400,
                'chapters': ['chapters/01.md'],
                'appendices': ['appendices/A.md'],
                'answers': ['answers/01.md'],
                'editions': {
                    'main': {
                        'title': 'Fixture Book',
                        'output': 'fixture-main',
                        'frontCover': 'assets/images/front.webp',
                        'backCover': 'assets/images/back.webp',
                    },
                    'answers': {
                        'title': 'Fixture Answers',
                        'output': 'fixture-answers',
                        'frontCover': 'assets/images/front.webp',
                        'backCover': 'assets/images/back.webp',
                    },
                },
            }
            (root / 'book.json').write_text(
                json.dumps(manifest),
                encoding='utf-8',
            )
            (root / 'VERSION').write_text('1.1.0\n', encoding='utf-8')
            for relative in ('chapters/01.md', 'appendices/A.md', 'answers/01.md'):
                source = root / relative
                source.parent.mkdir(parents=True, exist_ok=True)
                source.write_text('# Fixture\n', encoding='utf-8')

            loaded = module.load_manifest(root)

            self.assertEqual(loaded.book.title, 'Fixture Book')
            self.assertEqual(loaded.book.author, 'Michel Abboud')
            self.assertEqual(loaded.book.version, '1.1.0')
            self.assertEqual(getattr(loaded, 'creation_timestamp', None), 1785542400)
            self.assertEqual(loaded.edition('answers').title, 'Fixture Answers')
            self.assertEqual(loaded.edition('answers').output_name, 'fixture-answers')
            self.assertEqual(
                loaded.edition('main').front_cover,
                'assets/images/front.webp',
            )

    def test_manifest_rejects_wrong_publication_author(self) -> None:
        module = load_module('build_book_author_test', BUILDER)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            manifest = {
                'title': 'Fixture Book',
                'author': 'Wrong Author',
                'version': '1.1.0',
                'credit': 'Created by Visual Forge',
                'creationTimestamp': 1785542400,
                'chapters': [],
                'appendices': [],
                'answers': [],
                'editions': {
                    edition: {
                        'title': 'Fixture Book',
                        'output': f'fixture-{edition}',
                        'frontCover': 'assets/images/front.webp',
                        'backCover': 'assets/images/back.webp',
                    }
                    for edition in ('main', 'answers')
                },
            }
            (root / 'book.json').write_text(json.dumps(manifest), encoding='utf-8')
            (root / 'VERSION').write_text('1.1.0\n', encoding='utf-8')

            with self.assertRaisesRegex(
                module.BuildError,
                r'^book\.json author must be Michel Abboud\.$',
            ):
                module.load_manifest(root)

    def test_manifest_rejects_unsafe_output_basenames(self) -> None:
        module = load_module('build_book_output_basename_test', BUILDER)
        unsafe = (
            '',
            '.',
            '..',
            '../powershell-zero-to-hero',
            '/absolute',
            'nested/name',
            'nested\\name',
            'already.pdf',
            'has.dot',
            'control\nname',
            'control\x1bname',
        )
        for index, output_name in enumerate(unsafe):
            with self.subTest(output_name=output_name):
                with tempfile.TemporaryDirectory() as temporary_directory:
                    root = Path(temporary_directory)
                    write_build_fixture(root, main_output=output_name)
                    with self.assertRaisesRegex(
                        module.BuildError,
                        r"^book\.json edition 'main' output must be a safe extensionless basename\.$",
                    ):
                        module.load_manifest(root)

    def test_manifest_accepts_portable_output_basenames(self) -> None:
        module = load_module('build_book_valid_output_basename_test', BUILDER)
        for output_name in ('book', 'book-1', 'Book_2026'):
            with self.subTest(output_name=output_name):
                with tempfile.TemporaryDirectory() as temporary_directory:
                    root = Path(temporary_directory)
                    write_build_fixture(root, main_output=output_name)
                    self.assertEqual(
                        module.load_manifest(root).main.output_name,
                        output_name,
                    )

    def test_escape_output_is_rejected_without_touching_historical_sentinel(self) -> None:
        module = load_module('build_book_escape_sentinel_test', BUILDER)
        with tempfile.TemporaryDirectory() as temporary_directory:
            workspace = Path(temporary_directory)
            root = workspace / 'repository'
            root.mkdir()
            sentinel = workspace / 'powershell-zero-to-hero.pdf'
            sentinel.write_bytes(b'byte-identical historical sentinel')
            before = hashlib.sha256(sentinel.read_bytes()).hexdigest()
            write_build_fixture(root, main_output='../powershell-zero-to-hero')

            with self.assertRaisesRegex(module.BuildError, r'safe extensionless basename'):
                module.build(root, editions=('main',), formats=('pdf',))

            self.assertEqual(hashlib.sha256(sentinel.read_bytes()).hexdigest(), before)
            self.assertEqual(sentinel.read_bytes(), b'byte-identical historical sentinel')

    def test_build_rejects_symlinked_managed_roots_and_components(self) -> None:
        module = load_module('build_book_symlink_containment_test', BUILDER)
        cases = ('build', 'dist', 'dist/assets')
        for relative in cases:
            with self.subTest(relative=relative):
                with tempfile.TemporaryDirectory() as temporary_directory:
                    workspace = Path(temporary_directory)
                    root = workspace / 'repository'
                    root.mkdir()
                    write_build_fixture(root)
                    outside = workspace / 'outside'
                    outside.mkdir()
                    link = root / relative
                    link.parent.mkdir(parents=True, exist_ok=True)
                    link.symlink_to(outside, target_is_directory=True)

                    with mock.patch.object(module, 'check_tools'):
                        with self.assertRaisesRegex(
                            module.BuildError,
                            r'^managed output path must not contain symlinks:',
                        ):
                            module.build(root, editions=('main',), formats=())
                        with self.assertRaisesRegex(
                            module.BuildError,
                            r'^managed output path must not contain symlinks:',
                        ):
                            module.validate_build(root)

                    self.assertEqual(tuple(outside.iterdir()), ())

    def test_repository_manifest_declares_complete_public_book(self) -> None:
        manifest_path = ROOT / 'book.json'
        self.assertTrue(manifest_path.is_file(), 'book.json must exist')
        module = load_module('build_book_repository_manifest_test', BUILDER)

        manifest = module.load_manifest(ROOT)

        self.assertEqual(manifest.book.author, 'Michel Abboud')
        self.assertEqual(manifest.book.version, '1.1.0')
        self.assertEqual(manifest.book.credit, 'Created by Visual Forge')
        self.assertEqual(getattr(manifest, 'creation_timestamp', None), 1785542400)
        self.assertEqual(len(manifest.book.chapters), 18)
        self.assertEqual(manifest.book.chapters[0], 'chapters/00-preface.md')
        self.assertEqual(manifest.book.chapters[-1], 'chapters/17-devops-and-cicd.md')
        self.assertEqual(len(manifest.book.appendices), 3)
        self.assertEqual(len(manifest.book.answers), 18)
        self.assertEqual(
            manifest.edition('main').output_name,
            'powershell-zero-to-hero',
        )
        self.assertEqual(
            manifest.edition('answers').output_name,
            'powershell-zero-to-hero-answer-booklet',
        )
        self.assertEqual(
            manifest.edition('main').front_cover,
            'assets/images/ps-cover.webp',
        )
        self.assertEqual(
            manifest.edition('main').back_cover,
            'assets/images/ps-back-cover.webp',
        )

    def test_build_uses_relative_commands_and_emits_sorted_outputs(self) -> None:
        module = load_module('build_book_commands_test', BUILDER)
        self.assertTrue(hasattr(module, 'build'), 'build must exist')
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            manifest = {
                'title': 'Fixture Book',
                'author': 'Michel Abboud',
                'version': '1.1.0',
                'credit': 'Created by Visual Forge',
                'creationTimestamp': 1785542400,
                'chapters': ['chapters/01.md'],
                'appendices': ['appendices/A.md'],
                'answers': ['answers/01.md'],
                'editions': {
                    'main': {
                        'title': 'Fixture Book',
                        'output': 'fixture-main',
                        'frontCover': 'assets/images/front.webp',
                        'backCover': 'assets/images/back.webp',
                    },
                    'answers': {
                        'title': 'Fixture Answers',
                        'output': 'fixture-answers',
                        'frontCover': 'assets/images/front.webp',
                        'backCover': 'assets/images/back.webp',
                    },
                },
            }
            files: dict[str, str | bytes] = {
                'book.json': json.dumps(manifest),
                'VERSION': '1.1.0\n',
                'chapters/01.md': '# Chapter\n\n![Diagram](assets/images/example.png)\n',
                'appendices/A.md': '# Appendix\n',
                'answers/01.md': '# Answers\n',
                'assets/images/example.png': b'image bytes',
                'assets/images/front.webp': b'front cover',
                'assets/images/back.webp': b'back cover',
                'powershell-zero-to-hero.typ': '#let placeholder = none\n',
                'book/template.typ': '#let placeholder = none\n',
            }
            for relative, content in files.items():
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                if isinstance(content, bytes):
                    path.write_bytes(content)
                else:
                    path.write_text(content, encoding='utf-8')
            bin_dir = root / 'fake-bin'
            bin_dir.mkdir()
            fake_tool = '''#!/usr/bin/env python3
import json
import sys
from pathlib import Path

name = Path(sys.argv[0]).name
with Path('commands.jsonl').open('a', encoding='utf-8') as handle:
    handle.write(json.dumps({'tool': name, 'args': sys.argv[1:]}) + '\\n')
if name == 'pandoc':
    output_arg = next(arg for arg in sys.argv[1:] if arg.startswith('--output='))
    output = Path(output_arg.split('=', 1)[1])
    output.parent.mkdir(parents=True, exist_ok=True)
    if '--to=typst' in sys.argv:
        output.write_text('#image("assets/images/example.png")\\n\\\\newpage\\n', encoding='utf-8')
    else:
        output.write_text('<!doctype html><title>fixture</title>\\n', encoding='utf-8')
else:
    output = Path(sys.argv[-1])
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(b'%PDF-1.7 fixture')
'''
            for tool in ('pandoc', 'typst'):
                executable = bin_dir / tool
                executable.write_text(fake_tool, encoding='utf-8')
                executable.chmod(0o755)
            path_value = f'{bin_dir}{os.pathsep}{os.environ.get("PATH", "")}'

            with mock.patch.dict(os.environ, {'PATH': path_value}):
                outputs = module.build(
                    root,
                    editions=('main', 'answers'),
                    formats=('pdf', 'html'),
                )

            expected = tuple(
                sorted(
                    (
                        root / 'dist' / 'fixture-main.pdf',
                        root / 'dist' / 'fixture-main.html',
                        root / 'dist' / 'fixture-answers.pdf',
                        root / 'dist' / 'fixture-answers.html',
                    ),
                    key=lambda path: path.as_posix(),
                ),
            )
            self.assertEqual(outputs, expected)
            self.assertTrue(all(path.is_file() for path in outputs))
            self.assertEqual(
                (root / 'dist' / 'assets' / 'images' / 'example.png').read_bytes(),
                b'image bytes',
            )
            self.assertNotIn('# Answers', (root / 'build' / 'main.md').read_text(encoding='utf-8'))
            self.assertIn('# Answers', (root / 'build' / 'answers.md').read_text(encoding='utf-8'))
            typst_body = (root / 'build' / 'main-body.typ').read_text(encoding='utf-8')
            self.assertTrue(
                typst_body.startswith(
                    '#import "../book/template.typ": blockquote, horizontalrule\n',
                ),
            )
            self.assertIn('#image("../assets/images/example.png")', typst_body)
            self.assertIn('#pagebreak()', typst_body)

            commands = [
                json.loads(line)
                for line in (root / 'commands.jsonl').read_text(encoding='utf-8').splitlines()
            ]
            self.assertEqual(len(commands), 6)
            typst_commands = [command for command in commands if command['tool'] == 'typst']
            self.assertEqual(len(typst_commands), 2)
            for command in typst_commands:
                self.assertIn('--creation-timestamp', command['args'])
                timestamp_at = command['args'].index('--creation-timestamp')
                self.assertEqual(command['args'][timestamp_at + 1], '1785542400')
            original_root = '/'.join(
                ('', 'home', 'michel', '-'.join(('visual', 'forge', 'projects'))),
            )
            for command in commands:
                for argument in command['args']:
                    self.assertNotIn(original_root, argument)
                    if not argument.startswith('--'):
                        self.assertFalse(Path(argument).is_absolute(), argument)

    def test_reference_style_images_are_copied_and_resolve_in_html(self) -> None:
        module = load_module('build_book_reference_images_test', BUILDER)
        markdown = (
            '# Chapter\n\n'
            '![](assets/images/inline.png)\n'
            '![Full][full]\n'
            '![collapsed][]\n'
            '![shortcut]\n'
            '![][empty]\n\n'
            '[full]: assets/images/full.png\n'
            '[collapsed]: assets/images/collapsed.png\n'
            '[shortcut]: assets/images/shortcut.png\n'
            '[empty]: assets/images/empty.png\n'
        )
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            write_build_fixture(root, chapter_markdown=markdown)
            image_names = ('inline.png', 'full.png', 'collapsed.png', 'shortcut.png', 'empty.png')
            for name in image_names:
                (root / 'assets' / 'images' / name).write_bytes(name.encode())

            outputs = module.build(root, editions=('main',), formats=('html',))

            self.assertEqual(outputs, (root / 'dist' / 'fixture-main.html',))
            html = outputs[0].read_text(encoding='utf-8')
            for name in image_names:
                copied = root / 'dist' / 'assets' / 'images' / name
                self.assertEqual(copied.read_bytes(), name.encode())
                self.assertIn(f'src="assets/images/{name}"', html)

    def test_external_and_escaping_markdown_images_are_rejected(self) -> None:
        module = load_module('build_book_rejected_images_test', BUILDER)
        targets = ('https://example.invalid/private.png', '../outside.png')
        for target in targets:
            with self.subTest(target=target):
                with tempfile.TemporaryDirectory() as temporary_directory:
                    root = Path(temporary_directory)
                    write_build_fixture(root, chapter_markdown=f'# Chapter\n\n![Bad]({target})\n')
                    with mock.patch.object(module, 'check_tools'):
                        with self.assertRaisesRegex(
                            module.BuildError,
                            r'^image path must stay under assets/images:',
                        ):
                            module.build(root, editions=('main',), formats=())

    def test_selected_build_removes_stale_managed_outputs_and_images(self) -> None:
        module = load_module('build_book_stale_cleanup_test', BUILDER)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            write_build_fixture(
                root,
                chapter_markdown='# Chapter\n\n![Current](assets/images/current.png)\n',
            )
            (root / 'assets' / 'images' / 'current.png').write_bytes(b'current')
            stale: dict[str, bytes] = {
                'build/answers.md': b'stale answers',
                'build/main-body.typ': b'stale body',
                'dist/fixture-answers.pdf': b'stale pdf',
                'dist/fixture-main.pdf': b'stale unselected format',
                'dist/assets/images/stale.png': b'stale image',
                'dist/obsolete/nested.bin': b'stale nested file',
            }
            for relative, content in stale.items():
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(content)

            outputs = module.build(root, editions=('main',), formats=('html',))

            self.assertEqual(outputs, (root / 'dist' / 'fixture-main.html',))
            build_files = {
                path.relative_to(root / 'build').as_posix()
                for path in (root / 'build').rglob('*')
                if path.is_file()
            }
            dist_files = {
                path.relative_to(root / 'dist').as_posix()
                for path in (root / 'dist').rglob('*')
                if path.is_file()
            }
            self.assertEqual(build_files, {'main.md'})
            self.assertEqual(
                dist_files,
                {
                    'fixture-main.html',
                    'assets/images/back.webp',
                    'assets/images/current.png',
                    'assets/images/front.webp',
                },
            )

    def test_cli_routes_requested_edition_and_format(self) -> None:
        module = load_module('build_book_cli_route_test', BUILDER)
        self.assertTrue(hasattr(module, 'main'), 'main must exist')
        root = Path('fixture-root')
        with mock.patch.object(module, 'build', return_value=()) as build_mock:
            result = module.main(
                ['--edition', 'answers', '--format', 'html'],
                root=root,
            )

        self.assertEqual(result, 0)
        build_mock.assert_called_once_with(
            root,
            editions=('answers',),
            formats=('html',),
        )

    def test_typst_entrypoint_applies_manifest_metadata_and_visible_credit(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            (root / 'book').mkdir()
            (root / 'assets' / 'images').mkdir(parents=True)
            (root / 'build').mkdir()
            for relative in (
                'powershell-zero-to-hero.typ',
                'book/template.typ',
                'assets/images/ps-cover.webp',
                'assets/images/ps-back-cover.webp',
            ):
                source = ROOT / relative
                destination = root / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                destination.write_bytes(source.read_bytes())
            body = root / 'build' / 'main-body.typ'
            pdf = root / 'build' / 'template-contract.pdf'
            body.write_text('= TEMPLATE CONTRACT MARKER\n', encoding='utf-8')
            result = subprocess.run(
                [
                    'typst',
                    'compile',
                    '--root',
                    '.',
                    '--input',
                    'edition=main',
                    '--input',
                    'title=PowerShell: Zero to Hero',
                    '--input',
                    'author=Michel Abboud',
                    '--input',
                    'version=1.1.0',
                    '--input',
                    'credit=Created by Visual Forge',
                    '--input',
                    'front-cover=assets/images/ps-cover.webp',
                    '--input',
                    'back-cover=assets/images/ps-back-cover.webp',
                    'powershell-zero-to-hero.typ',
                    'build/template-contract.pdf',
                ],
                cwd=root,
                text=True,
                capture_output=True,
                check=False,
            )

            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            info = subprocess.check_output(
                ['pdfinfo', pdf],
                text=True,
                stderr=subprocess.DEVNULL,
            )
            text = subprocess.check_output(['pdftotext', pdf, '-'], text=True)
            self.assertIn('Title:           PowerShell: Zero to Hero', info)
            self.assertIn('Author:          Michel Abboud', info)
            self.assertIn('Created by Visual Forge', text)
            self.assertIn('Contents', text)
            self.assertIn('TEMPLATE CONTRACT MARKER', text)

    def test_check_preserves_seeded_managed_file_bytes(self) -> None:
        module = load_module('build_book_check_preservation_test', BUILDER)
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory)
            write_build_fixture(root)
            seeded = {
                'build/unrelated.bin': b'pre-existing build bytes\x00',
                'dist/unrelated.bin': b'pre-existing dist bytes\x00',
            }
            for relative, content in seeded.items():
                path = root / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(content)
            before = {
                relative: hashlib.sha256(content).hexdigest()
                for relative, content in seeded.items()
            }

            with mock.patch.object(module, 'check_tools'):
                module.validate_build(root)

            after = {
                relative: hashlib.sha256((root / relative).read_bytes()).hexdigest()
                for relative in seeded
            }
            self.assertEqual(after, before)

    def test_check_mode_validates_without_generating_outputs(self) -> None:
        before = {
            path.relative_to(ROOT).as_posix()
            for directory in (ROOT / 'build', ROOT / 'dist')
            if directory.exists()
            for path in directory.rglob('*')
            if path.is_file()
        }

        result = subprocess.run(
            [sys.executable, 'scripts/build_book.py', '--check'],
            cwd=ROOT,
            text=True,
            capture_output=True,
            check=False,
        )

        after = {
            path.relative_to(ROOT).as_posix()
            for directory in (ROOT / 'build', ROOT / 'dist')
            if directory.exists()
            for path in directory.rglob('*')
            if path.is_file()
        }
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(result.stdout, 'Build prerequisites and manifest are valid.\n')
        self.assertEqual(after, before)

    def test_generated_directories_are_ignored_but_entrypoint_is_trackable(self) -> None:
        ignored = [
            subprocess.run(
                ['git', 'check-ignore', '--quiet', relative],
                cwd=ROOT,
                check=False,
            ).returncode
            for relative in ('build/main.md', 'dist/book.pdf')
        ]
        entrypoint = subprocess.run(
            ['git', 'check-ignore', '--quiet', 'powershell-zero-to-hero.typ'],
            cwd=ROOT,
            check=False,
        )

        self.assertEqual(ignored, [0, 0])
        self.assertEqual(entrypoint.returncode, 1)


if __name__ == '__main__':
    unittest.main()
