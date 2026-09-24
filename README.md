# Office Productivity Palette & Action Hub

Office Productivity Palette & Action Hub is a keyboard-driven Windows productivity suite written for AutoHotkey v2. It includes a command palette, task board, snippets, text tools, calculations, workflow composition, and office utilities.

## License and authorship

This project is licensed under the GNU General Public License, version 3 or (at your option) any later version (**GPL-3.0-or-later**). See [LICENSE](LICENSE) for the complete license text and [AUTHORS.md](AUTHORS.md) for authorship and maintenance attribution.

This repository contains the complete source needed to run and rebuild this release. The primary entry point is `office_productivity_palette_v2.0.1.ahk`; all of its AutoHotkey includes are contained in this repository.

## Requirements

- Windows
- [AutoHotkey v2](https://www.autohotkey.com/v2/)
- Python 3.11 or later for the test harness
- Ahk2Exe, if you want to compile an executable

## Run from source

From the repository root in PowerShell:

```powershell
& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' .\office_productivity_palette_v2.0.1.ahk
```

## Test

Run the complete test harness from the repository root:

```powershell
python .\Tests\run_tests.py
```

The test sources and runner are in [Tests](Tests). They also audit that every `#Include` resolves inside the repository.

## Build an executable

Use Ahk2Exe with `office_productivity_palette_v2.0.1.ahk` as the source (entry point) and select an output location outside this repository, such as a folder under your user profile or a temporary build directory. Do not write compiled executables back into the checkout: generated `.exe` files are intentionally ignored.

With the standard AutoHotkey installation, a reproducible PowerShell build command is:

```powershell
& 'C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe' /in .\office_productivity_palette_v2.0.1.ahk /out "$env:USERPROFILE\Desktop\OfficeProductivityPalette.exe"
Copy-Item .\CivilEngineeringDefaults.ini "$env:USERPROFILE\Desktop\CivilEngineeringDefaults.ini"
```

The second command places `CivilEngineeringDefaults.ini` beside the compiled executable. The application loads that configuration relative to its script/executable directory, so this co-location is required for the compiled app to use the repository's supplied defaults.

## Clean first run and local data

A clean checkout starts with no tasks, snippets, recipes, settings, logs, history, or telemetry data. Runtime state is created locally only when features require it and is excluded by `.gitignore`; it is never part of this source release. The project does not seed example task, snippet, or recipe data.

## Vendored source dependencies

The following AutoHotkey modules are vendored in `Lib/` so a clone has a closed source dependency graph. They originated in Nishant Agarwal's local companion projects and are included here as project source under this repository's GPL-3.0-or-later release:

- [Lib/Actions_FindReplace.ahk](Lib/Actions_FindReplace.ahk) — originated in `Study_MarkdownHub v2.0/Lib/Actions_FindReplace.ahk`.
- [Lib/Hotstrings_Prompts.ahk](Lib/Hotstrings_Prompts.ahk) — originated in `Study_MarkdownHub v2.0/Lib/Hotstrings_Prompts.ahk`.
- [Lib/WordCountTooltip.ahk](Lib/WordCountTooltip.ahk) — originated in `Word Count Tooltip.ahk`.

For a feature-oriented guide, see [Docs/README_office_productivity_palette.md](Docs/README_office_productivity_palette.md).
