# User Intention Document — Office Productivity Palette & Action Hub v2.0.0

**Generated:** 2026-08-29 | Audit Date: 2026-08-29

**Purpose:** This document captures the USER'S ORIGINAL INTENT for every tool
registered in the codebase. Each entry describes WHAT the user wanted the
tool to do, HOW it should behave, and WHY certain design choices were made.
"Missed cases" that appear intentional are noted as DESIGN DECISIONS.

---

**Section 1: DATE & TIME TOOLS (10 Tools)**

**Source:** Lib\Actions_DateTime.ahk

## Tool 1: Today's ISO Date

**Intent:** User wants to type today's date in ISO format (yyyy-MM-dd) at the
cursor position with a single action. This is the most frequently needed
date format for file names, reports, and logs.

**Trigger:** Command Palette / Alt+Shift+D hotkey

**Input:** None (uses system clock A_Now)

**Output:** Inserts e.g. "2026-08-29" at caret via InsertText()

**Design Decision:** Description is evaluated at script startup, so the palette
shows the date as of boot time. This is intentional — the description serves
as a "preview" rather than a live value. The EXECUTION always uses live time.

## Tool 2: Compact File Timestamp

**Intent:** User wants a compact, sortable timestamp for file naming conventions
(YYMMDD_HHMMSS). This format is short enough for filenames but includes
date and time for uniqueness.

**Trigger:** Command Palette / Leader Key chord "t"

**Input:** None (uses system clock)

**Output:** Inserts e.g. "260829_060135" at caret

**Design Decision:** Uses 2-digit year deliberately for compactness.

## Tool 3: Formal Long Date

**Intent:** User wants a formal, human-readable date for letters, memos, and
professional documents (e.g. "Saturday, August 29, 2026").

**Trigger:** Command Palette

**Input:** None

**Output:** Inserts formatted date with full day name, month name, day, year.

## Tool 4: Current Time (12-Hour AM/PM)

**Intent:** User wants 12-hour clock format with AM/PM for correspondence and
meeting notes. Matches Microsoft Word's Alt+Shift+T behavior.

**Trigger:** Command Palette / Alt+Shift+T hotkey

**Input:** None

**Output:** Inserts e.g. "06:01 AM" at caret

## Tool 5: Current Time (24-Hour with Seconds)

**Intent:** User wants precise 24-hour time for logs, technical documentation,
and timestamping events.

**Trigger:** Command Palette

**Input:** None

**Output:** Inserts e.g. "06:01:35" at caret

## Tool 6: Tomorrow's Date

**Intent:** User frequently sets deadlines for "tomorrow" and wants ISO date
for the next calendar day without mental math.

**Trigger:** Command Palette

**Input:** None

**Output:** Inserts tomorrow's date in yyyy-MM-dd format

**Design Decision:** Always adds exactly 1 day — no business day logic.

## Tool 7: Yesterday's Date

**Intent:** User needs yesterday's date for referencing prior events, reports,
or backfilling entries.

**Trigger:** Command Palette

**Input:** None

**Output:** Inserts yesterday's date in yyyy-MM-dd format

## Tool 8: Current ISO Week Number

**Intent:** User works in sprint/week-based planning and wants to quickly insert
the current ISO week number (e.g. "Week 35, 2026").

**Trigger:** Command Palette

**Input:** None

**Output:** Inserts formatted ISO week string using FormatTime YWeek

## Tool 9: Current Month & Year

**Intent:** User wants the current period name for headers, report titles, and
monthly summaries (e.g. "August 2026").

**Trigger:** Command Palette

**Input:** None

**Output:** Inserts current month name and year

## Tool 10: Work Week Date Range

**Intent:** User wants the Monday-to-Friday date range for the current work week
for weekly status reports and planning headers.

**Trigger:** Command Palette

**Input:** None

**Output:** Inserts "yyyy-MM-dd to yyyy-MM-dd" (Monday to Friday)

**Design Decision:** On weekends, shows the PAST week's range (the week that
just ended). This is intentional — the user considers the completed week as
the "current" context until a new work week starts on Monday.


---

**Section 2: EMAIL TEMPLATES (10 Tools)**

**Source:** Lib\Actions_Email.ahk

## Tool 11: Email: Please Find Attached (PFA)

**Intent:** User frequently sends attachments and wants a professional one-liner
ready to paste. Avoids re-typing the same sentence hundreds of times.

**Input:** None

**Output:** "Please find the requested file(s) attached for your review."

## Tool 12: Email: Acknowledgment & Follow-Up

**Intent:** User wants to quickly acknowledge receipt and promise follow-up.

**Output:** "Acknowledged with thanks. I am reviewing this and will update you
shortly."

## Tool 13: Email: Meeting Availability Request

**Intent:** User frequently coordinates meetings and needs a polite availability
check template.

**Output:** "Could you please share your availability for a brief sync this week?"

## Tool 14: Email: Gentle Follow-Up / Reminder

**Intent:** User needs a non-aggressive follow-up nudge for pending items.

**Output:** "Just following up on my previous note to check if there are any
updates on this."

## Tool 15: Email: Out of Office Notice

**Intent:** User wants a professional OOO auto-reply template.

**Output:** Full OOO paragraph about limited access and delayed response.

## Tool 16: Email: Formal Business Greeting

**Intent:** User wants a formal salutation with a [Name] placeholder.

**Output:** "Dear [Name],\n\n"

**Design Decision:** Placeholders like [Name] are LITERAL and not auto-filled.
The user intentionally wants to manually replace them as a reminder.

## Tool 17: Email: Formal Sign-Off

**Intent:** User wants a professional closing block with placeholders.

**Output:** "Best regards,\n\n[Your Name]\n[Your Title]"

**Design Decision:** Same placeholder philosophy — literal [Your Name].

## Tool 18: Email: Action Required Notice

**Intent:** User needs a bold action-required flag for urgent email items.

**Output:** "ACTION REQUIRED: Please review and confirm by EOD."

## Tool 19: Email: Handover / Delegation Note

**Intent:** User frequently loops in colleagues and wants a standard delegation
phrase.

**Output:** "I am looping in [Name] who will assist you further with this request."

## Tool 20: Email: Appreciation Note

**Intent:** User wants a quick thank-you sentence for professional courtesy.

**Output:** "Thank you for your prompt assistance and support on this matter."

**Design Decision (all email tools):** No leader chords or dedicated hotkeys
are assigned to email templates. The user accesses them exclusively through
the Command Palette by typing keywords like "pfa", "ack", "ooo", etc.
This is intentional to avoid hotkey clutter — these are used occasionally,
not dozens of times per day like date/time tools.


---

**Section 3: TEXT TRANSFORMATION TOOLS (15 Tools)**

**Source:** Lib\Actions_Text.ahk

## Tool 21: Word & Character Statistics

**Intent:** User wants Microsoft Word-style word/character/line count as a
floating tooltip that auto-dismisses. Available EVERYWHERE, not just Word.

**Trigger:** Command Palette / Ctrl+Shift+G / Ctrl+Shift+C

**Input:** Selected text

**Output:** Tooltip showing Words, Unique Words, Chars (w/ and w/o spaces), Lines

**Design Decision:** Delegates to ShowTextStats() from external Word Count module.
Uses IsSet() guard so the tool silently no-ops if the module is missing.

## Tool 22: Cycle Text Case (Word Standard)

**Intent:** User wants Microsoft Word's Shift+F3 behavior — cycle through
lowercase → Title Case → UPPERCASE → lowercase. Works in ANY application.

**Trigger:** Command Palette / Shift+F3

**Input:** Selected text

**Output:** Replaces selection with next case state

**Design Decision:** Single-character text degrades to 2-state toggle (a↔A).
This is acceptable — the 3-state cycle is designed for multi-word text.

## Tool 23: Paste Clean Plain Text

**Intent:** User frequently copies text from PDFs, web pages, and formatted
documents that contains invisible Unicode characters, excessive whitespace,
and broken line wrapping. This tool normalizes it to clean plain text.

**Trigger:** Command Palette / Leader Key chord "v"

**Input:** Selected text (or clipboard)

**Output:** Cleaned text with normalized spaces, CRLF, no NBSP/zero-width chars

**Design Decision:** 2-pass behavior is intentional — first pass cleans
whitespace; if text is already clean, second pass un-wraps line breaks
into flowing paragraph. Repeated invocation toggles between wrapped/unwrapped.

## Tool 24: Convert to UPPERCASE

## Tool 25: Convert to lowercase

## Tool 26: Convert to Title Case

**Intent:** Direct case conversion utilities when the user knows exactly which
case they want (vs. cycling). Standard text editing operations.

**Input:** Selected text

**Output:** Replaced with converted case

## Tool 27: Convert to Sentence case

**Intent:** User wants proper grammatical sentence capitalization — lowercase
everything, then capitalize after . ! ? and at the start.

**Design Decision:** Does NOT handle abbreviations (Mr., e.g., i.e.) — this
is intentionally simple regex-based. Full NLP-aware sentence case is out
of scope for a lightweight AHK tool.

## Tool 28: Convert to snake_case

**Intent:** Developer user wants to quickly convert variable names or text to
snake_case for Python/SQL/etc.

**Trigger:** Command Palette / Leader Key chord "s"

**Design Decision:** Does NOT split on camelCase boundaries. The tool is
designed for converting SPACE-separated words to snake_case, not for
refactoring existing camelCase identifiers.

## Tool 29: Convert to kebab-case

**Intent:** Convert text to kebab-case for URLs, CSS class names, and slugs.

## Tool 30: Convert to camelCase

**Intent:** Convert text to camelCase for JavaScript/Java variable names.
Splits on spaces, underscores, and hyphens.

## Tool 31: Quote Lines (SQL IN format)

**Intent:** User frequently needs to convert a list of values into SQL IN
clause format: ('item1', 'item2', 'item3'). Handles single quote escaping.

**Input:** Multi-line selected text

**Output:** SQL-formatted ('val1', 'val2') with escaped quotes

## Tool 32: Join Lines into Single Paragraph

**Intent:** User copies text from PDFs and web pages that has artificial line
breaks in the middle of sentences. This merges all lines into one paragraph.

**Design Decision:** Uses aggressive regex — ALL newlines become spaces. This
is the desired behavior for PDF text extraction.

## Tool 33: Convert Lines to Bulleted List (•)

**Intent:** Turn plain text lines into a bulleted list using • character.
Strips existing bullet markers before re-applying.

## Tool 34: Convert Lines to Numbered List (1, 2, 3)

**Intent:** Turn plain text lines into a numbered list (1. 2. 3.).
Strips existing numbering before re-applying for clean renumbering.

## Tool 35: Convert Lines to Checklist ([ ])

**Intent:** Turn plain text lines into Markdown checkbox items (- [ ] task).

**Trigger:** Leader Key chord "x"
Strips existing checkboxes/bullets before re-applying.


---

**Section 4: MATH TOOLS (11 Tools)**

**Source:** Lib\Actions_Math.ahk

## Tool 36: Evaluate Math Expression

**Intent:** User wants an instant calculator that works on ANY selected text
containing a math formula. Supports ₹1500 * 1.18, 2^8, percentages, and
Indian number formats. No external dependencies (pure AHK parser).

**Trigger:** Command Palette / Leader Key chord "c"

**Input:** Selected text or InputBox formula

**Output:** Yellow HUD showing result, copies to clipboard, auto-pastes

**Design Decision:** Routes Pythagoras/Guniya queries to Civil module.

**Percentage handling:** "100 + 18%" = 100 + (100 * 0.18) = 118. The percentage
applies to the IMMEDIATELY preceding number, not the entire expression.

## Tool 37: GST / Tax Breakdown (18%)

**Intent:** Indian user frequently calculates 18% GST on base amounts for
invoicing. Shows Base, Tax amount, and Total in ₹ with Indian comma format.

**Input:** Selected number or currency text

**Output:** "Base: ₹1,000 | Tax (18%): ₹180 | Total: ₹1,180"

**Design Decision:** Always treats input as BASE amount (exclusive of tax).
For inclusive amounts, use "Reverse GST Calculator" instead.

## Tool 38: Percentage Difference Calculator

**Intent:** User wants to quickly see the percentage change between two numbers.

**Input:** Two numbers (e.g. "100 125" or "1L 1.25L")

**Output:** "100.00 -> 125.00 (+25.00%)"

**Design Decision:** First number is ALWAYS the old/baseline value, second is
the new value. Direction matters.

## Tool 39: Generate 16-Char Secure Password

**Intent:** User needs quick, memorable-yet-secure passwords. Uses a dictionary
word transformed with leetspeak substitutions and padded with cryptographic
random characters from RtlGenRandom.

**Trigger:** Command Palette / Leader Key chord "p"

**Input:** None

**Output:** 16-character password inserted and copied to clipboard

**Design Decision:** Dictionary-based approach is intentional — the user values
passwords that have some mnemonic structure over pure random noise.

## Tool 40: Generate UUID / GUID v4

**Intent:** User needs RFC 4122 UUIDs for database records, API keys, etc.
Uses Windows COM CoCreateGuid for standard compliance.

**Input:** None

**Output:** Standard UUID like "A1B2C3D4-E5F6-7890-ABCD-EF1234567890"

## Tool 41: Word & Character Counter

**Intent:** Duplicate entry of Tool 21 registered under Math category so users
searching for "count" or "words" in the Math context also find it.

**Design Decision:** Intentional duplicate registration for discoverability.

## Tool 42: Format Number with Commas

**Intent:** Format raw numbers with international 3-digit grouping (1,000,000).
No forced decimals — keeps integers as integers.

**Design Decision:** Uses includeDecimals=false intentionally. For decimals,
use the Finance version.

## Tool 43: Round Number to 2 Decimals

**Intent:** Quick rounding for financial/engineering values. Always shows
exactly 2 decimal places (e.g. 123.456 → 123.46).

## Tool 44: Sum Column of Selected Numbers

**Intent:** User selects a column of numbers (from a table, invoice, or list)
and wants the total sum. Supports currency symbols, Indian formats, etc.

**Output:** "Sum (N numbers): ₹X,XX,XXX (XXXX.XX)"

**Design Decision:** Always shows ₹ symbol in output. This is intentional —
the primary user is in India and most sums are monetary.

## Tool 45: Unix Timestamp to Readable Date

**Intent:** Developer/sysadmin user needs to convert Unix epoch seconds to
human-readable date format. Requires ≥9 digits to avoid false positives.

**Input:** Epoch timestamp (e.g. 1787385200)

**Output:** "yyyy-MM-dd HH:mm:ss"

**Design Decision:** Outputs as local time, not UTC. The user wants to see
the time in their local timezone (IST).
**Known Issue:** DateAdd from epoch base 19700101 is UTC-based; FormatTime
does not add timezone offset. The result is in UTC, not IST.

## Tool 46: Number to Words (Indian Rupees)

**Intent:** User writes cheques, invoices, and legal documents that require
the amount in Indian English words (e.g. "Rupees One Lakh Twenty-Five
Thousand Only"). Supports paise for fractional amounts.

**Trigger:** Command Palette / Leader Key chord "w"

**Input:** Number or currency text

**Output:** Indian format words with "Rupees ... and ... Paise Only"


---

**Section 5: FINANCE TOOLS (8 Tools)**

**Source:** Lib\Actions_Finance.ahk

## Tool 47: Indian Financial Year & Quarter

**Intent:** Indian user needs to quickly determine which Financial Year and
Quarter a date falls into (Indian FY runs April-March).

**Input:** Selected date text; if empty, defaults to TODAY

**Output:** "FY 2026-27 (Q2)"

**Design Decision:** Empty selection defaults to current date without prompting.
This is intentional — the most common use case is "what FY is it NOW?"

## Tool 48: Percentage Change vs Point (pp) Change

**Intent:** Finance/economics user needs to distinguish between percentage-POINT
change (absolute) and relative percentage change. E.g. interest rate going
from 5.0% to 6.5% is +1.5 pp but +30% relative change.

**Input:** Two rates/numbers

**Output:** MsgBox showing both pp and % calculations

**Design Decision:** Uses MsgBox (not HUD) because the result is informational
and the user needs time to read and understand both values.

## Tool 49: CAGR Growth Calculator

**Intent:** Investment analysis — user wants Compound Annual Growth Rate from
starting value, ending value, and number of years.

**Input:** 3 numeric tokens (beginning, ending, years)

**Output:** CAGR %, Absolute Return %, Growth Multiple in MsgBox

**Design Decision:** Uses MsgBox for multi-line detailed report display.

## Tool 50: Reverse GST Calculator (18%)

**Intent:** User has a GST-INCLUSIVE invoice amount and needs to back-calculate
the base price, total GST, and split CGST/SGST components.

**Input:** Total amount (inclusive of 18% GST)

**Output:** Multi-line breakdown inserted into document

**Design Decision:** Outputs CGST and SGST as equal 50/50 split, matching
standard Indian intrastate GST structure.

## Tool 51: Reverse GST (Custom Rate)

**Intent:** Same as above but for non-standard GST rates (5%, 12%, 28%, etc).
Prompts for rate if not detected in selected text.

**Design Decision:** Auto-detects rate from text like "including 12% GST" or
"GST = 28%". Falls back to prompt if not found.

## Tool 52: Clean Number to Raw Machine Value

**Intent:** User has formatted numbers ("1.25 Lakh", "2.5 Cr", "₹1,25,000")
and needs the raw numeric value for spreadsheets or calculations.

**Output:** Plain number like "125000" replacing the selected text

## Tool 53: Format Number with Indian Commas

**Intent:** Format a raw number with Indian numbering system commas
(12,34,567.89). Always includes 2 decimal places.

**Design Decision:** Does NOT prepend ₹ symbol. This is intentional — the
user may be formatting non-monetary numbers (quantities, measurements).

## Tool 54: Format Number with International Commas

**Intent:** Format a raw number with international 3-digit grouping
(1,234,567.89). Always includes 2 decimal places.


---

**Section 6: EXTRACTION TOOLS (7 Tools)**

**Source:** Lib\Actions_Extraction.ahk

## Tool 55: Extract All Email Addresses

**Intent:** User receives messy text (meeting notes, web pages, contact lists)
and wants to pull out all unique email addresses as a clean list.

**Input:** Selected text or pasted into InputBox

**Output:** Deduplicated newline-separated email list, copied to clipboard

**Design Decision:** Case-insensitive deduplication (user@domain.com and
User@Domain.com are treated as the same). Explorer windows are excluded
from text insertion to prevent accidental file renaming.

## Tool 56: Extract All URLs & Web Links

**Intent:** Pull all hyperlinks from messy text. Captures http://, https://,
and www. prefixed URLs. Strips trailing punctuation (.;:!?) that isn't
part of the URL.

**Design Decision:** Does not extract bare domain names without www. prefix.
This is intentional to avoid false positives.

## Tool 57: Extract Phone & Mobile Numbers

**Intent:** Pull Indian mobile numbers (starting with 6-9, optional +91) and
STD landline numbers from messy text.

**Design Decision:** Focused on INDIAN phone number formats. International
formats (US, UK) are not targeted. STD landline pattern matches
3-5 digit area code + 6-8 digit number.

## Tool 58: Extract Indian GSTINs

**Intent:** Pull 15-character GST Identification Numbers from invoices,
contracts, and compliance documents.

**Design Decision:** Regex follows the standard GSTIN structure:
2 digits + 5 letters + 4 digits + 1 letter + 1 alphanumeric + Z + 1 alphanumeric.
Results are uppercased.

## Tool 59: Extract Indian PAN Numbers

**Intent:** Pull 10-character PAN (Permanent Account Number) from text.
**Pattern:** 5 letters + 4 digits + 1 letter.

**Design Decision:** May match non-PAN strings that happen to follow the same
pattern. This is an acceptable false-positive trade-off for a quick
extraction tool.

## Tool 60: Extract All Dates from Text

**Intent:** Pull all date occurrences from contracts, emails, and documents.
Supports ISO (yyyy-MM-dd), European (dd/MM/yyyy), named month formats,
and validates against the Gregorian calendar.

**Output:** List of dates, invalid ones tagged with " [INVAL]"

**Design Decision:** Valid dates are NOT tagged with [VALID] — only invalid
dates get the [INVAL] suffix. This is intentional to keep output clean;
the absence of a tag means valid.

## Tool 61: Date Difference & Working Days

**Intent:** User wants to know how many calendar days and working days (Mon-Fri)
are between two dates. Used for project planning and deadline tracking.

**Output:** MsgBox showing total days, working days, and weeks+days breakdown

**Design Decision:** Uses MsgBox instead of HUD because the result is a
multi-line informational report. Does not account for public holidays —
this is intentional for a lightweight tool. Full holiday support would
require a locale-aware calendar database.


---

**Section 7: UTILITY TOOLS (12 Registrations)**

**Source:** Lib\Actions_Utility.ahk

## Tool 62: Export Diagnostic & Analytics Report

**Intent:** Power-user/developer tool to export full usage statistics, error
logs, system info, and zero-match search queries for debugging and
self-improvement.

**Output:** Text report saved to Desktop and opened in Notepad

## Tool 63: Copy Clean File Path (Forward Slashes)

**Intent:** Developer user wants file paths with forward slashes for Unix/WSL
commands, URLs, and cross-platform code.

**Input:** Explorer selection or clipboard path

**Output:** Path with \ → / conversion, copied to clipboard and typed

## Tool 64: Copy Clean File Path (Escaped Slashes)

**Intent:** Developer user wants escaped backslash paths for JSON strings,
Python raw strings, and code that requires \\ escaping.

**Output:** Path with \ → \\ conversion

## Tool 65: Prefix Selected File with Timestamp

**Intent:** User selects a file in Explorer and wants to prefix it with a
datestamp (YYMMDD_filename.ext) for version tracking and archival.

**Design Decision:** No confirmation dialog. This is intentional for speed —
the user can Ctrl+Z in Explorer to undo. The YYMMDD format matches the
compact timestamp tool for consistency.

## Tool 66: Google Search Selected Text

**Intent:** Quick web search shortcut — select any text and look it up on
Google without switching to browser and typing.

## Tool 67: Google Translate Selected Text

**Intent:** Quick translation shortcut — select text and open it in Google
Translate. Useful for multilingual office environments.

## Tool 68: Toggle Window Always-on-Top

**Intent:** Pin any window to stay on top of all others. Useful for reference
windows, calculators, and video calls during work.

**Design Decision:** Toggles the current window, not a specific window.
User is expected to focus the desired window before invoking.

## Tool 69: Toggle Window Transparency (75%)

**Intent:** Make the current window semi-transparent to see content behind it.
Toggles between 75% opacity and fully opaque.

**Design Decision:** Fixed 75% opacity (alpha 190) — no user-configurable
value for this simple toggle. X-Ray Layer Peek provides configurable
transparency for the more advanced use case.

## Tool 70: Open Today's Daily Scratchpad Notes

**Intent:** User wants a quick daily notepad file for jotting down notes,
meeting minutes, and quick thoughts. Creates a new file each day
(Scratchpad_YYYY_MM_DD.txt) and opens in Notepad.

**Trigger:** Command Palette / Leader Key chord "n"

**Design Decision:** Files are stored in the app's data directory, not on the
Desktop. One file per day provides natural organization.

## Tool 71: Empty Windows Recycle Bin

**Intent:** Quick cleanup utility. Empties recycle bin silently using
SHEmptyRecycleBin with all suppression flags.

**Design Decision:** No confirmation dialog — silent operation is intentional.
The user values speed and knows they can recover files from backup if needed.

## Tool 72: Quick Privacy Screen / Lock

**Intent:** Instantly lock the workstation for privacy when stepping away.
Calls Windows LockWorkStation API.

## Tool 73: Configure Civil Converter Defaults

**Intent:** Opens the CivilEngineeringDefaults.ini file in Notepad so the user
can customize material densities, rates, and other engineering defaults.

**Design Decision:** Registered in BOTH Utility and Civil categories for
discoverability. This duplicate is intentional.


---

**Section 8: WINDOW PEEK & X-RAY TOOLS (3 Tools)**

**Source:** Lib\Actions_WindowPeek.ahk + WindowPeekEngine.ahk

## Tool 74: Toggle Window Peek (CapsLock+Tab)

**Intent:** Enable/disable the Window Peek feature. When enabled, holding
CapsLock+Tab temporarily activates the window behind the current one
(like Alt+Tab but with instant preview and automatic restoration).

**Design Decision:** The palette action TOGGLES the feature on/off rather than
performing a peek. Actual peeking requires physical CapsLock+Tab hold.
This is intentional — palette clicks can't hold physical keys.

## Tool 75: X-Ray Layer Peek (Step-Down Transparency)

**Intent:** User wants to see through stacked windows by making them
progressively transparent. Hold CapsLock+Esc to ghost the top window,
then press Down/Up arrows to slice deeper/shallower through the stack.

**Design Decision:** Requires physical CapsLock hold. Palette invocation will
immediately end because the watchdog detects CapsLock is not held.
This is a physical-keyboard-only feature by design.

## Tool 76: Configure X-Ray Layer Transparency

**Intent:** User wants to customize how transparent X-Ray makes windows.
Accepts 5-90% opacity value (clamped for safety — below 5% makes windows
nearly invisible and unusable).


---

**Section 9: ACTION BOARD / TASK MANAGEMENT (4 Tools)**

**Source:** Lib\ActionBoardGui.ahk + TaskManager.ahk

## Tool 77: Open Action Board (Eisenhower Grid)

**Intent:** User wants a visual 4-quadrant Eisenhower Matrix for task management:
Q1 = Do First (Urgent+Important), Q2 = Schedule (Important, Not Urgent),
Q3 = Quick Win (Urgent, Not Important), Q4 = Backlog/Inbox.

**Trigger:** Win+T / Win+Shift+T

**Design Decision:** New tasks always land in Q4 (Inbox) and are triaged
through an automated pill-HUD classification workflow.

## Tool 78: Capture Selected Text as Task

**Intent:** User reads something in an email/document, selects the actionable
text, and wants to instantly capture it as a task. Double-tap Ctrl for
speed, or Ctrl+Shift+T.

**Design Decision:** Mouse drag selection > 30px with 30-100 chars shows a
toast suggesting double-Ctrl capture. This ambient detection is intentional.

## Tool 79: Export Tasks to CSV / Backup

**Intent:** User wants a manual backup snapshot of current tasks as a
timestamped CSV file in the Backups directory.

## Tool 80: Import Tasks from External CSV

**Intent:** User wants to import tasks from another CSV file (e.g. shared by
a colleague or from a previous installation). Deduplicates by description.

**Design Decision:** Import MERGES — never replaces existing tasks.


---

**Section 10: FIND & REPLACE (1 Tool)**

**Source:** Study_MarkdownHub v2.0\Lib\Actions_FindReplace.ahk

## Tool 81: Find & Replace in Selection

**Intent:** User selects a block of text and wants to perform find-and-replace
ONLY within that selection (not the whole document). This is a common
missing feature in many text editors.

**Trigger:** Ctrl+H / F12

**Input:** Selected text + Find/Replace strings via GUI modal

**Output:** Modified text pasted back into the document

**Design Decision:** Uses literal StrReplace (case-insensitive, no regex).
This is intentional — the user wants simple text replacement, not regex
complexity. Always replaces ALL occurrences in the selection.


---

**Section 11: CIVIL & CONSTRUCTION ENGINEERING (5 Tools)**

**Source:** Lib\Actions_CivilConvert.ahk + Civil* modules

## Tool 82: Civil & Construction Instant Converter

**Intent:** User (a civil engineer) wants a universal natural-language converter
that handles ALL engineering unit conversions in one place. Supports:
- Length, Area, Volume, Mass, Force, Pressure, Density, Flow, Angle
- Indian regional units: bigha, guntha, gaj, nali, katha, brass
- Hindi/Hinglish keywords: sariya, tircha, karna, guniya, fall
- Concrete grades (M20, M25 → psi)
- Compound expressions: "5000mm to ft", "10 bigha to sqm"

**Trigger:** Ctrl+Shift+U / Leader Key chord "u"

**Design Decision:** Non-destructive result HUD is shown for read-only
windows (PDF viewers, CAD). Editable windows get direct text insertion.

## Tool 83: Pythagoras & Plot Diagonal Calculator

**Intent:** On construction sites, the user needs to calculate hypotenuse/
diagonal for plot set-outs, column footings, and room diagonals. Includes
3-4-5 / Guniya right-angle match badge for on-site verification.

**Input:** Two leg dimensions or hypotenuse + one leg

**Output:** Hypotenuse/missing leg with feet-inch display and Guniya badge

**Design Decision:** Supports inverse solving (given hypotenuse, find leg).
Mixed units are NOT converted — both legs must be in the same unit.

## Tool 84: Construction Rate & Unit Price Converter

**Intent:** User needs to convert construction rates across units. E.g.
"₹50 lakh / bigha to per sqft" or "Rs 500 per sqft to sqm".
Supports cross-dimensional rate conversion with progressive parameter
prompts (e.g. thickness for area↔volume rate).

## Tool 85: Thumb Rule Cost & Material Estimator

**Intent:** Quick estimate for residential construction cost and material
quantities using Indian thumb rules. 3-tier verified approach:

**Tier 1:** Micro bottom-up schedule (concrete, steel, bricks, etc.)

**Tier 2:** Meso work-package rates (structure, finishing, MEP)

**Tier 3:** Macro benchmark rates (Basic/Standard/Premium per sqft)
If all 3 tiers converge within 5% variance → VERIFIED estimate.

**Design Decision:** Rates are calibrated for Indian residential construction
(2026 pricing). User can customize via CivilEngineeringDefaults.ini.

## Tool 86: Configure Civil Converter Defaults

(Duplicate of Tool 73 — registered in Civil category for discoverability)


---

**Section 12: HOTSTRINGS & TEXT EXPANSION (14 Triggers)**

**Source:** Study_MarkdownHub v2.0\Lib\Hotstrings_Prompts.ahk

- **Hotstring `gmd`:** → Markdown generation prompt (AI instruction)
- **Hotstring `fif`:** → "Follow instructions in file" prompt
- **Hotstring `srt1`:** → Technical transcription integration prompt
- **Hotstring `sqlbot`:** → SQL study notes generation prompt
- **Hotstring `inkpost1`:** → LinkedIn post synthesizer (image/articles)
- **Hotstring `inkpost`:** → Civil Engineering formula analogy LinkedIn post
- **Hotstring `sqlrev`:** → Rubric-based note verification prompt
- **Hotstring `lipsum`:** → 2 paragraphs of Lorem Ipsum dummy text
- **Hotstring `ldt`:** → Current long date + time (dddd, d MMMM yyyy Time: hh:mm tt)
- **Hotstring `tndate`:** → ISO datetime (yyyy-MM-dd HH:mm:ss)
- **Hotstring `egreet`:** → Time-aware greeting (Good morning/afternoon/evening)
- **Hotstring `inwords`:** → Convert clipboard number to Indian currency words
- **Hotstring `cbwrap`:** → Wrap clipboard text in double quotes
- **Hotstring `cblist`:** → Convert clipboard lines to numbered list

**Design Decision:** These are GLOBAL hotstrings available everywhere. AI
prompt hotstrings are used when composing queries in ChatGPT, Claude, etc.
The user types the abbreviation + space and the full text expands.


---

**Section 13: SNIPPET MANAGER (GUI-based)**

**Source:** Lib\SnippetManager.ahk + SnippetGui.ahk

**Intent:** User wants a visual manager for creating, editing, importing, and
exporting custom text replacement snippets. Snippets are stored in CSV
and dynamically registered as AHK hotstrings at runtime.

**Trigger:** Win+Esc (Snippet Manager GUI) / Ctrl+Shift+H (quick capture)

**Design Decision:** 4-tier health scoring system prevents data loss from
corrupted CSV files. Master backup preserves ALL snippet history including
disabled/superseded entries. External file watcher reloads changes made
in Notepad/Excel within 2 seconds.


---

**Section 14: TELEMETRY & DIAGNOSTICS**

**Source:** Lib\Telemetry.ahk

**Intent:** User wants to track their own productivity tool usage patterns:
which tools are used most, which applications they target, and which
palette searches return zero results (indicating missing features).

**Design Decision:** All telemetry is LOCAL — never transmitted anywhere.
Stored in INI files in %APPDATA%\OfficeProductivityHub. The export
report is designed for the user's own introspection and debugging.


---

**Section 15: GLOBAL INFRASTRUCTURE INTENTS**


**COMMAND PALETTE:** Double-tap Shift (JetBrains style) or Ctrl+Space.

**Intent:** Universal access point for ALL tools. Real-time fuzzy search.
Top 5 most-used tools shown when query is empty. Number keys 1-9 for
instant selection. Arrow keys for navigation. Dynamic height based on
result count. Transparency dimming when unfocused.

**LEADER KEY ENGINE:** Win+Shift+; or CapsLock (short tap <350ms).

**Intent:** Vim-style leader key for power users. Tap leader, then a single
character chord to execute a tool without opening the palette.

**Available chords:** t(timestamp), v(clean paste), s(snake_case),
x(checklist), c(calculator), p(password), w(indian words), n(scratchpad),
u(civil converter).

**CAPSLOCK BEHAVIOR:** CapsLock is permanently disabled (AlwaysOff).

**Intent:** User NEVER wants accidental ALL CAPS typing. CapsLock is
repurposed as a Hyper modifier key for Window Peek and leader chords.

**ESCAPE DISMISSAL:** Global Esc closes ALL open Office Hub UIs.

**Intent:** Single-key panic button to dismiss any floating HUD, palette,
snippet manager, action board, or civil converter dialog.

**REPEAT LAST ACTION:** Win+0 or Ctrl+0.

**Intent:** User wants to re-execute the most recently used tool without
re-searching the palette. Essential for repetitive tasks.
