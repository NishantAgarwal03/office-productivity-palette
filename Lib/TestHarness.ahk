; ======================================================================================================================
; Module: TestHarness.ahk - Unified Zero-Trust Headless Test Harness & Schema-Versioned Result Emitter
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0
#Warn All, StdOut

; --------------------------------------------------------------------------------------------------
; 1. Global Headless Error Trap (Suppresses Interactive GUI Dialogs)
; --------------------------------------------------------------------------------------------------
OnError(GlobalTestErrorHandler)

GlobalTestErrorHandler(err, mode) {
    fatalMsg := Format("[FATAL_UNHANDLED_EXCEPTION] {1}`nFile: {2} (Line {3})`nStack:`n{4}`n", 
                       err.Message, err.File, err.Line, err.Stack)
    try FileAppend(fatalMsg, "*", "UTF-8")
    
    global DataDir
    if (IsSet(DataDir) && DataDir != "") {
        try FileAppend(fatalMsg, DataDir . "\fatal_error.log", "UTF-8")
    }
    ExitApp(1)
    return true ; Suppress default AHK modal MsgBox dialog
}

; --------------------------------------------------------------------------------------------------
; 1B. Clipboard Snapshot & Bitwise Restoration (Zero Host Mutation)
; --------------------------------------------------------------------------------------------------
global TestHarnessInitialClipboard := ""
try TestHarnessInitialClipboard := ClipboardAll()

OnExit(TestHarnessRestoreClipboard)

TestHarnessRestoreClipboard(exitReason, exitCode) {
    global TestHarnessInitialClipboard
    try {
        if IsObject(TestHarnessInitialClipboard) {
            A_Clipboard := TestHarnessInitialClipboard
        }
    }
}

; --------------------------------------------------------------------------------------------------
; 2. JSON Test Results Emitter & Schema v1.0.0 Serializer
; --------------------------------------------------------------------------------------------------
EmitTestResults(suiteName, total, passed, failed, durationMs, testLogs, failureDetails) {
    global DataDir, IsTestMode
    
    outDir := (IsSet(DataDir) && DataDir != "") ? DataDir : A_ScriptDir
    
    ; Build JSON string safely
    jsonStr := "{"
    jsonStr .= '`n  "schema_version": "1.0.0",'
    jsonStr .= '`n  "suite_name": "' . JsonEscape(suiteName) . '",'
    jsonStr .= '`n  "total": ' . total . ','
    jsonStr .= '`n  "passed": ' . passed . ','
    jsonStr .= '`n  "failed": ' . failed . ','
    jsonStr .= '`n  "duration_ms": ' . Integer(durationMs) . ','
    jsonStr .= '`n  "failures": ['
    
    firstFail := true
    for fail in failureDetails {
        if (!firstFail)
            jsonStr .= ","
        firstFail := false
        jsonStr .= '`n    {'
        jsonStr .= '`n      "category": "' . JsonEscape(fail.HasOwnProp("category") ? fail.category : "") . '",'
        jsonStr .= '`n      "test_name": "' . JsonEscape(fail.HasOwnProp("testName") ? fail.testName : "") . '",'
        jsonStr .= '`n      "error": "' . JsonEscape(fail.HasOwnProp("error") ? fail.error : "") . '"'
        jsonStr .= '`n    }'
    }
    jsonStr .= '`n  ]'
    jsonStr .= '`n}'
    
    ; Write JSON result file
    jsonPath := outDir . "\results.json"
    try FileDelete(jsonPath)
    try FileAppend(jsonStr, jsonPath, "UTF-8-RAW")
    
    ; Write human-readable log file
    humanReport := "================================================================================`n"
    humanReport .= Format("      {1} TEST RESULTS REPORT`n", StrUpper(suiteName))
    humanReport .= "================================================================================`n"
    humanReport .= Format("Total Assertions: {1}`nPassed: {2}`nFailed: {3}`nSuccess Rate: {4:0.1f}%`nDuration: {5}ms`n`n", 
                          total, passed, failed, (passed / Max(total, 1)) * 100, durationMs)
    for line in testLogs {
        humanReport .= line . "`n"
    }
    
    logPath := outDir . "\" . suiteName . "_results.log"
    try FileDelete(logPath)
    try FileAppend(humanReport, logPath, "UTF-8")
    
    ; Emit human-readable text and completion sentinel token to stdout
    try FileAppend(humanReport . "`n", "*", "UTF-8")
    try FileAppend("[TEST_RUN_COMPLETE]`n", "*", "UTF-8")
    
    ExitApp(failed > 0 ? 1 : 0)
}

JsonEscape(str) {
    s := String(str)
    s := StrReplace(s, "\", "\\")
    s := StrReplace(s, '"', '\"')
    s := StrReplace(s, "`r", "\r")
    s := StrReplace(s, "`n", "\n")
    s := StrReplace(s, "`t", "\t")
    return s
}