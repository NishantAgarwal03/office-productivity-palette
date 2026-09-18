# Pending Work — Next Session

**Written:** 2026-09-18, at the close of a session covering a deep audit (`Docs/LLM_DEVELOPMENT_GUIDELINES.md`) plus a round of bug fixes and architecture remediation. **Updated:** same day, session resumed — closed stale PR #1 and fixed 10 items (D2, D1-adjacent follow-up, D3, D5, D7, D8, D9, D10, R5, R6); see `subject_tracker.md` "Deep Audit, Bug Fixes & Architecture Remediation" for the full account of what changed and why, and DEFECT-043 through DEFECT-052 (DEFECT-051 in `Tests\test_regression_defects.ahk`, DEFECT-052 in `Tests\test_ui_interaction_runner.ahk`) for the regression coverage. **Updated again:** same day — diagnosed and fixed a user-reported keyboard-freeze incident, fixed a user-reported `CleanPlainText` defect (flattened HTML-table cells never rejoin), and did a full refresh of `Docs/README_office_productivity_palette.md`; all three **committed together** as `ebdd4ac`. See `subject_tracker.md`'s three new subjects and Section 0 below.

**Project state right now:** working tree is **clean**, everything through commit `ebdd4ac` (`fix: stuck-CapsLock watchdog, CleanPlainText table rejoin, README refresh`). `master` is **5 commits ahead of `origin/master`** — not pushed. Zero-Trust suite passes **1,381/1,381** across all 8 suites, closed-world manifest clean. The compiled `.exe` is stale relative to this and the prior update — recompile before treating the binary as current. No stray branches, no stray processes.

This file exists because the audit found more issues than one session should try to fix at once. Everything below is deferred **on purpose**, not forgotten. Read `Docs/LLM_DEVELOPMENT_GUIDELINES.md` first for full context on each finding's ID (R#/A#/D#) before touching any of this — it has the reasoning, not just the location.

---

## 0. Landed this update (commit `ebdd4ac`, not yet pushed)

**0a. Stuck-CapsLock self-healing watchdog.** The user reported keyboard input freezing system-wide ("every key pressed opened something else"), recoverable only by a full Windows logoff/logon — restarting the script didn't help. Telemetry showed no exception logged for the incident, ruling out a script crash. Root-caused to `Lib\WindowPeekHotkeys.ahk`'s `#HotIf GetKeyState("CapsLock", "P")` block (lines 80-114), which hijacks `t/v/s/x/c/p/w/n/Space/Tab/Esc/Up/Down` system-wide for as long as CapsLock reads *physically* held — OS-level state that can get stuck "down" forever if a key-up event is ever dropped (UAC prompt, lock screen, focus-stealing dialog). Restarting the script can't fix this because the stuck state lives in the OS input session, not script variables.

Added `CheckCapsLockStuckWatchdog()` (polls every 1s, yields to `PeekState`/`XRayState`'s own 10s-capped watchdogs) and `ForceReleaseStuckCapsLock()` (sends synthetic `{CapsLock Up}` via `SendInput` once physical-down persists 12s+ outside a legitimate session — injected input still passes through the low-level hook and resyncs AHK's internal physical-key state, clearing the condition without a logoff). Logs via `LogAppError`, shows a toast. Wired in via `InitCapsLockStuckWatchdog()` in `InitApp()`.

**Still open:** no DEFECT-0XX regression test — a real stuck-physical-CapsLock condition can't be forced through `GetKeyState` the way the suite mocks other conditions. Worth designing a harness for this (e.g. exposing `CheckCapsLockStuckWatchdog`/`ForceReleaseStuckCapsLock` to direct unit-style invocation with a stubbed physical-state source) before calling it fully covered. Verified so far via `AutoHotkey64.exe /validate` (clean) and the full suite (no regressions) — that's syntax + no-regression, not new-behavior coverage.

**0b. `CleanPlainText` flattened HTML-table cell rejoin.** The user reported "Paste Clean Plain Text" mangling a copied HTML table — each cell lands on its own line with a lone leftover tab character stranded where the column boundary used to be, and the tool only normalized whitespace, leaving every cell isolated (destroying the label/value association) despite its own description claiming to "strip HTML." Added `RejoinFlattenedTableCells()` (`Lib\Actions_Text.ahk`): detects a line that is nothing but tab/space characters sandwiched between two content lines, rejoins adjacent cells into one tab-delimited row, loops to a fixpoint so 3+ column rows fully chain, and deliberately requires an actual tab/space char on the separator line so it never fires on an ordinary paragraph break. **Fully covered** — DEFECT-053 in `Tests\test_regression_defects.ahk`, verified to fail without the fix (257/258) and pass with it.

**0c. README full refresh.** `Docs/README_office_productivity_palette.md` was stuck at v2.0.0 with a stale 3-suite/199-assertion test table and missing entire shipped feature areas (Workflow Composer, Date Format Converter, CorpusSetEngine). Synced to v2.0.1 / the real 8-suite/1,377-assertion harness, added the missing sections, documented the watchdog under Telemetry, and corrected several outright-wrong claims found while cross-checking every tool bullet against actual `RegisterAction()` call sites (non-existent Leader Key chords, a non-existent "Validate GSTIN Checksum" tool, missing Utility-suite tools, `F12`/`Ctrl+0` hotkeys that were removed during the earlier PowerToys harmonization work). No test suite applies to documentation.

---

## 1. Worth doing soon (real bugs / real risk, not yet fixed)

| ID | What | Where | Why it matters |
|---|---|---|---|
| **R3** | `FileOpen()`/`.Close()` not guarded by `finally` in the standard save template — a throw mid-write leaks the handle. Repeated identically across 4+ files (`RunHistory.Record()`'s write site was fixed as a byproduct of the D3 redaction work below; `RunHistory.Delete()` and the other 3 locations were not touched). | `Lib\RunHistory.ahk:96-126` (`Delete()`), `Lib\SnippetManager.ahk:171-177`, `Lib\TaskManager.ahk:88+`, `Lib\RecipeModel.ahk:472+` | Violates the project's own coding standard (`MY_CODING_STYLE_AND_STANDARDS.txt` rule 19), and it's the same fixable pattern in every location — good candidate for a single focused session. |
| **R4** | `Sleep()` used for clipboard-restore timing, inside `ClipboardHelper.ahk` itself — the exact anti-pattern the standards doc names, in the module that's supposed to guarantee "zero clipboard mutation." | `Lib\ClipboardHelper.ahk:22,45,49,59`; `Lib\PaletteGui.ahk:236` (the `Sleep(50)` right after the now-guarded `WinActivate` — R5 fixed the missing try-catch, not this `Sleep`) | Standards violation in the highest-trust module in the codebase. |

---

## 2. Worth doing eventually (real, but lower urgency)

| ID | What | Where |
|---|---|---|
| **D4** | `WorkflowPrimitives.ExecuteFilter` builds a regex from free-text recipe settings with no ReDoS guard, applied to arbitrary long pasted text. | `Lib\WorkflowPrimitives.ahk:267-269` |
| **D6** | `ClipboardHelper.SetClipboardWithoutHistory` can leak `GlobalAlloc` handles on certain failure paths. Narrow edge case. | `Lib\ClipboardHelper.ahk:389-455` |
| **R7** | Magic-number `SetTimer` intervals with no named constant (8+ sites). Cosmetic/style only. | `ActionBoardGui.ahk:21-23`, `PaletteGui.ahk:27,65`, `SnippetManager.ahk:14`, `TaskManager.ahk:15,18` |

---

## 3. Acknowledged, probably not worth fixing (documented tradeoffs)

- **R1** — the main script still includes 3 files from two sibling projects outside this repo (`..\Study_MarkdownHub v2.0\Lib\...`, `..\Word Count Tooltip.ahk`). This makes the "0 external Lib leaks" / "closed-world manifest" claim inaccurate as currently worded. Two real options: (a) vendor those files into this project's own `Lib\`, or (b) update the closed-world manifest tool (`Tests\run_tests.py`) to explicitly allowlist and report cross-project includes instead of silently passing them as "0 leaks." Neither was done this session because both are judgment calls about project boundaries, not bug fixes — flag to the user before picking one.
- **R2** — no `g_` prefix on any global, project-wide. This session's audit concluded (and documented in `Lib\Globals.ahk`'s new "Global State Registry") that this is a deliberate, consistent, standing convention for this project, not a gap. Do not "fix" this by partially introducing `g_` prefixes — that would make things worse, not better.
- **A3** — no enforced module boundaries between `Lib\` files (inherent to AHK v2's single global namespace under `#Include`); `ToolAdapters_Builtin.ahk` reaches into other modules defensively via `IsSet(...)` guards rather than a defined public API. This is a structural property of the language/architecture, not a discrete bug — would need a deliberate "define a public API surface per module" initiative if it's ever worth doing, not a quick fix.

---

## 4. Fixed this update (2026-09-18, session resumed) — for reference

| ID | What was fixed | Regression coverage |
|---|---|---|
| **D2** | `CorpusSetEngine` tier classifier no longer double-counts 100%-coverage tokens as "Common" — they now get a distinct "Universal (Baseline)" tier, matching the module's own `> 75% and < 100%` header spec. | DEFECT-043 |
| **D1-adjacent** | Swept all `type: "any"` tool inputs for the D1 crash class (type-assumes String, breaks on Array/Map). Found and fixed one in `WorkflowPrimitives.ExecuteTemplate`'s `context` input. | DEFECT-044 |
| **D5** | `MathEvaluator`'s chained-percentage regex now compounds correctly (`"100 - 10% - 5%"` = 85.5, not the old wrong value) via a looped, balanced-paren-recursive substitution instead of a single pass against the original base. | DEFECT-045 |
| **D7** | Added `PipelineRunner._ReferenceExists()` to distinguish a broken/stale binding from a genuinely-empty field; wired into `_ExecuteStep` to log broken bindings via `LogAppError`. | DEFECT-046 |
| **D8** | `WorkflowPrimitives.ExecuteSlice` now throws on an inverted range (`end < start`) instead of silently returning an empty result. | DEFECT-047 |
| **D9** | `CorpusSetEngine.ExecutePipeline` now runs `Analyze()` once per invocation instead of up to 3x, by reusing the computed `universalTokens` for both the "difference" op and the `differences` output field. | DEFECT-048 |
| **D10** | `RecipeModel`'s loop-container return-type inference now resolves the designated return step's own declared `primary: true` output instead of hardcoding `.text`. | DEFECT-049 |
| **R6** | `Actions_Extraction.ParseAnyDateToYyyyMmDd` no longer carries its own independent fallback date parser — fully delegates to `DateFormatConverter.ParseIndianDate` (a strict superset). This also surfaced and fixed a real hidden gap: `test_integration_runner.ahk` never included `DateFormatConverter.ahk` and was silently relying on the now-removed duplicate. | DEFECT-050 |
| **D3** | Added `RedactSensitiveData()` to `Lib\Actions_Extraction.ahk` (masks GSTIN/PAN/phone/email matches with `[REDACTED:TYPE]`, reusing the module's own existing detection patterns — refactored into a shared `SensitivePatterns` class so both extraction and redaction read from one definition). `RunHistory.Record()` now recursively redacts every String in a run record (including nested Strings inside `step_snapshots`' Arrays/Maps/Objects) before it's ever written to `Logs\WorkflowRunHistory.json`. Chosen deliberately over encrypting the ledger at rest (discussed and rejected in favor of this lighter-weight option) — known-pattern coverage only; arbitrary sensitive text (names, unlisted formats) is still **not** caught, this is defense-in-depth, not a guarantee. | DEFECT-051 |
| **R5** | `PaletteExecuteSelection`'s `WinActivate("ahk_id " . TargetWindowHwnd)` (the busiest path in the app — runs on every single palette action) is now wrapped in try-catch with `LogAppError`, matching the guard pattern already used for every other `WinActivate` call in the codebase (`Lib\WindowPeekEngine.ahk`). The natural dynamic test can't actually force `WinActivate` to throw (a stale handle just fails the preceding `WinExist` gate, and AHK's `WinActivate` doesn't throw for a merely-missing window — only for a genuine close-timing race that isn't reproducible deterministically), so DEFECT-052 pairs a behavioral check (no crash, action still executes) with a static source-compliance check (confirms the call site text is actually try-guarded) — the latter is what actually flips fail→pass on this fix. | DEFECT-052 |

Also closed pre-existing stale **PR #1** (`fix/defect-034-math-evaluator-com-regression`) as superseded — its fix was already present on `master` via a later PR.

---

## 5. How to pick this back up

1. Read `Docs/LLM_DEVELOPMENT_GUIDELINES.md` in full — it has the reasoning, severity, and evidence behind every ID referenced above, plus a 16-point guideline checklist for how to work in this codebase (commit discipline, test-coverage depth, the FileOpen/Sleep/WinActivate patterns, etc.).
2. Re-run `python Tests/run_tests.py` first thing, before touching anything, to confirm the baseline is still 1,381/1,381 clean (things may have drifted if the user made manual edits between sessions).
3. `master` is 5 commits ahead of `origin/master` and unpushed — confirm with the user whether/when to push, and whether they want a PR opened for `ebdd4ac` or any of the earlier unpushed commits, before assuming any of this is meant to stay local-only.
4. Optionally close out Section 0a's open item — design a stubbed-state harness so the stuck-CapsLock watchdog gets a real DEFECT-0XX test instead of just validate+no-regression coverage.
5. Then pick one row from Section 1 above, fix it with a regression test that would fail without the fix (verify this by temporarily reverting and confirming the test actually fails — every fix in this update was checked that way), then commit/PR/merge it on its own rather than batching unrelated fixes together.
6. Update `subject_tracker.md` per the project's own convention as you go (see `.agents\skills\subject_tracker\SKILL.md`) — and if you complete a subject, mark it 🟢 Finalized so it doesn't linger as 🔴 Active in the file indefinitely.
7. The compiled `.exe` is stale relative to everything in Section 0 and the prior update — recompile with Ahk2Exe before considering the binary current.
