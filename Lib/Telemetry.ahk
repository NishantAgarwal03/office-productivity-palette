; ======================================================================================================================
; Module: Telemetry.ahk - Production Analytics, Performance, Feature Discovery & Error Telemetry Engine
; ======================================================================================================================

#Requires AutoHotkey v2.0

InitTelemetry() {
    global TelemetryDir, TelemetryStatsFile, TelemetryErrorLog, SessionStartTime
    try {
        if !DirExist(TelemetryDir)
            DirCreate(TelemetryDir)
            
        currSessions := Integer(IniRead(TelemetryStatsFile, "SystemStats", "TotalAppLaunches", "0"))
        IniWrite(String(currSessions + 1), TelemetryStatsFile, "SystemStats", "TotalAppLaunches")
        IniWrite(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss"), TelemetryStatsFile, "SystemStats", "LastLaunchTimestamp")
        IniWrite(A_IsCompiled ? "Compiled (.exe)" : "Script (.ahk)", TelemetryStatsFile, "SystemStats", "RuntimeMode")
        IniWrite(A_AhkVersion, TelemetryStatsFile, "SystemStats", "AhkVersion")
        IniWrite(A_OSVersion, TelemetryStatsFile, "SystemStats", "OSVersion")
        
        OnError(TelemetryGlobalErrorHandler)
    } catch as err {
        OutputDebug("[Telemetry Error] InitTelemetry failed: " . err.Message)
    }
}

LogToolExecution(toolName, category := "General", triggerMethod := "Palette", durationMs := 0, success := true) {
    global TelemetryStatsFile
    try {
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        activeExe := ""
        try activeExe := WinGetProcessName("A")
        if (activeExe = "")
            activeExe := "Desktop/System"

        currCount := Integer(IniRead(TelemetryStatsFile, "ToolFrequency", toolName, "0"))
        IniWrite(String(currCount + 1), TelemetryStatsFile, "ToolFrequency", toolName)
        
        IniWrite(category, TelemetryStatsFile, "ToolDetails_" . toolName, "Category")
        IniWrite(timestamp, TelemetryStatsFile, "ToolDetails_" . toolName, "LastUsed")
        IniWrite(activeExe, TelemetryStatsFile, "ToolDetails_" . toolName, "LastTargetApp")
        IniWrite(triggerMethod, TelemetryStatsFile, "ToolDetails_" . toolName, "LastTriggerMethod")
        if (durationMs > 0)
            IniWrite(String(durationMs) . "ms", TelemetryStatsFile, "ToolDetails_" . toolName, "LastExecDuration")

        trigCount := Integer(IniRead(TelemetryStatsFile, "TriggerMethods", triggerMethod, "0"))
        IniWrite(String(trigCount + 1), TelemetryStatsFile, "TriggerMethods", triggerMethod)
        
        appCount := Integer(IniRead(TelemetryStatsFile, "TargetApplications", activeExe, "0"))
        IniWrite(String(appCount + 1), TelemetryStatsFile, "TargetApplications", activeExe)
    } catch as err {
        OutputDebug("[Telemetry Error] LogToolExecution failed for '" . toolName . "': " . err.Message)
    }
}

LogZeroMatchQuery(query) {
    global TelemetryStatsFile, TelemetryMissLog
    q := Trim(query)
    if (q = "" || StrLen(q) < 2)
        return
        
    try {
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        
        currMissCount := Integer(IniRead(TelemetryStatsFile, "ZeroMatchQueries", q, "0"))
        IniWrite(String(currMissCount + 1), TelemetryStatsFile, "ZeroMatchQueries", q)
        
        logLine := Format("[{}] ZERO_MATCH: '{}'`n", timestamp, q)
        FileAppend(logLine, TelemetryMissLog, "UTF-8")
    } catch as err {
        OutputDebug("[Telemetry Error] LogZeroMatchQuery failed: " . err.Message)
    }
}

LogAppError(context, errObj) {
    global TelemetryErrorLog, TelemetryStatsFile
    try {
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        activeWin := ""
        activeExe := ""
        try activeWin := WinGetTitle("A")
        try activeExe := WinGetProcessName("A")
        
        errMsg := IsObject(errObj) ? errObj.Message : String(errObj)
        errFile := (IsObject(errObj) && errObj.HasOwnProp("File")) ? errObj.File : "Unknown"
        errLine := (IsObject(errObj) && errObj.HasOwnProp("Line")) ? errObj.Line : "0"
        errStack := (IsObject(errObj) && errObj.HasOwnProp("Stack")) ? errObj.Stack : ""
        
        logEntry := Format("[{}] ERROR in '{}'`n  • Message: {}`n  • File: {} (Line {})`n  • Target App: {} | Window: '{}'`n  • Stack: {}`n--------------------------------------------------------------------------------`n", 
                           timestamp, context, errMsg, errFile, errLine, activeExe, SubStr(activeWin, 1, 60), errStack)
        
        FileAppend(logEntry, TelemetryErrorLog, "UTF-8")
        
        totalErrors := Integer(IniRead(TelemetryStatsFile, "SystemStats", "TotalErrorsLogged", "0"))
        IniWrite(String(totalErrors + 1), TelemetryStatsFile, "SystemStats", "TotalErrorsLogged")
    } catch as err {
        OutputDebug("[Telemetry Error] LogAppError failed to write error log: " . err.Message)
    }
}

TelemetryGlobalErrorHandler(thrown, mode) {
    LogAppError("GlobalUnhandledException (Mode: " . mode . ")", thrown)
    ; Suppress AHK default fatal crash dialog and exit the offending thread cleanly
    return -1
}

ExportDiagnosticsReport() {
    global TelemetryStatsFile, TelemetryErrorLog, TelemetryMissLog, SessionStartTime
    try {
        timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
        desktopPath := A_Desktop . "\\Office_Productivity_Diagnostics_Report.txt"
        
        out := "================================================================================`n"
             . "          OFFICE PRODUCTIVITY PALETTE - TELEMETRY & DIAGNOSTICS REPORT          `n"
             . "================================================================================`n"
             . "Generated: " . timestamp . "`n`n"

        out .= "[1. SYSTEM & RUNTIME INFORMATION]`n"
             . "• App Version:       2.0.0 (Modular Production Release)`n"
             . "• Runtime Mode:      " . (A_IsCompiled ? "Compiled Standalone (.exe)" : "Script Source (.ahk)") . "`n"
             . "• AutoHotkey Ver:    " . A_AhkVersion . " (" . (A_PtrSize = 8 ? "64-bit" : "32-bit") . ")`n"
             . "• Windows Version:   " . A_OSVersion . "`n"
             . "• Total App Launches: " . IniRead(TelemetryStatsFile, "SystemStats", "TotalAppLaunches", "1") . "`n"
             . "• Total Errors Logged: " . IniRead(TelemetryStatsFile, "SystemStats", "TotalErrorsLogged", "0") . "`n"
             . "• Current Session Up: " . DateDiff(A_Now, SessionStartTime, "Minutes") . " minutes`n`n"

        out .= "[2. TOOL USAGE STATISTICS & ADOPTION]`n"
        toolSection := IniRead(TelemetryStatsFile, "ToolFrequency",, "")
        if (toolSection != "") {
            lines := StrSplit(toolSection, "`n", "`r")
            toolList := []
            for l in lines {
                parts := StrSplit(l, "=")
                if (parts.Length = 2 && Trim(parts[1]) != "")
                    toolList.Push({name: Trim(parts[1]), count: Integer(Trim(parts[2]))})
            }
            loop toolList.Length {
                i := A_Index
                loop toolList.Length - i {
                    j := A_Index
                    if (toolList[j].count < toolList[j + 1].count) {
                        temp := toolList[j]
                        toolList[j] := toolList[j + 1]
                        toolList[j + 1] := temp
                    }
                }
            }
            for idx, item in toolList {
                lastApp := IniRead(TelemetryStatsFile, "ToolDetails_" . item.name, "LastTargetApp", "General")
                lastTrig := IniRead(TelemetryStatsFile, "ToolDetails_" . item.name, "LastTriggerMethod", "Palette")
                out .= Format("  {1:2}. {2,-38} | Executions: {3,4} | Trigger: {4,-12} | Top App: {5}`n", idx, item.name, item.count, lastTrig, lastApp)
                if (idx >= 25)
                    break
            }
        } else {
            out .= "  (No tool executions recorded yet)`n"
        }
        out .= "`n"

        out .= "[3. TRIGGER METHODS BREAKDOWN]`n"
        trigSection := IniRead(TelemetryStatsFile, "TriggerMethods",, "")
        if (trigSection != "") {
            for l in StrSplit(trigSection, "`n", "`r") {
                if (Trim(l) != "")
                    out .= "  • " . StrReplace(Trim(l), "=", ": ") . " executions`n"
            }
        } else {
            out .= "  (No trigger data recorded yet)`n"
        }
        out .= "`n"

        out .= "[4. TARGET APPLICATION COMPATIBILITY]`n"
        appSection := IniRead(TelemetryStatsFile, "TargetApplications",, "")
        if (appSection != "") {
            for l in StrSplit(appSection, "`n", "`r") {
                if (Trim(l) != "")
                    out .= "  • " . StrReplace(Trim(l), "=", ": ") . " operations`n"
            }
        } else {
            out .= "  (No target application data recorded yet)`n"
        }
        out .= "`n"

        out .= "[5. ZERO-RESULT SEARCH QUERIES (FEATURE REQUESTS & USER INTENT)]`n"
        missSection := IniRead(TelemetryStatsFile, "ZeroMatchQueries",, "")
        if (missSection != "") {
            for l in StrSplit(missSection, "`n", "`r") {
                if (Trim(l) != "")
                    out .= "  • '" . StrSplit(l, "=")[1] . "' -> searched " . StrSplit(l, "=")[2] . " times`n"
            }
        } else {
            out .= "  (No unmatched search queries logged)`n"
        }
        out .= "`n"

        out .= "[6. RECENT ERROR LOG (LAST 2000 BYTES)]`n"
        if FileExist(TelemetryErrorLog) {
            errContent := FileRead(TelemetryErrorLog, "UTF-8")
            if (StrLen(errContent) > 2000)
                errContent := SubStr(errContent, StrLen(errContent) - 2000)
            out .= errContent . "`n"
        } else {
            out .= "  (System Healthy: 0 errors recorded)`n"
        }

        if FileExist(desktopPath)
            FileDelete(desktopPath)
        FileAppend(out, desktopPath, "UTF-8")
        
        A_Clipboard := out
        Run('notepad.exe "' . desktopPath . '"')
        ShowToast("✔ Diagnostic Report saved to Desktop & Clipboard!", 3000)
    } catch as err {
        MsgBox("Failed to export diagnostics: " . err.Message, "Export Error", "Icon!")
    }
}
