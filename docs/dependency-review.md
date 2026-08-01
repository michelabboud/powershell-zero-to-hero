# Build and CI Dependency Review

Checked on **2026-08-01** against the upstream sources linked below. Workflow
dependencies are intentionally narrow: GitHub-owned actions for checkout,
runtime setup, caching, and artifact transfer; official project release
archives for document tools; and the GitHub CLI already supplied by the
GitHub-hosted runner for tag releases.

Every external action is pinned to the full, signed release commit. Every
downloaded executable or font archive is pinned to an exact release and a
SHA-256 digest. Dependabot reviews GitHub Actions updates weekly, but an update
must retain full-SHA pinning and pass `tests/test_github_workflows.py`.

## GitHub Actions

| Dependency | Selected release and immutable commit | Upstream and license | Security and maintenance review |
| --- | --- | --- | --- |
| `actions/checkout` | v7.0.1, `3d3c42e5aac5ba805825da76410c181273ba90b1` | [release](https://github.com/actions/checkout/releases/tag/v7.0.1), [MIT license](https://github.com/actions/checkout/blob/v7.0.1/LICENSE) | Current signed release from GitHub's `actions` organization. The repository advisory list had no published advisories. Checkout receives only `contents: read`; credentials are not used by later steps. |
| `actions/cache` | v6.1.0, `55cc8345863c7cc4c66a329aec7e433d2d1c52a9` | [release](https://github.com/actions/cache/releases/tag/v6.1.0), [MIT license](https://github.com/actions/cache/blob/v6.1.0/LICENSE) | Current signed release. The repository advisory list had no published advisories. Cache keys include OS, architecture, and every exact tool version; pull-request caches remain scoped by GitHub's cache rules. Restored executables are version-checked before use. |
| `actions/setup-python` | v6.2.0, `a309ff8b426b58ec0e2a45f0f869d46889d02405` | [release](https://github.com/actions/setup-python/releases/tag/v6.2.0), [MIT license](https://github.com/actions/setup-python/blob/v6.2.0/LICENSE) | Current signed release, built for the Node 24 action runtime. The repository advisory list had no published advisories. The workflow requests an exact patch version and verifies the interpreter at runtime. |
| `actions/upload-artifact` | v7.0.1, `043fb46d1a93c77aae656e7c1c64a875d1fc6a0a` | [release](https://github.com/actions/upload-artifact/releases/tag/v7.0.1), [MIT license](https://github.com/actions/upload-artifact/blob/v7.0.1/LICENSE) | Current signed release. The repository advisory list had no published advisories. Upload paths enumerate the four regenerated books and checksum file; hidden files and the historical root PDF are outside the allowlist. |
| `actions/download-artifact` | v8.0.1, `3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c` | [release](https://github.com/actions/download-artifact/releases/tag/v8.0.1), [MIT license](https://github.com/actions/download-artifact/blob/v8.0.1/LICENSE) | Current signed release. [GHSA-cxww-7g56-2vh6](https://github.com/actions/download-artifact/security/advisories/GHSA-cxww-7g56-2vh6) affected 4.0.0 through 4.1.2 and was fixed in 4.1.3; v8.0.1 is outside that range. Downloaded books are verified against the separately transferred checksums before release. |

The resolved commits were also checked through the official GitHub commits API;
each release commit reported a valid GitHub signature. Full commit pins follow
GitHub's [secure-use guidance](https://docs.github.com/en/actions/reference/security/secure-use).

## Runtime and document toolchain

| Dependency | Exact version or artifact | Upstream and license | Security and selection review |
| --- | --- | --- | --- |
| Python | 3.12.13 | [Python 3.12.13 release](https://www.python.org/downloads/release/python-31213/), [PSF license](https://github.com/python/cpython/blob/v3.12.13/LICENSE) | Latest security release in the plan's Python 3.12 line. The signed CPython tag and the official `actions/python-versions` 3.12.13 build were present. Python 3.12 remains supported for security fixes through October 2028; the repository uses only its standard library. |
| PowerShell | 7.6.4; `powershell-7.6.4-linux-x64.tar.gz`; SHA-256 `4471b5a36bfe86ec7af8525d36bb1cacba0128e7aac22d05cc064bc00e604721` | [release](https://github.com/PowerShell/PowerShell/releases/tag/v7.6.4), [MIT license](https://github.com/PowerShell/PowerShell/blob/v7.6.4/LICENSE.txt) | Current stable release. The digest came from the official release asset metadata and is verified before extraction. Historical repository advisories target old runtime lines; the selected current release was not in their affected ranges. |
| Pester | 6.0.1 | [release](https://github.com/pester/Pester/releases/tag/6.0.1), [Apache-2.0 license](https://github.com/pester/Pester/blob/6.0.1/LICENSE) | Current stable release, installed by exact version from PowerShell Gallery. The repository advisory list had no published advisories. The test suite remains compatible with its declared Pester 5.7.1 floor, while CI tests the maintained current release. |
| Pandoc | 3.10.1; `pandoc-3.10.1-linux-amd64.tar.gz`; SHA-256 `72948bf5784f560d5ad1876709daca27e0667f262da727bb33f77b58e52df2f5` | [release](https://github.com/jgm/pandoc/releases/tag/3.10.1), [GPL-2.0-or-later license](https://github.com/jgm/pandoc/blob/3.10.1/COPYING.md) | Current stable release. [GHSA-xj5q-fv23-575g](https://github.com/jgm/pandoc/security/advisories/GHSA-xj5q-fv23-575g) affected 1.13 through 3.1.3 and was fixed in 3.1.4; 3.10.1 is outside that range. Pandoc is an unbundled build tool operating on reviewed repository content, so its GPL license does not change the MIT license of this guide. |
| Typst | 0.15.1; `typst-x86_64-unknown-linux-musl.tar.xz`; SHA-256 `a6d077d0a95eed5a2eba715b2dae06be954f624ccbf85758a03f389ded33118c` | [release](https://github.com/typst/typst/releases/tag/v0.15.1), [Apache-2.0 license](https://github.com/typst/typst/blob/v0.15.1/LICENSE) | Current stable release. The repository advisory list had no published advisories. The official static Linux build is verified before extraction and its version is checked before building. |
| Libertinus fonts | 7.051; `Libertinus-7.051.zip`; SHA-256 `4d9be29b5cb380c35af8ba967abcc752ad1e07be1f738a9789c33e0dd7478c92` | [release](https://github.com/alerque/libertinus/releases/tag/v7.051), [SIL OFL-1.1 license](https://github.com/alerque/libertinus/blob/v7.051/OFL.txt) | Current upstream release and the exact family required by `book/template.typ`. The repository advisory list had no published advisories. The release predates GitHub asset digests, so the workflow pin uses the SHA-256 measured from the immutable tagged release asset on the review date. Fonts are build inputs, not vendored source. |
| actionlint | 1.7.12; `actionlint_1.7.12_linux_amd64.tar.gz`; SHA-256 `8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8` | [release](https://github.com/rhysd/actionlint/releases/tag/v1.7.12), [MIT license](https://github.com/rhysd/actionlint/blob/v1.7.12/LICENSE.txt) | Current stable release. The repository advisory list had no published advisories. The official release digest is verified before actionlint parses both workflows. |

The GitHub-hosted `ubuntu-24.04` image supplies `curl`, `tar`, `unzip`,
`sha256sum`, and GitHub CLI. They are runner facilities rather than downloaded
actions. The release job prints the GitHub CLI version and gives `contents:
write` only to that tag-only job; all pull-request and build jobs remain
read-only.

## Alternatives considered

- Moving action tags were rejected because a tag can be retargeted; full commit
  SHAs are the only immutable action reference supported by GitHub.
- A `workflow_run` release workflow was rejected because it complicates the
  privilege boundary and can expose a write-capable follow-up to untrusted
  workflow inputs. A single tag-gated job has a smaller trust surface.
- A third-party release action was rejected in favor of GitHub CLI already on
  the hosted runner. This removes another executable action from the release
  trust chain while retaining exact, enumerated asset paths.
- Unversioned system Pandoc, Typst, PowerShell, Pester, and fonts were rejected
  because runner-image updates would make the book build non-reproducible.

## Ongoing review

Dependabot opens weekly `github-actions` updates. Reviewers must resolve the new
release tag to its full signed commit, update the inline version comment and
this report together, inspect upstream release notes and advisories, then run
the workflow contract suite and actionlint. Tool archives are not discoverable
by Dependabot, so their exact versions and release checksums are reviewed
manually during guide release preparation.
