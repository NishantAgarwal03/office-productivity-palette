# Office Productivity Palette & Action Hub

This is the feature guide for the complete, self-contained v2.0.1 source release. The project is licensed **GPL-3.0-or-later**; read the repository [README](../README.md), [LICENSE](../LICENSE), and [AUTHORS.md](../AUTHORS.md) before redistributing modified versions.

## Source layout

- `office_productivity_palette_v2.0.1.ahk` is the AutoHotkey v2 application entry point.
- `Lib/` contains the application modules, including every dependency included by the entry point.
- `Tests/` contains the automated verification suite and [run_tests.py](../Tests/run_tests.py).
- `CivilEngineeringDefaults.ini` contains non-personal converter defaults.

The source tree is complete: run the entry point with AutoHotkey v2 or compile that same entry point with Ahk2Exe. For a compiled executable, place `CivilEngineeringDefaults.ini` beside the executable so it can load the supplied defaults. See the root [README](../README.md#run-from-source) for exact source-run, test, and reproducible build instructions.

## Main capabilities

The palette provides keyboard-driven access to text transformations, calculations, civil and finance utilities, date conversion, extraction tools, snippets, a four-quadrant task board, window tools, and the Workflow Composer. The command palette opens with Double-Shift; use its search to discover available actions and their hotkeys.

Workflow Composer can combine built-in actions into saved recipes. A clean installation begins with an empty recipe catalog, so no example, personal, or historical recipes are provided.

Task, snippet, recipe, settings, diagnostic, history, and telemetry artifacts are runtime-local state. They are excluded from the public source tree and are not required to build the application.

## Vendored modules

These dependencies are present in this source tree rather than referenced from external local paths:

- [Actions_FindReplace.ahk](../Lib/Actions_FindReplace.ahk), from `Study_MarkdownHub v2.0/Lib/Actions_FindReplace.ahk`.
- [Hotstrings_Prompts.ahk](../Lib/Hotstrings_Prompts.ahk), from `Study_MarkdownHub v2.0/Lib/Hotstrings_Prompts.ahk`.
- [WordCountTooltip.ahk](../Lib/WordCountTooltip.ahk), from `Word Count Tooltip.ahk`.

They are attributed to Nishant Agarwal in [AUTHORS.md](../AUTHORS.md) and distributed with the rest of this project under GPL-3.0-or-later.

## Verification

Run the full suite from the repository root:

```powershell
python .\Tests\run_tests.py
```

The harness validates application behavior and checks that `#Include` directives remain repository-local. Keep generated test output, logs, and sandbox data out of version control.
