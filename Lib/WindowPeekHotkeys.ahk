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