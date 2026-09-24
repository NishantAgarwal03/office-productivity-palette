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
    global CapsLockPressTick, CapsLockChordFired, CapsLockLastSeenTick
    CapsLockLastSeenTick := A_TickCount   ; every key-down incl. auto-repeat proves the key is really held
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

#HotIf IsCapsLockChordActive()

; 1. Window Peek (Hold CapsLock + Tab -> Peek, Release -> Return)
*Tab::
{
    global CapsLockChordFired, IsWindowPeekEnabled, CapsLockLastSeenTick
    CapsLockChordFired := true
    CapsLockLastSeenTick := A_TickCount
    LogChordFired("Tab")
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
*Esc:: HyperEsc()
*Esc Up:: EndXRayLayerPeek()

; 3. Direct Hyper-Hold Chords (Hold CapsLock + Key -> Instant Sub-Millisecond Execution!)
*t:: HyperChord("t")
*v:: HyperChord("v")
*s:: HyperChord("s")
*x:: HyperChord("x")
*c:: HyperChord("c")
*p:: HyperChord("p")
*w:: HyperChord("w")
*n:: HyperChord("n")
*Space:: HyperChord("?")

#HotIf

; #HotIf gate for every CapsLock chord: OS physical state AND a recent script-observed key-down (see
; IsCapsLockChordWindowOpen in WindowPeekEngine.ahk). Keeps a stuck-down CapsLock from hijacking typing.
IsCapsLockChordActive() {
    global CapsLockLastSeenTick, CapsLockHijackWindowMs, PeekState, XRayState
    if !GetKeyState("CapsLock", "P")
        return false
    sessionActive := (PeekState.status != "IDLE" || XRayState.status != "IDLE")
    return IsCapsLockChordWindowOpen(A_TickCount, CapsLockLastSeenTick, CapsLockHijackWindowMs, sessionActive)
}

; Wrappers so every CapsLock-held hotkey reports to KeyStateTelemetry (stuck-key diagnosis)
HyperChord(key) {
    global CapsLockLastSeenTick
    CapsLockLastSeenTick := A_TickCount
    LogChordFired(key)
    ExecuteLeaderKeyChord(key)
}

HyperEsc() {
    global CapsLockLastSeenTick
    CapsLockLastSeenTick := A_TickCount
    LogChordFired("Esc")
    StartXRayLayerPeek()
}

#HotIf IsCapsLockChordActive() && (XRayState.status = "ACTIVE")
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
global CapsLockExpiryLogged    := false ; One HIJACK_SELF_EXPIRED telemetry entry per stuck episode

InitCapsLockStuckWatchdog() {
    SetTimer CheckCapsLockStuckWatchdog, 1000
}

CheckCapsLockStuckWatchdog() {
    global CapsLockStuckSince, CapsLockStuckThresholdMs, PeekState, XRayState, CapsLockExpiryLogged, CapsLockHijackWindowMs

    isPhysicallyDown := false
    try isPhysicallyDown := GetKeyState("CapsLock", "P")

    if !isPhysicallyDown {
        CapsLockStuckSince := 0
        CapsLockExpiryLogged := false
        return
    }

    ; Physically "down" but the chord gate has closed = the hijack already expired on its own (fix A).
    if (!CapsLockExpiryLogged && PeekState.status = "IDLE" && XRayState.status = "IDLE" && !IsCapsLockChordActive()) {
        CapsLockExpiryLogged := true
        if IsSet(LogKeyStateEvent)
            LogKeyStateEvent("HIJACK_SELF_EXPIRED", "CapsLock reads physically down with no script-observed key-down for " . CapsLockHijackWindowMs . "ms+; chord hotkeys disabled, typing restored")
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

    LogKeyStateEvent("WATCHDOG_FIRE", "stuck CapsLock detected, sending synthetic {CapsLock Up}")
    try {
        ; Injected input still passes through the low-level keyboard hook, which resyncs AHK's
        ; internal physical-key state from it — this is what actually clears the stuck condition.
        SendInput("{CapsLock Up}")
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("ForceReleaseStuckCapsLock (SendInput)", err)
    }

    ; Verify whether the synthetic release actually cleared the physical state (unproven assumption)
    SetTimer(() => LogKeyStateEvent("WATCHDOG_VERIFY", "physical CapsLock after synthetic up = " . (GetKeyState("CapsLock", "P") ? "STILL DOWN (release did not work)" : "cleared")), -300)

    CapsLockPressTick  := 0
    CapsLockChordFired := false
    CapsLockStuckSince := 0

    if IsSet(LogAppError)
        LogAppError("ForceReleaseStuckCapsLock", Error("Stuck physical CapsLock auto-released by watchdog after " . CapsLockStuckThresholdMs . "ms with no active Peek/X-Ray session"))

    try ShowToast("⚠ Stuck CapsLock auto-released (keyboard hijack watchdog)", 2500)
}