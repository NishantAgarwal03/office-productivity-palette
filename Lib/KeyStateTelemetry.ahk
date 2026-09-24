; ======================================================================================================================
; Module: KeyStateTelemetry.ahk - Keyboard-State Fault Telemetry (stuck / hijacked key diagnosis)
; Part of Office Productivity Hub (v2.0.1)
; ======================================================================================================================
; Purpose : "Every key I press does something else" incidents leave NO exception in error_telemetry.log, so they
;           were previously undiagnosable. This module writes keyboard_state_telemetry.log with the evidence needed
;           to tell the possible causes apart:
;
;             physical down + no input activity   -> the OS dropped a key-up event (external cause)
;             logical down + physical up          -> a synthetic modifier (our own SendInput) was left down
;             chord fired, script never saw CapsLock go down -> #HotIf hook is running on stale OS state
;             WTS_SESSION_LOCK / UNLOCK just before -> lock screen / UAC / disconnect swallowed the key-up
;             RunningSuspects / Active window     -> focus-stealing tool present when it happened
;
; Events  : SCRIPT_START, HELD_LONG, HELD_VERY_LONG, RELEASED, CHORD_SUSPECT, WTS_*, WATCHDOG_FIRE, WATCHDOG_VERIFY
; Log     : KeyStateTelemetryLog (Globals.ahk) - %AppData%\OfficeProductivityHub\keyboard_state_telemetry.log,
;           rotated to .old above KeyTelemetryMaxLogBytes. Also appended to the exported Diagnostics Report.
; ======================================================================================================================

#Requires AutoHotkey v2.0

; ======================================================================================================================
; CONFIGURATION
; ======================================================================================================================

; Catalogued in the "Global State Registry" in Lib/Globals.ahk — update that list if you add, rename, or remove these.
global KeyTelemetryWatchedKeys    := ["CapsLock", "LShift", "RShift", "LCtrl", "RCtrl", "LAlt", "RAlt", "LWin", "RWin"]
global KeyTelemetrySuspectProcs   := ["Workrave.exe", "PowerToys.exe", "Ditto.exe", "Everything.exe", "stickies.exe", "Flow.Launcher.exe"]
global KeyTelemetryPollMs         := 1000
global KeyTelemetryWarnMs         := 3000     ; a key held longer than this is logged once
global KeyTelemetryEscalateMs     := 30000    ; ...and once more if it is still held
global KeyTelemetryChordSuspectMs := 4000     ; a chord fired after CapsLock held this long is suspect
global KeyTelemetrySuspectLogCap  := 25       ; full-detail suspect chords per session, then every 50th
global KeyTelemetryMaxLogBytes    := 524288
global KeyTelemetryHeldSince      := Map()    ; "P:key" / "L:key" -> tick the condition was first seen
global KeyTelemetryStage          := Map()    ; "P:key" / "L:key" -> 0 none, 1 warned, 2 escalated
global KeyTelemetrySuspectCount   := 0

; ======================================================================================================================
; INITIALISATION
; ======================================================================================================================

InitKeyStateTelemetry() {
    global KeyTelemetryPollMs
    try {
        LogKeyStateEvent("SCRIPT_START", "snapshot at launch (a key held here that survived a reload = OS-level stuck key)")
        SetTimer(KeyStateTelemetryTick, KeyTelemetryPollMs)
        ; WTS_SESSION_CHANGE: lock / unlock / disconnect are the classic sources of dropped key-up events
        DllCall("wtsapi32\WTSRegisterSessionNotification", "ptr", A_ScriptHwnd, "uint", 0)
        OnMessage(0x02B1, KeyTelemetryOnSessionChange)
    } catch as err {
        OutputDebug("[Telemetry Error] InitKeyStateTelemetry failed: " . err.Message)
    }
}

KeyTelemetryOnSessionChange(wParam, lParam, msg, hwnd) {
    static names := Map(1, "CONSOLE_CONNECT", 2, "CONSOLE_DISCONNECT", 3, "REMOTE_CONNECT", 4, "REMOTE_DISCONNECT"
                      , 5, "SESSION_LOGON", 6, "SESSION_LOGOFF", 7, "SESSION_LOCK", 8, "SESSION_UNLOCK")
    LogKeyStateEvent("WTS_" . (names.Has(wParam) ? names[wParam] : "CODE_" . wParam))
}

; ======================================================================================================================
; SNAPSHOT & LOG WRITER
; ======================================================================================================================

BuildKeyStateSnapshot() {
    global KeyTelemetryWatchedKeys, KeyTelemetrySuspectProcs

    held := ""
    for k in KeyTelemetryWatchedKeys {
        p := GetKeyState(k, "P")
        l := GetKeyState(k)
        if (p || l)
            held .= k . "[phys=" . (p ? 1 : 0) . " logical=" . (l ? 1 : 0) . "] "
    }
    if (held = "")
        held := "none "

    activeExe := ""
    activeWin := ""
    try activeExe := WinGetProcessName("A")
    try activeWin := SubStr(WinGetTitle("A"), 1, 60)

    peek := "n/a"
    xray := "n/a"
    pressAge := "n/a"
    try peek := PeekState.status
    try xray := XRayState.status
    try pressAge := (CapsLockPressTick > 0) ? (A_TickCount - CapsLockPressTick) . "ms" : "no-script-keydown"

    suspects := ""
    for procName in KeyTelemetrySuspectProcs {
        if ProcessExist(procName)
            suspects .= procName . " "
    }

    return "Held: " . held
         . "| CapsLockToggle=" . (GetKeyState("CapsLock", "T") ? "ON" : "off")
         . " | IdlePhysical=" . A_TimeIdlePhysical . "ms"
         . " | PriorKey=" . A_PriorKey . " PriorHotkey=" . A_PriorHotkey
         . " | ScriptSawCapsDown=" . pressAge
         . " | Peek=" . peek . " XRay=" . xray
         . " | Active=" . activeExe . " '" . activeWin . "'"
         . " | RunningSuspects=" . (suspects = "" ? "none" : Trim(suspects))
}

LogKeyStateEvent(eventType, detail := "") {
    global KeyStateTelemetryLog, KeyTelemetryMaxLogBytes
    try {
        if (FileExist(KeyStateTelemetryLog) && FileGetSize(KeyStateTelemetryLog) > KeyTelemetryMaxLogBytes)
            FileMove(KeyStateTelemetryLog, KeyStateTelemetryLog . ".old", true)

        line := Format("[{}] {}{}`n    {}`n", FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss"), eventType
                     , (detail = "" ? "" : " - " . detail), BuildKeyStateSnapshot())
        FileAppend(line, KeyStateTelemetryLog, "UTF-8")
    } catch as err {
        OutputDebug("[Telemetry Error] LogKeyStateEvent failed: " . err.Message)
    }
}

; ======================================================================================================================
; POLLING: HELD-KEY DETECTION
; ======================================================================================================================

KeyStateTelemetryTick() {
    global KeyTelemetryWatchedKeys, KeyTelemetryWarnMs, KeyTelemetryEscalateMs

    for k in KeyTelemetryWatchedKeys {
        phys := GetKeyState(k, "P")
        logi := GetKeyState(k)
        ; Physical hold, plus the mismatch case: logically down while physically up = an injected key left down
        TrackKeyCondition("P:" . k, phys, k . " physically held", KeyTelemetryWarnMs, KeyTelemetryEscalateMs)
        TrackKeyCondition("L:" . k, logi && !phys, k . " LOGICALLY down but not physically (synthetic/injected stuck key)", KeyTelemetryWarnMs, KeyTelemetryEscalateMs)
    }
}

TrackKeyCondition(trackId, isActive, description, warnMs, escalateMs) {
    global KeyTelemetryHeldSince, KeyTelemetryStage

    if !isActive {
        if KeyTelemetryHeldSince.Has(trackId) {
            if (KeyTelemetryStage[trackId] >= 1)
                LogKeyStateEvent("RELEASED", description . " ended after " . (A_TickCount - KeyTelemetryHeldSince[trackId]) . "ms")
            KeyTelemetryHeldSince.Delete(trackId)
            KeyTelemetryStage.Delete(trackId)
        }
        return
    }

    if !KeyTelemetryHeldSince.Has(trackId) {
        KeyTelemetryHeldSince[trackId] := A_TickCount
        KeyTelemetryStage[trackId] := 0
        return
    }

    heldMs := A_TickCount - KeyTelemetryHeldSince[trackId]
    if (KeyTelemetryStage[trackId] < 2 && heldMs >= escalateMs) {
        KeyTelemetryStage[trackId] := 2
        LogKeyStateEvent("HELD_VERY_LONG", description . " for " . heldMs . "ms - likely stuck")
    } else if (KeyTelemetryStage[trackId] < 1 && heldMs >= warnMs) {
        KeyTelemetryStage[trackId] := 1
        LogKeyStateEvent("HELD_LONG", description . " for " . heldMs . "ms (expected if Peek/X-Ray is active)")
    }
}

; ======================================================================================================================
; CHORD HIJACK DETECTION
; ======================================================================================================================

; Called from every CapsLock-held hotkey. Normal use is only counted; suspicious use is logged in full.
LogChordFired(keyName) {
    global KeyTelemetryChordSuspectMs, KeyTelemetrySuspectLogCap, KeyTelemetrySuspectCount, TelemetryStatsFile

    pressTick := 0
    try pressTick := CapsLockPressTick
    heldMs := (pressTick > 0) ? (A_TickCount - pressTick) : -1
    noScriptKeydown := (pressTick = 0)
    tooLong := (heldMs > KeyTelemetryChordSuspectMs)

    if (!noScriptKeydown && !tooLong) {
        try {
            n := Integer(IniRead(TelemetryStatsFile, "TriggerMethods", "Chord", "0"))
            IniWrite(String(n + 1), TelemetryStatsFile, "TriggerMethods", "Chord")
        }
        return
    }

    KeyTelemetrySuspectCount += 1
    if (KeyTelemetrySuspectCount > KeyTelemetrySuspectLogCap && Mod(KeyTelemetrySuspectCount, 50) != 0)
        return
    LogKeyStateEvent("CHORD_SUSPECT", "'" . keyName . "' fired with "
        . (noScriptKeydown ? "NO script-observed CapsLock keydown (hook running on stale OS state)" : "CapsLock held " . heldMs . "ms")
        . " | suspect#" . KeyTelemetrySuspectCount)
}

; ======================================================================================================================
; REPORT SUPPORT
; ======================================================================================================================

ReadKeyStateLogTail(maxChars := 2500) {
    global KeyStateTelemetryLog
    if !FileExist(KeyStateTelemetryLog)
        return "  (No keyboard-state events recorded yet)`n"
    content := FileRead(KeyStateTelemetryLog, "UTF-8")
    return (StrLen(content) > maxChars) ? SubStr(content, StrLen(content) - maxChars) . "`n" : content . "`n"
}
