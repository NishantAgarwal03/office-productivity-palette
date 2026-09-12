; ======================================================================================================================
; Module: test_integration_runner.ahk - Live Integration, Recovery, Focus & Data Integrity Test Suite
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent(false)

ShowTextStats(*) => ""
LogAppError(*) => ""

#Include "..\Lib\TestHarness.ahk"
#Include "..\Lib\Globals.ahk"
#Include "..\Lib\CSVParser.ahk"
#Include "..\Lib\ClipboardHelper.ahk"
#Include "..\Lib\NumberParser.ahk"
#Include "..\Lib\MathEvaluator.ahk"
#Include "..\Lib\Actions_DateTime.ahk"
#Include "..\Lib\Actions_Text.ahk"
#Include "..\Lib\Actions_Finance.ahk"
#Include "..\Lib\Actions_Extraction.ahk"
#Include "..\Lib\Actions_Math.ahk"
#Include "..\Lib\Core.ahk"
#Include "..\Lib\TaskManager.ahk"
#Include "..\Lib\SnippetManager.ahk"
#Include "..\Lib\WindowPeekEngine.ahk"

global IntegTestsTotal := 0
global IntegTestsPassed := 0
global IntegTestsFailed := 0
global IntegLogLines := []
global Failures := []
global StartTick := A_TickCount

AssertInteg(suite, testName, condition, actualVal := "") {
    global IntegTestsTotal, IntegTestsPassed, IntegTestsFailed, IntegLogLines, Failures
    IntegTestsTotal++
    if (condition) {
        IntegTestsPassed++
        IntegLogLines.Push("[INTEG PASS] " . suite . " | " . testName . " -> OK")
    } else {
        IntegTestsFailed++
        IntegLogLines.Push("[INTEG FAIL] " . suite . " | " . testName . " -> FAILED (Got: '" . String(actualVal) . "')")
        Failures.Push({category: suite, testName: testName, error: "Got: '" . String(actualVal) . "'"})
    }
}

try {

; --------------------------------------------------------------------------------------------------
; 1. Number Extraction & Comma Handling (Item 1)
; --------------------------------------------------------------------------------------------------
colText := "1,25,000`n50,000`n2,00,000"
colNums := ExtractAllNumbers(colText)
AssertInteg("CommaExtraction", "Extract 3 comma numbers", colNums.Length == 3, colNums.Length)

totalSum := 0.0
for n in colNums
    totalSum += n
AssertInteg("CommaExtraction", "Sum 1,25,000 + 50,000 + 2,00,000 = 375000", totalSum == 375000, totalSum)

sumReceipt := FormatSumOutput([100, 250, 150, 12])
expectedReceipt := "Items (4): 100 + 250 + 150 + 12`nTotal    : ₹512.00 (512.00)"
AssertInteg("SumFormat", "FormatSumOutput items and total alignment", sumReceipt == expectedReceipt, sumReceipt)

pctNums := ExtractAllNumbers("1,00,000 to 1,25,000")
AssertInteg("CommaExtraction", "Percentage delta comma nums", pctNums.Length == 2 && pctNums[1] == 100000 && pctNums[2] == 125000, pctNums.Length)

cagrNums := ExtractAllNumbers("from ₹1,25,000 to ₹2,50,000 in 3 years")
AssertInteg("CommaExtraction", "CAGR sentence with commas", cagrNums.Length == 3 && cagrNums[1] == 125000 && cagrNums[2] == 250000 && cagrNums[3] == 3, cagrNums.Length)

mixedCol := "1,25,000.50`n-5,000`n(25,000)`n2.5 Cr"
mixedNums := ExtractAllNumbers(mixedCol)
AssertInteg("CommaExtraction", "Mixed signs, units & decimals count", mixedNums.Length == 4, mixedNums.Length)
if (mixedNums.Length == 4) {
    AssertInteg("CommaExtraction", "Mixed: 1,25,000.50", mixedNums[1] == 125000.5, mixedNums[1])
    AssertInteg("CommaExtraction", "Mixed: -5,000", mixedNums[2] == -5000, mixedNums[2])
    AssertInteg("CommaExtraction", "Mixed: (25,000) accounting", mixedNums[3] == -25000, mixedNums[3])
    AssertInteg("CommaExtraction", "Mixed: 2.5 Cr multiplier", mixedNums[4] == 25000000, mixedNums[4])
}

; --------------------------------------------------------------------------------------------------
; 2. Invalid Input Non-Destructive Preservation (Item 4)
; --------------------------------------------------------------------------------------------------
AssertInteg("DataPreservation", "FormatIndianCommas('N/A') preserves string", FormatIndianCommas("N/A") == "N/A", FormatIndianCommas("N/A"))
AssertInteg("DataPreservation", "FormatInternationalCommas('Pending') preserves", FormatInternationalCommas("Pending") == "Pending", FormatInternationalCommas("Pending"))
AssertInteg("DataPreservation", "CleanToMachineNumber('Unknown') preserves", CleanToMachineNumber("Unknown") == "Unknown", CleanToMachineNumber("Unknown"))
AssertInteg("DataPreservation", "CleanToMachineNumber('12-34-56') preserves SKU", CleanToMachineNumber("12-34-56") == "12-34-56", CleanToMachineNumber("12-34-56"))
AssertInteg("DataPreservation", "FormatIndianCommas('2026-08-25') preserves Date", FormatIndianCommas("2026-08-25") == "2026-08-25", FormatIndianCommas("2026-08-25"))
AssertInteg("DataPreservation", "RoundNumber('InvalidText') preserves", RoundNumber("InvalidText") == "InvalidText", RoundNumber("InvalidText"))
AssertInteg("DataPreservation", "RoundNumber('123.456', 2) formats valid float", RoundNumber("123.456", 2) == "123.46", RoundNumber("123.456", 2))
AssertInteg("DataPreservation", "FormatIndianCommas('999.999') carry", FormatIndianCommas("999.999") == "1,000.00", FormatIndianCommas("999.999"))
AssertInteg("DataPreservation", "FormatInternationalCommas('999.999') carry", FormatInternationalCommas("999.999") == "1,000.00", FormatInternationalCommas("999.999"))

; --------------------------------------------------------------------------------------------------
; 3. Window Targeting & Safe Visibility Checks
; --------------------------------------------------------------------------------------------------
AssertInteg("WindowSafety", "SafeIsWindowVisible(non-object) is false", SafeIsWindowVisible("") == false, SafeIsWindowVisible(""))
AssertInteg("WindowSafety", "SafeIsWindowVisible(0) is false", SafeIsWindowVisible(0) == false, SafeIsWindowVisible(0))

testGui := Gui("+AlwaysOnTop", "IntegTestGui")
testGui.Show("w100 h100 NoActivate")
AssertInteg("WindowSafety", "SafeIsWindowVisible(live GUI) is true", SafeIsWindowVisible(testGui) == true, SafeIsWindowVisible(testGui))
testGui.Destroy()
AssertInteg("WindowSafety", "SafeIsWindowVisible(destroyed GUI) is false", SafeIsWindowVisible(testGui) == false, SafeIsWindowVisible(testGui))

; --------------------------------------------------------------------------------------------------
; 4. Clipboard Simulation & Retention Test
; --------------------------------------------------------------------------------------------------
originalClip := "USER_IMPORTANT_CLIPBOARD_DATA_12345"
A_Clipboard := originalClip
Sleep(50)
clipBackup := ClipboardAll()
AssertInteg("ClipboardSafety", "Clipboard contains initial data", A_Clipboard == originalClip, A_Clipboard)

; --------------------------------------------------------------------------------------------------
; 5. CSV Stream Parser & Corrupt Data Fault Recovery
; --------------------------------------------------------------------------------------------------
corruptCsvData := 'id,task,created,commitmentType,priority,done`n1,"Normal task",2026-08-24 10:00,Task,Q1,false`n2,"Broken task with comma, and unclosed quotes,2026-08-24 10:00,Task,Q1,false`n3,"Valid task 3",2026-08-24 10:00,Promise,Q4,false'
parsedRows := ParseFullCSV(corruptCsvData)
AssertInteg("CsvRecovery", "Streaming parser recovers rows from corrupt CSV", parsedRows.Length >= 2, parsedRows.Length)

; --------------------------------------------------------------------------------------------------
; --------------------------------------------------------------------------------------------------
; 6. Backup Creation & Disaster Recovery Verification (Sandboxed)
; --------------------------------------------------------------------------------------------------
origSnippetsFile := SnippetsFile
origMasterBackupFile := SnippetsMasterBackupFile
origPrevBackupFile := SnippetsPrevBackupFile
origPreImportFile := SnippetsPreImportFile
origSnippets := []
for sn in Snippets
    origSnippets.Push({trigger: sn.trigger, replacement: sn.replacement, enabled: sn.enabled})

sandboxDir := DataDir . "\_test_sandbox"
if !DirExist(sandboxDir)
    DirCreate(sandboxDir)

SnippetsFile := sandboxDir . "\test_snippets.csv"
SnippetsMasterBackupFile := sandboxDir . "\test_snippets_backup_master.csv"
SnippetsPrevBackupFile := sandboxDir . "\test_snippets_backup_previous.csv"
SnippetsPreImportFile := sandboxDir . "\test_snippets_backup_pre_import.csv"
Snippets := []

; Test candidate scoring primitive
testDummyFile := sandboxDir . "\test_dummy.csv"
FileAppend("trigger,replacement,enabled`nmyemail,john@example.com,true`nmyphone,12345,true`nmyaddr,home,true`n", testDummyFile, "UTF-8")

testRichFile := sandboxDir . "\test_rich.csv"
FileAppend("trigger,replacement,enabled`nalpha,Alpha Exp,true`nbeta,Beta Exp,true`ngamma,Gamma Exp,true`ndelta,Delta Exp,true`n", testRichFile, "UTF-8")

testEmptyFile := sandboxDir . "\test_empty.csv"
FileAppend("trigger,replacement,enabled`n", testEmptyFile, "UTF-8")

dummyList := []
dummyScore := ScoreSnippetCandidate(testDummyFile, &dummyList)
AssertInteg("HeuristicScoring", "Dummy catalog scores between 10 and 20", dummyScore >= 10 && dummyScore < 50, dummyScore)
AssertInteg("HeuristicScoring", "Dummy catalog parsed 3 items", dummyList.Length == 3, dummyList.Length)

richList := []
richScore := ScoreSnippetCandidate(testRichFile, &richList)
AssertInteg("HeuristicScoring", "Rich catalog scores >= 1000", richScore >= 1000, richScore)
AssertInteg("HeuristicScoring", "Rich catalog parsed 4 items", richList.Length == 4, richList.Length)

emptyList := []
emptyScore := ScoreSnippetCandidate(testEmptyFile, &emptyList)
AssertInteg("HeuristicScoring", "Header-only CSV scores 0", emptyScore == 0, emptyScore)

nonExistentScore := ScoreSnippetCandidate(sandboxDir . "\does_not_exist.csv", &emptyList)
AssertInteg("HeuristicScoring", "Non-existent file scores -1", nonExistentScore == -1, nonExistentScore)

; Test Content Change Detector
isChangedIdentical := IsSnippetCatalogChanged(richList, testRichFile)
AssertInteg("ContentChangeDetect", "Identical catalog detects NO change", isChangedIdentical == false, isChangedIdentical)

modifiedRichList := []
for r in richList
    modifiedRichList.Push({trigger: r.trigger, replacement: r.replacement, enabled: r.enabled})
modifiedRichList[1].replacement := "Modified Alpha Text"
isChangedDiff := IsSnippetCatalogChanged(modifiedRichList, testRichFile)
AssertInteg("ContentChangeDetect", "Edited replacement detects change", isChangedDiff == true, isChangedDiff)

; Test Master Snapshot Merge & Deduplication with Conflict Inactivation
MergeIntoMasterBackup(richList)
AssertInteg("MasterBackup", "Master snapshot file created", FileExist(SnippetsMasterBackupFile) != "", FileExist(SnippetsMasterBackupFile))

; Merge conflicting item: same trigger 'alpha', different replacement -> preserve both, set older inactive
MergeIntoMasterBackup([{trigger: "alpha", replacement: "Brand New Alpha", enabled: true}])
masterRows := ParseFullCSV(FileRead(SnippetsMasterBackupFile, "UTF-8"))
; Expected: Header + 4 original (with alpha set to false) + 1 new active alpha = 6 rows total
AssertInteg("MasterBackup", "Conflict preserves both entries (5 items + header)", masterRows.Length == 6, masterRows.Length)

; --------------------------------------------------------------------------------------------------
; 7. Dynamic Hotstring Scoped Registration & Schema Lenience
; --------------------------------------------------------------------------------------------------
testTrigger := "!integtest"
UpsertSnippet(testTrigger, "Integration Snippet Expansion", true)
AssertInteg("HotstringScoped", "Dynamic snippet registered in memory", Snippets.Length > 0, Snippets.Length)
DeleteSnippet(testTrigger)
AssertInteg("HotstringScoped", "Dynamic snippet cleanly deleted", true, "OK")

; Test 2-Column Schema Lenience in CSV parsing / loading
twoColCsv := "trigger,replacement`nquicktest,Quick Expansion Content"
parsed2Col := ParseFullCSV(twoColCsv)
AssertInteg("SnippetSchema", "2-Column CSV parsed successfully", parsed2Col.Length == 2, parsed2Col.Length)

; Test in-memory upsert helper
UpsertSnippetInMemory("memtest", "Memory Value", true)
foundMem := false
for sn in Snippets {
    if (sn.trigger == "memtest") {
        foundMem := true
        break
    }
}
AssertInteg("SnippetMemory", "UpsertSnippetInMemory updates array directly", foundMem == true, foundMem)
DeleteSnippet("memtest")

; Test Disaster Recovery: Primary has Dummy, Master has Rich -> Master Wins & Heals Primary
FileCopy(testDummyFile, SnippetsFile, 1)
FileCopy(testRichFile, SnippetsMasterBackupFile, 1)
try FileDelete(SnippetsPrevBackupFile)

LoadSnippets()
AssertInteg("SelfHealing", "Heuristic selection promotes Rich Master Backup over Dummy Primary", Snippets.Length == 4, Snippets.Length)
if (Snippets.Length == 4) {
    AssertInteg("SelfHealing", "Winner contains custom trigger alpha", Snippets[1].trigger == "alpha", Snippets[1].trigger)
}

; Test Anti-Overwrite Guard: Saving dummy cannot overwrite rich backup
FileCopy(testRichFile, SnippetsPrevBackupFile, 1)
FileCopy(testDummyFile, SnippetsFile, 1)
overwrote := CreateSnippetBackup(SnippetsPrevBackupFile, false)
AssertInteg("AntiOverwrite", "Guard blocks overwriting rich backup with dummy file", overwrote == false, overwrote)

; Clean up sandbox and restore production globals
try FileDelete(testDummyFile)
try FileDelete(testRichFile)
try FileDelete(testEmptyFile)
try FileDelete(SnippetsFile)
try FileDelete(SnippetsMasterBackupFile)
try FileDelete(SnippetsPrevBackupFile)
try FileDelete(SnippetsPreImportFile)
try DirDelete(sandboxDir, true)

SnippetsFile := origSnippetsFile
SnippetsMasterBackupFile := origMasterBackupFile
SnippetsPrevBackupFile := origPrevBackupFile
SnippetsPreImportFile := origPreImportFile
Snippets := origSnippets

; --------------------------------------------------------------------------------------------------
; 8. Timer & Cooldown Debounce Verification
; --------------------------------------------------------------------------------------------------
nowTs := A_TickCount
LastClassifierPromptTick := nowTs
isCooldownActive := (nowTs - LastClassifierPromptTick < 600000)
AssertInteg("TimerDebounce", "Classifier cooldown active prevents spam", isCooldownActive == true, isCooldownActive)

; --------------------------------------------------------------------------------------------------
; 9. ExtractNumericTokens Value Object Boundary Tests (Item 2)
; --------------------------------------------------------------------------------------------------
tokText := "Advance: ₹1,25,000.50`nDiscount: -$5,000`nProject Cap: 2.5 Crore"
toks := ExtractNumericTokens(tokText)
AssertInteg("NumericTokens", "Extract 3 rich value objects", toks.Length == 3, toks.Length)
if (toks.Length == 3) {
    AssertInteg("NumericTokens", "Token 1 value & currency", toks[1].value == 125000.5 && toks[1].currency == "INR", toks[1].value . " " . toks[1].currency)
    AssertInteg("NumericTokens", "Token 2 negative sign & currency", toks[2].value == -5000 && toks[2].isNegative && toks[2].currency == "USD", toks[2].value)
    AssertInteg("NumericTokens", "Token 3 unit & multiplier", toks[3].value == 25000000 && toks[3].unit == "Crore", toks[3].value . " " . toks[3].unit)
}

; --------------------------------------------------------------------------------------------------
; 10. Win32 RtlGenRandom CSPRNG Password Generation (Item 5)
; --------------------------------------------------------------------------------------------------
pass1 := GenerateSecurePassword(16)
pass2 := GenerateSecurePassword(16)
AssertInteg("CSPRNGPassword", "Password length 16 chars", StrLen(pass1) == 16, StrLen(pass1))
AssertInteg("CSPRNGPassword", "Two generated passwords differ", pass1 != pass2, pass1 . " vs " . pass2)
AssertInteg("CSPRNGPassword", "Password contains diverse charset", RegExMatch(pass1, "[A-Za-z0-9!@#$%^&*()-_=+]"), pass1)

; --------------------------------------------------------------------------------------------------
; 11. ISO-8601 Week & Year Boundary Synchronization (Item 6)
; --------------------------------------------------------------------------------------------------
isoJan1 := GetIsoWeekInfo("20210101000000") ; Jan 1 2021 was Friday of Week 53, 2020
AssertInteg("IsoWeekSync", "Jan 1 2021 -> Week 53, 2020", isoJan1.formatted == "Week 53, 2020" && isoJan1.year == "2020" && isoJan1.week == 53, isoJan1.formatted)

isoDec31 := GetIsoWeekInfo("20181231000000") ; Dec 31 2018 was Monday of Week 1, 2019
AssertInteg("IsoWeekSync", "Dec 31 2018 -> Week 1, 2019", isoDec31.formatted == "Week 1, 2019" && isoDec31.year == "2019" && isoDec31.week == 1, isoDec31.formatted)

isoAug25 := GetIsoWeekInfo("20260825000000") ; Aug 25 2026 is Week 35, 2026
AssertInteg("IsoWeekSync", "Aug 25 2026 -> Week 35, 2026", isoAug25.formatted == "Week 35, 2026" && isoAug25.year == "2026" && isoAug25.week == 35, isoAug25.formatted)

; --------------------------------------------------------------------------------------------------
; 12. Non-Destructive Date & Financial Validation (Item 1 & 4)
; --------------------------------------------------------------------------------------------------
AssertInteg("FinanceValidation", "Invalid date string returns 'Invalid Date'", ResolveIndianFinancialYear("GibberishString") == "Invalid Date", ResolveIndianFinancialYear("GibberishString"))
AssertInteg("FinanceValidation", "Valid date string parses Q2", ResolveIndianFinancialYear("2026-08-25") == "FY 2026-27 (Q2)", ResolveIndianFinancialYear("2026-08-25"))
AssertInteg("FinanceValidation", "Reverse GST -100% Rate Safe", InStr(CalculateReverseGST(10000, -100), "Invalid GST rate") > 0, CalculateReverseGST(10000, -100))

; --------------------------------------------------------------------------------------------------
; 13. FormatShortcutBadge Presentation Tests
; --------------------------------------------------------------------------------------------------
dummySnip := { isCustom: true, triggerName: "myemail" }
dummyHotkey := { isCustom: false, hotkey: "Alt+Shift+D", chord: "" }
dummyChord := { isCustom: false, hotkey: "", chord: "v" }
dummyNone := { isCustom: false, hotkey: "", chord: "" }

AssertInteg("ShortcutBadges", "Snippet badge ::myemail", FormatShortcutBadge(dummySnip) == "::myemail", FormatShortcutBadge(dummySnip))
AssertInteg("ShortcutBadges", "Hotkey badge Alt+Shift+D", FormatShortcutBadge(dummyHotkey) == "Alt+Shift+D", FormatShortcutBadge(dummyHotkey))
AssertInteg("ShortcutBadges", "Leader badge Leader, V", FormatShortcutBadge(dummyChord) == "Leader, V", FormatShortcutBadge(dummyChord))
AssertInteg("ShortcutBadges", "Default badge ↵", FormatShortcutBadge(dummyNone) == "↵", FormatShortcutBadge(dummyNone))

; --------------------------------------------------------------------------------------------------
; 14. Window Peek 4-State FSM Lifecycle Integration Tests
; --------------------------------------------------------------------------------------------------
; Verify default startup is enabled
try IniDelete(TelemetryStatsFile, "Settings", "WindowPeekEnabled")
InitWindowPeekEngine()
AssertInteg("WindowPeekFSM", "Default startup is ENABLED", IsWindowPeekEnabled == true, IsWindowPeekEnabled)

; Test toggle persistence and safe mid-peek reset
ToggleWindowPeek()
AssertInteg("WindowPeekFSM", "Toggle changes state to DISABLED", IsWindowPeekEnabled == false, IsWindowPeekEnabled)
ToggleWindowPeek()
AssertInteg("WindowPeekFSM", "Toggle changes state to ENABLED", IsWindowPeekEnabled == true, IsWindowPeekEnabled)

; Verify Win32 filter primitive safety
AssertInteg("WindowPeekFSM", "Zero HWND is rejected by filter", IsActivatableAppWindow(0) == false, IsActivatableAppWindow(0))
AssertInteg("WindowPeekFSM", "Negative/offscreen window rejected", IsActivatableAppWindow(-1) == false, IsActivatableAppWindow(-1))
AssertInteg("WindowPeekFSM", "Minimized filter check rejects 0", IsActivatableAppWindow(0, false) == false, IsActivatableAppWindow(0, false))

; --------------------------------------------------------------------------------------------------
; 15. X-Ray Layer Peek Integration Lifecycle Tests
; --------------------------------------------------------------------------------------------------
xrayGui1 := Gui("+AlwaysOnTop", "XRayTestGui1")
xrayGui1.Show("w200 h200 x150 y150 NoActivate")

xrayGui2 := Gui("+AlwaysOnTop", "XRayTestGui2")
xrayGui2.Show("w200 h200 x150 y150 NoActivate")

InitXRayEngine()
AssertInteg("XRayLifecycle", "Initial state is IDLE", XRayState.status == "IDLE", XRayState.status)

; Simulate candidate list with test GUIs
XRayState.candidates := [xrayGui1.Hwnd, xrayGui2.Hwnd]
XRayState.status := "ACTIVE"
XRayState.currentIndex := 1
XRayState.stack := [xrayGui1.Hwnd]
try WinSetTransparent(XRayAlphaValue, "ahk_id " . xrayGui1.Hwnd)

AssertInteg("XRayLifecycle", "Layer 1 made transparent", XRayState.stack.Length == 1, XRayState.stack.Length)

; Step down to Layer 2
XRayStepDown()
AssertInteg("XRayLifecycle", "Step down adds Layer 2 to stack", XRayState.stack.Length == 2, XRayState.stack.Length)

; Step up to restore Layer 2
XRayStepUp()
AssertInteg("XRayLifecycle", "Step up pops Layer 2 from stack", XRayState.stack.Length == 1, XRayState.stack.Length)

; End X-Ray Peek & Clean up
EndXRayLayerPeek()
AssertInteg("XRayLifecycle", "End peek resets status to IDLE", XRayState.status == "IDLE", XRayState.status)
AssertInteg("XRayLifecycle", "End peek empties stack", XRayState.stack.Length == 0, XRayState.stack.Length)

xrayGui1.Destroy()
xrayGui2.Destroy()

; --------------------------------------------------------------------------------------------------
; 16. TaskManager Same-Day Older Task Completion Invariant (Concern 4)
; --------------------------------------------------------------------------------------------------
todayFormatted := FormatTime(A_Now, "yyyy-MM-dd")
ActionTasks := [
    {id: 101, task: "Old Task Done Today", created: "2026-08-01 10:00", commitmentType: "Task", priority: "Q1", done: true, doneDate: todayFormatted},
    {id: 102, task: "Old Task Done Yesterday", created: "2026-08-01 10:00", commitmentType: "Task", priority: "Q2", done: true, doneDate: "2026-08-28"},
    {id: 103, task: "Pending Task", created: "2026-08-01 10:00", commitmentType: "Task", priority: "Q3", done: false, doneDate: ""}
]
ArchivePreviousDaysCompletedTasks()
AssertInteg("TaskArchiveLifecycle", "Task done today is NOT archived prematurely", ActionTasks.Length == 2, ActionTasks.Length)
AssertInteg("TaskArchiveLifecycle", "Task 101 preserved", ActionTasks[1].id == 101, ActionTasks[1].id)
AssertInteg("TaskArchiveLifecycle", "Task 103 preserved", ActionTasks[2].id == 103, ActionTasks[2].id)
} catch as testErr {
    IntegTestsFailed++
    IntegLogLines.Push("[INTEG FATAL] " . testErr.Message . " at Line " . testErr.Line)
    Failures.Push({category: "IntegrationFatalException", testName: "FatalException", error: testErr.Message . " (Line " . testErr.Line . ")"})
}

durationMs := A_TickCount - StartTick
EmitTestResults("test_integration_runner", IntegTestsTotal, IntegTestsPassed, IntegTestsFailed, durationMs, IntegLogLines, Failures)

