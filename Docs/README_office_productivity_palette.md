# 🏢 Office Productivity Palette & Action Hub (v2.0.1 Modular Production Release)

> **Core Purpose:** A high-speed, keyboard-driven productivity suite tailored for executive office workflows, corporate accounting, Indian GST/Finance calculations, precision text extraction, 4-Quadrant task matrix prioritization, text statistics, dynamic text expansions, and no-code multi-step Workflow automation — all invoked without leaving the keyboard.

> [!NOTE]
> **PowerToys Compatible:** Ships with `A_MenuMaskKey := "vk07"` so Win/Alt release never injects synthetic Control keystrokes, keeping Microsoft PowerToys' exact-modifier chords (Color Picker, Text Extractor, Always On Top, etc.) working alongside this suite.

---

## ⚡ Master Hotkeys & Quick Reference

| Shortcut                                | Action                                   | Description                                                                                                                                     |
|:--------------------------------------- |:---------------------------------------- |:----------------------------------------------------------------------------------------------------------------------------------------------- |
| **`Double-Shift`**                      | **🔍 Spotlight Command Palette**         | Minimalist search bar. Toggles open/close from anywhere. Tap `1..9` or press `↓` for Top 5 tools. Auto-fades to 75% translucency on focus loss. |
| **`Esc`**                               | **❌ Global Escape Dismissal**            | Instantly dismisses **any** active Office UI window (Palette, Action Board, Snippet Manager, HUDs) even when clicked away or unfocused.         |
| **`CapsLock + Tab`**                    | **👁️ Hold-to-Peek Window**              | 4-State FSM: hold to preview previous window, release to return instantly. Self-capped at 10s and physical-key-release guarded.                 |
| **`CapsLock + Esc`**                    | **👻 X-Ray Layer Peek**                  | Ghosts top window to inspect layered windows beneath; down arrow peels deeper layers. Same 10s safety cap as Window Peek.                       |
| **`Shift + CapsLock`**                  | **🔠 Real CapsLock Toggle**              | Toggles real CapsLock state ON/OFF without unwanted ALL CAPS accidents.                                                                         |
| **`Ctrl + Shift + U`**                  | **🏗️ Civil Instant Converter**          | High-speed multi-unit converter for Length, Area, Volume, Weight, Force, Pressure, Rebar, Density & Flow.                                       |
| **`Win + 0`**                           | **⚡ Repeat Last Transformation**         | Re-applies whatever transformation was last used on highlighted text in **1 tap**.                                                              |
| **`Ctrl + H`**                          | **🔍 In-Selection Find & Replace**       | Precision search and replace restricted exclusively to highlighted selection.                                                                   |
| **`Ctrl + Shift + G`**                  | **📊 Word & Character Statistics**       | Live tooltip showing Words, Unique Words, Characters (with/without spaces), and Lines.                                                          |
| **`Shift + F3`**                        | **🔤 3-State Case Cycler**               | Cycles selection through `lowercase` → `Title Case` → `UPPERCASE` across all Windows applications.                                              |
| **`Win + T`**                           | **📋 Action Board (Task Matrix)**        | 4-Quadrant Eisenhower visual grid (`Q1 Do First`, `Q2 Schedule`, `Q3 Quick Win`, `Q4 Backlog`).                                                 |
| **`Double-Ctrl`**                       | **📌 Instant Task Capture**              | Captures highlighted text or prompt input directly into **Q4 Backlog / Triage** with zero window switching.                                     |
| **`Win + Esc`**                         | **✨ Text Replacement & Snippet Manager** | Visual management table for adding, editing, searching, and toggling dynamic text triggers.                                                     |
| **`Win + Shift + ;`**<br>`Tap CapsLock` | **⚡ Leader Key Mode**                    | Two-stage chord menu — hold `CapsLock` + `c`=Calc, `v`=Clean Text, `s`=snake_case, `x`=Checklist, `p`=Password, `w`=Number→Words, `t`=Timestamp, `n`=Daily Scratchpad, `Space`=Palette. |
| **`Alt + Shift + D`**                   | **📅 Today's ISO Date**                  | Inserts current ISO date (`YYYY-MM-DD`).                                                                                                        |
| **`Alt + Shift + T`**                   | **⏰ Current 12-Hour Time**               | Inserts formatted 12-hour timestamp with AM/PM (`hh:mm tt`).                                                                                    |

---

## 🎨 Unified Dark Theme Design System

The application strictly implements the **Unified Dark Mode Design System** across all 9 UI dialogs, HUDs, and ListViews:

* **Primary (`#7B909D`):** Slate Grey / Cool Steel Blue (Headers, active borders, Q2 quadrant).
* **Secondary (`#73828C`):** Muted Steel Slate (Subtitles, metadata, Q3 quadrant).
* **Accent (`#CE6B40`):** Warm Terracotta / Burnt Amber (Active highlights, notifications, Q1 quadrant).
* **Background (`#0A0D10`):** Ultra Dark Charcoal Navy.
* **Surface (`#182025`):** Deep Dark Slate Navy (Cards, panels, modal dialogs).
* **Text (`#F8FAFC`):** Crisp Off-White typography with `Segoe UI`.
* **Muted Text (`#98A9B3`):** Soft Slate Grey for auxiliary labels and Q4 backlog.
* **Border (`#33424D`):** Medium Dark Slate Borders.

> [!NOTE]
> **Accessibility Standard:** Zero text is placed directly over solid primary or solid accent backgrounds, ensuring maximum legibility across all monitors.

---

## 🧮 Pure-AHK Math & Calculation HUD

* **Zero COM Overhead:** Replaced legacy `ComObject("htmlfile")` with a pure-AHK recursive descent math evaluator (`NativeMathParser`) and UTF-8 buffer byte encoder with 100% Unicode parity.
* **Non-Destructive Calculation HUD:** Displays calculation results in a high-contrast HUD and automatically pastes into editable text fields.
* **Comma-Aware Number Engine (`ExtractAllNumbers`):** Correctly parses Indian currency notations (`1,25,000`, `₹2,50,000`, `2.5 Cr`, `(25,000)`) without breaking internal commas during summation or CAGR analysis.
* **Non-Destructive Data Preservation:** Invalid or non-numeric inputs (e.g. `"N/A"`, `"Pending"`) are preserved unaltered rather than silently converting to `0` or `0.00`.

---

## 🎯 4-Quadrant Eisenhower Matrix & Action Board (`Win + T`)

### 1. The 4 Quadrants

* **Q1 (Top-Left, Accent `#CE6B40`):** 🔥 **DO FIRST** (Urgent & Important).
* **Q2 (Top-Right, Primary `#7B909D`):** 📅 **SCHEDULE** (Important, Not Urgent).
* **Q3 (Bottom-Left, Secondary `#73828C`):** ⚡ **QUICK WIN** (<5 min / Delegate).
* **Q4 (Bottom-Right, Muted `#98A9B3`):** ⏳ **BACKLOG / TRIAGE** (Capture & Review).

### 2. Standardized Task Capture

* All quick-capture entry points (Action Board input box, Double-Ctrl capture, Command Palette quick tasks) land directly into **Q4 Backlog / Triage** by default.
* Tasks can be reassigned between quadrants (`Q1`..`Q4`) using the Quick-Prioritizer micro-tiles or matrix context controls.

### 3. Automatic Midnight Archiving

* **Pending tasks NEVER disappear** — they roll over day after day.
* Tasks marked `[✔] Done` from previous calendar days are automatically archived to `office_tasks_archive.csv` daily, keeping active quadrants clutter-free.

---

## ⚡ Dynamic Snippets & Text Expansions (`Win + Esc`)

Manage dynamic text replacements with real-time hardware virtual-key paste (`^{vk56}`):

| Trigger   | Replacement / Dynamic Action                                                                 | Context                     |
|:--------- |:-------------------------------------------------------------------------------------------- |:--------------------------- |
| `myemail` | `john.doe@example.com`                                                                       | Instant Email Expansion     |
| `myphone` | `+1 (555) 123-4567`                                                                          | Phone Expansion             |
| `myaddr`  | Multi-line street and postal address                                                         | Postal Address              |
| `inwords` | Converts numbers into formal Indian words (e.g. `Rupees One Lakh Twenty-Five Thousand Only`) | Cheques, Invoices & Banking |
| `egreet`  | Context-aware email greeting (Morning, Afternoon, Evening)                                   | Outlook & Gmail             |
| `cbwrap`  | Wraps clipboard content in quotation marks (`"..."`)                                         | Code & SQL Queries          |

---

## 🧩 Workflow Composer & Pipeline Runner (search **"Workflow Composer"** in Palette)

A 2-panel visual, no-code designer for chaining any of the built-in tools into a multi-step, reusable pipeline — palette-invoked only (zero global hotkeys, by design):

* **Linear Visual Model:** Presents a clear top-to-bottom step sequence while supporting DAG-style referencing between steps under the hood.
* **Auto-Wiring & Manual Override:** Automatically binds each new step to the latest compatible upstream output; every binding can be overridden per-step via **⚙ Step Settings**.
* **Flat-Flow Loop Blocks:** `LOOP START` / `LOOP END` containers with isolated, immutable per-iteration scoping — no nested modal-in-a-modal editing.
* **Complete Source & Sink Options:** Selection, Clipboard, User Prompt, File, or None as input; Clipboard, Paste/Replace, Toast HUD, or Silent as output.
* **Non-Destructive Test Run:** Executes the recipe against sample or real input with zero clipboard mutation, zero stray toasts, and zero Run History pollution, plus a granular per-step input/output inspector.
* **Prevalidated Saving:** Full 8-point schema/type validation (`RecipeModel.Validate`) runs before any recipe is written to `Recipes/`.
* **Run History & Diagnostics:** Every real (non-test) run is recorded to `Logs\WorkflowRunHistory.json`, viewable via **"Workflow: Run History & Diagnostics"** in Palette — known-sensitive fields (GSTIN/PAN/phone/email) are automatically redacted before being written to disk.
* Saved recipes surface back in the Command Palette instantly under the **🔄 Recipe** category for 1-tap re-execution.

---

## 🏛️ Comprehensive Catalog of 90+ Built-In Tools

### 🏗️ 1. Civil & Construction Engineering Suite (`Lib\Actions_CivilConvert.ahk`)

* **Civil & Construction Instant Converter (`Ctrl + Shift + U`):** 120+ units across Length, Area (Bigha, Nali, Gaj, Guntha), Volume (CFT, Brass, Cum), Rebar Weights & Spacing, Pressures (MPa, psi), Densities, and Flow.
* **Pythagoras & Plot Diagonal Calculator:** Solves 3-4-5 rule, right angles, plot corners, diagonals, and inverse missing sides (`pythagoras 30ft 40ft`).
* **Construction Rate & Unit Price Converter:** Converts rates (`Rs 500/sqft to sqm`, `4500/cum to cft`, `2500/brass to cft`).
* **Thumb Rule Cost & Material Estimator:** Estimates total budget, cement bags, steel kg, sand, aggregates, and bricks from built-up area.
* **Configure Civil Converter Defaults:** Customizes regional bigha area, material densities, and rebar sizing in `CivilEngineeringDefaults.ini`.

### 💰 2. Finance & Accounting Suite (`Lib\Actions_Finance.ahk`)

* **Reverse GST Calculator (18%) / Reverse GST (Custom Rate):** [Needs Selection] Extracts Base Price + GST from an inclusive amount or sentence, at 18% by default or any custom rate on prompt.
* **Indian Financial Year & Quarter:** [Needs Selection] Converts a date to its Indian FY string (e.g. `FY 2026-27 (Q2)`).
* **Percentage Change vs Point (pp) Change:** [Needs Selection] Compares two rates and reports both the percentage-point delta and the relative % change (e.g. `5.0% -> 6.5%` = `+1.5pp / +30%`).
* **Format Number: Indian Lakhs / International Millions:** Converts a raw number to `1,23,45,678` (Lakhs/Crores) or `12,345,678` (Millions/Billions) notation.
* **Clean Number to Raw Machine Value:** Converts `'1.25 Lakh'` / `'2.5 Cr'` / `'1,25,000'` → `125000`.
* **CAGR Growth Calculator:** [Needs Selection] Computes compound annual growth rate from natural-language Beg Val / End Val / Years text, with Indian comma support.

### 🔤 3. Text Formatting & List Suite (`Lib\Actions_Text.ahk`)

* **Word & Character Statistics (`Ctrl + Shift + G`):** Words, Unique Words, Chars, and Lines.
* **Convert Lines to Bulleted List (`•`):** Prefixes lines with bullet points.
* **Convert Lines to Numbered List (`1, 2, 3`):** Converts lines into sequential numbers.
* **Convert Lines to Markdown Checklist (`- [ ]`):** Formats lines into checkboxes.
* **3-State Case Cycler (`Shift + F3`):** `lowercase` → `Title Case` → `UPPERCASE`.
* **Join Lines:** Merges wrapped email or PDF lines into a single clean paragraph.
* **SQL IN Clause:** Formats lines into `('item1', 'item2')`.
* **Deduplicate Lines (Remove Duplicates):** Removes duplicate lines while preserving original order.
* **Insert Lorem Ipsum Dummy Text:** Inserts standard 2-paragraph placeholder filler text.
* **Set Intersect & Difference (Corpus Comparison) — `Lib\CorpusSetEngine.ahk`:** [Needs 2+ lines/files/selection] Universal mathematical set engine over 2+ documents — computes the 100% mutual baseline and reports a non-destructive, count-only toast across 5 distinctiveness tiers (Common `>75%`, Moderately distinctive `>50%`, Distinctive `>20%`, Low distinctive `>4%`, Very distinctive `<=4%`). Also available as the `corpus_set_analyzer` Workflow Composer tool for full structured output.

### 🔍 4. Regex Extraction Suite (`Lib\Actions_Extraction.ahk`)

* **Extract Indian PAN Numbers:** [Needs Selection] Pulls 10-character PAN identifiers into a clean list.
* **Extract Indian GSTINs:** [Needs Selection] Pulls 15-character GST Identification Numbers into a clean list.
* **Extract All Email Addresses:** [Needs Selection] Pulls a clean list of all emails from messy text.
* **Extract Phone & Mobile Numbers:** [Needs Selection] Pulls Indian mobile and STD phone numbers.
* **Extract All URLs & Web Links:** [Needs Selection] Pulls a clean list of all web URLs and links.
* **Extract All Dates from Text:** [Needs Selection] Pulls dates in all formats with `[VALID]` / `[INVAL]` tags.
* **Date Difference & Working Days:** Calculates calendar days and working days (Mon-Fri) between two dates.

### 📅 5. Universal Bidirectional Date Format Converter (`Lib\DateFormatConverter.ahk`)

* **Convert Date Format:** [Needs Selection] Silently replaces any Indian-standard date in place with your remembered default format — arbitrary delimiters (`/ - . \ _` space), ordinals, connectors (`of`), weekday prefixes, and unspaced alphanumeric forms (`5sept2026`, `sept5 2026`) all accepted as input.
* **Cycle Date Format (9 Formats):** [Needs Selection] Cycles the exhaustive set of 9 canonical Indian office formats (`DD/MM/YYYY`, `DD-MM-YYYY`, `DD.MM.YYYY`, `DD/MM/YY`, `DD-MM-YY`, `DD Month YYYY`, `Month DD, YYYY`, `DD Month, YYYY`, `DDDD, dd Month YYYY`) one press at a time.
* **Configure Default Date Format:** Sets the everyday silent-conversion target, persisted to `office_productivity_settings.ini`.
* Handles read-only/non-pasteable targets (PDF viewers, browsers) with a copy-to-clipboard toast fallback instead of failing silently.

### 📌 6. Window Pinning & System Utilities (`Lib\Actions_Utility.ahk`)

* **Toggle Window Always-on-Top:** Pins or unpins the active window to always stay visible.
* **Toggle Window Transparency (75%):** Semi-transparency on the active window for comparing documents.
* **Open Today's Daily Scratchpad Notes (`Win + Shift + ;` → `n`):** Opens a timestamped daily text file for quick notes.
* **Copy Clean File Path (Forward Slashes / Escaped Slashes):** Converts a clipboard/selection Windows path to `C:/Folder/File` or `C:\\Folder\\File` for URLs, JSON, Python, or SQL strings.
* **Prefix Selected File with Timestamp:** Renames the file selected in Explorer with a `YYMMDD_` prefix.
* **Google Search / Google Translate Selected Text:** Opens the default browser against the selected term.
* **Empty Windows Recycle Bin:** Silently purges all items from the Recycle Bin.
* **Quick Privacy Screen / Lock:** Instantly locks the Windows workstation.
* **Export Diagnostic & Analytics Report:** Generates and opens the full diagnostics & telemetry report on the Desktop (see [Production Telemetry & Diagnostics](#-production-telemetry--diagnostics) below).

---

## 📈 Production Telemetry & Diagnostics

Telemetry and logs are stored in `%APPDATA%\OfficeProductivityHub\`:

* **`usage_analytics.ini`:** Tracks tool execution counts, top target applications, and launch triggers.
* **`zero_result_searches.log`:** Missing Feature Discovery Engine — records searches with 0 results.
* **`error_telemetry.log`:** Intercepts runtime exceptions with callstacks and line numbers.
* **Export Diagnostic Report:** Search `"Export Diagnostic & Analytics Report"` in Palette to create a full diagnostic dump on your Desktop.

### 🛡️ Self-Healing: Stuck-CapsLock Watchdog

The `CapsLock + Tab/Esc/t/v/s/x/c/p/w/n/Space` hotkeys are gated on Windows' *physical* CapsLock state. If a key-up event is ever dropped (a UAC prompt, lock screen, or other focus-stealing surface), the OS can keep reporting CapsLock as held indefinitely, which used to require a full logoff/logon to clear. A background watchdog (`Lib\WindowPeekHotkeys.ahk`) now polls that state every second and, if it stays down 12+ seconds outside a legitimate Window Peek / X-Ray session, forces a synthetic release and logs the event to `error_telemetry.log` — no logoff required.

---

## 🧪 Automated Test Verification

The application is backed by a Zero-Trust Master Test Harness (`Tests\run_tests.py`) running 8 suites, plus a static `#Include` hermeticity audit and a cryptographic closed-world manifest (SHA-256 sealed snapshot of every project file, verified unmutated at the end of every run):

| Test Suite                        | File                                | Assertions | Pass Rate  |
|:---------------------------------- |:------------------------------------ |:----------:|:----------:|
| **Unit Test Suite**                | `test_suite_runner.ahk`             | 501        | **100.0%** |
| **Live Integration Suite**         | `test_integration_runner.ahk`       | 75         | **100.0%** |
| **Civil Converter Suite**          | `test_civil_converter.ahk`          | 128        | **100.0%** |
| **Civil All-Units Exhaustive**     | `test_civil_all_units_exhaustive.ahk` | 179      | **100.0%** |
| **Modularity / Manifest Suite**    | `test_modularity_runner.ahk`        | 64         | **100.0%** |
| **Workflow Composer Suite**        | `test_workflow_composer.ahk`        | 83         | **100.0%** |
| **Defect Regression Suite**        | `test_regression_defects.ahk`       | 254        | **100.0%** |
| **UI Interaction Suite**           | `test_ui_interaction_runner.ahk`    | 93         | **100.0%** |
| **Total Test Assertions**          | —                                    | **1,377**  | **100.0%** |
| **Closed-World Manifest**          | —                                    | 0 leaks / 0 mutations | **Clean** |

---

## 🛠️ Developer Guide: Adding New Tools

The suite is **100% modular and decoupled**:

1. Add your transformation function to any `Lib/Actions_*.ahk` file:
   
   ```autohotkey
   MyCustomTransform(text) {
       return StrUpper(text)
   }
   ```

2. Register it in that module's `Register*Actions()` function:
   
   ```autohotkey
   RegisterAction("My Custom Tool", "⚡ Category", "Description of tool", "keyword1, keyword2", (*) => TransformSelectedText((txt) => MyCustomTransform(txt)), "m")
   ```

3. The new tool automatically appears in the Command Palette (`Double-Shift`), is indexed for fuzzy search, ranked by frequency tracking, and supports `Win + 0` (Repeat Last Action) with zero additional configuration.
