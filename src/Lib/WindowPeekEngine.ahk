; ======================================================================================================================
; Module: WindowPeekEngine.ahk - Decoupled Pure State Machine, Z-Order Algorithms & X-Ray Slicing Engine
; Part of Office Productivity Hub (v2.0.0)
; Contains zero keyboard hooks or persistent hotkey definitions (Headless Test Compatible).
; ======================================================================================================================

#Requires AutoHotkey v2.0

global IsWindowPeekEnabled := true
global PeekState           := { status: "IDLE", origHwnd: 0, targetHwnd: 0, targetWasMinimized: false, startTick: 0 }
global CapsLockPressTick   := 0
global CapsLockChordFired  := false
global XRayState           := { status: "IDLE", stack: [], candidates: [], currentIndex: 0, startTick: 0 }
global XRayOpacityPercent  := 15
global XRayAlphaValue      := 38

; --------------------------------------------------------------------------------------------------
; 1. Startup & Configuration Lifecycle (Default Enabled: 1)
; --------------------------------------------------------------------------------------------------

InitWindowPeekEngine() {
    global IsWindowPeekEnabled, TelemetryStatsFile
    try {
        val := IniRead(TelemetryStatsFile, "Settings", "WindowPeekEnabled", "1")
        IsWindowPeekEnabled := (val != "0")
    } catch {
        IsWindowPeekEnabled := true
    }
}

InitXRayEngine() {
    global XRayOpacityPercent, XRayAlphaValue, TelemetryStatsFile
    try {
        val := IniRead(TelemetryStatsFile, "Settings", "XRayOpacityPercent", "15")
        if IsNumber(val) {
            p := Integer(val)
            if (p < 5)
                p := 5
            if (p > 90)
                p := 90
            XRayOpacityPercent := p
        } else {
            XRayOpacityPercent := 15
        }
    } catch {
        XRayOpacityPercent := 15
    }
    XRayAlphaValue := Integer((XRayOpacityPercent / 100.0) * 255)
}

ConfigureXRayTransparency() {
    global XRayOpacityPercent, XRayAlphaValue, TelemetryStatsFile
    ib := OfficeInputBox("Enter X-Ray Window Opacity % (5 to 90):`n(Lower % = More Transparent / Easier to see through)", "Configure X-Ray Transparency", String(XRayOpacityPercent))
    if (ib.Result != "OK" || Trim(ib.Value) = "" || !IsNumber(Trim(ib.Value)))
        return
        
    p := Integer(Trim(ib.Value))
    if (p < 5)
        p := 5
    if (p > 90)
        p := 90
        
    XRayOpacityPercent := p
    XRayAlphaValue := Integer((XRayOpacityPercent / 100.0) * 255)
    
    try {
        IniWrite(String(XRayOpacityPercent), TelemetryStatsFile, "Settings", "XRayOpacityPercent")
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("ConfigureXRayTransparency (IniWrite)", err)
    }
    
    ShowToast("✔ X-Ray Opacity set to " . XRayOpacityPercent . "%", 2000)
}

ToggleWindowPeek() {
    global IsWindowPeekEnabled, PeekState, TelemetryStatsFile
    
    ; If toggled mid-peek, safely restore the original window before disabling
    if (PeekState.status != "IDLE")
        EndWindowPeek()

    IsWindowPeekEnabled := !IsWindowPeekEnabled
    
    try {
        IniWrite(IsWindowPeekEnabled ? "1" : "0", TelemetryStatsFile, "Settings", "WindowPeekEnabled")
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("ToggleWindowPeek (IniWrite)", err)
    }
    
    statusText := IsWindowPeekEnabled ? "ENABLED" : "DISABLED"
    try ShowToast("👁️ Window Peek (CapsLock+Tab): " . statusText, 1500)
}

; --------------------------------------------------------------------------------------------------
; 2. Window Peek FSM Lifecycle Methods (IDLE -> STARTING -> PEEKING -> RESTORING)
; --------------------------------------------------------------------------------------------------

StartWindowPeek() {
    global PeekState
    ; Reject if already in any non-idle state (prevents keyboard repeat driver spam)
    if (PeekState.status != "IDLE")
        return

    origHwnd := WinExist("A")
    if !origHwnd || !IsActivatableAppWindow(origHwnd, true)
        return
        
    targetHwnd := GetPreviousZOrderWindow(origHwnd)
    if !targetHwnd || targetHwnd == origHwnd
        return

    ; Check if target is currently minimized
    targetWasMin := false
    try {
        targetWasMin := (WinGetMinMax("ahk_id " . targetHwnd) == -1)
    } catch {
        targetWasMin := false
    }

    ; Transition to STARTING
    PeekState.status             := "STARTING"
    PeekState.origHwnd           := origHwnd
    PeekState.targetHwnd         := targetHwnd
    PeekState.targetWasMinimized := targetWasMin
    PeekState.startTick          := A_TickCount

    ; Start high-speed safety & release watchdog
    SetTimer CheckPeekWatchdog, 50

    try {
        WinActivate("ahk_id " . targetHwnd)
        ; Bounded wait (up to 400ms) to accommodate focus-delayed applications
        if WinWaitActive("ahk_id " . targetHwnd, , 0.4) {
            ; Check if user already released keys while activation was in-flight
            if (PeekState.status = "STARTING") {
                PeekState.status := "PEEKING"
            } else if (PeekState.status = "RESTORING") {
                ; User released early: proceed with queued restoration immediately
                ExecuteRestoration()
            }
        } else {
            ; Activation timed out or failed
            EndWindowPeek()
        }
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("StartWindowPeek (WinActivate)", err)
        EndWindowPeek()
    }
}

EndWindowPeek() {
    global PeekState
    if (PeekState.status = "IDLE")
        return

    ; If activation was still in-flight, mark as RESTORING so completion triggers restore
    if (PeekState.status = "STARTING") {
        PeekState.status := "RESTORING"
        return
    }

    PeekState.status := "RESTORING"
    ExecuteRestoration()
}

ExecuteRestoration() {
    global PeekState
    SetTimer CheckPeekWatchdog, 0
    
    try {
        ; If target window was originally minimized, re-minimize it to preserve desktop state
        if (PeekState.targetWasMinimized && PeekState.targetHwnd && WinExist("ahk_id " . PeekState.targetHwnd)) {
            try WinMinimize("ahk_id " . PeekState.targetHwnd)
        }

        ; Reactivate original window
        if (PeekState.origHwnd && WinExist("ahk_id " . PeekState.origHwnd)) {
            WinActivate("ahk_id " . PeekState.origHwnd)
            WinWaitActive("ahk_id " . PeekState.origHwnd, , 0.3)
        }
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("ExecuteRestoration", err)
    } finally {
        ResetPeekState()
    }
}

CheckPeekWatchdog() {
    global PeekState
    if (PeekState.status = "IDLE")
        return
        
    ; Watchdog: cancel if held > 10s or if CapsLock OR Tab is physically released
    if (A_TickCount - PeekState.startTick > 10000) || !GetKeyState("CapsLock", "P") || !GetKeyState("Tab", "P") {
        EndWindowPeek()
    }
}

ResetPeekState() {
    global PeekState
    SetTimer CheckPeekWatchdog, 0
    PeekState.status             := "IDLE"
    PeekState.origHwnd           := 0
    PeekState.targetHwnd         := 0
    PeekState.targetWasMinimized := false
    PeekState.startTick          := 0
}

; --------------------------------------------------------------------------------------------------
; 3. Win32 Application Window Filter Primitive
; --------------------------------------------------------------------------------------------------

IsActivatableAppWindow(hwnd, allowMinimized := true) {
    if !hwnd || !IsInteger(hwnd) || hwnd <= 0
        return false

    try {
        if !WinExist("ahk_id " . hwnd)
            return false
    } catch {
        return false
    }

    ; 1. Exclude own script process windows (Palette, Toast HUD, SnippetGui)
    try {
        winPid := WinGetPID("ahk_id " . hwnd)
        if (winPid == ProcessExist())
            return false
    } catch {
        return false
    }

    ; 2. Exclude system shell surfaces & overlay frames
    try {
        winClass := WinGetClass("ahk_id " . hwnd)
        if (winClass = "Progman" || winClass = "WorkerW" || winClass = "Shell_TrayWnd" 
            || winClass = "MultitaskingViewFrame" || winClass = "XamlExplorerHostIslandWindow"
            || winClass = "Windows.UI.Core.CoreWindow")
            return false
    } catch {
        return false
    }

    try {
        style    := WinGetStyle("ahk_id " . hwnd)
        exStyle  := WinGetExStyle("ahk_id " . hwnd)
        minMax   := WinGetMinMax("ahk_id " . hwnd)
        WinGetPos(&x, &y, &w, &h, "ahk_id " . hwnd)
    } catch {
        return false
    }

    ; 3. Check minimized preference
    if (!allowMinimized && minMax == -1)
        return false

    ; 4. Must be visible, not disabled, and have positive dimensions
    if !(style & 0x10000000) || (style & 0x08000000) || (w <= 100 || h <= 100)
        return false

    ; 5. Exclude tool windows and non-activatable overlays
    if (exStyle & 0x00000080) || (exStyle & 0x08000000)
        return false

    ; 6. Exclude DWM Cloaked windows (Background UWP apps)
    try {
        cloaked := 0
        res := DllCall("dwmapi\DwmGetWindowAttribute", "ptr", hwnd, "uint", 14, "uint*", &cloaked, "uint", 4)
        if (res == 0 && cloaked != 0)
            return false
    } catch {
        return false
    }

    ; 7. Exclude owned popup windows (GW_OWNER = 4)
    try {
        ownerHwnd := DllCall("GetWindow", "ptr", hwnd, "uint", 4, "ptr")
        if (ownerHwnd != 0)
            return false
    } catch {
        return false
    }

    return true
}

GetPreviousZOrderWindow(currentHwnd) {
    try {
        winList := WinGetList()
        
        ; Pass 1: Prefer visible, un-minimized application windows
        for hwnd in winList {
            if (hwnd == currentHwnd)
                continue
            if IsActivatableAppWindow(hwnd, false)
                return hwnd
        }
        
        ; Pass 2: Fallback to top minimized application window
        for hwnd in winList {
            if (hwnd == currentHwnd)
                continue
            if IsActivatableAppWindow(hwnd, true)
                return hwnd
        }
    } catch {
        return 0
    }
    return 0
}

; --------------------------------------------------------------------------------------------------
; 4. X-Ray Layer Peek Engine (Progressive Multi-Window Ghosting & Layer Stepping)
; --------------------------------------------------------------------------------------------------

GetXRayCandidateWindows() {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    
    candidates := []
    try {
        allHwnds := WinGetList()
        for h in allHwnds {
            if !IsActivatableAppWindow(h, false)
                continue
                
            try {
                WinGetPos(&wX, &wY, &wW, &wH, "ahk_id " . h)
                if (mX >= wX && mX <= wX + wW && mY >= wY && mY <= wY + wH) {
                    candidates.Push(h)
                }
            }
        }
        
        if (candidates.Length == 0) {
            for h in allHwnds {
                if IsActivatableAppWindow(h, false)
                    candidates.Push(h)
            }
        }
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("GetXRayCandidateWindows", err)
    }
    return candidates
}

StartXRayLayerPeek() {
    global XRayState, XRayAlphaValue, CapsLockChordFired
    CapsLockChordFired := true
    
    if (XRayState.status != "IDLE")
        return
        
    cands := GetXRayCandidateWindows()
    if (cands.Length == 0) {
        ShowToast("⚠️ No visible application windows to slice", 1500)
        return
    }
    
    XRayState.status       := "ACTIVE"
    XRayState.candidates   := cands
    XRayState.stack        := []
    XRayState.currentIndex := 1
    XRayState.startTick    := A_TickCount
    
    firstHwnd := cands[1]
    XRayState.stack.Push(firstHwnd)
    try WinSetTransparent(XRayAlphaValue, "ahk_id " . firstHwnd)
    
    ShowToast("🔍 X-Ray Layer 1/" . cands.Length . " (↓ Deeper | ↑ Back | Release to Return)", 1500)
    SetTimer CheckXRayWatchdog, 25
}

XRayStepDown() {
    global XRayState, XRayAlphaValue
    if (XRayState.status != "ACTIVE")
        return
        
    if (XRayState.currentIndex < XRayState.candidates.Length) {
        XRayState.currentIndex += 1
        nextHwnd := XRayState.candidates[XRayState.currentIndex]
        XRayState.stack.Push(nextHwnd)
        try WinSetTransparent(XRayAlphaValue, "ahk_id " . nextHwnd)
        
        statusMsg := (XRayState.currentIndex == XRayState.candidates.Length) 
            ? "🔍 X-Ray Layer " . XRayState.currentIndex . "/" . XRayState.candidates.Length . " (Desktop Level Reached)"
            : "🔍 X-Ray Layer " . XRayState.currentIndex . "/" . XRayState.candidates.Length . " (↓ Deeper | ↑ Back)"
        ShowToast(statusMsg, 1500)
    } else {
        ShowToast("🔍 X-Ray: Reached Desktop (Deepest Layer)", 1000)
    }
}

XRayStepUp() {
    global XRayState
    if (XRayState.status != "ACTIVE")
        return
        
    if (XRayState.currentIndex > 1) {
        topGhostedHwnd := XRayState.stack.Pop()
        try WinSetTransparent("Off", "ahk_id " . topGhostedHwnd)
        XRayState.currentIndex -= 1
        ShowToast("🔍 X-Ray Layer " . XRayState.currentIndex . "/" . XRayState.candidates.Length . " (↓ Deeper | ↑ Back)", 1500)
    } else {
        ShowToast("🔍 X-Ray: Top Layer (Press ↓ to Slice Deeper)", 1000)
    }
}

EndXRayLayerPeek() {
    global XRayState
    if (XRayState.status = "IDLE")
        return
        
    XRayState.status := "RESTORING"
    SetTimer CheckXRayWatchdog, 0
    
    try {
        for h in XRayState.stack {
            try WinSetTransparent("Off", "ahk_id " . h)
        }
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("EndXRayLayerPeek", err)
    } finally {
        XRayState.status       := "IDLE"
        XRayState.stack        := []
        XRayState.candidates   := []
        XRayState.currentIndex := 0
        XRayState.startTick    := 0
    }
}

CheckXRayWatchdog() {
    global XRayState
    if (XRayState.status != "ACTIVE")
        return
        
    if (!GetKeyState("CapsLock", "P") || (A_TickCount - XRayState.startTick > 15000)) {
        EndXRayLayerPeek()
    }
}