; ======================================================================================================================
; Module: WindowPeekHotkeys.ahk - Physical Keyboard Hooks & Chording Engine for Window Peek & Leader Key
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

; --------------------------------------------------------------------------------------------------
; 1. Real CapsLock Toggles (Shift + CapsLock and Ctrl + CapsLock)
; --------------------------------------------------------------------------------------------------

+CapsLock::
^CapsLock::
{
    curr := GetKeyState("CapsLock", "T")
    SetCapsLockState(curr ? "AlwaysOff" : "AlwaysOn")
    try ShowToast(curr ? "🔒 CapsLock: OFF" : "🔠 CapsLock: ON", 1200)
}

; --------------------------------------------------------------------------------------------------
; 2. CapsLock Press & Release: Tap = Leader/Escape, Hold = Hyper-Modifier
; --------------------------------------------------------------------------------------------------

*CapsLock::
{
    global CapsLockPressTick, CapsLockChordFired
    if (CapsLockPressTick == 0) {
        CapsLockPressTick := A_TickCount
        CapsLockChordFired := false
    }
}

*CapsLock Up::
{
    global CapsLockPressTick, CapsLockChordFired, PeekState, XRayState
    
    ; 1. If actively peeking, end peek immediately
    if (PeekState.status = "STARTING" || PeekState.status = "PEEKING") {
        EndWindowPeek()
        CapsLockPressTick := 0
        CapsLockChordFired := false
        return
    }
    
    ; 2. If actively in X-Ray layer peek, restore all windows immediately
    if (XRayState.status = "ACTIVE") {
        EndXRayLayerPeek()
        CapsLockPressTick := 0
        CapsLockChordFired := false
        return
    }
    
    elapsed := A_TickCount - CapsLockPressTick
    pressTick := CapsLockPressTick
    wasChord := CapsLockChordFired
    
    CapsLockPressTick := 0
    CapsLockChordFired := false
    
    ; 3. If a chord was fired while holding CapsLock, do not trigger tap action
    if (wasChord)
        return
        
    ; 4. Quick Tap (< 350ms): Modal Escape Dismissal OR Leader Key
    if (elapsed < 350 && pressTick > 0) {
        if (IsSet(IsAnyOfficeUIVisible) && IsAnyOfficeUIVisible()) {
            if IsSet(CloseAllOfficeUIs)
                CloseAllOfficeUIs()
            return
        }
        if IsSet(ActivateLeaderKey)
            ActivateLeaderKey()
    }
}

; --------------------------------------------------------------------------------------------------
; 3. CapsLock Hyper-Engine: Window Peek, X-Ray Slicing & Direct Chording
; --------------------------------------------------------------------------------------------------

#HotIf GetKeyState("CapsLock", "P")

; 1. Window Peek (Hold CapsLock + Tab -> Peek, Release -> Return)
*Tab::
{
    global CapsLockChordFired, IsWindowPeekEnabled
    CapsLockChordFired := true
    if (IsWindowPeekEnabled) {
        StartWindowPeek()
    }
}

*Tab Up::
{
    global PeekState
    if (PeekState.status = "STARTING" || PeekState.status = "PEEKING")
        EndWindowPeek()
}

; 2. X-Ray Layer Peek (Hold CapsLock + Esc -> Ghost Top Window, Release -> Return)
*Esc:: StartXRayLayerPeek()
*Esc Up:: EndXRayLayerPeek()

; 3. Direct Hyper-Hold Chords (Hold CapsLock + Key -> Instant Sub-Millisecond Execution!)
*t:: ExecuteLeaderKeyChord("t")
*v:: ExecuteLeaderKeyChord("v")
*s:: ExecuteLeaderKeyChord("s")
*x:: ExecuteLeaderKeyChord("x")
*c:: ExecuteLeaderKeyChord("c")
*p:: ExecuteLeaderKeyChord("p")
*w:: ExecuteLeaderKeyChord("w")
*n:: ExecuteLeaderKeyChord("n")
*Space:: ExecuteLeaderKeyChord("?")

#HotIf

#HotIf GetKeyState("CapsLock", "P") && (XRayState.status = "ACTIVE")
*Down:: XRayStepDown()
*Up:: XRayStepUp()
#HotIf

; --------------------------------------------------------------------------------------------------
; 4. Stuck Physical-Key Watchdog (Self-Healing for Dropped Key-Up Events)
;
; The #HotIf blocks above hijack t/v/s/x/c/p/w/n/Space/Tab/Esc/Up/Down system-wide for as long as
; GetKeyState("CapsLock", "P") reports the key physically held. That OS-level physical state is
; outside this script's control: if a key-up event is ever dropped (a UAC prompt, lock screen, or
; other focus-stealing surface steals the up-event while CapsLock is down), Windows can keep
; reporting CapsLock as held indefinitely. When that happens every press of those keys silently
; fires a chord/peek action instead of typing — and reloading or exiting the script does NOT fix it,
; because the stuck state lives in the OS input session, not in script variables. This watchdog
; detects that condition and forces a synthetic release so the hook resyncs without a logoff.
; --------------------------------------------------------------------------------------------------

; Catalogued in the "Global State Registry" in Lib/Globals.ahk — update that list if you add,
; rename, or remove either global below.
global CapsLockStuckSince      := 0      ; Tick when the watchdog first saw an unexplained hold
global CapsLockStuckThresholdMs := 12000 ; Longer than CheckPeekWatchdog/CheckXRayWatchdog's own 10s cap

InitCapsLockStuckWatchdog() {
    SetTimer CheckCapsLockStuckWatchdog, 1000
}

CheckCapsLockStuckWatchdog() {
    global CapsLockStuckSince, CapsLockStuckThresholdMs, PeekState, XRayState

    isPhysicallyDown := false
    try isPhysicallyDown := GetKeyState("CapsLock", "P")

    if !isPhysicallyDown {
        CapsLockStuckSince := 0
        return
    }

    ; Window Peek and X-Ray legitimately hold CapsLock down and already run their own watchdogs
    ; (10s cap) — never fight those; only act once both are back to IDLE.
    if (PeekState.status != "IDLE" || XRayState.status != "IDLE") {
        CapsLockStuckSince := 0
        return
    }

    if (CapsLockStuckSince == 0) {
        CapsLockStuckSince := A_TickCount
        return
    }

    if (A_TickCount - CapsLockStuckSince > CapsLockStuckThresholdMs)
        ForceReleaseStuckCapsLock()
}

ForceReleaseStuckCapsLock() {
    global CapsLockPressTick, CapsLockChordFired, CapsLockStuckSince, CapsLockStuckThresholdMs

    try {
        ; Injected input still passes through the low-level keyboard hook, which resyncs AHK's
        ; internal physical-key state from it — this is what actually clears the stuck condition.
        SendInput("{CapsLock Up}")
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("ForceReleaseStuckCapsLock (SendInput)", err)
    }

    CapsLockPressTick  := 0
    CapsLockChordFired := false
    CapsLockStuckSince := 0

    if IsSet(LogAppError)
        LogAppError("ForceReleaseStuckCapsLock", Error("Stuck physical CapsLock auto-released by watchdog after " . CapsLockStuckThresholdMs . "ms with no active Peek/X-Ray session"))

    try ShowToast("⚠ Stuck CapsLock auto-released (keyboard hijack watchdog)", 2500)
}