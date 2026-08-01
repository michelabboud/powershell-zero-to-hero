#!/usr/bin/env python3
"""Publication-safety contracts for the GitHub Actions configuration."""

from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VALIDATE = ROOT / '.github' / 'workflows' / 'validate.yml'
BUILD = ROOT / '.github' / 'workflows' / 'build-book.yml'
DEPENDABOT = ROOT / '.github' / 'dependabot.yml'
DEPENDENCY_REVIEW = ROOT / 'docs' / 'dependency-review.md'

BOOK_OUTPUTS = (
    'dist/powershell-zero-to-hero.pdf',
    'dist/powershell-zero-to-hero.html',
    'dist/powershell-zero-to-hero-answer-booklet.pdf',
    'dist/powershell-zero-to-hero-answer-booklet.html',
)


def workflow_text(path: Path) -> str:
    """Read one required workflow with a focused failure message."""
    if not path.is_file():
        raise AssertionError(f'missing required workflow: {path.relative_to(ROOT)}')
    return path.read_text(encoding='utf-8')


def external_action_uses(text: str) -> tuple[tuple[str, str, str], ...]:
    """Return external action owner/name, revision, and comment triples."""
    matches: list[tuple[str, str, str]] = []
    pattern = re.compile(
        r'^\s*-?\s*uses:\s*([^\s@]+)@([^\s#]+)\s+#\s*(\S.*?)\s*$',
        re.MULTILINE,
    )
    for action, revision, comment in pattern.findall(text):
        if not action.startswith('./'):
            matches.append((action, revision, comment))
    return tuple(matches)


def job_block(text: str, job_name: str) -> str:
    """Extract one top-level job without an unbounded multiline regex."""
    marker = f'  {job_name}:\n'
    try:
        start = text.index(marker, text.index('jobs:\n'))
    except ValueError as error:
        raise AssertionError(f'missing required job: {job_name}') from error
    following = re.search(r'(?m)^  [a-z][a-z0-9-]*:\n', text[start + len(marker):])
    if following is None:
        return text[start:]
    end = start + len(marker) + following.start()
    return text[start:end]


def step_blocks(text: str) -> tuple[str, ...]:
    """Return top-level step blocks from a workflow without parsing shell text."""
    blocks: list[list[str]] = []
    current: list[str] | None = None
    for line in text.splitlines(keepends=True):
        if line.startswith('      - name: '):
            if current is not None:
                blocks.append(current)
            current = [line]
        elif current is not None:
            if line.startswith('  ') and line.strip() and not line.startswith('        '):
                blocks.append(current)
                current = None
            else:
                current.append(line)
    if current is not None:
        blocks.append(current)
    return tuple(''.join(block) for block in blocks)


class GitHubWorkflowContractTests(unittest.TestCase):
    def test_validate_exposes_exact_required_check_contexts(self) -> None:
        text = workflow_text(VALIDATE)
        self.assertRegex(text, r'(?m)^name: validate$')
        self.assertRegex(text, r'(?m)^  repository:\n    name: repository$')
        self.assertRegex(text, r'(?m)^  pester:\n    name: pester$')

    def test_validate_is_reusable_and_runs_for_pushes_and_pull_requests(self) -> None:
        text = workflow_text(VALIDATE)
        for trigger in ('workflow_call:', 'push:', 'pull_request:'):
            self.assertIn(trigger, text)
        self.assertNotIn('pull_request_target:', text)
        self.assertNotIn('workflow_run:', text)

    def test_build_has_all_supported_triggers_and_exact_check_context(self) -> None:
        text = workflow_text(BUILD)
        self.assertRegex(text, r'(?m)^name: build-book$')
        for trigger in ('push:', 'pull_request:', 'workflow_dispatch:'):
            self.assertIn(trigger, text)
        self.assertIn("- 'v*'", text)
        self.assertRegex(text, r'(?m)^  all-formats:\n    name: all-formats$')
        self.assertNotIn('pull_request_target:', text)
        self.assertNotIn('workflow_run:', text)

    def test_all_formats_depends_on_reusable_validation(self) -> None:
        text = workflow_text(BUILD)
        self.assertIn('    uses: ./.github/workflows/validate.yml\n', job_block(text, 'validation'))
        self.assertIn('    needs: validation\n', job_block(text, 'all-formats'))

    def test_document_tool_check_runs_only_after_document_tools_are_installed(self) -> None:
        validate_repository_job = job_block(workflow_text(VALIDATE), 'repository')
        build_job = job_block(workflow_text(BUILD), 'all-formats')
        self.assertNotIn('python scripts/build_book.py --check', validate_repository_job)
        self.assertIn('python scripts/build_book.py --check', build_job)

    def test_repository_installs_document_tools_before_full_python_suite(self) -> None:
        text = workflow_text(VALIDATE)
        repository_job = job_block(text, 'repository')
        for required in (
            "PANDOC_VERSION: '3.10.1'",
            "TYPST_VERSION: '0.15.1'",
            "LIBERTINUS_VERSION: '7.051'",
            "PANDOC_SHA256: '72948bf5784f560d5ad1876709daca27e0667f262da727bb33f77b58e52df2f5'",
            "TYPST_SHA256: 'a6d077d0a95eed5a2eba715b2dae06be954f624ccbf85758a03f389ded33118c'",
            "LIBERTINUS_SHA256: '4d9be29b5cb380c35af8ba967abcc752ad1e07be1f738a9789c33e0dd7478c92'",
        ):
            self.assertIn(required, text)
        install = '      - name: Install Pandoc, Typst, and Libertinus from official releases\n'
        run_tests = '      - name: Run repository contracts and validation\n'
        self.assertIn(install, repository_job)
        self.assertLess(repository_job.index(install), repository_job.index(run_tests))
        self.assertIn("python -m unittest discover -s tests -p 'test_*.py'", repository_job)

    def test_repository_installs_exact_pdf_inspection_tools_before_tests(self) -> None:
        text = workflow_text(VALIDATE)
        repository_job = job_block(text, 'repository')
        self.assertIn("POPPLER_UTILS_VERSION: '24.02.0-1ubuntu9.9'", text)
        install = '      - name: Install exact PDF inspection utilities\n'
        run_tests = '      - name: Run repository contracts and validation\n'
        self.assertIn(install, repository_job)
        self.assertLess(repository_job.index(install), repository_job.index(run_tests))
        self.assertIn('"poppler-utils=$POPPLER_UTILS_VERSION"', repository_job)
        self.assertIn("dpkg-query -W -f='${Version}' poppler-utils", repository_job)

    def test_external_actions_use_full_shas_with_version_comments(self) -> None:
        action_uses = external_action_uses(
            workflow_text(VALIDATE) + '\n' + workflow_text(BUILD),
        )
        self.assertGreaterEqual(len(action_uses), 5)
        for action, revision, comment in action_uses:
            with self.subTest(action=action):
                self.assertRegex(revision, r'^[0-9a-f]{40}$')
                self.assertRegex(comment, r'^v\d+(?:\.\d+){1,2}$')

    def test_expected_action_releases_are_selected(self) -> None:
        text = workflow_text(VALIDATE) + '\n' + workflow_text(BUILD)
        expected = {
            'actions/checkout': (
                '3d3c42e5aac5ba805825da76410c181273ba90b1',
                'v7.0.1',
            ),
            'actions/cache': (
                '55cc8345863c7cc4c66a329aec7e433d2d1c52a9',
                'v6.1.0',
            ),
            'actions/setup-python': (
                '5fda3b95a4ea91299a34e894583c3862153e4b97',
                'v7.0.0',
            ),
            'actions/upload-artifact': (
                '043fb46d1a93c77aae656e7c1c64a875d1fc6a0a',
                'v7.0.1',
            ),
            'actions/download-artifact': (
                '3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c',
                'v8.0.1',
            ),
        }
        selected = {
            action: (revision, comment)
            for action, revision, comment in external_action_uses(text)
        }
        self.assertEqual(selected, expected)

    def test_every_checkout_disables_persisted_credentials(self) -> None:
        checkout_steps = tuple(
            step
            for text in (workflow_text(VALIDATE), workflow_text(BUILD))
            for step in step_blocks(text)
            if 'uses: actions/checkout@' in step
        )
        self.assertEqual(len(checkout_steps), 3)
        for step in checkout_steps:
            with self.subTest(step=step.splitlines()[0].strip()):
                self.assertIn('        with:\n', step)
                self.assertIn('          persist-credentials: false\n', step)

    def test_workflows_default_to_read_only_permissions(self) -> None:
        for path in (VALIDATE, BUILD):
            with self.subTest(path=path.name):
                text = workflow_text(path)
                self.assertRegex(text, r'(?m)^permissions:\n  contents: read$')
                self.assertNotRegex(text, r'(?m)^\s+(actions|checks|id-token): write$')

    def test_only_tag_release_job_receives_contents_write(self) -> None:
        text = workflow_text(BUILD)
        self.assertEqual(text.count('contents: write'), 1)
        release = job_block(text, 'release')
        self.assertIn(
            "    if: github.event_name == 'push' && startsWith(github.ref, 'refs/tags/v')\n",
            release,
        )
        self.assertIn('    permissions:\n      contents: write\n', release)

    def test_jobs_have_timeouts_and_workflows_have_concurrency(self) -> None:
        expected_timeouts = {VALIDATE: 2, BUILD: 2}
        for path, count in expected_timeouts.items():
            with self.subTest(path=path.name):
                text = workflow_text(path)
                self.assertIn('concurrency:', text)
                # GitHub does not support timeout-minutes on a reusable-workflow
                # caller job, so build's validation caller is intentionally exempt.
                self.assertEqual(text.count('timeout-minutes:'), count)

    def test_toolchain_versions_and_download_hashes_are_exact(self) -> None:
        text = workflow_text(VALIDATE) + '\n' + workflow_text(BUILD)
        expected_versions = {
            'PYTHON_VERSION': '3.12.13',
            'POWERSHELL_VERSION': '7.6.4',
            'PESTER_VERSION': '6.0.1',
            'PANDOC_VERSION': '3.10.1',
            'TYPST_VERSION': '0.15.1',
            'LIBERTINUS_VERSION': '7.051',
        }
        for name, version in expected_versions.items():
            self.assertRegex(text, rf"(?m)^  {name}: '{re.escape(version)}'$")
        self.assertRegex(text, r'(?m)^  POWERSHELL_SHA256: \'[0-9a-f]{64}\'$')
        self.assertRegex(text, r'(?m)^  PANDOC_SHA256: \'[0-9a-f]{64}\'$')
        self.assertRegex(text, r'(?m)^  TYPST_SHA256: \'[0-9a-f]{64}\'$')
        self.assertRegex(text, r'(?m)^  LIBERTINUS_SHA256: \'[0-9a-f]{64}\'$')

    def test_build_uploads_exact_named_artifacts(self) -> None:
        text = workflow_text(BUILD)
        self.assertIn('name: powershell-zero-to-hero-books', text)
        self.assertIn('name: powershell-zero-to-hero-checksums', text)
        for output in BOOK_OUTPUTS:
            self.assertGreaterEqual(text.count(output), 2, output)
            self.assertGreaterEqual(text.count(Path(output).name), 3, output)
        self.assertIn('dist/SHA256SUMS', text)

    def test_historical_pdf_is_never_uploaded_or_released(self) -> None:
        text = workflow_text(BUILD)
        for match in re.finditer(r'(?m)^\s+(?:path: )?(\S+\.pdf)\s*$', text):
            self.assertTrue(
                match.group(1).startswith(('dist/', 'release-assets/books/')),
                match.group(1),
            )
        self.assertNotRegex(text, r'(?m)^\s+powershell-zero-to-hero\.pdf\s*$')

    def test_release_inputs_are_fixed_and_not_derived_from_pr_content(self) -> None:
        text = workflow_text(BUILD)
        self.assertNotIn('github.event.pull_request.', text)
        self.assertNotIn('github.event.issue.', text)
        self.assertNotIn('github.event.head_commit.message', text)
        self.assertIn('GH_TOKEN: ${{ github.token }}', text)
        self.assertIn('GH_REPO: ${{ github.repository }}', text)

    def test_dependabot_checks_actions_weekly(self) -> None:
        text = workflow_text(DEPENDABOT)
        self.assertIn('version: 2', text)
        self.assertIn('package-ecosystem: github-actions', text)
        self.assertIn('directory: /', text)
        self.assertIn('interval: weekly', text)
        self.assertIn('open-pull-requests-limit:', text)

    def test_dependency_review_records_every_pin_and_security_basis(self) -> None:
        text = workflow_text(DEPENDENCY_REVIEW)
        for required in (
            '2026-08-01',
            '3d3c42e5aac5ba805825da76410c181273ba90b1',
            '55cc8345863c7cc4c66a329aec7e433d2d1c52a9',
            '043fb46d1a93c77aae656e7c1c64a875d1fc6a0a',
            '5fda3b95a4ea91299a34e894583c3862153e4b97',
            '3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c',
            'license',
            'security',
            'Dependabot',
        ):
            self.assertIn(required, text)


if __name__ == '__main__':
    unittest.main()
