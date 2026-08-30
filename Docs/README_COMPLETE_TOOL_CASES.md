# Office Productivity Palette & Action Hub — Complete Tool Cases

Source audited: `office_productivity_palette_v2.0.0.ahk` and all reachable included modules on 2026-08-28. Current source SHA-256: `CE7C195B1BDC585195BA9A64C3167BD7BCA82BBDFC80E8367A5EE76C88D0EA2E`.

This is a behavior audit, not just a feature list. It records what the current source covers, what only partially works, what is not covered, and what should be added. The AHK source was not modified; this README was updated to match the audited 2026-08-28 source.

## Status legend

- **Working (source-verified):** the branch exists and its deterministic result was traced from the current AHK source.
- **Partially working:** accepted, but the result is incomplete, surprising, unsafe, ambiguous, or inconsistent with the tool description.
- **Not covered:** the current implementation does not recognize or implement the case.
- **Should be included:** recommended behavior; it is **not** a current capability.
- **Runtime-verified:** covered by a fresh assertion or audit execution named in this document.
- **Historical test evidence:** a result is retained only as evidence for the older revision that produced it; it is not silently promoted to proof of the current revision.

## Contents

1. [Shared behavior and access](#1-shared-behavior-and-access)
2. [Date and time — 10 tools](#2-date-and-time-tools-10)
3. [Email — 10 tools](#3-email-tools-10)
4. [Text — 15 tools](#4-text-tools-15)
5. [Math — 11 tools](#5-math-tools-11)
6. [Finance — 8 tools](#6-finance-tools-8)
7. [Extraction — 7 tools](#7-extraction-tools-7)
8. [Utility — 12 registrations](#8-utility-tools-12)
9. [Window Peek and X-Ray — 3 tools](#9-window-peek-and-x-ray-3-tools)
10. [Action Board — 4 tools](#10-action-board-tools-4)
11. [Find & Replace in Selection — 1 external tool](#11-find--replace-in-selection-1-external-tool)
12. [Civil and construction — 5 registrations](#12-civil-and-construction-5-registrations)
13. [Hotstrings and replacement manager](#13-hotstrings-and-replacement-manager)
14. [Global/context hotkeys](#14-global-and-context-hotkeys)
15. [Highest-priority missing cases](#15-highest-priority-cases-that-should-be-included)

## 1. Shared behavior and access

### Command Palette

- Open with double-tap `Shift` (within 350 ms, Shift tapped alone) or `Ctrl+Space`.
- Search matches name, category, description, and keywords in registration order; it is substring search, not fuzzy search.
- `1`–`9` and Numpad `1`–`9` execute the corresponding result. This can prevent typing numeric searches while results exist.
- `Up`/`Down` wraps, `Enter` executes, `Esc` closes.
- `Win+0` or `Ctrl+0` repeats only the last action executed through the palette. Direct hotkeys and leader actions are not recorded.
- Zero-result queries are logged; sensitive queries can therefore enter telemetry.

### Selection, prompt, paste, and clipboard rules

- Most transform tools copy the current selection. If it is blank, they show an InputBox; Cancel or blank stops.
- `SafeGetSelection(timeoutSec)` now honors the supplied timeout and restores a `ClipboardAll()` snapshot after Ctrl+C succeeds or times out.
- Successful transforms call centralized `InsertText(text, restoreClipboard := false)`. By default it replaces the clipboard and sends Ctrl+V; callers may opt into delayed clipboard restoration with `restoreClipboard := true`.
- Calculation results generally copy output, show a yellow HUD for 4.5 seconds, and attempt to paste.
- Extraction results paste in normal apps, but only copy in Explorer/Desktop.
- Word-count code preserves the clipboard and shows a tooltip rather than pasting.
- **Partially working:** the helper now checks `ClipWait`, but clipboard restoration is optional rather than the default and exception paths are not protected by one outer `finally` block.
- **Should be included:** explicit Copy/Paste/Replace choices and guaranteed restoration on every optional-restore exit path.

### Version and inventory discrepancies

- Version metadata is now consistent: the main header and `Lib/Globals.ahk` both declare `2.0.0`.
- **Working (source-verified):** local modules make **85 registration calls**: Date 10, Email 10, Text 15, Math 11, Finance 8, Extraction 7, Utility 12, Action Board 4, Window Peek/X-Ray 3, and Civil 5. The reachable external Find/Replace module registers 1 more row, for **86 reachable palette rows**.
- There are **85 unique action names**, not 86: `Configure Civil Converter Defaults` is registered twice (once by Utility and once by Civil), so the palette contains a duplicate entry. The duplicate callbacks open the same INI file.
- Several module comments and UI claims have stale action counts or shortcuts.

### Verification evidence (2026-08-28)

- **Compile-verified:** `Ahk2Exe` compiled the actual current main file and its reachable include graph with exit code 0 on 2026-08-28.
- **Historical only:** the prior revision recorded **148/148 assertions**, **81/81 deep audits**, and **52/52 integration scenarios**. The current test and civil runners stayed resident and produced no fresh completion report, so those figures are not current runtime proof. The existing `deep_audit_results.log` is dated 2026-08-27 and remains historical evidence.
- The current test sources include checks for formatter carry, GST bounds, X-Ray metadata/defaults, direct and cross-dimensional civil conversions, rebar, slope/DMS, Pythagoras variants, unit rates, and cost estimation; inclusion in a test file is not equivalent to a fresh pass.
- **Not runtime-verified:** live Window Peek/X-Ray activation and restoration, elevated/UAC or secure-desktop focus, virtual desktops, live hotkeys, slow clipboard/paste timing, browser launching, full GUI interaction, snippet recovery against real user files, file rename, Recycle Bin purge, destructive-operation return codes, privacy behavior and crash consistency.

### How status labels apply inside tool entries

- **Classification rule for every claim in this document:** unless a sentence, bullet, example, or table cell is explicitly marked otherwise, a statement describing what the current code accepts, calculates, emits, opens, copies, writes, or invokes is **Working (source-verified)**.
- A statement introduced by **Defect**, **Danger**, **Limitation**, **Ambiguity**, **Mismatch**, **Partially working**, or wording such as “can fail,” “can be wrong,” “is lost,” “is discarded,” “is ignored,” “is overwritten,” “is stale,” “is inconsistent,” or “is unreliable” is classified **Partially working**.
- A statement introduced by **Not covered**, “does not,” “no support,” “unsupported,” “rejects,” or “missing” is classified **Not covered**.
- Every recommendation introduced by **Should be included** is classified **Should be included** and never inherits Working status.
- In a table, a current exact output/accepted-input cell is **Working (source-verified)**; a limitation column is **Partially working** or **Not covered** according to its wording; a recommendation column is **Should be included**.

---

## 2. Date and time tools (10)

All insert at the caret, require no selection, use local system time, and replace the clipboard.

Palette descriptions containing a computed date/time are snapshots created during registration. If the app remains running across a date/time boundary, the description can be stale while the callback still inserts a freshly calculated value.

### 2.1 Today's ISO Date

- **Working:** `yyyy-MM-dd`; on 2026-08-24 → `2026-08-24`.
- Hotkey: `Alt+Shift+D` outside Microsoft Word.
- **Not covered:** UTC, timezone/offset, alternate calendar.
- **Should be included:** UTC/local choice and clipboard-preserve option.

### 2.2 Compact File Timestamp

- **Working:** `yyMMdd_HHmmss`; e.g. `260824_203015`.
- Leader chord: `t`.
- **Partially working:** two-digit year is century-ambiguous; executions in the same second can collide.
- **Should be included:** `yyyyMMdd_HHmmss`, milliseconds, UTC/offset, collision-safe suffix.

### 2.3 Formal Long Date

- **Working:** `dddd, MMMM d, yyyy`; e.g. `Monday, August 24, 2026`.
- **Partially working:** weekday/month language follows Windows locale.
- **Should be included:** explicit locale and stable English/ISO variant.

### 2.4 Current Time (12-Hour AM/PM)

- **Working:** `hh:mm tt`; e.g. `08:30 PM`.
- Hotkey: `Alt+Shift+T` outside Word.
- **Not covered:** seconds, date, timezone, offset, milliseconds.

### 2.5 Current Time (24-Hour with Seconds)

- **Working:** `HH:mm:ss`; e.g. `20:30:15`.
- **Not covered:** timezone/offset and milliseconds.

### 2.6 Tomorrow's Date

- **Working:** adds one calendar day with month/year/leap rollover; outputs `yyyy-MM-dd`.
- **Not covered:** next business day, holidays, timezone choice.

### 2.7 Yesterday's Date

- **Working:** subtracts one calendar day; outputs `yyyy-MM-dd`.
- **Not covered:** previous business day and holidays.

### 2.8 Current ISO Week Number

- **Working (runtime-verified):** `GetIsoWeekInfo()` derives both week and year from `YWeek`; `2021-01-01` → `Week 53, 2020`, `2018-12-31` → `Week 1, 2019`, and a normal output is `Week 35, 2026`.
- The helper also exposes canonical `YYYY-Www`, such as `2026-W35`, although the registered action inserts the prose form.
- **Should be included:** offer the canonical ISO form as an action/output option.

### 2.9 Current Month & Year

- **Working:** `MMMM yyyy`; e.g. `August 2026`.
- **Partially working:** month language is locale-dependent.
- **Should be included:** `yyyy-MM` option and explicit locale.

### 2.10 Work Week Date Range

- **Working:** Monday through Friday of the current Monday–Sunday week; e.g. `2026-08-24 to 2026-08-28`.
- Sunday maps back six days; weekends still show the surrounding Monday–Friday range.
- **Not covered:** holidays, configurable workweek/week start, timezone.

---

## 3. Email tools (10)

All insert literal text, require no selection, overwrite the clipboard, and do not resolve placeholders.

| Exact tool name                     | Exact output                                                                                                                                                  | Not covered / should be included                                        |
| ----------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| Email: Please Find Attached (PFA)   | `Please find the requested file(s) attached for your review.`                                                                                                 | Attachment verification, filename, singular/plural, recipient, deadline |
| Email: Acknowledgment & Follow-Up   | `Acknowledged with thanks. I am reviewing this and will update you shortly.`                                                                                  | Concrete owner/date/time; “shortly” is undefined                        |
| Email: Meeting Availability Request | `Could you please share your availability for a brief sync this week?`                                                                                        | Dates, duration, timezone, attendees, meeting link                      |
| Email: Gentle Follow-Up / Reminder  | `Just following up on my previous note to check if there are any updates on this.`                                                                            | Context, earlier-message date, response date, escalation variant        |
| Email: Out of Office Notice         | `Thank you for your email. I am currently out of the office with limited access to email. I will respond to your message as soon as possible upon my return.` | Return date, backup contact, urgent route, timezone                     |
| Email: Formal Business Greeting     | `Dear [Name],` plus two newlines                                                                                                                              | `[Name]` is literal; should prompt/profile-fill                         |
| Email: Formal Sign-Off              | `Best regards,` + blank line + `[Your Name]` + `[Your Title]`                                                                                                 | Literal placeholders; should support profiles and contact details       |
| Email: Action Required Notice       | `ACTION REQUIRED: Please review and confirm by EOD.`                                                                                                          | EOD date/time/timezone and requested action details                     |
| Email: Handover / Delegation Note   | `I am looping in [Name] who will assist you further with this request.`                                                                                       | Literal name, ownership/effective date/contact                          |
| Email: Appreciation Note            | `Thank you for your prompt assistance and support on this matter.`                                                                                            | Personalization and referenced deliverable                              |

**Should be included across all templates:** preview/edit before paste, prompted/profile placeholders, subject variants, date/timezone fields, concise/formal variants, and configurable clipboard preservation.

---

## 4. Text tools (15)

### 4.1 Word & Character Statistics

- Requires a selection; unlike normal transforms, there is no manual-input fallback.
- Output tooltip: Words, Unique Words, characters with spaces, characters without regex `\s`, and LF-based lines.
- Word delimiters are only space/LF/CR/tab; punctuation stays attached. `word` and `word,` are distinct; uniqueness is case-insensitive.
- `StrLen` is not a grapheme-cluster count. NBSP/Unicode separators and trailing-line behavior can surprise.
- Hotkeys: `Ctrl+Shift+G` outside Word; included module also globally exposes `Ctrl+Shift+C`.
- **Should be included:** punctuation/Unicode-aware tokenization, sentence/paragraph counts, clear grapheme/code-unit policy.

### 4.2 Cycle Text Case (Word Standard)

- ASCII lowercase only → Title Case; ASCII uppercase only → lowercase; all other mixed/title input → uppercase.
- `hello world` → `Hello World` → `HELLO WORLD` → `hello world`.
- No ASCII letters → unchanged. Unicode-only text, acronyms, apostrophes and mixed case can behave unexpectedly.
- Hotkey: `Shift+F3` outside Word.
- **Should be included:** Unicode/locale-aware state detection and acronym policy.

### 4.3 Paste Clean Plain Text

- Normalizes NBSP and selected zero-width characters, line endings, trailing horizontal whitespace, repeated spaces/tabs and excessive blank lines, then trims the result.
- `"  <b>Hello</b>   world  "` → `"<b>Hello</b> world"`.
- If input is already byte-for-byte normalized multiline text, the same action unwraps isolated single line breaks while preserving blank-line paragraph breaks. A first pass that changes invisible whitespace may therefore normalize without unwrapping; a second pass can then unwrap.
- **Partially working:** HTML tags/styles remain and HTML entities are not decoded. Replacing zero-width joiners/non-joiners with spaces can alter words/scripts, and the second-pass behavior makes results depend on invisible input details.
- Leader chord: `v`.
- **Should be included:** separate “clean” and “unwrap lines” actions, HTML removal/entity decoding, and an explicit remove-versus-space policy for zero-width characters.

### 4.4 Convert to UPPERCASE

- Uses `StrUpper`; preserves punctuation/spacing. `Hello 2` → `HELLO 2`.
- Casing is Windows/AHK locale-dependent.

### 4.5 Convert to lowercase

- Uses `StrLower`. `Hello 2` → `hello 2`.
- Same locale limitations.

### 4.6 Convert to Title Case

- Uses `StrTitle`; `hello world` → `Hello World`.
- **Not covered:** editorial headline rules, small words, acronym/name exceptions, language-specific rules.

### 4.7 Convert to Sentence case

- Lowercases everything, then capitalizes an ASCII letter at the start or after `. ! ?` plus whitespace.
- `HELLO WORLD. NEXT ITEM!` → `Hello world. Next item!`.
- Regression case: `HELLO. NEXT! AGAIN?` → `Hello. Next! Again?`; punctuation and following spaces are preserved.
- **Partially working:** destroys acronyms/proper nouns; misses quotes, brackets, colon/semicolon, Unicode initials, and punctuation without following whitespace.

### 4.8 Convert to snake_case

- Deletes characters outside word/space/hyphen, collapses whitespace/underscore/hyphen to `_`, trims delimiters, lowercases.
- ` Hello, world-test! ` → `hello_world_test`.
- `foo.bar` → `foobar`; camel boundaries are not split.
- Leader chord: `s`.
- **Should be included:** punctuation-to-boundary policy, camel splitting, Unicode/transliteration policy.

### 4.9 Convert to kebab-case

- Same rules as snake case with `-`: ` Hello, world_test! ` → `hello-world-test`.
- Same concatenation/camel/Unicode limitations.

### 4.10 Convert to camelCase

- Punctuation becomes spaces; split occurs on literal space, `_`, or `-`; first token lowercased, later tokens title-initialized.
- `HELLO-world_test` → `helloWorldTest`.
- `XMLHttpRequest` → `xmlhttprequest`; tabs/newlines are not consistently split; no identifier validation.
- **Should be included:** all-whitespace splitting, acronym and existing-camel handling.

### 4.11 Quote Lines (SQL IN format)

- Trims LF-separated lines, drops blanks, doubles apostrophes, preserves duplicates/order.
- `O'Brien` + newline + `Alice` → `('O''Brien', 'Alice')`.
- **Not covered:** numeric/NULL typing, dialects, batching, parameterization/prepared statements.

### 4.12 Join Lines into Single Paragraph

- Newline runs become one space; horizontal whitespace runs of 2+ become one; result is not trimmed.
- `exam-` + newline + `ple` → `exam- ple`; paragraph boundaries are lost.
- **Should be included:** dehyphenation, paragraph/bullet/table detection, final trim.

### 4.13 Convert Lines to Bulleted List (•)

- Trims lines, drops blanks, removes leading `•`, `-`, or `*`, prefixes `• `.
- `- Alpha` / `* Beta` → `• Alpha` / `• Beta`.
- Destroys indentation/nesting and can strip intentional leading symbols.

### 4.14 Convert Lines to Numbered List (1, 2, 3)

- Removes leading decimal `N.` or `N)` and renumbers from 1.
- `9) Alpha` / `2. Beta` → `1. Alpha` / `2. Beta`.
- Does not recognize Roman/letter numbering, `1:`, or nested indentation.

### 4.15 Convert Lines to Checklist ([ ])

- Removes `[ ]`, lowercase `[x]`, bullet/dash/star, or decimal markers and prefixes `- [ ] `.
- `[x] Done` / `• Next` → `- [ ] Done` / `- [ ] Next`.
- Leader chord: `x`.
- **Partially working:** completion state is lost; uppercase `[X]` is not recognized; nesting/metadata are destroyed.

---

## 5. Math tools (11)

### Cross-tool math input coverage

| Tool                             | **Working cases**                                                                                                                                   | **Partially working / not covered**                                            |
| -------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Evaluate Math Expression         | raw integers/decimals, currency symbols/codes, grouped commas, operator aliases, percentages, unary signs, parentheses and right-associative powers | locale comma-decimal notation and named functions are not supported            |
| GST / Tax Breakdown (18%)        | selection or prompt accepts the shared number/currency parser, including lakh/crore/k/m/b and accounting notation                                   | zero and negative bases are rejected                                           |
| Percentage Difference Calculator | first two rich numeric tokens, including grouped/currency/signed/unit values                                                                        | extra numbers are silently ignored; standalone `L` suffix is not expanded      |
| Format Number with Commas        | shared parser expands currency and `k/lakh/crore/m/b`, preserves negative sign, and emits international commas without forced decimals              | invalid input is returned unchanged; no invalid-input feedback                 |
| Round Number to 2 Decimals       | shared parser accepts currency, grouped numbers, signs and suffix units; output is fixed-width                                                      | invalid input is returned unchanged without feedback                           |
| Sum Column of Selected Numbers   | all rich tokens across lines/prose, including Indian/international groups, signs, currencies and supported suffixes                                 | standalone `L` suffix is not expanded; rejected-token details are not reported |
| Unix Timestamp to Readable Date  | unsigned epoch seconds of at least 9 digits                                                                                                         | sign, milliseconds, timezone choice and separated prose numbers                |
| Number to Words (Indian Rupees)  | shared parser accepts currency, grouped numbers, accounting notation and `k/lakh/crore/m/b`; paise is rounded                                       | negative amounts are explicitly rejected                                       |

### 5.1 Evaluate Math Expression

**Working syntax:**

- Trailing `=`, `=?`, or `?` is removed.
- `$ ₹ € £ ¥` are removed.
- Standard comma groups before exactly three digits are removed.
- `[]` and `{}` become parentheses.
- Multiplication: `x`, `X`, `*`, `×`, `·`; division: `÷`, `\`, `/`, `:` when between operands.
- `1500 + 18%` → `1770`; `500 * 20%` → `100`; `1500x300x87` → `39150000`; `2^3` → `8`.
- `^` and `**` are evaluated natively and right-associatively; unary `+`/`-` and nested parentheses are supported.
- Integer output has no decimals; noninteger output uses at most four decimals with trailing zeros removed.

**Partial/not covered:**

- The evaluator is now pure AHK with no COM dependency. Division by zero, missing parentheses, unknown tokens, invalid expressions, and extreme overflow return explicit failure results.
- Implementation: `Lib/MathEvaluator.ahk` uses `NativeMathParser`; financial normalization is provided by `ParseNumberOrCurrency` in `Lib/NumberParser.ahk`.
- Preprocessing still removes unsupported residual characters before tokenization, so locale decimal commas and named functions are not supported.
- **Runtime-verified:** arithmetic, percentage add/subtract/multiply, `^`, `**`, `x`, `÷`, brackets, currency stripping, grouped commas, invalid text, and division-by-zero safety are covered by the assertion suite.
- **Should be included:** locale decimal policy and an explicit supported-grammar reference in the UI.

### 5.2 GST / Tax Breakdown (18%)

- Treats input as **base/exclusive** amount. `1000` → `Base: ₹1,000.00 | Tax (18%): ₹180.00 | Total: ₹1,180.00`.
- Selection and prompt both use `ParseNumberOrCurrency`, so currency codes/symbols, grouping, accounting negatives and lakh/crore/k/m/b syntax are parsed consistently.
- Zero, negative, and invalid bases are rejected with a toast.
- **Should be included:** make “exclusive base” explicit in the registered tool description and allow a custom rate from this action.

### 5.3 Percentage Difference Calculator

- Actually directional percentage change: `100 125` → `100.00 -> 125.00 (+25.00%)`.
- `ExtractAllNumbers` preserves grouped, currency, signed and supported unit tokens; the first two are used and extra values are ignored.
- Old value zero shows warning and stops.
- **Partially working:** the prompt advertises `1L`, but the multi-token extractor omits standalone `l`; `1L 1.25L` is read as `1` and `1.25`, not lakh values.
- **Should be included:** rename to Percentage Change or add symmetric percentage difference, add the `l` alias, and warn on extra tokens.

### 5.4 Generate 16-Char Secure Password

- Generates 16 random characters from selected letters, digits 2–9, and symbols `!@#$%^&*()-_=+`; visually ambiguous letters/digits are reduced.
- Primary path gets bytes from Windows `advapi32\SystemFunction036` (`RtlGenRandom`); AHK `Random()` is the silent fallback if that OS call fails.
- **Partially working / safety warning:** no guarantee of one lowercase/uppercase/digit/symbol, byte-to-character `Mod()` mapping introduces bias, and the fallback is not reported to the user. Tests establish length/difference/basic diversity, not entropy quality.
- Leader chord: `p`.
- **Should be included:** rejection sampling or another unbiased mapping, class guarantees, configurable length/options, and fallback telemetry.

### 5.5 Generate UUID / GUID v4

- Uses Windows `CoCreateGuid`; uppercase canonical `8-4-4-4-12` UUID v4 shape.
- API failure returns blank with no user-visible error.
- **Should be included:** failure feedback.

### 5.6 Word & Character Counter

- Delegates to the same tooltip behavior documented under Word & Character Statistics; clipboard preserved.

### 5.7 Format Number with Commas

- International 3-digit grouping without forced decimals; uses the shared parser.
- `1250000` → `1,250,000`.
- `1 cr` → `10,000,000`; `10000k` → `10,000,000`; `-5000` → `-5,000`.
- Invalid input is returned unchanged.
- **Should be included:** explicit “international” name and visible invalid-input feedback.

### 5.8 Round Number to 2 Decimals

- Uses the shared number/currency parser and fixed-width formatting; suffix units and accounting signs are supported.
- `1.235` → `1.24`; `1.2` → `1.20`; `1` → `1.00`.
- Invalid input is returned unchanged without feedback.

### 5.9 Sum Column of Selected Numbers

- Uses `ExtractAllNumbers` across the selected text; grouped numbers, currencies, signs, multiple space-separated values and supported units are consumed, and zeros are included in the count.
- Output: `Sum (N numbers): ₹<Indian commas, two decimals> (<plain fixed-two-decimal total>)`.
- **Runtime-verified:** `1,25,000 + 50,000 + 2,00,000` → total `375000`; mixed currency/sign/accounting/unit tokens are also covered.
- **Partially working:** standalone `L` suffix is not expanded, and rejected-token details are not reported.

### 5.10 Unix Timestamp to Readable Date

- Keeps digits only; requires at least 9; outputs `yyyy-MM-dd HH:mm:ss` from epoch seconds.
- Negative sign is lost; prose digits concatenate; 13-digit milliseconds are treated as seconds; no timezone label.
- **Should be included:** signed epoch, 10/13-digit detection, bounds, UTC/local choice and label.

### 5.11 Number to Words (Indian Rupees)

- Uses the strict shared number/currency parser; currency, grouped numbers and `k/lakh/crore/m/b` units are expanded before conversion. Paise is rounded to two digits, including carry into rupees.
- `1250000` → `Rupees Twelve Lakh Fifty Thousand Only`.
- `10000000` → `Rupees One Crore Only`.
- `1 cr` / `1 crore` → `Rupees One Crore Only`.
- `10000k` → `Rupees Ten Crore Only`.
- `0.50` → `Fifty Paise Only`; `0` → `Rupees Zero Only`.
- Negative input returns `Negative Amounts Not Supported` and the palette action shows a warning instead of inserting words.
- **Runtime-verified:** unit expressions, INR prefix, zero, paise-only, crore/lakh, and paise rounding are assertion-tested.
- **Should be included:** singular “Rupee,” explicit maximum range, and an optional formal “and” style policy.

---

## 6. Finance tools (8)

### Cross-tool finance input-form matrix

This matrix covers all common and specifically requested number/currency families. Rare, malformed, and explicitly unsupported families are also listed so they are not mistaken for working input. Detailed tool sections below supply exact output formats and defects.

| Input family                                                               | Shared parser / clean raw                | Indian & international formatters                  | Reverse GST                                                                                    | CAGR                                                                                | % / pp tools                              | Number to words                           |
| -------------------------------------------------------------------------- | ---------------------------------------- | -------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | ----------------------------------------- | ----------------------------------------- |
| Raw digits `1250000`                                                       | **Working**                              | **Working**                                        | **Working**                                                                                    | **Working**                                                                         | **Working**                               | **Working**                               |
| Indian grouped `₹1,25,000`                                                 | **Working** → `125000`                   | **Working**                                        | **Working**, including common invoice prose                                                    | **Working** in prose/first-three-token input                                        | **Working**                               | **Working**                               |
| International grouped `1,250,000`                                          | **Working** → `1250000`                  | **Working**                                        | **Working**                                                                                    | **Working**                                                                         | **Working**                               | **Working**                               |
| Currency `₹`, `INR`, `Rs.`, `$`, `USD`, `€`, `EUR`, `£`, `GBP`, `¥`, `JPY` | **Working; currency metadata detected**  | value formatted without retaining the input symbol | **Working** through rich token extraction                                                      | **Working** through rich token extraction                                           | **Working** through rich token extraction | **Working**                               |
| `k`, `thousand(s)`                                                         | **Working** ×1,000                       | **Working**                                        | **Working**                                                                                    | **Working**                                                                         | **Working as numeric values**             | **Working**                               |
| `l`, `lakh(s)`, `lac(s)`                                                   | **Working** ×100,000                     | **Working**                                        | full names work; standalone `l` is omitted by the multi-token extractor                        | full names work; standalone `l` is omitted by the multi-token extractor             | same standalone-`l` limitation            | **Working**                               |
| `cr`, `crore(s)`                                                           | **Working** ×10,000,000                  | **Working**                                        | **Working**                                                                                    | **Working**                                                                         | **Working as numeric values**             | **Working**                               |
| `m`, `million(s)`                                                          | **Working** ×1,000,000                   | **Working**                                        | **Working**                                                                                    | **Working**                                                                         | **Working as numeric values**             | **Working**                               |
| `b`, `billion(s)`                                                          | **Working** ×1,000,000,000               | **Working**                                        | **Working**                                                                                    | **Working**                                                                         | **Working as numeric values**             | **Working**                               |
| Negative / accounting `(1,000)`                                            | **Working and sign-preserving**          | **Working and sign-preserving**                    | rejected because total must be positive                                                        | rejected because values must be positive                                            | ungrouped negative tokens work            | words action explicitly rejects negatives |
| Decimal / European `1.250,50`                                              | **Working** → `1250.50`                  | rounded to two displayed decimals when enabled     | whole-value input works                                                                        | European natural form not supported                                                 | European form not supported               | **Working with rounded paise**            |
| Scientific `1e6`, `mn`/`bn`, word-only `one crore`                         | **Not covered**                          | invalid input is returned unchanged                | **Not covered**                                                                                | **Not covered**                                                                     | **Not covered**                           | **Not covered**                           |
| Multiple numbers or surrounding prose                                      | strict single-value parser rejects prose | inherits parser result                             | first rich token, or second when the first equals detected rate; token-order ambiguity remains | first three rich tokens regardless of surrounding prose; extras can displace values | first two tokens used; extras ignored     | strict parser rejects arbitrary prose     |

The shared parser returns value, unit, sign, normalized text and currency metadata. Higher-level multi-value tools now use `ExtractNumericTokens`, but its suffix list omits standalone `l`, and first-N-token heuristics still need semantic labels or extra-token warnings.

### 6.1 Indian Financial Year & Quarter

- Accepts selection containing `YYYY-MM-DD`, `YYYY/MM/DD`, numeric DMY-like dates, `24-Aug-2026`, or month-first English text such as `Aug 24th, 2026`; blank uses today.
- `2026-08-24` → `FY 2026-27 (Q2)`; `2026-03-31` → `FY 2025-26 (Q4)`; `2026-04-01` → `FY 2026-27 (Q1)`.
- Quarters: Apr–Jun Q1, Jul–Sep Q2, Oct–Dec Q3, Jan–Mar Q4.
- **Working (runtime-verified):** invalid/unsupported nonblank input returns `Invalid Date`; the action shows `⚠️ Invalid date format` and stops instead of silently using today.
- **Should be included:** explicit numeric locale choice and FY date-range output.

### 6.2 Percentage Change vs Point (pp) Change

- First two parsed numeric tokens; `%`, arrows and labels tolerated; negatives supported.
- `5.0% 6.5%` → `+1.50 pp` and `+30.00%` relative change.
- Grouped/currency/supported-unit tokens are preserved; extra numbers are ignored.
- Initial zero returns `+0.00%` relative change rather than undefined.
- **Partially working:** standalone `L` is not expanded by the multi-token extractor.
- **Should be included:** fraction-vs-percent mode, undefined-zero result, `L` alias and extra-token warning.

### 6.3 CAGR Growth Calculator

- Uses the first three rich numeric tokens as beginning value, ending value and years; all must be positive. Connective prose is tolerated but not semantically required.
- Correct helper example: 10,00,000 → 20,00,000 over 5 years gives CAGR `14.87%`, absolute return `+100.00%`, `2.00x`.
- `from ₹10,00,000 to ₹20,00,000 over 5 years`, `10 Lakh 20 Lakh 5`, and `1,25,000 2,50,000 3` preserve grouping/units and calculate correctly.
- **Partially working:** earlier unrelated numbers can displace the intended three values; the third token need not be labeled as years. The prompt advertises `10L 20L 5`, but standalone `L` is omitted by `ExtractNumericTokens`, so that example is treated as 10, 20 and 5.
- **Runtime-verified:** the CAGR formula, 14.87% example and absolute return are assertion/audit tested.
- **Should be included:** labeled-token validation, extra-token warning, and standalone `L` support.

### 6.4 Reverse GST Calculator (18%)

- Input is **GST-inclusive** total. An embedded `GST 12%`, `GST=12%`, or `including 12%` rate can override the nominal 18%.

- For total ₹1,18,000 at 18%, intended report:
  
  ```text
  Total (Incl. 18% GST): ₹1,18,000.00
  • Taxable Base: ₹1,00,000.00
  • Total GST (18%): ₹18,000.00 (CGST: ₹9,000.00 | SGST: ₹9,000.00)
  ```

- Whole-value inputs such as `₹1,18,000`, `118000`, `1.18 Lakh`, and supported currency/unit variants parse through the shared parser.

- **Working:** common invoice prose is tokenized without destroying comma grouping; `invoice total including 18% GST is ₹1,18,000` selects ₹1,18,000 and produces the report above.

- **Partially working:** if the first token numerically equals the detected rate it is assumed to be the rate and the second token becomes the amount; unrelated leading numbers can therefore select the wrong amount.

- **Runtime-verified:** 5%, 12%, 18%, and 28% reverse-GST calculations are covered by assertions/audit checks.

- **Working:** the helper rejects rates `<= -100` and rates `> 500`, preventing the former division-by-zero path.

- **Should be included:** use a realistic configurable GST whitelist/range, associate amounts with labels, and warn on ambiguous extra numbers.

### 6.5 Reverse GST (Custom Rate)

- Bare or grouped whole-value selections are accepted directly. If a valid amount is selected, the detected/default rate is used immediately; otherwise the action prompts for a rate and delegates to the amount workflow.
- The shared helper rejects rates `<= -100` and `> 500`; `-100` no longer reaches division by zero. Rates between `-99.99` and `0`, zero, and unusually high positive rates up to 500 are still accepted.
- **Should be included:** a realistic allowed-rate policy (or explicit warning/confirmation) and one explicit amount+rate prompt.

### 6.6 Clean Number to Raw Machine Value

The shared parser is case-insensitive and anchored to a single number/currency value. It supports sign/accounting notation, currency metadata, grouping and one suffix unit. Integer clean output has no decimals; fractional clean output uses up to two decimals.

| Working input forms                 | Multiplier / output example                                 |
| ----------------------------------- | ----------------------------------------------------------- |
| `cr`, `crore`, `crores`             | ×10,000,000; `1 cr` → `10000000`; `2.5 Crores` → `25000000` |
| `l`, `lakh`, `lakhs`, `lac`, `lacs` | ×100,000; `1.25 Lakh` → `125000`                            |
| `k`, `thousand`, `thousands`        | ×1,000; `10000k` → `10000000`                               |
| `m`, `million`, `millions`          | ×1,000,000                                                  |
| `b`, `billion`, `billions`          | ×1,000,000,000                                              |
| European `1.250,50`                 | `1250.50`                                                   |
| Other symbols/commas                | stripped; `₹1,25,000` → `125000`                            |

**Working cases (source-verified) — requested inputs:**

- `1250000` → `1250000`
- `1 cr` → `10000000`
- `10000000` → `10000000`
- `10000k` → `10000000`
- `1 crore` → `10000000`

Additional **Working** suffix examples:

- `2m`, `2 million`, `2 millions` → `2000000`
- `1.5b`, `1.5 billion`, `1.5 billions` → `1500000000`
- `2 thousand`, `2 Thousands` → `2000`
- `3 lac`, `3 lacs`, `3 LAKHS` → `300000`
- `2 Cr`, `2 CRORES` → `20000000`

**Runtime-verified:** raw, signed, accounting-negative, INR/USD, Indian/international/European grouping, leading decimal, crore/lakh/lac/k/m/b, and invalid-text cases are assertion-tested.

**Not covered:** scientific notation, `mn`/`bn`, word-only amounts, multiple values, and arbitrary prose. `INR` is detected as currency metadata: `INR 5000` → `5000`; `INR 1.25 Lakh` → `125000`.

### 6.7 Format Number with Indian Commas

This is the current closest tool to the requested “Format Currency → Indian system.” It uses the shared parser, preserves negative signs, applies Indian 3-then-2 grouping, and rounds to exactly two displayed decimals by default.

| Input       | Actual working output |
| ----------- | --------------------- |
| `1250000`   | `12,50,000.00`        |
| `1 cr`      | `1,00,00,000.00`      |
| `10000000`  | `1,00,00,000.00`      |
| `10000k`    | `1,00,00,000.00`      |
| `1 crore`   | `1,00,00,000.00`      |
| `1.25 lakh` | `1,25,000.00`         |

- **Important:** it does **not** add `₹`. Therefore `1250000 → ₹12,50,000.00` is **not currently covered by a single registered formatter**.
- Invalid input is returned unchanged; `-5000` → `-5,000.00`; internal no-decimal mode is supported.
- **Working (source-verified):** the complete absolute value is rounded before grouping; `999.999` → `1,000.00` and negative carry is preserved correctly.
- **Should be included:** a dedicated **Format Currency — Indian System** action that outputs `₹`, reports invalid input, and supports symbol/accounting choices.

### 6.8 Format Number with International Commas

- Same shared normalization, sign preservation and rounded two-decimal display, grouping by threes.
- `1250000` → `1,250,000.00`.
- `1 cr`, `10000000`, `10000k`, `1 crore` → `10,000,000.00`.
- No currency symbol; invalid input is returned unchanged. Negative values are preserved, and complete-value carry rounding is handled.

---

## 7. Extraction tools (7)

List extractors preserve first-seen order and return one item per LF line. Blank/no-result shows a toast. Results copy and normally paste; Explorer/Desktop only copy.

### 7.1 Extract All Email Addresses

- Accepts ASCII local characters `A-Z 0-9 . _ % + -`, `@`, ASCII domain/dots/hyphens, alphabetic TLD length ≥2.
- Explicit word boundaries reduce some larger-token substring matches but do not make the expression RFC-valid.
- Case-insensitive dedupe; first spelling retained.
- `A@Example.com a@example.com b+tag@x.co.in` → `A@Example.com`, `b+tag@x.co.in`.
- **Overaccepts:** consecutive dots, invalid domain-label hyphens, substrings of larger invalid addresses.
- **Not covered:** quoted local parts, Unicode/IDN, domain literals, RFC/MX validation.

### 7.2 Extract All URLs & Web Links

- Accepts `http://`, `https://`, or `www.` until whitespace, `<`, `>`, a single quote, or a double quote; trims trailing spaces plus `. , ; : ! ?` and quotes.
- Deduplication is case-sensitive.
- **Not covered:** bare domains, FTP/mailto/file, protocol-relative links.
- Closing parentheses are captured. Balanced parentheses inside a URL are no longer forcibly truncated, but prose wrappers can leave an unwanted trailing `)`, `]`, or `}`; there is no balancing, parsing, normalization or safety validation.

### 7.3 Extract Phone & Mobile Numbers

- Mobile: optional `+91` plus ten contiguous digits beginning 6–9.
- STD-like: 3–5 digits, one hyphen/space, 6–8 digits.
- Accepts `9876543210`, `+91 9876543210`, `011-12345678`.
- Exact-text dedupe only; formatted equivalents remain duplicated.
- **Not covered:** `91` without plus, `0` mobile prefix, parentheses, internal mobile spaces, extensions, international numbers.
- Can match substrings/arbitrary numeric IDs; should normalize and validate.

### 7.4 Extract Indian GSTINs

- Structural regex: 2 digits + 5 letters + 4 digits + letter + alphanumeric + `Z` + alphanumeric; output uppercase; deduped.
- `07aaaaa0000a1z5` → `07AAAAA0000A1Z5`.
- **Not covered:** state-code range, PAN semantics, entity constraints, checksum/official verification.

### 7.5 Extract Indian PAN Numbers

- Structural `[A-Z]{5}[0-9]{4}[A-Z]`, case-insensitive; output uppercase/deduped.
- `abcde1234f ABCDE1234F` → `ABCDE1234F`.
- **Not covered:** holder-type semantics/checksum/external verification; false positives possible.

### 7.6 Extract All Dates from Text

**Recognized forms:**

- `YYYY-M-D`, `YYYY/M/D`
- `D-M-YY`, `D/M/YY`, `D-M-YYYY`, `D/M/YYYY`
- `D-Mon-YY/YYYY`, `D Mon YYYY`
- `Month D, YYYY` and `Month D YYYY`, optional `st/nd/rd/th`
- Separators can mix; English month matching uses first three letters; two-digit years always become 2000–2099; numeric dates are DMY.

**Validation/results:**

- Gregorian day/month/leap validation, year range 1900–2100.
- Valid match is returned unchanged with **no tag**.
- Invalid match gets ` [INVAL]`.
- `2024-02-29` → `2024-02-29`; `31/02/2026` → `31/02/2026 [INVAL]`; `August 21st, 2026` remains unchanged.
- `12/31/2026` is treated DMY and marked invalid; `01/02/03` means 1 Feb 2003.
- **Description defect:** promises `[VALID] / [INVAL]`, but `[VALID]` is never emitted.
- **Overacceptance:** because the comma and whitespace before a month-first year are both optional, concatenated text such as `August 212026` can be divided into day 21/year 2026 and accepted.
- Exact raw duplicates only; equivalent formats/case are not semantically deduped.
- **Should be included:** locale/ambiguity choice, normalized output, `[VALID]`, pivot-year policy, non-English months, consistent separators, date-time/timezone.

### 7.7 Date Difference & Working Days

- Uses first two valid extracted dates; prompts if fewer; silently ignores any additional dates.
- Reverses later/earlier input to ascending order and discards direction/sign.
- Calendar difference is exclusive. Workday loop counts start through day before end, Monday–Friday only.
- Mon 2026-08-24 to Fri 2026-08-28 → 4 calendar days, 4 working days; Friday is excluded.
- Fri to following Mon → 3 calendar days, 1 working day; same date → 0.
- Holidays, custom weekends, leave, half-days and working hours are not considered.
- Result is a MsgBox, not copied/pasted.
- **Should be included:** explicit inclusive/exclusive option, signed direction, holiday region/calendar, extra-date warning, copy/export.

---

## 8. Utility tools (12)

### 8.1 Export Diagnostic & Analytics Report

- Generates/opens a diagnostics and telemetry report through the telemetry module.
- **Side effects:** reads logs/stats and writes a report, exposing diagnostic/app-use information.
- **Should be included:** preview/redaction, destination choice, failure/report-path confirmation.

### 8.2 Copy Clean File Path (Forward Slashes)

- Source precedence: captured palette target Explorer selection, visible Explorer selection/folder, Desktop, path-like selected text, then clipboard.
- Converts `\` to `/`; can handle multiple Explorer paths for conversion.
- Copies and normally pastes outside Explorer/Desktop.
- **Should be included:** quote policy, per-line robust handling, explicit copy-only option.

### 8.3 Copy Clean File Path (Escaped Slashes)

- Same source precedence; converts `\` to `\\` for code/JSON-style text.
- Same clipboard/paste side effects and limitations.

### 8.4 Prefix Selected File with Timestamp

- Explorer-only physical rename to `YYMMDD_<name>`.
- Only today’s prefix is recognized as already prefixed; older date prefixes stack.
- Multiple selected paths may be passed as one newline path and fail.
- **Danger:** no confirmation/undo; file/folder is renamed/moved.
- **Should be included:** preview, one/many handling, four-digit year, collision check, undo.

### 8.5 Google Search Selected Text

- Uses selection or manual prompt, percent-encodes UTF-8 bytes with a native AHK helper, then opens the default browser.
- **Partially working:** encoding failure returns the raw string, which can make a malformed/leaky URL.
- **Privacy:** sends selected text to Google.
- **Should be included:** explicit encoding-failure feedback, provider choice, privacy confirmation for sensitive text.

### 8.6 Google Translate Selected Text

- Same selection/prompt/COM behavior; opens Google Translate.
- No explicit source/target language choice in the action.
- Same privacy/encoding recommendations.

### 8.7 Toggle Window Always-on-Top

- Toggles the active window topmost state.
- **Side effect:** mutates arbitrary active window.
- **Should be included:** reliable state indicator and exclude protected/system windows.

### 8.8 Toggle Window Transparency (75%)

- Toggles alpha 190 versus 255.
- Only recognizes exactly 190 as “currently toggled”; other pre-existing alpha is overwritten.
- **Should be included:** restore original alpha, configurable level, visibility/focus safeguards.

### 8.9 Open Today's Daily Scratchpad Notes

- Creates/opens UTF-8 `Scratchpad_YYYY_MM_DD.txt` under app directory in Notepad; leader chord `n`.
- **Should be included:** configurable notes directory/editor, collision/permission error feedback.

### 8.10 Empty Windows Recycle Bin

- Calls `SHEmptyRecycleBin` silently with flags 7.
- **Danger:** irreversible, no confirmation, return code ignored, success toast can appear even on failure.
- **Should be included:** confirmation, item/size preview, result check, safer Windows UI route.

### 8.11 Quick Privacy Screen / Lock

- Immediately calls `LockWorkStation`.
- **Should be included:** failure feedback only; immediate behavior is appropriate for a privacy shortcut.

### 8.12 Configure Civil Converter Defaults

- Opens `CivilEngineeringDefaults.ini` in Notepad if it exists; otherwise shows a warning.
- The INI controls geometry fallbacks, densities, packaging, force/pressure defaults, rebar, hydraulic/slope defaults, regional land values, cost tiers, package rates and material multipliers.
- **Duplicate registration:** the Civil module registers the same action name and callback again. Both rows are functional, but only one should be exposed.
- **Should be included:** schema/range validation, comments-preserving settings UI, reload confirmation, and removal of the duplicate registration.

---

## 9. Window Peek and X-Ray (3 tools)

### 9.1 Toggle Window Peek (CapsLock+Tab)

- The palette action toggles enablement; it does **not** itself perform a peek. The feature defaults to enabled and persists `WindowPeekEnabled=1|0` under `[Settings]` in the telemetry INI.
- Hold `CapsLock+Tab` to activate the first eligible previous Z-order application window. `Tab Up` or `CapsLock Up` requests restoration of the original window.
- Target choice prefers eligible non-minimized windows, then falls back to an eligible minimized window. If the target was minimized, restoration minimizes it again before reactivating the original.
- State machine: `IDLE → STARTING → PEEKING → RESTORING → IDLE`; target activation waits up to 400 ms, original restoration waits up to 300 ms, and a 50-ms watchdog restores after 10 seconds or release of physical CapsLock **or Tab**.
- Toggling during a non-idle peek calls the restoration path before changing the setting.
- Filters own-process windows, shell/taskbar/overlay classes, hidden/disabled windows, windows at most 100 px wide/high, tool/no-activate windows, DWM-cloaked windows and owned popups.
- **Meaning of “previous”:** first eligible current Z-order entry, not guaranteed Windows Alt-Tab MRU history.
- **Improved but not live-verified:** physical Tab is now included in the watchdog. Rapid release during `STARTING` records `RESTORING` and restores after activation completes, but real focus timing is still not proven by an automated live-window test.
- **Partially working:** filtering all owned windows and windows ≤100 px can skip legitimate dialogs/utilities. Persistence failure is logged, but the toast still reports the in-memory state as though it persisted.
- **Not runtime-verified:** elevated/UAC windows, secure desktop, virtual desktops, fullscreen apps, destroyed original/target windows during transition, real minimized-window restoration and focus-denial behavior.
- **Should be included:** live window-state tests, cancellation of an in-flight activation where Windows permits it, and explicit persistence/restore failure feedback.

### 9.2 X-Ray Layer Peek (Step-Down Transparency)

- Hold `CapsLock+Esc` to make the top eligible window under the mouse transparent. If no eligible window is under the pointer, the engine falls back to all eligible non-minimized app windows in Z-order.
- While held, `Down` ghosts the next candidate and `Up` restores the most recently ghosted layer. Releasing `Esc` or CapsLock restores every window recorded in the stack. A 25-ms watchdog restores after CapsLock release or 15 seconds.
- Uses the same application-window exclusions as Window Peek and does not target minimized windows.
- **Partially working / state-loss risk:** restoration calls `WinSetTransparent("Off")`; it does not remember or restore each window's pre-existing transparency. A window that was already translucent can therefore be changed to fully opaque.
- **Partially working:** the palette callback directly starts X-Ray without requiring CapsLock; the watchdog then sees CapsLock up and ends it almost immediately. The registered action is therefore mainly discoverability metadata, not a useful click-to-run workflow.
- **Not runtime-verified:** overlapping-window order, destroyed windows, already-transparent windows, fullscreen/elevated apps, and multi-monitor layouts.
- **Should be included:** original-alpha capture/restore, a clear palette-only interaction, Esc-release verification in the watchdog, and live multi-window tests.

### 9.3 Configure X-Ray Layer Transparency

- Reads/writes `XRayOpacityPercent` in `[Settings]` of the telemetry INI. Default is 15%; accepted effective range is clamped to 5–90% and converted to alpha with `Integer(percent / 100 * 255)`.
- Cancel, blank, or nonnumeric input makes no change. Out-of-range numeric input is silently clamped (for example, `1` → 5 and `99` → 90).
- Persistence errors are logged, but the success toast still reports the in-memory setting.
- **Should be included:** explain clamping, report persistence failure, and preview opacity safely.

### CapsLock access and side effects

- Startup calls `SetCapsLockState("AlwaysOff")`, overriding the user’s existing Caps Lock state.
- A quick bare CapsLock tap under 350 ms closes visible Office UI or starts the 2.5-second leader mode.
- `Shift+CapsLock` or `Ctrl+CapsLock` toggles real Caps Lock.
- While CapsLock is held, `t/v/s/x/c/p/w/n/Space` directly execute the corresponding leader action; these keys are intercepted as chords rather than typed normally. CapsLock+Space opens the palette.

---

## 10. Action Board tools (4)

### 10.1 Open Action Board (Eisenhower Grid)

- Opens Q1 Do First, Q2 Schedule, Q3 Quick Win, Q4 Backlog.
- Board keys: `1`–`4` move, `Space` done/pending, `V` full view, `Del` deletes with no confirmation.
- Supports text filter, previews, editing, new-task Enter.
- **Should be included:** delete undo/confirmation, accessible navigation, quiet/privacy modes.

### 10.2 Capture Selected Text as Task

- Selection or InputBox; new tasks default Q4/Unassigned.
- Double-Ctrl and `Ctrl+Shift+T` also capture.
- IDs are `last array item ID + 1`, not max/UUID; unsorted import/deletion can create duplicate IDs.
- **Should be included:** stable UUID/max+1, duplicate prompt, source/context link.

### 10.3 Export Tasks to CSV / Backup

- Manual timestamped snapshot under `Backups`; weekly backup created at startup if absent.
- No retention/cleanup; weekly backup errors are swallowed.
- **Should be included:** destination, retention, integrity verification and error report.

### 10.4 Import Tasks from External CSV

- Schema: `id,task,created,commitmentType,priority,done`.
- Merges by exact case-sensitive task text; ignores imported IDs; preserves other fields; malformed/short rows are ignored.
- Priority containing 1/2/3 maps to Q1/Q2/Q3, everything else Q4; done accepts `true`/`1`.
- **Danger/partial:** no preview, validation report, rollback, provenance, robust conflict policy.
- **Should be included:** schema version, dry run, case-normalized dedupe, conflict resolution, transaction/backup.

### Board lifecycle and automation cases

- Six commitment types: Deliverable, Promise, Deadline, Follow-Up, Review, Quick.
- Classifier checks every 6 seconds, auto-dismisses after 10 seconds, throttles 10 minutes.
- Prioritizer checks every 30 seconds for classified pending Q4 tasks, auto-dismisses after 10 seconds, throttles 1 hour.
- Q1 nudge checks each minute and exposes up to two task texts near cursor; no quiet hours/screenshare protection.
- File watcher polls every 2 seconds. Internal save does not update known mtime, so it can reload/toast its own changes; timestamp resolution can miss rapid edits.
- Completed tasks created before today archive hourly/startup to `office_tasks_archive.csv` and are removed from active data. Archive is not atomic; malformed/empty created date is treated as old; no restore/dedupe/browser.
- Saves use temp then delete original then move temp, leaving a data-loss window if move fails.
- **Should be included:** atomic replace without deleting source first, locking/recovery, watcher mtime update, archive transaction/restore/dedupe, privacy controls.

---

## 11. Find & Replace in Selection (1 external tool)

### Find & Replace in Selection

- **Working:** searchable palette action registered by the reachable external module. It also opens with `Ctrl+H` or `F12`.
- Requires nonblank selection; find text cannot be empty; replacement may be empty.
- Uses literal, case-sensitive `StrReplace` and replaces **all** occurrences.
- No-match still reports success; no count/preview; original captured selection is pasted even if target content changed while modal was open.
- “Last find/replacement” variables are never updated, so prefill memory does not work.
- **Not covered:** replace one, case-insensitive, whole word, regex, preview, match count, no-match feedback, changed-target detection.
- **Should be included:** all those modes plus actual last-value update and clipboard restoration.

---

## 12. Civil and construction (5 registrations)

The Civil engine is reachable from the palette, leader chord `u`, and `Ctrl+Shift+U`. It first uses selected text; if none is available it opens a custom input prompt. Successful results are copied to the clipboard and displayed in a temporary HUD. Cross-dimensional cases may open a second prompt; blank/`DEFAULT` applies the INI fallback.

### 12.1 Civil & Construction Instant Converter

This is the complete router. It recognizes the following current case families:

| Family   | Covered units / aliases and representative working cases                                                                                                                                                                          |
| -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Length   | `m/meter/metre/mtr/mts/rmt`, `mm`, `cm`, `km`, `in/inch/"`, `ft/foot/feet/'/rft`, `yd/yard`; `10 m to ft`, `2500 mm in m`, `5' 6" to m`                                                                                           |
| Area     | `sqm/sq m/m2/m²/sqmt`, `sqmm/mm2`, `sqcm/cm2`, `sqft/sft/ft2`, `sqyd/yd2`, `gaj/gaz/गज`, acre, hectare/ha, guntha/gunta/गुंठा, bigha/beegah/बीघा, nali/naali/नाली, katha/कट्ठा, `brass_area`; `500 gaj to sqft`, `1 bigha to sqm` |
| Volume   | `cum/cu m/m3/m³`, `cft/cu ft/ft3`, cubic yard, litre/liter/ltr/L/लीटर, mL, US gallon, cubic inch, `brass`; `10 cum to cft`, `5000 litre in m3`, `1 brass to cft`                                                                  |
| Mass     | kg/kilo, g/gram, quintal/qtl, tonne/ton/MT, lb/pound, 50-kg cement bag; `20 bags to kg`, `5 quintal to kg`                                                                                                                        |
| Force    | N/newton, kN, kgf, tonne-force/ton-force/tf; `100 kN to ton-force`, `1000 kgf to kN`                                                                                                                                              |
| Pressure | Pa, kPa, MPa, `N/mm2`, `kN/m2`, bar, `kg/cm2`, psi; `25 MPa to N/mm2`, `2 bar to kg/cm2`                                                                                                                                          |
| Density  | `kg/m3`, `tonne/m3`, `g/cm3`/`g/cc`, `kg/ft3`/`kg/cft`, `lb/cft`/pcf; `1.6 g/cm3 to kg/m3`                                                                                                                                        |
| Flow     | `L/s`/LPS, `L/min`/LPM, `m3/hr`, `m3/min`, `m3/s`, CFM, GPM; `10 LPS to m3/hr`, `100 cfm to lps`                                                                                                                                  |
| Angle    | degree/deg/°, rad/radian; `90 degree to rad`                                                                                                                                                                                      |
| Geometry | `10 m x 20 m` calculates area; `2 m x 3 m x 1.5 m to cft` calculates volume; compound feet/inches is recognized                                                                                                                   |
| Survey   | fall/run, `1:N`, percent slope, degree slope, DMS↔decimal, and concrete grades M15/M20/M25/M30/M35/M40; examples: `fall 100mm in 10m`, `1:100 slope`, `2% slope to degree`, `M25 to psi`                                          |
| Rebar    | Unit weight `d²/162.28`, length↔weight, alternate diameter/length order, and equal-area spacing substitution; examples: `12mm bar weight`, `500 kg 12mm bar`, `100m 16mm steel`, `10mm @ 150 to 12mm`                             |

- Same-dimension conversions are direct. Supported deliberate cross-dimension paths are length→area, length→volume, area↔volume, volume/liquid→mass using a material/fluid density, force↔pressure using an area, and flow→mass-rate using density.
- Without a secondary parameter, configurable fallbacks include square/cube geometry, cube-root/slab depth, default layer thickness, RCC density, 1 m² loaded area and water density. These are assumptions, not measurements.
- Incompatible dimensions such as `10 m to kg/m3`, `90 degree to bar`, and `25 MPa to degree` return an explanatory rejection instead of performing arbitrary multiplication.
- Regional-unit caveat: bare `bigha`, `nali` and `katha` use fixed registry factors (the current bare `bigha` is Uttarakhand 770 m²). Although the INI lists several regional values, ordinary unit resolution does not select a region from user text.
- **Partially working:** the advertised “120+ units” counts aliases, not 120 distinct physical units. Bare `brass` resolves as volume; area requires the internal `brass_area` key, which is not natural user wording.
- **Should be included:** region selection for bigha/katha, dimensional-unit ambiguity prompts, locale-aware decimals, negative/zero validation by domain, uncertainty/assumption labels, and fresh executable tests for every canonical unit and alias.

### 12.2 Pythagoras & Plot Diagonal Calculator

- Accepts two legs in forms including `pythagoras 3 4`, `diagonal 20ft 30ft`, `right triangle 3m 4m`, `3-4-5`, `3 x 4 diagonal`, `3 by 4 diagonal`, `10x8 diag`, base/height, vertical/horizontal, `corner-to-corner`, room/slab/floor diagonal, and Hindi/site terms `guniya`, `tircha/tirchi`, `kona se kona`, `kone se kone`.
- Inverse cases solve the missing leg when a hypotenuse/diagonal and one side are identified: `5m diagonal 3m side` → 4 m; `hyp 10 base 6` → 8.
- The action prepends `diagonal` when its case-sensitive pre-check does not find lowercase `pythagoras`, `diagonal`, or `hyp`; the engine itself normalizes case, so uppercase wording can be redundantly prefixed but generally still routes.
- **Should be included:** explicit unit-mismatch handling, triangle validity messages, precision choice, third-side labeling, and visual 3-4-5/set-out guidance.

### 12.3 Construction Rate & Unit Price Converter

- Syntax requires a numeric rate plus `per` or `/`, a source unit, a connector (`to/in/into/ko/=/se`), and a target unit. Optional `Rs`, `₹`, and `lakh/crore/cr/k/m/lac` multipliers are recognized.
- Same-dimension examples: `500 per sqft to sqm` → about `5381.96` per sqm; `4500 per cum to cft` → about `127.43` per cft; `2500 per brass to cft` → `25` per cft.
- Material words can support rate conversions across volume/mass using configured density: steel/rebar/TMT/sariya, sand/ret/balu, aggregate/gravel/kadi/rodi/gitti, cement, RCC/concrete, water/pani, diesel and petrol/gasoline.
- **Partially working:** the wrapper’s selection check for `per` or `/` is case-sensitive, although the engine regex is case-insensitive; an uppercase `PER` selection can unnecessarily open the prompt.
- **Should be included:** currency preservation, explicit rate direction in the output, material/density confirmation, division-by-zero/unit validation, and rounding/precision controls.

### 12.4 Thumb Rule Cost & Material Estimator

- Recognizes `thumb rule`, `cost estimate`, `construction cost`, `house cost`, `material estimate`, `estimate <number>` and `cost <number>`. Area defaults to sqft if the unit is absent; supported area units are converted through the unit registry.
- Quality words select Basic (`basic/economy/budget`), Standard (default), or Premium (`premium/luxury/elite`) rates. Current defaults are ₹1,500, ₹1,800 and ₹2,400 per sqft.
- Produces a three-tier reconciliation: bottom-up quantities/costs, work-package costs, and macro cost-per-sqft benchmark. It estimates concrete split, member-wise steel, shuttering, cement by activity, bricks, sand, aggregate, electrical/plumbing, paint/putty/primer, flooring/joinery, labour, overhead and variance.
- `cost 1500 sqft house` uses the Standard macro benchmark of ₹27,00,000 before reconciliation details.
- **Important:** this is a configurable thumb-rule estimate, not a structural design, BOQ, tender quote, code-compliance check or site measurement. Market rates and ratios can become stale.
- **Should be included:** location/date/rate source, floors and structural system, wastage/tax/contingency choices, unit-rate provenance, result export, and a prominent professional-estimate disclaimer.

### 12.5 Configure Civil Converter Defaults

- Same action and callback as Utility 8.12; it is registered a second time. See that entry for covered settings and gaps.

---

## 13. Hotstrings and replacement manager

Personal replacement bodies are intentionally not reproduced.

### Static/dynamic included triggers

- Static prompt triggers present: `gmd`, `fif`, `srt1`, `sqlbot`, `inkpost1`, `inkpost`, `sqlrev`.
- Dynamic utility triggers: `ldt`, `tndate`, `egreet`, `inwords`, `cbwrap`, `cblist`, `lipsum`.
- `ldt`/`tndate` insert local timestamps/dates; `egreet` chooses morning/afternoon/evening; `inwords` uses clipboard or prompt; `cbwrap` quotes clipboard; `cblist` numbers nonblank clipboard lines; `lipsum` inserts filler.
- `:T:` variants omit terminating character; plain `::` variants follow normal AHK end-character behavior.

### Advanced Text Replacement Manager

- Opens with `Win+Esc`; the current local `SnippetGui.ahk` and unified `SnippetManager.ahk` support filtering, add/edit multiline, delete confirmation, enable/disable, duplicate-trigger checks, import/export, context menu and keyboard controls.
- Dynamic triggers use `:?X:`: execute callback and allow trigger inside another word. This contradicts GUI/help claims of whole-word behavior; default matching is case-insensitive.
- Replacement save escapes quotes and stores line breaks as literal `\n`.
- Import **merges/upserts in memory** by case-insensitive trigger, then performs one save and one dynamic re-registration; missing `enabled` defaults to true. It does not replace the entire catalog.
- Import reports the number of processed valid rows, including updates—not only newly added triggers.

### Unified snippet engine and remaining limitations

- `Ctrl+Shift+H`, the manager GUI, palette snippets, import/export and startup registration now use one `Snippets` collection and one `SnippetsFile`.
- Dynamic re-registration disables only triggers recorded in `RegisteredTriggers`; it no longer calls global `Hotstring("Reset")`, so unrelated static/external triggers are not globally wiped.
- Hotstring callbacks use centralized `InsertText` and append `A_EndChar` when present.
- Startup scores four candidates and loads the highest-scoring valid catalog: primary `office_productivity_snippets.csv`, master `Backups\snippets_backup_master.csv`, previous `Backups\snippets_backup_previous.csv`, and pre-import `Backups\snippets_backup_pre_import.csv`. A catalog containing custom triggers scores far above the three dummy seeds; a recovered backup self-heals the primary.
- A changed save first attempts to copy the old primary to the previous slot, merges the new catalog into the master snapshot, and then writes the primary through a `.tmp` file. Before import it also snapshots the primary to the pre-import slot. The “never overwrite more with less” guard prevents a rich previous backup from being replaced by a dummy-only primary unless forced.
- **Current on-disk audit (2026-08-28):** the primary has 32 data rows and the legacy `Backups\text_replacements.csv` has 31 data rows, but both recognized `previous` and `pre_import` slots contain only the three dummy seeds and no recognized master file exists. `text_replacements.csv` is **not in `candidateFiles`**. Therefore, if the primary is absent/corrupt at startup, this code will not load that rich legacy backup and can fall back to dummy values. This precisely explains the reported “must manually load the file on first start” behavior.
- **Partially working / recovery ranking:** the score heavily rewards the number of non-dummy triggers, so an older larger catalog can beat a newer smaller intentional catalog. Recency is only a tiny tie-breaker. Master conflict handling also retains multiple rows with the same trigger and different replacements, disabling older versions; loading/registering duplicate trigger rows can make final active behavior order-dependent.
- **Partially working / crash safety:** primary and master replacement delete the destination before moving the temporary file. A failure between delete and move can leave the destination missing. There is no filesystem lock, checksum, schema version, or automatic discovery/migration of legacy filenames.
- **Partially working:** dynamic `:?X:` triggers can expand inside words; trigger collision checks cover the unified dynamic catalog but not every statically included hotstring. Replacement text may still be visible in the manager/palette.
- **Should be included:** add `Backups\text_replacements.csv` as a one-time migration candidate (or explicitly migrate it), seed all recognized recovery slots from the best rich catalog, prefer a documented version/recency policy over “largest wins,” use atomic replace and locking, validate a post-write checksum, deduplicate master conflicts deterministically, add cross-source collision detection, optional whole-word mode, and sensitive-body redaction.

---

## 14. Global and context hotkeys

| Shortcut                                        | Current behavior / issue                                                                            |
| ----------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| Double-Shift / `Ctrl+Space`                     | Open palette                                                                                        |
| `Win+0` / `Ctrl+0`                              | Repeat last palette-executed action only                                                            |
| `Ctrl+H` / `F12`                                | Selection Find/Replace                                                                              |
| Double-Ctrl (50–450 ms)                         | Capture task; can false-trigger around normal Ctrl shortcuts because “tapped alone” is not enforced |
| `Win+T` / `Win+Shift+T`                         | Toggle board                                                                                        |
| `Ctrl+Shift+T`                                  | Capture task                                                                                        |
| `Ctrl+Shift+H`                                  | Capture selection into the unified snippet catalog                                                  |
| `Win+Esc`                                       | Replacement manager                                                                                 |
| `Win+Shift+;` / `Win+Shift+Space`               | Start the 2.5-second leader mode                                                                    |
| Quick bare `CapsLock` tap (<350 ms)             | Close visible Office UI, otherwise start leader mode                                                |
| Hold `CapsLock+Tab`                             | Peek previous eligible Z-order window; release either key to request return                         |
| Hold `CapsLock+Esc`                             | Start X-Ray; `Down` ghosts deeper layers, `Up` restores one layer, release restores the stack       |
| `Shift+CapsLock` / `Ctrl+CapsLock`              | Toggle real Caps Lock despite startup `AlwaysOff`                                                   |
| Hold CapsLock + `t/v/s/x/c/p/w/n/Space`         | Direct hyper chord; Space opens palette                                                             |
| `Ctrl+Shift+U`                                  | Open Civil & Construction Instant Converter                                                         |
| `Alt+Shift+D`                                   | ISO date outside Word                                                                               |
| `Alt+Shift+T`                                   | 12-hour time outside Word                                                                           |
| `Ctrl+Shift+G`                                  | Stats outside Word                                                                                  |
| `Shift+F3`                                      | Case cycle outside Word                                                                             |
| `Ctrl+Shift+C`                                  | Included “standalone” word count is globally active everywhere                                      |
| Mouse drag >30 px horizontal or >20 px vertical | Copies selection; if trimmed length is 30–100, shows a task reminder                                |

Leader chords: `t` compact timestamp, `v` clean text, `s` snake_case, `x` checklist, `c` math, `p` password, `w` number-to-words, `n` notes, `u` Civil Converter, and `?`/CapsLock+Space for the palette. The previous `g/f/q/j/k` mappings are no longer registered. Direct leader actions do not update Repeat Last or normal palette telemetry.

Context keys:

- Palette results: top-row/Numpad `1`–`9` execute; numeric query typing can accidentally execute.
- Palette: Up/Down/Enter/Escape.
- Replacement list: Space toggle, Del delete, F2/Enter edit.
- Board outside task input: `1`–`4`, Space, `V`, Del.
- Board task input: Enter adds.

---

## 15. Highest-priority cases that should be included

1. **Fix snippet first-start recovery/migration.** Add the existing rich `Backups\text_replacements.csv` to one-time recovery, seed recognized backup slots from the best valid catalog, and test primary-missing/corrupt/empty/dummy scenarios in an isolated temporary directory.
2. **Repair the verification runners.** The current runners stayed resident and produced no fresh result files during this audit. In particular, `test_suite_runner.ahk` textually includes `Actions_WindowPeek.ahk` (which defines hotkeys) before its assertion body; isolate pure logic from hotkey modules and make every runner fail fast with a console result and timeout.
3. Add a real **Format Currency — Indian System** action:
   - `1250000` → `₹12,50,000.00`
   - `1 cr`, `10000000`, `10000k`, `1 crore` → `₹1,00,00,000.00`
   - add `₹`, visible invalid-input feedback and symbol/accounting choices. Complete-value carry rounding is already fixed: `999.999` → `1,000.00`.
4. **Protect window state:** capture and restore original X-Ray alpha, then add real-window tests for Peek/X-Ray Z-order, focus denial, minimized restoration, destroyed handles, rapid release and multi-monitor overlap.
5. **Protect destructive state:** add confirmation/undo/result checking for Recycle Bin purge, file rename, task delete/import/archive, plus atomic replace/locking for task and snippet files.
6. Tighten GST custom-rate policy: `-100` and lower are now rejected, but zero, negative rates above -100, and implausible positive rates through 500 remain accepted.
7. Remove the duplicate `Configure Civil Converter Defaults` registration and validate/reload the INI with bounds and a safe settings UI.
8. Label every Civil cross-dimensional assumption and thumb-rule estimate; add regional land-unit choice, rate provenance/date/location, and professional-estimate warnings.
9. Add standalone `L` to rich token extraction and validate labeled/extra numbers in CAGR and percentage tools.
10. Correct the date extractor’s false `[VALID] / [INVAL]` description, require a separator before month-first years, and add explicit locale/ambiguity policy.
11. Define inclusive/exclusive workday rules and support holiday calendars/custom weekends.
12. Split “Clean Plain Text” from “Unwrap Lines”; add HTML/style removal, entity decoding and an explicit zero-width-character policy.
13. Make clipboard restoration the default or an explicit per-action choice; guarantee restoration on all optional-restore exception paths.
14. Add static/dynamic hotstring collision detection, deterministic master dedupe, schema/checksum validation, and sensitive-body redaction.

## Audit conclusion

The palette exposes **86 reachable registered rows** from **85 unique action names**: 85 local registration calls plus external Find/Replace, with one duplicated Civil-defaults action name. The 2026-08-28 source and full include graph compile successfully. The older **148/148**, **81/81**, and **52/52** figures remain historical, not current proof; the current runners did not complete cleanly in this audit. The Indian normalizer and Indian comma formatter cover all five requested numeric/unit cases and carry rounding is fixed, but the formatter still does not prepend `₹`. The largest 80/20 risks are snippet migration/recovery, non-self-proving test runners, destructive file/window-state handling, and unlabelled Civil estimation assumptions.

### Current code rating: 40/50

| Area                             | Score     | Audit basis                                                                                                                                                               |
| -------------------------------- | ---------:| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Functionality and correctness    | 14/15     | Broad 85-unique-action coverage, fixed formatter carry/GST crash path, and a substantial Civil engine; ambiguity and duplicate-registration issues remain.                |
| Reliability and state safety     | 7/10      | Peek FSM and multi-slot snippet design are thoughtful, but the actual rich legacy backup is undiscoverable, replacement is delete-then-move, and X-Ray loses prior alpha. |
| Input validation and data safety | 7/10      | Strict number parsing and incompatible-dimension rejection are good; destructive actions, permissive GST rates, assumptions and catalog conflicts need stronger controls. |
| Architecture and maintainability | 7/8       | Domain modules and centralized helpers are strong; global state, duplicate registration, large modules and external relative includes increase coupling.                  |
| Verification and documentation   | 5/7       | Current main include graph compiles and test sources are broad, but fresh runners did not terminate/report; historical pass counts cannot certify this revision.          |
| **Total**                        | **40/50** | Feature-rich and compile-clean, with the biggest deduction for recovery truth and executable verification—not for missing breadth.                                        |
