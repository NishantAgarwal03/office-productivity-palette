# Office Productivity Palette v2.0.1 — Expanded Source Preview

Office Productivity Palette v2.0.1 is a more stable direct-use Windows release with a much broader source preview for developers who want to review, suggest improvements, or contribute ideas.

## Download and try it

Download `office_productivity_palette_v2.0.1.exe` from this release's assets. It is a standalone executable, not an installer, and is intended for Windows 10 and Windows 11.

Before launching, verify the file:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath .\office_productivity_palette_v2.0.1.exe
```

- Size: **1,924,096 bytes**
- SHA-256: `A9E6F71BB62419006633126F1206699A7814A43D12DCEB0F03CE058F3CC7060B`
- Embedded `FileVersion`: **2.0.26**
- Embedded `ProductVersion`: **2.0.26**
- Code signature: **Not signed**

The embedded version remains 2.0.26 while the owner-designated release and filename are v2.0.1. Use the exact filename, size, and SHA-256 above to identify the reviewed artifact.

## Highlights

- **Workflow Composer and Pipeline Runner:** Build, validate, preview, save, reopen, and run reusable multi-step recipes with selectable inputs, outputs, loops, explicit final outputs, and per-step inspection.
- **Safer workflow previews:** Preview runs suppress normal sinks, notifications, and history recording while exposing step inputs and outputs for review.
- **Date conversion:** Preview nine common formats, remember the preferred default, and handle a broader range of date inputs.
- **Civil-engineering workflows:** Improved calculations and practical 3-4-5/Guniya guidance for site use.
- **Better palette input:** Numeric queries can be typed normally; visible results use `Alt+1` through `Alt+9` for quick execution.
- **Everyday refinements:** More reliable Action Board selection, clearer percentage-growth reporting, distinct Indian/international number-format actions, a visible pinned-window marker, run history, and stronger recipe validation.

## Verification summary

A fresh pre-release run completed **1,294/1,294 assertions across eight suites** with zero failures. The harness also verified all ten integrity invariants, including 56 production and test AHK files with no external `<Lib>` leaks and a closed-world manifest with no additions, deletions, mutations, or leaks during testing.

The supplied earlier audit informed the release review, but its older score and 666-test result predate the final v2.0.1 changes and are not used as current release evidence. Automated checks prove only the cases they assert; this release is not represented as defect-free.

## Expanded source preview

This release expands the public review surface from five selected library modules to the complete current **46-file `Lib` folder**: **626,986 bytes** and **14,677 text lines**. The repository also retains the previously published v2.0.0 main script.

The v2.0.1 main script and other build-required files are intentionally not included in this phase. As a result, the published source cannot run independently, rebuild the application, or reproduce the EXE. The expanded library set is provided for focused code review, suggestions, and improvement.

INI settings, CSV user data, tests, logs, developer scratch files, spreadsheets, the private audit PDF, and other unapproved files are not published.

## License position

The files published as source in the repository are licensed under GNU GPL v3.0 or later (`GPL-3.0-or-later`). Complete corresponding source for the v2.0.1 EXE is not published, so no claim is made that the current EXE distribution is GPLv3-compliant.

Feedback, practical use cases, stability reports, and improvement suggestions are welcome through the repository's issue tracker.
