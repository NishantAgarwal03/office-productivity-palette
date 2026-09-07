# Public Audit Summary — v2.0.1

**Audit date:** 2026-09-07

**Release:** `v2.0.1 — Expanded Source Preview`

This summary records the publication checks performed for the v2.0.1 repository update and separately distributed Windows executable. The private combined audit PDF was reviewed but is not published because it predates later v2.0.1 changes.

## Publication inventory

| Item | Public status | Verification |
|---|---|---|
| Complete current `src/Lib` folder | Published | 46 AHK files; 626,986 bytes; 14,677 text lines; staged copies matched the approved private files by relative path and SHA-256 |
| Previously published v2.0.0 main script | Retained | Historical source retained unchanged |
| v2.0.1 main script | Excluded | Not approved for this phase |
| v2.0.1 EXE | GitHub Release asset only | Exact metadata and checksum recorded below |
| Existing screenshots | Retained | Representative earlier views; not recaptured for v2.0.1 |
| INI/CSV runtime data, tests, logs, scratch files, spreadsheets, and private audit PDF | Excluded | Not copied into the publication tree |

The public source is an expanded but incomplete preview. Without the v2.0.1 main script and other build-required files, it cannot run independently, rebuild the application, or reproduce the EXE.

## Fresh test evidence

The private source tree's zero-trust master harness was run on 2026-09-07 as the release candidate was prepared:

| Suite | Passed |
|---|---:|
| Core suite | 501/501 |
| Integration | 74/74 |
| Civil converter | 128/128 |
| Civil exhaustive | 179/179 |
| Modularity | 58/58 |
| Workflow Composer | 76/76 |
| Regression defects | 188/188 |
| UI interaction | 90/90 |
| **Total** | **1,294/1,294** |

All ten harness integrity invariants passed. The dependency audit checked 56 production and test AHK files with no external `<Lib>` leaks. A 139-file closed-world manifest showed no additions, deletions, mutations, or leaks during testing. Automated tests validate asserted cases, not every possible behavior.

## Executable identity

| Artifact | Owner release | Embedded versions | Bytes | Signature | SHA-256 |
|---|---|---|---:|---|---|
| `office_productivity_palette_v2.0.1.exe` | v2.0.1 | FileVersion 2.0.26; ProductVersion 2.0.26 | 1,924,096 | Not signed | `A9E6F71BB62419006633126F1206699A7814A43D12DCEB0F03CE058F3CC7060B` |

The embedded version differs from the release identity. Identify the reviewed artifact by its exact filename, byte size, and SHA-256.

After downloading, verify it with:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath .\office_productivity_palette_v2.0.1.exe
```

## Public-safety review

The 46 library files were scanned for Windows user-home paths, credential assignments, authorization tokens, private-key headers, and email-like strings. No private path, credential, access token, or private key was identified. One synthetic example address, `john.doe@example.com`, remains in source as a sample snippet value.

Runtime data was deliberately excluded. Users should treat snippet files, workflow run history, telemetry output, and exported diagnostics as potentially sensitive because they may contain selected text, clipboard content, filenames, window titles, queries, or error context.

The scan is heuristic and does not prove the absence of every possible sensitive value. The EXE was identified by metadata and checksum but was not code-signed or independently authenticated.

## License and limits

Published source files are licensed under GNU GPL v3.0 or later (`GPL-3.0-or-later`). Complete corresponding source for the v2.0.1 EXE is not available in this publication, so no claim is made that the current binary distribution is GPLv3-compliant.

This audit does not establish a reproducible build, complete-source availability, code signing, publisher authentication, exhaustive security, or defect-free behavior.
