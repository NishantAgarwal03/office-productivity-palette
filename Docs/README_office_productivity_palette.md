# 🏢 Office Productivity Palette & Action Hub (v2.0.0 Unified Production Release)

> **Core Purpose:** A high-speed, keyboard-driven productivity suite tailored for executive office workflows, corporate accounting, Indian GST/Finance calculations, precision text extraction, 4-Quadrant task matrix prioritization, text statistics, and dynamic text expansions.

---

## ⚡ Master Hotkeys & Quick Reference

| Shortcut                                | Action                                   | Description                                                                                                                                     |
|:--------------------------------------- |:---------------------------------------- |:----------------------------------------------------------------------------------------------------------------------------------------------- |
| **`Double-Shift`**                      | **🔍 Spotlight Command Palette**         | Minimalist search bar. Toggles open/close from anywhere. Tap `1..9` or press `↓` for Top 5 tools. Auto-fades to 75% translucency on focus loss. |
| **`Esc`**                               | **❌ Global Escape Dismissal**            | Instantly dismisses **any** active Office UI window (Palette, Action Board, Snippet Manager, HUDs) even when clicked away or unfocused.         |
| **`CapsLock + Tab`**                    | **👁️ Hold-to-Peek Window**              | 4-State FSM: hold to preview previous window, release to return instantly.                                                                      |
| **`CapsLock + Esc`**                    | **👻 X-Ray Layer Peek**                  | Ghosts top window to inspect layered windows beneath; down arrow peels deeper layers.                                                           |
| **`Shift + CapsLock`**                  | **🔠 Real CapsLock Toggle**              | Toggles real CapsLock state ON/OFF without unwanted ALL CAPS accidents.                                                                         |
| **`Ctrl + Shift + U`**                  | **🏗️ Civil Instant Converter**          | High-speed multi-unit converter for Length, Area, Volume, Weight, Force, Pressure, Rebar, Density & Flow.                                       |
| **`Win + 0` / `Ctrl + 0`**              | **⚡ Repeat Last Transformation**         | Re-applies whatever transformation was last used on highlighted text in **1 tap**.                                                              |
| **`Ctrl + H` / `F12`**                  | **🔍 In-Selection Find & Replace**       | Precision search and replace restricted exclusively to highlighted selection.                                                                   |
| **`Ctrl + Shift + G`**                  | **📊 Word & Character Statistics**       | Live tooltip showing Words, Unique Words, Characters (with/without spaces), and Lines.                                                          |
| **`Shift + F3`**                        | **🔤 3-State Case Cycler**               | Cycles selection through `lowercase` → `Title Case` → `UPPERCASE` across all Windows applications.                                              |
| **`Win + T`**                           | **📋 Action Board (Task Matrix)**        | 4-Quadrant Eisenhower visual grid (`Q1 Do First`, `Q2 Schedule`, `Q3 Quick Win`, `Q4 Backlog`).                                                 |
| **`Double-Ctrl`**                       | **📌 Instant Task Capture**              | Captures highlighted text or prompt input directly into **Q4 Backlog / Triage** with zero window switching.                                     |
| **`Win + Esc`**                         | **✨ Text Replacement & Snippet Manager** | Visual management table for adding, editing, searching, and toggling dynamic text triggers.                                                     |
| **`Win + Shift + ;`**<br>`Tap CapsLock` | **⚡ Leader Key Mode**                    | Two-stage chord menu (`g`=GST, `f`=FY, `w`=Stats, `c`=Calc, `v`=RawText, `u`=Civil, `p`=Pass, `t`=Time, `n`=Notes, `x`=Checklist).              |
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

## 🏛️ Comprehensive Catalog of 85+ Built-In Tools

### 🏗️ 1. Civil & Construction Engineering Suite (`Lib\Actions_CivilConvert.ahk`)

* **Civil & Construction Instant Converter (`Ctrl + Shift + U`):** 120+ units across Length, Area (Bigha, Nali, Gaj, Guntha), Volume (CFT, Brass, Cum), Rebar Weights & Spacing, Pressures (MPa, psi), Densities, and Flow.
* **Pythagoras & Plot Diagonal Calculator:** Solves 3-4-5 rule, right angles, plot corners, diagonals, and inverse missing sides (`pythagoras 30ft 40ft`).
* **Construction Rate & Price Converter:** Converts rates (`Rs 500/sqft to sqm`, `4500/cum to cft`, `2500/brass`).
* **Thumb Rule Cost & Material Estimator:** Estimates total budget, cement bags, steel kg, sand, aggregates, and bricks from built-up area.
* **Configure Civil Converter Defaults:** Customizes regional bigha area, material densities, and rebar sizing in `CivilEngineeringDefaults.ini`.

### 💰 2. Finance & Accounting Suite (`Lib\Actions_Finance.ahk`)

* **Reverse GST (5%, 12%, 18%, 28%):** Breaks gross amounts into Base Price + CGST + SGST.
* **Current Financial Year (`Win + Shift + ;` → `f`):** Formats and inserts Indian FY string (e.g. `FY 2026-27 (Q2)`).
* **Validate GSTIN Checksum:** Verifies 15-character GSTIN structure, state codes, and checksums.
* **Format Currency (Indian Lakhs/Crores):** Converts numbers to `₹12,50,000.00` format.
* **Number to Words (Indian Rupees):** Generates formal words for invoices (`Rupees ... Only`).
* **CAGR Growth Calculator:** Computes compound annual growth rate with Indian comma support.

### 🔤 3. Text Formatting & List Suite (`Lib\Actions_Text.ahk`)

* **Word & Character Statistics (`Ctrl + Shift + G`):** Words, Unique Words, Chars, and Lines.
* **Convert Lines to Bulleted List (`•`):** Prefixes lines with bullet points.
* **Convert Lines to Numbered List (`1, 2, 3`):** Converts lines into sequential numbers.
* **Convert Lines to Markdown Checklist (`- [ ]`):** Formats lines into checkboxes.
* **3-State Case Cycler (`Shift + F3`):** `lowercase` → `Title Case` → `UPPERCASE`.
* **Join Lines (`Win + Shift + ;` → `j`):** Merges wrapped email or PDF lines into a single clean paragraph.
* **SQL IN Clause (`Win + Shift + ;` → `q`):** Formats lines into `('item1', 'item2')`.

### 🔍 3. Regex Extraction Suite (`Lib\Actions_Extraction.ahk`)

* **Extract All PAN Numbers:** Scrapes 10-character PAN identifiers (`[A-Z]{5}[0-9]{4}[A-Z]{1}`).
* **Extract All GSTIN Numbers:** Extracts 15-character GSTINs into clean lists.
* **Extract All Email Addresses:** Scrapes emails from unformatted web text or logs.
* **Extract All Phone Numbers:** Captures 10-digit mobile and landline numbers (+91 / 0 prefixes).
* **Extract All URLs:** Extracts HTTP/HTTPS links into structured lists.

### 📌 4. Window Pinning & Utilities (`Lib\Actions_Utility.ahk`)

* **Toggle Always-On-Top (`Win + Shift + ;` → `k`):** Pins any active window on top.
* **Quick Scratchpad (`Win + Shift + ;` → `n`):** Floating, borderless notepad for phone notes.
* **Convert Windows Path to Unix Path:** Converts `C:\Users\Admin\Docs` → `C:/Users/Admin/Docs`.
* **Escape Backslashes in Path:** Converts `\` to `\\` for JSON, Python, and SQL strings.

---

## 📈 Production Telemetry & Diagnostics

Telemetry and logs are stored in `%APPDATA%\OfficeProductivityHub\`:

* **`usage_analytics.ini`:** Tracks tool execution counts, top target applications, and launch triggers.
* **`zero_result_searches.log`:** Missing Feature Discovery Engine — records searches with 0 results.
* **`error_telemetry.log`:** Intercepts runtime exceptions with callstacks and line numbers.
* **Export Diagnostic Report:** Search `"Export Diagnostic & Analytics Report"` in Palette to create a full diagnostic dump on your Desktop.

---

## 🧪 Automated Test Verification

The application is backed by three test runners:

| Test Suite                 | File                          | Scenarios                 | Pass Rate  |
|:-------------------------- |:----------------------------- |:-------------------------:|:----------:|
| **Unit Test Suite**        | `test_suite_runner.ahk`       | 108                       | **100.0%** |
| **Deep Audit Suite**       | `deep_audit_runner.ahk`       | 67                        | **100.0%** |
| **Live Integration Suite** | `test_integration_runner.ahk` | 24                        | **100.0%** |
| **Total Test Assertions**  | —                             | **199**                   | **100.0%** |
| **`#Warn All, StdOut`**    | —                             | **0 Warnings / 0 Errors** | **Clean**  |

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

3. The new tool automatically appears in the Command Palette (`Double-Shift`), is indexed for fuzzy search, ranked by frequency tracking, and supports `Win + 0` / `Ctrl + 0` (Repeat Last Action) with zero additional configuration.
