# Office Productivity Palette v2.0.0

Office Productivity Palette v2.0.0 is a direct-use Windows executable that provides a command palette, action board, snippet and task workflows, selection-based utilities, and office-oriented keyboard shortcuts.

> **Limited-source warning:** The repository publishes only six selected AHK files. That subset is **not independently runnable or rebuildable** and **cannot reproduce the EXE**. It is not the complete application source.

## System and artifact

- Supported operating systems stated by the approved main source: Windows 10 and Windows 11.
- Executable: `office_productivity_palette_v2.0.0.exe`
- Distribution form: standalone executable; no installer is claimed.

## Direct use

1. Download `office_productivity_palette_v2.0.0.exe` from the v2.0.0 release assets.
2. Verify its SHA-256 checksum using the command below.
3. Run the executable on Windows 10 or Windows 11.

Windows may display its normal security prompt for a downloaded executable. Review the file name and verified checksum before choosing whether to run it. No code-signing claim is made.

## Primary hotkeys verified from the main source

| Hotkey | Action |
|---|---|
| Double-tap Shift | Open the universal command palette |
| `Ctrl+Space` | Open the command palette (fallback) |
| Double-tap Ctrl | Capture selected text as a task |
| `Win+T` or `Win+Shift+T` | Toggle the action board |
| `Ctrl+Shift+T` | Capture selected text as a task |
| `Ctrl+Shift+H` | Save selected text as a snippet |
| `Ctrl+Shift+U` | Open the civil and construction converter |
| `Win+Esc` | Open the snippet manager |
| `Ctrl+H` or `F12` | Open in-selection find and replace |
| `Win+0` or `Ctrl+0` | Repeat the last action |
| `Win+Shift+;` or `Win+Shift+Space` | Activate the leader key |
| `Alt+Shift+D` | Insert an ISO date outside Microsoft Word |
| `Alt+Shift+T` | Insert a 12-hour time outside Microsoft Word |
| `Ctrl+Shift+G` | Show word and character statistics outside Microsoft Word |
| `Shift+F3` | Cycle selected-text case outside Microsoft Word |

## Verify the executable

From PowerShell in the folder containing the downloaded file:

```powershell
Get-FileHash -Algorithm SHA256 -LiteralPath .\office_productivity_palette_v2.0.0.exe
```

Expected SHA-256:

```text
1D51880EAEEDE855A139FB3C215882EC1138E101DDA1843963AF918EC728CCE7
```

The audited executable size is 1,753,088 bytes. If the computed hash differs, do not use the file as this audited v2.0.0 artifact.

## Source and license

The published material is provided under **GPL-3.0-or-later**; see `LICENSE`. The public audit in `docs/PUBLIC_AUDIT.md` records the selected-source inventory, include coverage, executable checksum, screenshot evidence, scan summary, method, and limitations.

The public subset omits 23 of the main script’s 28 declared include targets. It therefore does not support an independent source run, a complete rebuild, or a reproducible build of `office_productivity_palette_v2.0.0.exe`.
