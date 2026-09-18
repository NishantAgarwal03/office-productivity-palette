# Pending Work — Next Session

**Written:** 2026-09-18, at the close of a session covering a deep audit (`Docs/LLM_DEVELOPMENT_GUIDELINES.md`) plus a round of bug fixes and architecture remediation.

**Project state right now:** `master` is clean, all work from this session is merged, and the full Zero-Trust suite passes **1,335/1,335** across 8 suites with a clean closed-world manifest. The compiled `.exe` is up to date with source. Working tree is clean, no stray branches, no stray processes. Safe to close.

This file exists because the audit found more issues than one session should try to fix at once. Everything below is deferred **on purpose**, not forgotten. Read `Docs/LLM_DEVELOPMENT_GUIDELINES.md` first for full context on each finding's ID (R#/A#/D#) before touching any of this — it has the reasoning, not just the location.

---

## 0. Unrelated, pre-existing open item

- **PR #1** (`fix/defect-034-math-evaluator-com-regression`, opened 2026-09-12) is still open on GitHub. It predates this session and was never reviewed or touched here. Decide whether to merge, update, or close it before it goes further stale.

---

## 1. Worth doing soon (real bugs / real risk, not yet fixed)

| ID | What | Where | Why it matters |
|---|---|---|---|
| **D2** | Tier classifier counts 100%-coverage tokens as "Common," contradicting its own documented `>75% and <100%` boundary — the toast HUD reports an inflated Common count. | `Lib\CorpusSetEngine.ahk` tier classification (~line 219-239) vs. its own header comment (line 10) | User-facing output is wrong relative to the feature's own spec. |
| **D3** | `RunHistory` persists full recipe input/output text to `Logs\WorkflowRunHistory.json` in plaintext, indefinitely (200-run retention) — including anything the Extraction tools find (GSTIN/PAN/financial data), since inputs can be clipboard/selection text. | `Lib\PipelineRunner.ahk:253-266,342-348`, `Lib\RunHistory.ahk:41-49` | Privacy/leak surface that's in real tension with the app's "zero clipboard mutation" claims. Easy to reproduce: just run any recipe with sensitive text and check the log file. |
| **D1-adjacent follow-up** | Confirm no *other* Workflow Composer tool with an `"any"`-typed input has the same class of bug as D1 (type-assumes String, breaks on Array/Map). D1 itself is fixed (`CorpusSetEngine.DetectDelimiter`), but the pattern wasn't swept for other adapters. | `Lib\ToolAdapters_Builtin.ahk`, `Lib\WorkflowPrimitives.ahk` — grep for `type: "any"` in tool definitions, then check each handler's assumptions | Same crash class could exist elsewhere and just hasn't been triggered by a test yet. |
| **R3** | `FileOpen()`/`.Close()` not guarded by `finally` in the standard save template — a throw mid-write leaks the handle. Repeated identically across 4+ files. | `Lib\RunHistory.ahk:44-48`, `Lib\SnippetManager.ahk:171-177`, `Lib\TaskManager.ahk:88+`, `Lib\RecipeModel.ahk:472+` | Violates the project's own coding standard (`MY_CODING_STYLE_AND_STANDARDS.txt` rule 19), and it's the same fixable pattern in every location — good candidate for a single focused session. |
| **R4** | `Sleep()` used for clipboard-restore timing, inside `ClipboardHelper.ahk` itself — the exact anti-pattern the standards doc names, in the module that's supposed to guarantee "zero clipboard mutation." | `Lib\ClipboardHelper.ahk:22,45,49,59`; `Lib\PaletteGui.ahk:232` | Standards violation in the highest-trust module in the codebase. |
| **R5** | `WinActivate()` not wrapped in try-catch on the busiest path in the app (every single palette action), while the same call *is* correctly guarded elsewhere. | `Lib\PaletteGui.ahk:230-232` (compare `Lib\WindowPeekEngine.ahk:133,181`) | One-line fix, high-traffic code path, inconsistency with the codebase's own established pattern. |

---

## 2. Worth doing eventually (real, but lower urgency)

| ID | What | Where |
|---|---|---|
| **D4** | `WorkflowPrimitives.ExecuteFilter` builds a regex from free-text recipe settings with no ReDoS guard, applied to arbitrary long pasted text. | `Lib\WorkflowPrimitives.ahk:267-269` |
| **D5** | `MathEvaluator`'s chained-percentage regex is single-pass, not re-scanned — `"100 - 10% - 5%"` silently evaluates wrong. No error, just a wrong number. | `Lib\MathEvaluator.ahk:207-208` |
| **D7** | `PipelineRunner._ResolveReference` can't distinguish "broken/stale reference" from "field is genuinely empty" — both return `""` silently. Makes debugging a broken recipe binding harder than it needs to be. | `Lib\PipelineRunner.ahk:516-538` |
| **D8** | `WorkflowPrimitives.ExecuteSlice` silently returns an empty result (no error) when `end < start`. | `Lib\WorkflowPrimitives.ahk:344-352` |
| **D6** | `ClipboardHelper.SetClipboardWithoutHistory` can leak `GlobalAlloc` handles on certain failure paths. Narrow edge case. | `Lib\ClipboardHelper.ahk:389-455` |
| **D9** | `CorpusSetEngine` re-runs its full `Analyze()`/tokenization pass up to 3× per single invocation — a performance risk for large multi-document corpora, which is exactly what this tool is for. | `Lib\CorpusSetEngine.ahk:448-483` |
| **D10** | `RecipeModel`'s loop-container return-type inference only reliably matches outputs literally named `text` — a future tool adapter with a differently-named primary output gets silently wrong type inference downstream. Latent trap for future tool authors, not an active bug today. | `Lib\RecipeModel.ahk:196-208` |
| **R6** | `Actions_Extraction.ahk` tries `DateFormatConverter.ParseIndianDate` first, then falls back to its *own* independent date-parsing logic instead of delegating the fallback too — a second date parser, contradicting the "zero role duplication" claim. | `Lib\Actions_Extraction.ahk:302-335` |
| **R7** | Magic-number `SetTimer` intervals with no named constant (8+ sites). Cosmetic/style only. | `ActionBoardGui.ahk:21-23`, `PaletteGui.ahk:27,65`, `SnippetManager.ahk:14`, `TaskManager.ahk:15,18` |

---

## 3. Acknowledged, probably not worth fixing (documented tradeoffs)

- **R1** — the main script still includes 3 files from two sibling projects outside this repo (`..\Study_MarkdownHub v2.0\Lib\...`, `..\Word Count Tooltip.ahk`). This makes the "0 external Lib leaks" / "closed-world manifest" claim inaccurate as currently worded. Two real options: (a) vendor those files into this project's own `Lib\`, or (b) update the closed-world manifest tool (`Tests\run_tests.py`) to explicitly allowlist and report cross-project includes instead of silently passing them as "0 leaks." Neither was done this session because both are judgment calls about project boundaries, not bug fixes — flag to the user before picking one.
- **R2** — no `g_` prefix on any global, project-wide. This session's audit concluded (and documented in `Lib\Globals.ahk`'s new "Global State Registry") that this is a deliberate, consistent, standing convention for this project, not a gap. Do not "fix" this by partially introducing `g_` prefixes — that would make things worse, not better.
- **A3** — no enforced module boundaries between `Lib\` files (inherent to AHK v2's single global namespace under `#Include`); `ToolAdapters_Builtin.ahk` reaches into other modules defensively via `IsSet(...)` guards rather than a defined public API. This is a structural property of the language/architecture, not a discrete bug — would need a deliberate "define a public API surface per module" initiative if it's ever worth doing, not a quick fix.

---

## 4. How to pick this back up

1. Read `Docs/LLM_DEVELOPMENT_GUIDELINES.md` in full — it has the reasoning, severity, and evidence behind every ID referenced above, plus a 16-point guideline checklist for how to work in this codebase (commit discipline, test-coverage depth, the FileOpen/Sleep/WinActivate patterns, etc.).
2. Re-run `python Tests/run_tests.py` first thing, before touching anything, to confirm the baseline is still 1,335/1,335 clean (things may have drifted if the user made manual edits between sessions).
3. Pick one row from Section 1 above, fix it with a regression test that would fail without the fix (verify this by temporarily reverting and confirming the test actually fails — several of this session's fixes were checked this way), then commit/PR/merge it on its own rather than batching unrelated fixes together.
4. Update `subject_tracker.md` per the project's own convention as you go (see `.agents\skills\subject_tracker\SKILL.md`) — and if you complete a subject, mark it 🟢 Finalized so it doesn't linger as 🔴 Active in the file indefinitely.
