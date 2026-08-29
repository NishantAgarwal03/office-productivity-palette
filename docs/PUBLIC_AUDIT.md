# Public Audit — v2.0.0

**Audit date:** 2026-08-30
**Public scope:** the six AHK files under `src/`, the three PNG files under `docs/images/`, and the separately distributed Windows executable named below. This audit does not cover unpublished modules, development files, runtime data, or any other private material.

> **Important:** The published source is a limited subset. It is **not independently runnable or rebuildable**, and it **cannot reproduce the EXE**.

## Published AHK inventory

Hashes are raw-file SHA-256 values. Line counts use text lines as read from each unmodified file; bytes are raw file sizes.

| Repository-relative path | Bytes | Lines | SHA-256 |
|---|---:|---:|---|
| `src/office_productivity_palette_v2.0.0.ahk` | 7,854 | 235 | `C7AD59BD61EE3A7F25AC73BB89AB940CE76B0638A09768BF310DFAAEEB23F7E2` |
| `src/Lib/ActionBoardGui.ahk` | 17,234 | 402 | `38AFDEEA72D6B43E3E1ADA2B878248F199BC7D94DE8DAB17BD140FAE8EBA7422` |
| `src/Lib/ActionBoardPills.ahk` | 11,486 | 269 | `654E0A646E78B0CDAA58DE366EBFB570D178AF1AAA2AF6B6CD4B152BA9DD5274` |
| `src/Lib/Actions_Math.ahk` | 13,539 | 272 | `323A2A2E10CFBBA4B7F083C9C214194096E9802C03CCCF27B1BF69216B1F9142` |
| `src/Lib/Actions_WindowPeek.ahk` | 1,229 | 14 | `317B7C3A84D24130C0D2797E88536E1B5A8DF5B70D6DC2BBF70E0E9FD4A2A774` |
| `src/Lib/CSVParser.ahk` | 2,362 | 71 | `1CBFBA01D30A00B21EB4202BACE520AB9CA46AD7256361755DCEB06CDE29A243` |
| **Aggregate** | **53,704** | **1,263** | — |

Each of these six public blobs was compared by raw SHA-256 with its corresponding approved-source file and was byte-identical on the audit date.

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

| Artifact | Bytes | Raw SHA-256 |
|---|---:|---|
| `office_productivity_palette_v2.0.0.exe` | 1,753,088 | `1D51880EAEEDE855A139FB3C215882EC1138E101DDA1843963AF918EC728CCE7` |

The executable is audited as a binary artifact. No claim is made that it can be rebuilt from the public source subset.

## Screenshot inventory

| Repository-relative path | Dimensions | SHA-256 |
|---|---:|---|
| `docs/images/action-board-demo.png` | 1220 × 860 | `53EFDDFB91C25CD71FC4D9D553F6A7FE8774DDF6B1E6D819FC429650407FE7AE` |
| `docs/images/command-palette-query.png` | 1400 × 480 | `B96A1BA24EF5818115E748A4ACFAEAD808CF5FB594700BD926B21370F55AFFFB` |
| `docs/images/representative-tool-query.png` | 520 × 100 | `B67CB775B865ACC9C4ECD2F0DD99E6F9A6C6DB8B71AB22C58952E754A9D10EB6` |

## Secret-scan summary

The scan covered repository publication text (`LICENSE`, Markdown, configuration, and the six AHK files) plus the corresponding six approved-source files. PNG contents were inventoried and hashed but were not OCR-scanned. Patterns covered common API-key and token labels and formats, authorization/bearer strings, private-key headers, password/secret terms, and absolute user-home paths.

No credential material, private key, access token, or absolute user-home path was identified. Context-only matches were classified as false positives: names and descriptions for the password-generator feature, ordinary uses of “token” in documentation, and GPL text discussing authorization keys or passwords. No matched value is reproduced here.

## Method and limitations

- Raw byte sizes and SHA-256 values were computed directly from the audited files.
- Text line counts were obtained by reading logical lines without normalizing file bytes.
- Main-script includes were parsed from every `#Include` directive and resolved against the six published AHK paths for the public-subset count.
- Screenshot dimensions were read from the PNG metadata; hashes cover the raw PNG files.
- Public AHK files were checked against corresponding approved-source files by raw SHA-256.
- The secret scan was pattern-based and is not proof that no sensitive information exists. Binary screenshot pixels were not OCR-scanned.
- The audit does not establish code signing, provenance beyond the stated comparisons, runtime correctness, complete-source availability, or reproducible builds.
- Because 23 declared dependencies are not published in the six-file subset, the subset cannot be used to run the main script, rebuild the product, or reproduce the executable.
