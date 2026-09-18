# Pending Work — Next Session

**Written:** 2026-09-18, at the close of a session covering a deep audit (`Docs/LLM_DEVELOPMENT_GUIDELINES.md`) plus a round of bug fixes and architecture remediation. **Updated:** same day, session resumed — closed stale PR #1 and fixed 10 items (D2, D1-adjacent follow-up, D3, D5, D7, D8, D9, D10, R5, R6); see `subject_tracker.md` "Deep Audit, Bug Fixes & Architecture Remediation" for the full account of what changed and why, and DEFECT-043 through DEFECT-052 (DEFECT-051 in `Tests\test_regression_defects.ahk`, DEFECT-052 in `Tests\test_ui_interaction_runner.ahk`) for the regression coverage. **Updated again:** same day — diagnosed a real user-reported keyboard-freeze incident and implemented a fix; see `subject_tracker.md` "Keyboard Freeze Diagnosis & Stuck-CapsLock Watchdog" and Section 0 below.

**Project state right now:** working tree is **not clean** — 3 files are modified and **uncommitted** (see Section 0). The Zero-Trust suite still passes **1,377/1,377** across all 8 suites with the changes applied (verified after making them; the change is additive, no test file touched, closed-world manifest still clean at 119 files). The compiled `.exe` is stale relative to both this update and the prior one — recompile before treating the binary as current. No stray branches, no stray processes.

This file exists because the audit found more issues than one session should try to fix at once. Everything below is deferred **on purpose**, not forgotten. Read `Docs/LLM_DEVELOPMENT_GUIDELINES.md` first for full context on each finding's ID (R#/A#/D#) before touching any of this — it has the reasoning, not just the location.

---

## 0. Uncommitted right now — pick this up first

**What happened:** the user reported that keyboard input froze system-wide during actual use ("not able to type, every key pressed opened something else"), and neither exiting nor restarting the script fixed it — only a full Windows logoff/logon recovered it.

**Root cause (confirmed via telemetry, no script exception logged for the incident):** `Lib\WindowPeekHotkeys.ahk`'s `#HotIf GetKeyState("CapsLock", "P")` block (lines 80-114) hijacks `t/v/s/x/c/p/w/n/Space/Tab/Esc/Up/Down` system-wide for as long as CapsLock reads *physically* held. That's OS-level state outside the script's control — a dropped key-up event (UAC prompt, lock screen, focus-stealing dialog, RDP hiccup) can leave Windows reporting CapsLock as permanently held, silently rerouting ordinary typing into chord/peek actions. Restarting the script doesn't help because the stuck state lives in the OS input session, not script variables.

**Fix implemented (uncommitted):**
- `Lib\WindowPeekHotkeys.ahk` — new Section 4: `CheckCapsLockStuckWatchdog()` (polls every 1s, yields to `PeekState`/`XRayState` while either is non-IDLE) and `ForceReleaseStuckCapsLock()` (sends synthetic `{CapsLock Up}` via `SendInput` once physical-down persists 12s+ outside a legitimate Peek/X-Ray session, resets chord-tracking globals, logs via `LogAppError`, shows a toast). New globals: `CapsLockStuckSince`, `CapsLockStuckThresholdMs`.
- `office_productivity_palette_v2.0.1.ahk:86` — calls `InitCapsLockStuckWatchdog()` from `InitApp()`.
- `Lib\Globals.ahk` — Global State Registry entry added for the two new globals.

**What's left before this is "done" by this project's own standards:**
1. **No regression test yet** — this project pairs every fix with a DEFECT-0XX test in `Tests\test_regression_defects.ahk` verified to fail without the fix. A real stuck-physical-CapsLock condition can't be forced through `GetKeyState` the way the suite mocks other conditions; worth designing a harness for this (e.g. exposing `CheckCapsLockStuckWatchdog`/`ForceReleaseStuckCapsLock` to direct unit-style invocation with a stubbed physical-state source) before calling it covered.
2. **Not committed** — no branch/PR opened yet, just working-tree changes.
3. **`.exe` not recompiled** since these changes (or since the prior D2/D1-adjacent/D3/D5/D7/D8/D9/D10/R5/R6 update either).
4. Ran `AutoHotkey64.exe /validate` (clean) and the full suite (1,377/1,377, unchanged) as verification so far — that's syntax + no-regression, not new-behavior coverage.

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
2. Re-run `python Tests/run_tests.py` first thing, before touching anything, to confirm the baseline is still 1,377/1,377 clean (things may have drifted if the user made manual edits between sessions).
3. **Start with Section 0** — it's uncommitted working-tree state, not a queued idea. Decide whether to add regression coverage for the stuck-CapsLock watchdog before committing, or commit as-is and track the missing test separately; either way get it off the working tree (branch + PR, per this project's normal flow) so it doesn't get lost or conflated with the next piece of work.
4. Then pick one row from Section 1 above, fix it with a regression test that would fail without the fix (verify this by temporarily reverting and confirming the test actually fails — every fix in this update was checked that way), then commit/PR/merge it on its own rather than batching unrelated fixes together.
5. Update `subject_tracker.md` per the project's own convention as you go (see `.agents\skills\subject_tracker\SKILL.md`) — and if you complete a subject, mark it 🟢 Finalized so it doesn't linger as 🔴 Active in the file indefinitely.
6. The compiled `.exe` is stale relative to Section 0's changes and the prior update's — recompile with Ahk2Exe once both are settled, before considering the binary current.
