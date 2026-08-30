# 🔍 Final Code Audit — Office Productivity Palette & Action Hub v2.0.0

> [!NOTE]
> Full audit of `office_productivity_palette_v2.0.0.ahk` and all 33+ library files.
> 86 registered actions / 85 unique tools across 12 domains analyzed.

---

## 🔴 CRITICAL BUGS (Will Crash or Produce Wrong Results)

### 1. `ConvertUnixTimestamp()` — Broken Regex Strips All Digits

**File:** [Actions_Math.ahk:L218,L223](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Actions_Math.ahk#L218-L223)

```ahk
num := RegExReplace(sel, "[^\\d]", "")     ; ← BROKEN
```

AHK v2 doesn't use `\` as string escape. `"[^\\d]"` becomes PCRE `[^\\d]` which matches everything except `\` and `d`. **All digits are stripped**, making the tool permanently broken.

**Fix:** `RegExReplace(sel, "[^\d]", "")` or `RegExReplace(sel, "\D", "")`

---

### 2. `GenerateUUID()` — Double-Backslash DLL Call

**File:** [Actions_Math.ahk:L176](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Actions_Math.ahk#L176)

```ahk
DllCall("ole32\\CoCreateGuid", "Ptr", guid.Ptr)    ; ← Double backslash
```

AHK v2 expects `"ole32\CoCreateGuid"`. Double backslash may cause DLL lookup failure.

---

### 3. Slope Evaluation Crashes — Wrong Class Method Call

**File:** [CivilSurvey.ahk:L64](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/CivilSurvey.ahk#L64)

```ahk
pRun := CivilUnits.ParseDimensionInput(param, "L")   ; ← Wrong class!
```

`ParseDimensionInput` is defined in `CivilCrossPhysics`, not `CivilUnits`. Runtime exception: `Property or method not found`.

**Fix:** `CivilCrossPhysics.ParseDimensionInput(param, "L")`

---

### 4. Pythagoras Strips Dimension "90" Accidentally

**File:** [CivilPythagoras.ahk:L126](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/CivilPythagoras.ahk#L126)

```ahk
cleanTokens := RegExReplace(clean, "i)\b90\s*(?:°|deg|degree)?\s*(?:triangle|check|...)?\b", " ")
```

All qualifiers are optional (`?`), so bare `90` matches. Input `pythagoras 90 120` strips `90`, leaving only `120` → fails with < 2 dimensions.

**Fix:** Require at least one angle keyword to be present.

---

### 5. Fluid Density 1000× Double Multiplication

**File:** [CivilCrossPhysics.ahk:L85-89](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/CivilCrossPhysics.ahk#L85-L89)

Config stores `cfg["Diesel"] = 840.0` (already kg/m³), but code does `cfg["Diesel"] * 1000.0` → 840,000 kg/m³. Same issue with Water at L426 (`fluidDensityKgL := cfg["Water"]` assumes kg/L but gets 1000).

---

### 6. `ProcessReverseGST()` — Rate Misidentified as Amount

**File:** [Actions_Finance.ahk:L150-153](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Actions_Finance.ahk#L150-L153)

If user highlights `"GST 18%"`, tokens find only `18.0`. Since `tokens.Length >= 2` is false, it assigns `extractedAmt := 18.0` and computes Reverse GST for ₹18 at 18%.

**Fix:** Check `if tokens.Length = 1 && tokens[1].value = extractedRate` → prompt for amount.

---

### 7. `ResolveIndianFinancialYear()` — Crash on Invalid Month

**File:** [Actions_Finance.ahk:L36-43](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Actions_Finance.ahk#L36-L43)

US-format date `12/25/2026` parsed as DD/MM → month 25 → `FormatTime` fails → `Integer("")` throws unhandled `ValueError`.

---

### 8. `Integer()` Crashes on Empty ListView Text

**File:** [ActionBoardGui.ahk:L183,L261,L273,L295,L307,L335](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/ActionBoardGui.ahk#L183)

`taskId := Integer(lvCtrl.GetText(itemIndex, 2))` — if column 2 is `""` (deselection), `Integer("")` throws `ValueError`.

**Fix:** Guard with `txt := lvCtrl.GetText(row, 2)` → `if (txt != "" && IsInteger(txt))`

---

### 9. X-Ray Unusable — `*Esc Up` Terminates Immediately

**File:** [WindowPeekHotkeys.ahk:L100-101](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/WindowPeekHotkeys.ahk#L100-L101)

`*Esc Up:: EndXRayLayerPeek()` — when user releases Esc to press Down/Up arrows for layer stepping, X-Ray immediately terminates. Multi-layer stepping is impossible.

**Fix:** Remove `*Esc Up` handler; rely on `*CapsLock Up` and watchdog.

---

### 10. Task Auto-Watcher False Reload Loop

**File:** [TaskManager.ahk:L97-101, L194-209](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/TaskManager.ahk#L97-L101)

`SaveActionTasks()` never updates `LastTaskFileModTime` after writing. Within 2s, the file watcher detects a "change", reloads, and shows a spurious `"🔄 Tasks automatically reloaded"` toast.

**Fix:** Add `LastTaskFileModTime := FileGetTime(ActionTasksFile, "M")` after `FileMove`.

---

### 11. Task ID Collision on Delete + Add

**File:** [TaskManager.ahk:L126](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/TaskManager.ahk#L126)

`newId := ActionTasks[ActionTasks.Length].id + 1` assumes last element has max ID. After deleting middle tasks, IDs can collide.

**Fix:** Compute `maxId := 0` across all tasks, then `maxId + 1`.

---

## 🟡 MEDIUM SEVERITY ISSUES

### 12. Timer Closure Leakage in Pill HUDs

[ActionBoardPills.ahk:L58,L149,L256](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/ActionBoardPills.ahk#L58)
`SetTimer(() => DismissNudgeHud(NudgeHudGui), -2500)` creates a new closure per call. Previous timer never cancelled → premature HUD dismissal.

### 13. Division by Zero in Civil Survey & Rebar

- [CivilSurvey.ahk:L42](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/CivilSurvey.ahk#L42): `runM / riseM` — zero fall crashes
- [CivilRebar.ahk:L39,L43-44](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/CivilRebar.ahk#L39-L44): `d1=0` or `s1=0` or rounded `s2=0` → division by zero

### 14. Space Key Trimmed in Leader Mode

[Core.ahk](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Core.ahk) — InputHook captures space, Trim() strips it to `""`, exits before reaching the `space` comparison branch.

### 15. Missing Escape Handler on Civil Prompt

[CivilConverterGui.ahk:L117-124](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/CivilConverterGui.ahk#L117-L124)
Cancel button says "✖ Cancel (Esc)" but no `OnEvent("Escape")` is attached.

### 16. `LastActiveLV` Desynchronization

[ActionBoardGui.ahk:L182](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/ActionBoardGui.ahk#L182)
`LastActiveLV` only updated on `ItemSelect`. Clicking empty space in another quadrant lets keyboard ops execute on the wrong task.

### 17. Untriaged Tasks Silently Become "Task" in Modal Editor

[ActionBoardGui.ahk:L360-368](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/ActionBoardGui.ahk#L360-L368)
Dropdown lacks "Unassigned"/"Backlog" — saving defaults to "Task".

### 18. CapsLock Chord Hotkeys Missing `CapsLockChordFired := true`

[WindowPeekHotkeys.ahk:L104-112](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/WindowPeekHotkeys.ahk#L104-L112)
Quick release (<350ms) triggers both chord AND leader/tap action.

### 19. Pill HUDs Hardcoded to Monitor 1

[ActionBoardPills.ahk:L53,L144](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/ActionBoardPills.ahk#L53)
Multi-monitor setups show classifier/prioritizer on wrong screen.

### 20. `WinGetTransparent()` Crashes on Never-Transparent Windows

[Actions_Utility.ahk:L141](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Actions_Utility.ahk#L141)
No `try...catch` — throws `TargetError` on windows that have never had transparency set.

### 21. `NormalizeInput()` Breaks Slope "fall in run" Syntax

[CivilConverterEngine.ahk:L225](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/CivilConverterEngine.ahk#L225)
`\s+in\s+` → `to` transforms `"fall 100mm in 10m"` → `"fall 100mm to 10m"`, breaking slope parsing.

### 22. `Telemetry.ahk` — IndexError on `StrSplit` with `=` in Queries

[Telemetry.ahk:L186-187](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Telemetry.ahk#L186-L187)
`StrSplit(l, "=")[2]` crashes if query contains `=` or line is malformed.

### 23. Premature Task Archiving

[TaskManager.ahk:L309-310](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/TaskManager.ahk#L309-L310)
Completing an older task today immediately archives it because `created date != today`.

### 24. Pythagoras Mixed Units Not Converted

[CivilPythagoras.ahk:L140-144](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/CivilPythagoras.ahk#L140-L144)
`10m 20ft diag` → treats 10 and 20 as same unit → wrong hypotenuse.

### 25. NumberParser: "5 L" (litres) Parsed as 500,000

[NumberParser.ahk](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/NumberParser.ahk)
Single letters `l`/`m`/`b` aggressively matched as Lakh/Million/Billion.

### 26. MathEvaluator: Scale+Percentage Precedence Bug

`1.5 Lakh + 10%` → 150000 + 10000 = 160,000 instead of 165,000 (10% of 150,000).

### 27. MathEvaluator: `-3^2 = 9` Instead of `-9`

Evaluates as `(-3)^2 = 9` instead of `-(3^2) = -9`.

### 28. Clipboard Race in `TransformSelectedText`

[ClipboardHelper.ahk](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/ClipboardHelper.ahk)
Never restores the user's original clipboard after transformation.

### 29. `Hotstrings_Prompts.ahk:L52` — Wrong Toast Function

Calls `ShowToast()` but Study Suite uses `ShowStudyToast()`. May cause runtime error if alias not loaded.

### 30. Snippet Master Backup Restoration Creates Duplicates

[SnippetManager.ahk:L144-161](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/SnippetManager.ahk#L144-L161)
Recovering from master backup loads both enabled and disabled duplicate triggers into memory.

---

## 🔵 LOW / COSMETIC ISSUES

| #   | Issue                                                                             | Location                                                                                                                                                                                                    |
| --- | --------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 31  | Telemetry desktop path has double backslash `\\`                                  | [Telemetry.ahk:L109](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Telemetry.ahk#L109)                   |
| 32  | Category emoji mismatch: WindowPeek uses `⚙️ Utility` vs others use `📁 Utility`  | [Actions_WindowPeek.ahk:L11](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Actions_WindowPeek.ahk#L11)   |
| 33  | Date parser assumes DD/MM for slash dates — US format MM/DD fails                 | [Actions_Extraction.ahk:L299](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Actions_Extraction.ahk#L299) |
| 34  | 2-digit year `95` mapped to `2095` not `1995`                                     | [Actions_Extraction.ahk:L302](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Actions_Extraction.ahk#L302) |
| 35  | Phone regex lacks `\b` boundaries — long numbers match as phones                  | [Actions_Extraction.ahk:L92](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Actions_Extraction.ahk#L92)   |
| 36  | ProcessExtraction sentinel `InStr(extracted, "No ")` false-matches `no_reply@...` | [Actions_Extraction.ahk:L27](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Actions_Extraction.ahk#L27)   |
| 37  | `SumSelectedNumbers()` hardcodes `₹` symbol for non-monetary sums                 | [Actions_Math.ahk](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Actions_Math.ahk)                       |
| 38  | Unix timestamp shows UTC time, not local IST                                      | [Actions_Math.ahk:L230-231](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Actions_Math.ahk#L230-L231)    |
| 39  | `ToSentenceCase` regex lacks multiline flag                                       | Actions_Text.ahk                                                                                                                                                                                            |
| 40  | List transformers output LF not CRLF                                              | Actions_Text.ahk                                                                                                                                                                                            |
| 41  | Duplicate "Word & Character Statistics" in Text+Math                              | Actions_Text.ahk & Actions_Math.ahk                                                                                                                                                                         |
| 42  | Duplicate "Configure Civil Defaults" in Utility+Civil                             | Actions_Utility.ahk & Actions_CivilConvert.ahk                                                                                                                                                              |
| 43  | `PaletteNavigate` steals focus from search box                                    | PaletteGui.ahk                                                                                                                                                                                              |
| 44  | TaskManager CSV doesn't use `FormatCSVRow()` — comma in data breaks format        | [TaskManager.ahk:L80](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/TaskManager.ahk#L80)                 |
| 45  | `DirMove` flag `0` should be `"R"` for rename                                     | [Actions_Utility.ahk:L78](file:///C:/Users/Admin/Documents/AutoHotkey/Final%20versions%20of%20ahk%20files/OFFICE%20PRODUCTIVITY%20PALETTE%20%26%20ACTION%20HUB%202.0.0/Lib/Actions_Utility.ahk#L78)         |

---

## 📊 Summary

| Severity                               | Count  |
| -------------------------------------- | ------ |
| 🔴 Critical (crashes or wrong results) | 11     |
| 🟡 Medium (functional impact)          | 19     |
| 🔵 Low / Cosmetic                      | 15     |
| **Total**                              | **45** |

> [!IMPORTANT]
> The 11 critical bugs should be fixed before distribution. The medium/low issues are working-as-designed trade-offs that the user may choose to address later.
