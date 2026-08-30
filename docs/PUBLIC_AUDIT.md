# Public Audit — v2.0.0

**Audit date:** 2026-08-30
**Public scope:** the six AHK files under `src/`, the three PNG files under `docs/images/`, and the separately distributed Windows executable named below. This audit does not cover unpublished modules, development files, runtime data, or any other private material.

> **Important:** The published source is a limited subset. It is **not independently runnable or rebuildable**, and it **cannot reproduce the EXE**.

## Evidence status

| Evidence | Reproducibility status |
|---|---|
| Published AHK inventory, raw hashes, byte counts, line counts, includes, and screenshot hashes | Publicly reproducible now from repository files |
| Comparison with the complete approved private-source reference set | Operator-local only; not publicly reproducible by design |
| Executable size and hash in the publication-state review | Operator-local evidence; the EXE remains intentionally outside Git history |
| Embedded executable version metadata | Operator-local evidence: Windows `FileVersion` and `ProductVersion` report 2.0.26, while the owner-designated release is v2.0.0 |
| Designated public executable location | [v2.0.0 release page](https://github.com/NishantAgarwal03/office-productivity-palette/releases/tag/v2.0.0) and [`office_productivity_palette_v2.0.0.exe` asset](https://github.com/NishantAgarwal03/office-productivity-palette/releases/download/v2.0.0/office_productivity_palette_v2.0.0.exe); public availability and downloaded-byte identity require post-upload verification |

## Published AHK inventory

Hashes are raw-file SHA-256 values. Line counts use text lines as read from each unmodified file; bytes are raw file sizes.

| Repository-relative path | Bytes | Lines | SHA-256 |
|---|---:|---:|---|
| `src/office_productivity_palette_v2.0.0.ahk` | 7,854 | 235 | `C7AD59BD61EE3A7F25AC73BB89AB940CE76B0638A09768BF310DFAAEEB23F7E2` |
| `src/Lib/ActionBoardGui.ahk` | 17,242 | 402 | `AE729B81CEE3C49E8313883BAF23AF4B663CB43DCBBFE696A46D17CA38EF0107` |
| `src/Lib/ActionBoardPills.ahk` | 11,486 | 269 | `654E0A646E78B0CDAA58DE366EBFB570D178AF1AAA2AF6B6CD4B152BA9DD5274` |
| `src/Lib/Actions_Math.ahk` | 13,539 | 272 | `323A2A2E10CFBBA4B7F083C9C214194096E9802C03CCCF27B1BF69216B1F9142` |
| `src/Lib/Actions_WindowPeek.ahk` | 1,229 | 14 | `317B7C3A84D24130C0D2797E88536E1B5A8DF5B70D6DC2BBF70E0E9FD4A2A774` |
| `src/Lib/CSVParser.ahk` | 2,362 | 71 | `1CBFBA01D30A00B21EB4202BACE520AB9CA46AD7256361755DCEB06CDE29A243` |
| **Aggregate** | **53,712** | **1,263** | — |

### Approved private-source comparison

This comparison is **operator-local, not publicly reproducible by design** because the complete private source is intentionally excluded from publication. For each inventory row, the operator mapped the repository-relative approved file path beneath `src/` to the same relative path in the private-source reference set, then compared both the raw SHA-256 value and byte count. All six pairs matched on 2026-08-30.

Public readers can independently verify the repository blobs, byte counts, and hashes in this audit. They cannot independently verify the excluded private reference set or repeat the private-side comparison.

## Runtime requirement

The approved main source declares `#Requires AutoHotkey v2.0`. This verifies the source-language requirement for the selected source; it does not make the limited public subset runnable.

## Include audit

The main script declares **28** `#Include` directives. **5** targets are present in the six-file public subset and **23** are excluded or absent from that subset. The final three parent-relative includes are external private dependencies and are intentionally marked **private/excluded**, not audit errors.

| Declared include | Public-subset status |
|---|---|
| `Lib/Globals.ahk` | Excluded from public subset |
| `Lib/CSVParser.ahk` | Present |
| `Lib/ClipboardHelper.ahk` | Excluded from public subset |
| `Lib/NumberParser.ahk` | Excluded from public subset |
| `Lib/MathEvaluator.ahk` | Excluded from public subset |
| `Lib/Telemetry.ahk` | Excluded from public subset |
| `Lib/SnippetManager.ahk` | Excluded from public subset |
| `Lib/SnippetGui.ahk` | Excluded from public subset |
| `Lib/TaskManager.ahk` | Excluded from public subset |
| `Lib/ActionBoardPills.ahk` | Present |
| `Lib/ActionBoardGui.ahk` | Present |
| `Lib/PaletteGui.ahk` | Excluded from public subset |
| `Lib/Core.ahk` | Excluded from public subset |
| `Lib/Actions_DateTime.ahk` | Excluded from public subset |
| `Lib/Actions_Text.ahk` | Excluded from public subset |
| `Lib/Actions_Email.ahk` | Excluded from public subset |
| `Lib/Actions_Math.ahk` | Present |
| `Lib/Actions_Finance.ahk` | Excluded from public subset |
| `Lib/Actions_Extraction.ahk` | Excluded from public subset |
| `Lib/Actions_Utility.ahk` | Excluded from public subset |
| `Lib/Actions_WindowPeek.ahk` | Present |
| `Lib/WindowPeekHotkeys.ahk` | Excluded from public subset |
| `Lib/CivilConverterEngine.ahk` | Excluded from public subset |
| `Lib/CivilConverterGui.ahk` | Excluded from public subset |
| `Lib/Actions_CivilConvert.ahk` | Excluded from public subset |
| `../Study_MarkdownHub v2.0/Lib/Actions_FindReplace.ahk` | Private/excluded external relative dependency |
| `../Study_MarkdownHub v2.0/Lib/Hotstrings_Prompts.ahk` | Private/excluded external relative dependency |
| `../Word Count Tooltip.ahk` | Private/excluded external relative dependency |

## Windows executable

| Artifact | Owner-designated release | Embedded FileVersion | Embedded ProductVersion | Bytes | Last modified | Signature status | Raw SHA-256 |
|---|---|---|---|---:|---|---|---|
| `office_productivity_palette_v2.0.0.exe` | v2.0.0 | 2.0.26 | 2.0.26 | 1,753,088 | 2026-08-30 03:26:08 +05:30 | Not signed | `2CA9F72CAABF9EEADC90E7C44A93A2A4AAECB673399965AD625747562AFD7741` |

The difference between the embedded **2.0.26** version values and the owner-designated **v2.0.0** release/filename is a known metadata mismatch and is not claimed to be fixed. It is not evidence of a different download. Readers should identify the reviewed artifact by the exact filename, size, and SHA-256 recorded above.

The EXE is intentionally outside Git history. Its designated publication locations are the [v2.0.0 GitHub Release](https://github.com/NishantAgarwal03/office-productivity-palette/releases/tag/v2.0.0) and the direct [`office_productivity_palette_v2.0.0.exe` asset URL](https://github.com/NishantAgarwal03/office-productivity-palette/releases/download/v2.0.0/office_productivity_palette_v2.0.0.exe). This audit does not claim that an upload has already been verified: public availability, exact asset naming, size, and downloaded SHA-256 remain post-upload checks.

After downloading the published asset, run these commands from its containing directory:

```powershell
Get-Item .\office_productivity_palette_v2.0.0.exe
Get-FileHash .\office_productivity_palette_v2.0.0.exe -Algorithm SHA256
```

The expected `Length` is exactly **1,753,088 bytes**. The expected SHA-256 is exactly:

```text
2CA9F72CAABF9EEADC90E7C44A93A2A4AAECB673399965AD625747562AFD7741
```

The executable is audited as a binary artifact. No claim is made that it can be rebuilt from the public source subset.

## Screenshot inventory

The existing screenshots were captured from the earlier reviewed build and were not recaptured for the newly designated binary at the owner's direction. They are illustrative UI evidence, not attestation of this binary version.

| Repository-relative path | Dimensions | SHA-256 |
|---|---:|---|
| `docs/images/action-board-demo.png` | 1220 × 860 | `53EFDDFB91C25CD71FC4D9D553F6A7FE8774DDF6B1E6D819FC429650407FE7AE` |
| `docs/images/command-palette-query.png` | 1400 × 480 | `B96A1BA24EF5818115E748A4ACFAEAD808CF5FB594700BD926B21370F55AFFFB` |
| `docs/images/representative-tool-query.png` | 520 × 100 | `B67CB775B865ACC9C4ECD2F0DD99E6F9A6C6DB8B71AB22C58952E754A9D10EB6` |

## Secret-scan summary

The textual scan used **ripgrep 15.2.0**. It covered repository publication text (`LICENSE`, Markdown, configuration, and the six AHK files), excluding `.git`, PNG screenshots, and executable files. The same expressions were applied operator-locally to the corresponding six approved private-source text files without recording their private root. From the repository root, the exact public scan command was:

```powershell
rg -n --hidden -g '!.git/**' -g '!docs/images/**' -g '!*.exe' -e '(?i)(api[_-]?key|secret|token|password)\s*[:=]\s*["'']?[^\s"'']+' -e '(?i)\bAuthorization\s*[:=]\s*\S+|\bBearer\s+\S+' -e '-----BEGIN [A-Z ]*PRIVATE KEY-----' -e '(?i)([A-Z]:\\Users\\[^\\\s]+|[A-Z]:\\)' .
```

These expressions cover API-key assignments, secret/token/password assignments, Authorization or Bearer material, private-key headers, Windows user-home paths, and Windows drive paths.

The exact public command returned one contextual self-match: this audit's own sentence describing the pattern categories. It contained no credential value. A broader keyword-only review also produced false positives from password-generator feature text, ordinary uses of “token” in documentation, and GPL text discussing authorization keys or passwords. No credential material, private key, access token, or absolute user-home path was identified, and no matched value is reproduced here.

The three PNG screenshots were separately inspected visually on 2026-08-30. That manual review found application UI and sample task/query content but no visible credential, username, user-home path, or machine identifier. This was a visual inspection, not OCR or a textual scan.

## Method and limitations

- Raw byte sizes and SHA-256 values were computed directly from the audited files.
- Text line counts were obtained by reading logical lines without normalizing file bytes.
- Main-script includes were parsed from every `#Include` directive and resolved against the six published AHK paths for the public-subset count.
- Screenshot dimensions were read from the PNG metadata; hashes cover the raw PNG files.
- Public AHK files were checked against corresponding approved-source files by raw SHA-256 and byte count using the relative-path mapping described above; the private side of that check is operator-local only.
- The secret scan is heuristic and is not proof of absence. Screenshot pixels were manually inspected but not OCR-scanned. The binary EXE was hashed and sized but was not content-scanned.
- The audit does not establish code signing, provenance beyond the stated comparisons, runtime correctness, complete-source availability, or reproducible builds.
- The embedded `FileVersion` and `ProductVersion` are 2.0.26 even though the owner-designated release and filename are v2.0.0. This known metadata mismatch remains a limitation and is not claimed to be fixed; artifact identity rests on the exact filename, size, and SHA-256.
- Because 23 declared dependencies are not published in the six-file subset, the subset cannot be used to run the main script, rebuild the product, or reproduce the executable.
