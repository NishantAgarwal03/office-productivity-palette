# Deep Audit & LLM Development Guidelines — Office Productivity Palette & Action Hub v2.0.1

**Audit date:** 2026-09-18
**Scope:** `office_productivity_palette_v2.0.1.ahk` + all 46 files in `Lib\` (~800KB), `Tests\`, `subject_tracker.md`, and git history.
**Method:** independent verification against (a) `MY_CODING_STYLE_AND_STANDARDS.txt`, (b) the project's own self-reported claims, (c) direct code reading. Ran `python Tests/run_tests.py` myself: **1,362/1,362 assertions pass, 115-file closed-world manifest, 0 external `Lib\` leaks** (as of this session — see Finding R1 for why that last number is misleading).

This document is written to be read by an LLM (or human) before the next edit to this codebase. Section 5 is the actionable checklist; Sections 1–4 are the evidence behind it.

---

## 1. Requirements & Scope Audit

*Does the code actually follow the user's own 20 non-negotiable AHK standards and the project's own stated invariants?*

| # | Finding | Severity | Evidence |
|---|---|---|---|
| R1 | **"Zero external Lib leaks" / "sealed closed-world manifest" is false.** Main file includes files *outside the project directory*: `..\Study_MarkdownHub v2.0\Lib\Actions_FindReplace.ahk`, `..\Study_MarkdownHub v2.0\Lib\Hotstrings_Prompts.ahk`, `..\Word Count Tooltip.ahk`. | 🔴 Critical | `office_productivity_palette_v2.0.1.ahk:58-60`; contradicts `subject_tracker.md:13,90,110,132` |
| R2 | **`g_` prefix rule is violated for ~100% of mutable globals**, consistently, project-wide. Either the rule was abandoned for this project or never adopted — never flagged as a deliberate deviation anywhere. | 🔴 Critical (docs gap) | `Lib\Globals.ahk:102-166` (~40 globals, none prefixed) |
| R3 | **`FileOpen()`/`.Close()` not guarded by `finally`** in the standard save template, repeated identically across 5+ files — a throw mid-write leaks the handle. | 🔴 Critical | `Lib\RunHistory.ahk:44-48`, `Lib\SnippetManager.ahk:171-177`, `Lib\TaskManager.ahk:88+`, `Lib\RecipeModel.ahk:472+` |
| R4 | **`Sleep()` used for clipboard-restore timing** — the exact anti-pattern the standards doc names, inside the module that's supposed to guarantee "zero clipboard mutation." | 🟡 Medium | `Lib\ClipboardHelper.ahk:22,45,49,59`; `Lib\PaletteGui.ahk:232` |
| R5 | **`WinActivate()` not wrapped in try-catch** on the hub's most-executed path (every palette action), while the same call *is* correctly guarded elsewhere in the codebase — inconsistency, not ignorance of the rule. | 🟡 Medium | `Lib\PaletteGui.ahk:230-232` vs. `Lib\WindowPeekEngine.ahk:133,181` |
| R6 | **"Zero role duplication" claim is false**: `Actions_Extraction.ahk` tries `DateFormatConverter.ParseIndianDate` first, then falls back to its *own* independent month-name/OCR-lenient parser instead of delegating the fallback too — a second date-parsing engine, not zero duplication. | 🟡 Medium | `Lib\Actions_Extraction.ahk:302-335` |
| R7 | Magic-number `SetTimer` intervals with no named constant (8+ sites). | 🔵 Low | `ActionBoardGui.ahk:21-23`, `PaletteGui.ahk:27,65`, `SnippetManager.ahk:14`, `TaskManager.ahk:15,18` |
| R8 | The class-vs-flat-function split (`class` for stateless engines like `CorpusSetEngine`/`MathEvaluator`/Civil* modules; flat globals+Maps for GUI/hotkey/dispatch code) is **consistent and coherent** — not sloppiness — but is nowhere documented as an intentional convention. | 🔵 Low (informational) | grep `^class \w+` across `Lib\` |
| R9 | "85+ essential tools" banner claim is **accurate, if conservative**: independently counted 93 `RegisterAction(` calls + 37 `ToolCatalog.Register(` calls. Not inflated. | 🔵 Low (positive) | `Lib\*.ahk` |
| R10 | The three sibling-project includes (R1) have **zero entries** in `subject_tracker.md` despite being load-bearing (wire hotkeys `^h`, `^+t`) — confirms R1 independently. | 🔵 Low | `subject_tracker.md` (no matching subject) |

---

## 2. Codebase Architecture Audit

*Structural health: coupling, global state, naming, duplication, the two-paradigm (direct-action vs. Workflow-Composer) design, GUI architecture, file-size hygiene.*

| # | Finding | Severity | Evidence |
|---|---|---|---|
| A1 | **Extraction/aggregation logic is duplicated, not reused, between the direct-action layer and the Workflow Composer adapter layer** — email/URL/phone/GSTIN regexes and sum/average loops are retyped in `ToolAdapters_Builtin.ahk` instead of calling `Actions_Extraction.ahk`'s functions. Any future regex fix (e.g. a GSTIN correction) must be made twice and will silently diverge otherwise. This is exactly the "duplication of roles" the project explicitly says it avoids. | 🔴 Critical | `Actions_Extraction.ahk:41-44,65-68,89-92,120-123` vs. `ToolAdapters_Builtin.ahk:810-904`; sum/avg at `:779-807` vs `Actions_Math.ahk:250-258` |
| A2 | For the "heavy" engines (Civil*, MathEvaluator, DateFormatConverter), adapter reuse is done correctly — this is a real, positive contrast that shows the duplication in A1 is a discipline gap, not a framework flaw. | 🟢 Good | `ToolAdapters_Builtin.ahk:992-1181` calling into `CivilPythagoras.Evaluate`, `SafeEvaluateMath`, `CalculateDateDifference` |
| A3 | No enforced module boundaries exist (inherent to AHK's single global namespace under `#Include`) — `ToolAdapters_Builtin.ahk` reaches into other modules' internals defensively via `IsSet(...)` guards rather than a defined public API, suggesting fragility to include-order changes. | 🟡 Medium | `ToolAdapters_Builtin.ahk:1046,1164` |
| A4 | Global state is only *partially* centralized. `Globals.ahk` holds the core theme/path/handle state, but `WorkflowComposerGui.ahk` (14 globals), `SnippetGui.ahk` (12), `WindowPeekEngine.ahk` (7) declare additional file-local globals never listed there — a contributor editing only `Globals.ahk` will miss real shared state. | 🟡 Medium | `Lib\WorkflowComposerGui.ahk` top-of-file globals |
| A5 | Functions re-declare large `global A, B, C, ...` lists (14-15 names) to touch shared GUI-handle state — implicit threading of mutable state through many functions instead of an object/param. | 🟡 Medium | `Core.ahk:138,157` |
| A6 | File naming mixes 3 undocumented schemes (`Actions_*.ahk`, bare nouns, `*Gui.ahk`/`*Engine.ahk`) — the Civil subsystem alone uses all three with no stated rule for which file gets which pattern. | 🟡 Medium | `Lib\Civil*.ahk` (7 files) |
| A7 | GUI dark-theme boilerplate (`DllCall("uxtheme\SetWindowTheme", ...)`, `.BackColor := ThemeBg`) is copy-pasted independently across 7 `*Gui.ahk` files rather than factored into a shared `ApplyDarkTheme()`/`NewThemedGui()` helper. Theme *tokens* are correctly centralized in `Globals.ahk` — only the *application* of the theme is duplicated. | 🟡 Medium | `DateFormatGui.ahk:57`, `PaletteGui.ahk:52`, `SnippetGui.ahk:82` |
| A8 | Large files have sparse internal sectioning relative to size: `WorkflowComposerGui.ahk` (56KB, 6 banners), `ToolAdapters_Builtin.ahk` (49KB, 2 banners), `RecipeModel.ahk` (30KB, 2 banners), `PipelineRunner.ahk` (26KB, 2 banners) — roughly one banner per 10-25KB, making navigation dependent on function-name scanning alone. | 🟡 Medium | file-level banner-comment counts |
| A9 | Toast/tooltip notification logic and CSV parsing are **correctly single-sourced** with no competing implementations found — a genuine architectural strength worth preserving as a model for other subsystems. | 🟢 Good | `ClipboardHelper.ahk:236-354`, `CSVParser.ahk` |
| A10 | Include order in the main file is a legitimate, correct topological sort matching actual call dependencies — not a source of fragility by itself. | 🟢 Good | `office_productivity_palette_v2.0.1.ahk:19-57` |

**Resolution status (2026-09-18, `refactor/architecture-a1-a4-a8` branch):**

- **A1 — Fixed.** `ToolAdapters_Builtin.ahk`'s email/URL/phone/GSTIN adapters now delegate to `Actions_Extraction.ahk`'s canonical functions instead of retyping the regexes. `ExecuteExtractDates` and `ExecuteSumNumbers`/`ExecuteAverageNumbers` were deliberately left alone (different contracts, not true duplicates — see the commit message for the reasoning).
- **A4/A5 — Documented, not restructured.** Added a "Global State Registry" block to `Lib/Globals.ahk` cataloguing every module-owned global declared outside that file (`WorkflowComposerGui.ahk`, `SnippetGui.ahk`, `WindowPeekEngine.ahk`, `DateFormatGui.ahk`, `RunHistoryGui.ahk`), plus a one-line pointer comment above each of those files' own global declarations. Physically moving ~30 globals into `Globals.ahk` wouldn't change their scope in AHK v2 (there's one flat global namespace regardless of which file declares them) — it would just add indirection. The re-declared `global A, B, C, ...` lists in `Core.ahk` (A5) are inherent to AHK v2 function scoping and were left as-is for the same reason.
- **A6 — Documented.** Added a "File Naming & Module Organization Convention" block to `Lib/Globals.ahk` explicitly writing down the `Actions_*.ahk` / `*Engine.ahk`-or-bare / `*Gui.ahk` split, which was previously real-but-implicit. Renaming ~46 existing files to retrofit a stricter scheme was judged too high-risk (breaks every `#Include`) for the benefit.
- **A7 — Fixed** for the 3 flagged sites. Added `ApplyDarkListViewTheme()` to `Lib/Globals.ahk`; `DateFormatGui.ahk`, `PaletteGui.ahk`, `SnippetGui.ahk` now call it instead of repeating the `uxtheme\SetWindowTheme` `DllCall`. The separate `.BackColor := ThemeBg`-vs-`ThemeSurface` inconsistency was left alone — unifying it would change each window's actual background color by design choice, not just deduplicate identical code, and isn't something the non-visual test suite can verify.
- **A8 — Fixed** for `PipelineRunner.ahk` and `RecipeModel.ahk` (added banners at the genuinely sparse boundaries). On closer inspection, `ToolAdapters_Builtin.ahk` and `WorkflowComposerGui.ahk` already had denser sectioning than this audit estimated (27 and 18 section comments respectively) — left unchanged to avoid comment churn with no real benefit.

All changes in this pass verified via the full suite (1,328/1,328 across 8 suites) after each individual commit, plus (for A7) confirmation that the extracted helper is a byte-identical `DllCall` at the same call site, not a behavior change.

---

## 3. Progress & Evidence Audit

*Does `subject_tracker.md`'s self-reported history hold up against git, the test artifacts, and the old `docs/audit_report.md` (v2.0.0) findings?*

**Fixed / unfixed verdicts on the prior audit's critical findings:**

| Old finding | Verdict | Evidence |
|---|---|---|
| `ConvertUnixTimestamp()` broken regex (`[^\\d]`) | ✅ **Fixed** | `Actions_Math.ahk:289` now `[^\d]` |
| `GenerateUUID()` double-backslash `ole32\\CoCreateGuid` | ❌ **Still unfixed** — and has **zero test coverage**, so it can never surface as a regression | `Actions_Math.ahk:197`; `grep -rn GenerateUUID Tests/` → no matches |
| CivilSurvey wrong-class `ParseDimensionInput` call | ✅ **Fixed**, with an inline comment noting the fix | `CivilSurvey.ahk:81-82` |
| CivilSurvey division-by-zero on slope | 🟡 **Partially fixed** — `runM` is guarded, `riseM` is not; `0mm fall in 10m` still divides by zero | `CivilSurvey.ahk:56-59` |
| CivilRebar division-by-zero (`d1`, `s1`, `s2`) | ❌ **Unfixed**, no guard, no test | `CivilRebar.ahk:31-47` |
| Clipboard race — `TransformSelectedText` never restores original clipboard | ❌ **Unfixed, and mislabeled as resolved.** Commit `17df23e` ("clipboard race... try/finally restore") only fixed the *read-side* race in `SafeGetSelection`. `InsertText(text, restoreClipboard := false)` still defaults to false, and `TransformSelectedText` relies on that default — the user's clipboard is still permanently overwritten after every text transform. | `ClipboardHelper.ahk:148` (`InsertText` call site) |

**Other evidence findings:**

| # | Finding | Severity | Evidence |
|---|---|---|---|
| P1 | **The single largest self-reported "subject" — CorpusSetEngine — has never been committed.** Logged "Completed (100% Pass)" 7 times across `subject_tracker.md:118-144`, yet `Lib\CorpusSetEngine.ahk` is untracked and 8+ other files sit as unstaged modifications. A "Completed" tracker entry currently means nothing about durability of the work. | 🔴 Critical | `git status` |
| P2 | `Tests/master_test_summary.json` stores only aggregate pass/fail counts, never per-assertion content — a weakened or silently-deleted assertion would not change the reported "1,362/1,362" figure in any detectable way. | 🟡 Medium | `Tests\master_test_summary.json` structure |
| P3 | DEFECT-038–041 (CorpusSetEngine) regression tests are genuinely substantive (call real `Analyze`/`ComputeDifferences`/etc.). DEFECT-016 ("108 notification sites" claim) tests only duration/anchor math — far shallower than the narrated scope. Coverage depth is inconsistent across DEFECT entries. | 🟡 Medium | `Tests\test_regression_defects.ahk` |
| P4 | Known-critical bugs (GenerateUUID, Civil division-by-zero) have **no regression test at all** — "zero regressions" is true only for paths the suite actually exercises. | 🟡 Medium | (see fixed/unfixed table) |
| P5 | Quantitative claims that *are* independently verifiable (tool counts, sequential test-count growth across sessions) check out and are not inflated. | 🟢 Good | cross-referenced against R9 |

---

## 4. Independent Adversarial Audit

*New, previously-unreported bugs found by direct code reading of the newest/least-audited subsystems (CorpusSetEngine, Workflow Composer/Pipeline).*

| # | Finding | Severity | Trigger / Evidence |
|---|---|---|---|
| D1 | **`CorpusSetEngine.ExecutePipeline` crashes on Array input.** `DetectDelimiter(source)` calls `InStr(rawText, "\`r\`n")`, which requires a String — but `WorkflowTypes.AreCompatible` treats `"any"` as compatible with every type, so a recipe author can legally bind `corpus_set_analyzer.source` to another step's Array output (e.g. `primitive_split.items`). Recipe fails every time, uncaught. | 🔴 Critical | `CorpusSetEngine.ahk:449` |
| D2 | **Tier classification double-counts 100%-coverage tokens as "Common"**, contradicting the module's own documented boundary ("Common: > 75% and < 100%", line 10) — the toast HUD reports an inflated Common count. | 🟡 Medium | `CorpusSetEngine.ahk:219-239` vs. header comment L10 |
| D3 | **`RunHistory` persists full input/output snapshots of every recipe run to `Logs\WorkflowRunHistory.json`, unencrypted, indefinitely (200-run retention).** Since inputs can be clipboard/selection text, and the Extraction tools are literally designed to find GSTIN/PAN/financial data, sensitive text run through any recipe is durably written to disk — a different leak surface than the "zero clipboard mutation" guarantee the project advertises, and not covered by that guarantee's scope. | 🟡 Medium (privacy) | `PipelineRunner.ahk:253-266,342-348`; `RunHistory.ahk:41-49` |
| D4 | **`WorkflowPrimitives.ExecuteFilter` builds a live regex from a free-text recipe setting with no ReDoS guard**, applied to arbitrary long clipboard-derived text — a pathological pattern (nested quantifiers) can hang the single-threaded GUI indefinitely. | 🟡 Medium | `WorkflowPrimitives.ahk:267-269` |
| D5 | **`MathEvaluator` chained-percentage regex is single-pass, not re-scanned** — `"100 - 10% - 5%"` silently evaluates to `89.95` (second `%` term is misinterpreted as a bare fraction) instead of either plausible intended reading. No error; silently wrong number. | 🟡 Medium | `MathEvaluator.ahk:207-208` |
| D6 | `ClipboardHelper.SetClipboardWithoutHistory` can leak `GlobalAlloc` handles for exclusion/history/cloud markers if `SetClipboardData` fails or an exception occurs between allocation and transfer — narrow edge case, unguarded relative to the rest of the file's fail-safe style. | 🔵 Low | `ClipboardHelper.ahk:389-455` |
| D7 | `PipelineRunner._ResolveReference` returns `""` for both "reference doesn't exist" and "field is genuinely empty" — a stale reference after a step rename fails silently instead of raising, masking the real cause of downstream errors. | 🔵 Low | `PipelineRunner.ahk:516-538` |
| D8 | `WorkflowPrimitives.ExecuteSlice` silently returns an empty result (no error) when `end < start` — a misconfigured recipe step produces a confusing "did nothing" symptom with no diagnostic. | 🔵 Low | `WorkflowPrimitives.ahk:344-352` |
| D9 | `CorpusSetEngine` re-runs the full `Analyze()`/tokenization pass up to 3× per single invocation (once directly, twice more inside two separate `ComputeDifferences()` calls) — a performance risk for the large multi-document corpora the tool is designed for. | 🔵 Low (perf) | `CorpusSetEngine.ahk:448-483` |
| D10 | `RecipeModel`'s loop-container return-type inference only reliably matches outputs named `.text` — a future tool adapter whose primary output has a different field name gets silently wrong type inference downstream. Latent trap for future tool authors, not an active bug today. | 🔵 Low | `RecipeModel.ahk:196-208` |

---

## 5. Guidelines for Future LLM Development

Read this before the next session touching this codebase.

### Process rules (the tracker's credibility is currently broken — fix the process, not just the wording)
1. **Never mark a subject "Completed" in `subject_tracker.md` without a corresponding git commit in the same session.** P1 shows this has already happened at scale (the entire CorpusSetEngine subject). If you finish work, commit it before writing "Completed" — otherwise the tracker is fiction.
2. **Don't trust `subject_tracker.md`'s narrative as evidence of correctness.** It records *intent and self-assessment*, not verification. Before claiming a fix, re-derive it from the diff and, ideally, a new regression test that would fail without the fix (P3, P4 show several tests are shallower than their tracker description).
3. **When you claim "zero regressions" or "100% pass," state what the suite does *not* cover.** A pass rate is only meaningful relative to what's tested. `GenerateUUID()` and Civil division-by-zero paths have been "regression-clean" for months because nothing exercises them (P4).
4. **Every commit message should map to exactly one tracker entry, and vice versa.** Audit found this correspondence holds for most subjects except the largest, most recent one — keep it that way going forward.

### Code rules (apply the existing 20-rule standard, but close these specific gaps)
5. **`FileOpen()` → `.Close()` must be in a `finally` block**, no exceptions — this is the project's own save-template pattern and it's currently violated everywhere (R3). Fix the template once, in one place if possible, and copy the fixed version forward.
6. **Never use `Sleep()` for clipboard-restore or UI-dismiss timing** — use `SetTimer` with a negative one-shot delay, per the standards doc. R4 shows this rule is violated inside the very module (`ClipboardHelper.ahk`) responsible for the "zero clipboard mutation" guarantee — that module should be the strictest, not the most lax.
7. **`WinActivate`, `ProcessClose`, `ProcessExist`, `WinHide` must always be in try-catch**, with no exceptions for "hot" code paths. R5 shows the rule is known (it's applied correctly elsewhere) but skipped on the busiest path in the app.
8. **Before adding a new Workflow Composer tool adapter, search `Actions_*.ahk` and `*Engine.ahk` first.** If equivalent logic already exists, call it — do not retype the regex/logic. A1 shows this discipline already broke down for the entire extraction/aggregation category; don't let it happen again for the next category of tools.
9. **Decide the globals-prefix question once, explicitly, and write it down.** Either adopt `g_` project-wide (large mechanical change) or formally amend the local standard to say "this project uses unprefixed globals, centralized in `Globals.ahk`" and then actually centralize them there (A4 shows they currently aren't). Leaving it silently inconsistent (R2) means every future session re-decides it ad hoc.
10. **Any regex applied to arbitrary user-selected/clipboard text (i.e., almost every regex in this app) should be treated as adversarial input.** Avoid nested-quantifier patterns; consider a length cap before `RegExMatch`/`RegExReplace` on unbounded pasted text (D4).
11. **Any tool whose input can legally be typed `"any"` in `WorkflowTypes` must defend its own input type at runtime**, not assume it will be a String just because most callers pass one (D1). Adapter authors: validate `Type(input)` before format-specific operations.
12. **Chained/compound regex transforms (percentage math, unit conversion, date parsing) need to be tested with more than one operator in the same expression.** D5 is a single-pass regex bug that a two-operator test case (`"100 - 10% - 5%"`) would have caught immediately — the existing MathEvaluator tests apparently don't include such a case.

### Architecture rules
13. **Keep `#Include` inside the project's own `Lib\` tree.** If a shared dependency genuinely needs to live in a sibling project (`Word Count Tooltip.ahk`, `Study_MarkdownHub`), either vendor a copy into this project's `Lib\`, or update the closed-world manifest tool (`run_tests.py`) to explicitly allowlist and report on cross-project includes instead of silently passing them as "0 leaks" (R1).
14. **New GUI files should call a shared theming helper, not re-implement `SetWindowTheme`/`BackColor` boilerplate.** Factor `ApplyDarkTheme(guiObj, listviews*)` out of the 7 existing duplicates (A7) the next time any one of them is touched — don't add an 8th copy.
15. **Files over ~15KB need a banner comment roughly every 2-4KB of logic**, not every 10-25KB (A8). If you're adding a new `Execute*`/handler group to `ToolAdapters_Builtin.ahk`, `WorkflowComposerGui.ahk`, `RecipeModel.ahk`, or `PipelineRunner.ahk`, add a `; --- Section Name ---` banner before it even if the surrounding file doesn't consistently have them yet.
16. **Sensitive-data tools (GSTIN/PAN/financial extraction, corpus analysis on confidential documents) and `RunHistory` persistence are in tension.** If a future session touches `PipelineRunner.ahk`'s history recording, consider a redaction/opt-out path for these tool categories rather than persisting raw snapshots indefinitely (D3) — this directly affects whether the project's privacy claims are honest.

### What's already good — don't regress these
- The Civil/Math/Date "heavy engine" adapters correctly delegate instead of duplicating (A2) — use this as the template for A1's fix.
- Toast/tooltip notification and CSV read/write are cleanly single-sourced (A9) — a good model for consolidating theming (rule 14) and extraction logic (rule 8).
- The class-vs-flat architectural split is coherent even though undocumented (R8) — write it down instead of changing it.
- The zero-trust test harness itself (closed-world manifest + 8 suites + SHA-256 sealing) is a genuinely strong piece of infrastructure — the problems found here are about *what* it tests and *when* work gets committed, not the harness design.

---

## Summary table

| Category | Critical | Medium | Low | Total |
|---|---|---|---|---|
| Requirements & Scope | 3 | 3 | 4 | 10 |
| Architecture | 1 | 6 | 0 | 7 (+3 positive) |
| Progress & Evidence | 1 | 3 | 0 | 4 (+1 positive) |
| Adversarial (new bugs) | 1 | 4 | 5 | 10 |
| **Total actionable findings** | **6** | **16** | **9** | **31** |

The codebase's test infrastructure and heavy-engine adapter pattern are genuinely strong. The recurring theme across all four audit angles is the same one: **self-reported completion claims (in `subject_tracker.md`, in banner comments, in commit messages) are not currently backed by an independent verification step**, and the one place that habit caused real damage is the entirely uncommitted CorpusSetEngine subject (P1) sitting in the working tree as this audit was written.
