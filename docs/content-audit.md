# Content Audit

Audit date: 2026-08-01

Scope: every main-edition source file (18 chapters and 3 appendices), the 17
four-exercise answer sets, and their 17 executable Pester suites. Commands and
platform claims were checked against the primary sources below. Local Markdown
links and image targets were checked by `scripts/validate_repository.py`; the
assembled main and answer editions were also rebuilt to exercise all source
paths. `reviewed` means the row was examined and either corrected or confirmed.

## Primary sources

- S1: [PowerShell support lifecycle](https://learn.microsoft.com/en-us/powershell/scripting/install/powershell-support-lifecycle)
- S2: [Installing PowerShell on Windows](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows)
- S3: [about_PowerShell_Editions](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_editions)
- S4: [about_Comparison_Operators](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comparison_operators)
- S5: [about_Operators](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators)
- S6: [about_Pipelines](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_pipelines)
- S7: [about_Automatic_Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_automatic_variables)
- S8: [about_Functions_Advanced](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced)
- S9: [about_Functions_Advanced_Methods](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions_advanced_methods)
- S10: [about_Character_Encoding](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding)
- S11: [Import-Csv](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/import-csv) and [Export-Csv](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/export-csv)
- S12: [ConvertTo-Json](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertto-json)
- S13: [about_Try_Catch_Finally](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_try_catch_finally)
- S14: [.NET regular-expression language quick reference](https://learn.microsoft.com/en-us/dotnet/standard/base-types/regular-expression-language-quick-reference)
- S15: [Microsoft.PowerShell.PSResourceGet](https://learn.microsoft.com/en-us/powershell/gallery/powershellget/overview)
- S16: [about_Modules](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_modules)
- S17: [about_Remote](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote)
- S18: [PowerShell remoting over SSH](https://learn.microsoft.com/en-us/powershell/scripting/security/remoting/ssh-remoting-in-powershell)
- S19: [about_Jobs](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_jobs)
- S20: [about_Thread_Jobs](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_thread_jobs)
- S21: [ActiveDirectory module](https://learn.microsoft.com/en-us/powershell/module/activedirectory/) and [about_ActiveDirectory_Filter](https://learn.microsoft.com/en-us/powershell/module/activedirectory/about/about_activedirectory_filter)
- S22: [Get-Service](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-service)
- S23: [Send-MailMessage](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/send-mailmessage) and [Send-MgUserMail](https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.users.actions/send-mguserMail)
- S24: [Pester installation and update guide](https://pester.dev/docs/introduction/installation) and [Invoke-Pester](https://pester.dev/docs/commands/Invoke-Pester)
- S25: [PSScriptAnalyzer overview](https://learn.microsoft.com/en-us/powershell/utility-modules/psscriptanalyzer/overview)
- S26: [actions/checkout v7.0.1](https://github.com/actions/checkout/releases/tag/v7.0.1), [actions/cache v6.1.0](https://github.com/actions/cache/releases/tag/v6.1.0), and [actions/upload-artifact v7.0.1](https://github.com/actions/upload-artifact/releases/tag/v7.0.1)
- S27: [GitHub Actions workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
- S28: [Get-CimInstance](https://learn.microsoft.com/en-us/powershell/module/cimcmdlets/get-ciminstance) and [ConvertTo-Html](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertto-html)
- S29: [Install PowerShell on Ubuntu](https://learn.microsoft.com/en-us/powershell/scripting/install/install-ubuntu) and [Install PowerShell on Debian](https://learn.microsoft.com/en-us/powershell/scripting/install/install-debian)
- S30: [PDF Reference 1.7](https://opensource.adobe.com/dc-acrobat-sdk-docs/pdfstandards/pdfreference1.7old.pdf) and [Typst issue #7140](https://github.com/typst/typst/issues/7140)

## File-by-file matrix

File | Commands | Links | Exercise | Answer | Test | Sources | Changes | Status
--- | --- | --- | --- | --- | --- | --- | --- | ---
`chapters/00-preface.md` | Version, installation, shell, help, discovery, and safety guidance checked | Local chapter/appendix/image links pass | Reference preface; no numbered exercise | n/a: no exercise to solve | n/a: no executable exercise | S1-S3 | Updated current PowerShell/Pester baseline, cross-platform framing, and safe-command guidance | reviewed
`chapters/01-what-is-powershell.md` | `Get-Process`, `Where-Object`, `Select-Object`, object/property discovery, platform installation | Local links and images pass | 4/4 present | `answers/01-answers.md`, 4/4 | `tests/ch-01.tests.ps1`, 4/4 | S2, S3, S6, S29 | Split Ubuntu and Debian installation into guarded procedures using their matching Microsoft feeds; corrected platform assumptions and object-versus-text explanations | reviewed
`chapters/02-the-console.md` | Help, history, aliases, quoting, completion, profile paths | Local links and images pass | 4/4 present | `answers/02-answers.md`, 4/4 | `tests/ch-02.tests.ps1`, 4/4 | S2, S3, S7 | Replaced host-specific paths and clarified profiles, aliases, and native-command behavior | reviewed
`chapters/03-commands-and-cmdlets.md` | Command discovery, parameters, provider paths, sorting, selecting | Local links and images pass | 4/4 present | `answers/03-answers.md`, 4/4 | `tests/ch-03.tests.ps1`, 4/4 | S6-S8 | Made discovery examples portable and aligned parameter/pipeline explanations | reviewed
`chapters/04-variables-and-types.md` | Variables, arrays, hashtables, casts, strings, automatic variables | Local links and images pass | 4/4 present | `answers/04-answers.md`, 4/4 | `tests/ch-04.tests.ps1`, 4/4 | S7 | Corrected collection/type behavior and removed environment-specific assumptions | reviewed
`chapters/05-operators-and-expressions.md` | Equality, containment, regex, ranges, replacement, arithmetic | Local links and images pass | 4/4 present | `answers/05-answers.md`, 4/4 | `tests/ch-05.tests.ps1`, 4/4 | S4, S5, S14 | Corrected invariant-culture/case semantics, range materialization, and unsafe secret comparison advice | reviewed
`chapters/06-control-flow.md` | Conditions, loops, `switch`, validation, retry flow | Local links and images pass | 4/4 present | `answers/06-answers.md`, 4/4 | `tests/ch-06.tests.ps1`, 4/4 | S4, S5, S13 | Added retry validation and clarified loop/switch collection behavior | reviewed
`chapters/07-functions-and-scripts.md` | Advanced functions, parameter binding, pipeline blocks, `ShouldProcess` | Local links and images pass | 4/4 present | `answers/07-answers.md`, 4/4 | `tests/ch-07.tests.ps1`, 4/4 | S8, S9 | Distinguished `CmdletBinding` from `SupportsShouldProcess` and corrected output-stream guidance | reviewed
`chapters/08-the-pipeline-deep-dive.md` | Streaming, formatting, grouping, parallel execution, information stream | Local links and images pass | 4/4 present | `answers/08-answers.md`, 4/4 | `tests/ch-08.tests.ps1`, 4/4 | S6, S7, S20 | Corrected streaming-versus-buffering, format sink, parallelism, and `Write-Host` claims | reviewed
`chapters/09-working-with-files.md` | Providers, path joins, text/CSV/JSON encoding, temp paths, filesystem operations | Local links and images pass | 4/4 present | `answers/09-answers.md`, 4/4 | `tests/ch-09.tests.ps1`, 4/4 | S10-S12 | Updated PowerShell 7 encoding, CSV/JSON, canonical temp-path, and path-containment examples | reviewed
`chapters/10-error-handling.md` | Terminating errors, `try/catch/finally`, native exits, retry, cleanup | Local links and images pass | 4/4 present | `answers/10-answers.md`, 4/4 | `tests/ch-10.tests.ps1`, 4/4 | S7, S13 | Added native-command error-policy caveat and corrected collection matching/error behavior | reviewed
`chapters/11-regex-and-text.md` | .NET regex, `-match`, captures, replacements, parsing | Local links and images pass | 4/4 present | `answers/11-answers.md`, 4/4 | `tests/ch-11.tests.ps1`, 4/4 | S4, S14 | Clarified scalar versus collection `-match`, capture scope, and literal/regex distinctions | reviewed
`chapters/12-modules-and-packages.md` | Module manifests, import/export, `Find/Install/Update-PSResource`, repositories | Local links and images pass | 4/4 present | `answers/12-answers.md`, 4/4 | `tests/ch-12.tests.ps1`, 4/4 | S15, S16 | Migrated package examples to PSResourceGet and current Pester install/version guidance | reviewed
`chapters/13-objects-and-dotnet.md` | Type inspection, members, classes, .NET APIs, TCP checks | Local links and images pass | 4/4 present | `answers/13-answers.md`, 4/4 | `tests/ch-13.tests.ps1`, 4/4 | S3, S7 | Replaced platform-specific probes with portable .NET/path/TCP patterns and qualified Windows-only APIs | reviewed
`chapters/14-remote-and-jobs.md` | SSH/WSMan remoting, sessions, background/thread jobs, parallel work | Local links and images pass | 4/4 present | `answers/14-answers.md`, 4/4 | `tests/ch-14.tests.ps1`, 4/4 | S17-S20 | Removed insecure policy bypasses and credentials, documented SSH subsystem setup, Windows WSMan/JEA boundaries, and job lifetime/isolation | reviewed
`chapters/15-active-directory.md` | AD filters, create/update/disable, groups, bulk changes, `WhatIf`, staged failure reporting | Local links and images pass | 4/4 present | `answers/15-answers.md`, 4/4 | `tests/ch-15.tests.ps1`, 4 exercise checks plus 2 Ex-4 failure-mode regressions | S9, S13, S21 | Replaced the unsafe completion claim with terminating AD calls, `WhatIf` with zero mutations, explicit partial-success state, and opt-in compensating cleanup that is not described as transactional | reviewed
`chapters/16-automation-recipes.md` | Cleanup, backup/retention, CIM/HTML, scheduled tasks, alert adapters, drift | Local links and images pass | 4/4 present | `answers/16-answers.md`, 4/4 | `tests/ch-16.tests.ps1`, 4/4 | S9, S13, S22, S23, S28 | Gated every backup mutation, made inventory exercise portable, labeled Windows-only recipes, replaced obsolete mail transport, and corrected retention timestamp semantics | reviewed
`chapters/17-devops-and-cicd.md` | Pester config/mocks, PSScriptAnalyzer, `#Requires`, GitHub/Azure CI, PSResourceGet publishing | Local links and images pass | 4/4 present | `answers/17-answers.md`, 4/4 | `tests/ch-17.tests.ps1`, 4/4 | S15, S24-S27 | Updated Pester 6/current floor, fixed build result handling/XML output, set reviewed action tags to checkout 7.0.1, cache 6.1.0, and upload-artifact 7.0.1, hardened workflow permissions/credentials, and corrected information-stream claims | reviewed
`appendices/A-cheat-sheet.md` | Core syntax, pipeline, objects, errors, files, modules, remoting quick reference | Local links pass | n/a: reference-only appendix | n/a: no exercise to solve | n/a: no executable exercise | S4-S20 | Updated cross-platform paths, current PSResourceGet commands, output streams, and current syntax caveats | reviewed
`appendices/B-common-errors.md` | Parser/runtime errors, command/module discovery, remoting, permissions, native exits | Local links pass | n/a: reference-only appendix | n/a: no exercise to solve | n/a: no executable exercise | S2, S3, S7, S13, S15, S17-S20 | Replaced unsafe execution-policy advice, added platform-aware diagnostics, and aligned package/remoting fixes | reviewed
`appendices/C-from-bash-to-powershell.md` | Shell command translation, paths, streams, processes, package tools | Local links pass | n/a: reference-only appendix | n/a: no exercise to solve | n/a: no executable exercise | S3, S6, S7, S10, S15 | Corrected object-pipeline differences, quoting/encoding, portable temp paths, and package-command translations | reviewed

## Validation notes

- Exercise contract: chapters 01-17 each contain exactly four exercises; each
  has one matching four-answer file and one Pester file. There are 68 primary
  exercise checks plus 2 additional Chapter 15 failure-mode checks (70 total).
- Compatibility contract: all exercise tests and the canonical runner require
  Pester 5.7.1 or later. The complete suite passes on both Pester 5.7.1 and
  6.0.1 under PowerShell 7.6.4.
- Appendix contract: appendices are intentionally reference-only. They add no
  exercise or answer IDs, so answer/test cells are explicitly n/a.
- External references above are documentation sources, not build inputs; the
  book remains reproducible offline from tracked Markdown and image assets once
  Pandoc, Typst, and fonts are installed.

## PDF visual inspection

Both editions were rebuilt with
`python3 scripts/build_book.py --edition all --format all`. Pages were rendered
at 120 DPI with `pdftoppm` and inspected as PNGs. After the remediation review,
the main guide is 202 pages and the answer booklet is 281 pages.

| Check | Edition and page | Finding |
| --- | --- | --- |
| Cover | Main, p. 1 | Full-bleed cover art is centered, sharp, and free of clipping or unintended margins. |
| Table of contents | Main, p. 3 (continues through p. 7) | Generated outline is readable, aligned, and points to the correct content pages. The audit discovered that the first build omitted a TOC; `book/template.typ` and its PDF contract test were corrected before this inspection. |
| First content page | Main, p. 8 | Preface heading, quotation, body text, opening illustration, table start, and page number render cleanly without overlap. |
| Code-heavy page | Main, p. 74 | Monospace pipeline examples remain legible, wrap inside the text area, and do not collide with headings, illustration, or footer. |
| Distribution procedures | Main, p. 14 | Ubuntu and Debian headings, guards, feed URLs, and commands are distinct, legible, and contained on one page. |
| AD remediation | Main, p. 147; answer booklet, p. 269 | Staged result and non-transaction warning render legibly. A heading/code collision found during the spot check was corrected with introductory prose and rechecked. |
| Action-version remediation | Main, p. 170; answer booklet, p. 278 | Exact checkout and upload-artifact tags render intact in YAML and the exercise solution. |
| Image-heavy page | Main, p. 149 | Chapter 16 opener artwork is sharp and contained; heading and following prose remain balanced on the page. |
| Answer-edition boundary | Answer booklet, p. 204 | Answer-booklet introduction starts on a clean page immediately after the shared guide/appendices; hierarchy and verification command are legible. |
| Final page | Main, p. 202 | Full-bleed back-cover art fills the page without clipping, stray text, or a trailing blank sheet. |

Text extraction additionally confirmed that the main content ends on p. 201,
the answer content ends on p. 280, and each edition's final page is its intended
back cover. `pdfinfo` reports title and author metadata correctly for both PDFs.

### Poppler `Suspects` interoperability note

With Typst 0.14.2 and Poppler `pdfinfo` 24.02.0, `pdfinfo` exits successfully
but writes `Syntax Error: Suspects object is wrong type (boolean)` for the
generated tagged PDF 1.7 files. A one-line Typst document reproduces the same
warning, which isolates it from this book's content and template. `mutool`
1.23.10 reads the files successfully and shows the relevant dictionary as
`/MarkInfo << /Marked true /Suspects false >>`; the PDF 1.7 reference defines
`Suspects` as a Boolean. Typst issue #7140 records the same minimal reproduction
and identifies a Poppler condition that emits the warning when the valid value
is `false`.

Forcing PDF 1.5 suppresses the warning by omitting the PDF 1.6-era `Suspects`
entry, and `--no-pdf-tags` would also avoid the path by removing accessibility
tagging. Neither workaround fixes the book, and both change valid default PDF
semantics only to accommodate a reader diagnostic. The build therefore keeps
tagged PDF 1.7 output and retains all existing nonempty-file, metadata, text,
page-boundary, and visual checks. This warning is documented rather than
silenced or converted into a weaker validation path. Sources: S30.
