# Office Productivity Palette v2.0.0

Office Productivity Palette v2.0.0 is a direct-use Windows executable that provides a command palette, action board, snippet and task workflows, selection-based utilities, and office-oriented keyboard shortcuts.

> **Limited-source warning:** The repository publishes only six selected AHK files. That subset is **not independently runnable or rebuildable** and **cannot reproduce the EXE**. It is not the complete application source.

> **Phased-preview compliance warning:** Corresponding-source compliance for the distributed EXE remains unresolved because complete corresponding source is not currently published. No claim is made that the present binary distribution is GPLv3-compliant.

## System and artifact

- Supported operating systems stated by the approved main source: Windows 10 and Windows 11.
- Executable: `office_productivity_palette_v2.0.0.exe`
- Owner-designated release/tag identity: **v2.0.0**.
- Embedded Windows `FileVersion`: **2.0.26**.
- Embedded Windows `ProductVersion`: **2.0.26**.
- Distribution form: standalone executable; no installer is claimed.

The embedded **2.0.26** values and owner-designated **v2.0.0** release/filename form a known metadata mismatch that is not claimed to be fixed. This is not evidence of a different download. Identify the reviewed artifact by the exact filename, size, and SHA-256 in these notes.

## Direct use

1. [Download `office_productivity_palette_v2.0.0.exe`](https://github.com/NishantAgarwal03/office-productivity-palette/releases/download/v2.0.0/office_productivity_palette_v2.0.0.exe) from the [v2.0.0 release](https://github.com/NishantAgarwal03/office-productivity-palette/releases/tag/v2.0.0).
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
2CA9F72CAABF9EEADC90E7C44A93A2A4AAECB673399965AD625747562AFD7741
```

The audited executable size is 1,753,088 bytes. If the computed hash differs, do not use the file as this audited v2.0.0 artifact.

A matching checksum verifies byte identity and integrity against the audited value. It does not independently establish publisher authenticity.

## Source and license

The project owner licenses the files published in this repository under the GNU General Public License v3.0 or later (**GPL-3.0-or-later**). See [LICENSE](../LICENSE) for the complete GPLv3 terms. The [public audit](../docs/PUBLIC_AUDIT.md) records the selected-source inventory, include coverage, executable checksum, screenshot evidence, scan summary, method, and limitations.

The public subset omits 23 of the main script’s 28 declared include targets. It therefore does not support an independent source run, a complete rebuild, or a reproducible build of `office_productivity_palette_v2.0.0.exe`.
