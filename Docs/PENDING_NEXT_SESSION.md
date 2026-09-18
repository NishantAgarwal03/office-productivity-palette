# Pending Work — Next Session

**Written:** 2026-09-18, at the close of a session covering a deep audit (`Docs/LLM_DEVELOPMENT_GUIDELINES.md`) plus a round of bug fixes and architecture remediation. **Updated:** same day, session resumed — closed stale PR #1 and fixed 8 items (D2, D1-adjacent follow-up, D5, D7, D8, D9, D10, R6); see `subject_tracker.md` "Deep Audit, Bug Fixes & Architecture Remediation" for the full account of what changed and why, and DEFECT-043 through DEFECT-050 in `Tests\test_regression_defects.ahk` for the regression coverage.

**Project state right now:** `master` is clean, all work is committed, and the full Zero-Trust suite passes **1,362/1,362** across 8 suites with a clean closed-world manifest. The compiled `.exe` has **not** been recompiled since this update — do that before treating the binary as current. Working tree is clean, no stray branches, no stray processes.

This file exists because the audit found more issues than one session should try to fix at once. Everything below is deferred **on purpose**, not forgotten. Read `Docs/LLM_DEVELOPMENT_GUIDELINES.md` first for full context on each finding's ID (R#/A#/D#) before touching any of this — it has the reasoning, not just the location.

---

## 1. Worth doing soon (real bugs / real risk, not yet fixed)

| ID | What | Where | Why it matters |
|---|---|---|---|
| **D3** | `RunHistory` persists full recipe input/output text to `Logs\WorkflowRunHistory.json` in plaintext, indefinitely (200-run retention) — including anything the Extraction tools find (GSTIN/PAN/financial data), since inputs can be clipboard/selection text. | `Lib\PipelineRunner.ahk:253-266,342-348`, `Lib\RunHistory.ahk:41-49` | Privacy/leak surface that's in real tension with the app's "zero clipboard mutation" claims. Easy to reproduce: just run any recipe with sensitive text and check the log file. |
| **R3** | `FileOpen()`/`.Close()` not guarded by `finally` in the standard save template — a throw mid-write leaks the handle. Repeated identically across 4+ files. | `Lib\RunHistory.ahk:44-48`, `Lib\SnippetManager.ahk:171-177`, `Lib\TaskManager.ahk:88+`, `Lib\RecipeModel.ahk:472+` | Violates the project's own coding standard (`MY_CODING_STYLE_AND_STANDARDS.txt` rule 19), and it's the same fixable pattern in every location — good candidate for a single focused session. |
| **R4** | `Sleep()` used for clipboard-restore timing, inside `ClipboardHelper.ahk` itself — the exact anti-pattern the standards doc names, in the module that's supposed to guarantee "zero clipboard mutation." | `Lib\ClipboardHelper.ahk:22,45,49,59`; `Lib\PaletteGui.ahk:232` | Standards violation in the highest-trust module in the codebase. |
| **R5** | `WinActivate()` not wrapped in try-catch on the busiest path in the app (every single palette action), while the same call *is* correctly guarded elsewhere. | `Lib\PaletteGui.ahk:230-232` (compare `Lib\WindowPeekEngine.ahk:133,181`) | One-line fix, high-traffic code path, inconsistency with the codebase's own established pattern. |

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

Also closed pre-existing stale **PR #1** (`fix/defect-034-math-evaluator-com-regression`) as superseded — its fix was already present on `master` via a later PR.

---

## 5. How to pick this back up

1. Read `Docs/LLM_DEVELOPMENT_GUIDELINES.md` in full — it has the reasoning, severity, and evidence behind every ID referenced above, plus a 16-point guideline checklist for how to work in this codebase (commit discipline, test-coverage depth, the FileOpen/Sleep/WinActivate patterns, etc.).
2. Re-run `python Tests/run_tests.py` first thing, before touching anything, to confirm the baseline is still 1,362/1,362 clean (things may have drifted if the user made manual edits between sessions).
3. Pick one row from Section 1 above, fix it with a regression test that would fail without the fix (verify this by temporarily reverting and confirming the test actually fails — every fix in this update was checked that way), then commit/PR/merge it on its own rather than batching unrelated fixes together.
4. Update `subject_tracker.md` per the project's own convention as you go (see `.agents\skills\subject_tracker\SKILL.md`) — and if you complete a subject, mark it 🟢 Finalized so it doesn't linger as 🔴 Active in the file indefinitely.
5. The compiled `.exe` is stale relative to this update's source changes — recompile with Ahk2Exe before considering the binary current.
