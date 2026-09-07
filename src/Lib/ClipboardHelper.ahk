; ======================================================================================================================
; Module: ClipboardHelper.ahk - Fail-Safe Clipboard, Selection Capture, UI Positioning & Standardized Toast HUD
; ======================================================================================================================

#Requires AutoHotkey v2.0

SafeGetSelection(timeoutSec := 0.4) {
    clipBackup := ClipboardAll()
    A_Clipboard := ""
    
    SendInput("{Ctrl down}c{Ctrl up}")
    
    if !ClipWait(timeoutSec) {
        A_Clipboard := clipBackup
        return ""
    }
    
    sel := A_Clipboard
    A_Clipboard := clipBackup
    return sel
}

InsertText(text, restoreClipboard := false) {
    if (text = "")
        return
        
    local clipBackup := ""
    if restoreClipboard {
        try clipBackup := ClipboardAll()
    }
    
    try {
        A_Clipboard := ""
        A_Clipboard := text
        if !ClipWait(0.4) {
            SendText(text)
            return
        }
        Sleep(30)
        SendInput("{Ctrl down}v{Ctrl up}")
        
        if restoreClipboard {
            Sleep(150)
            try A_Clipboard := clipBackup
        }
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("InsertText", err)
        try SendText(text)
    }
}

CanPasteToTargetWindow(hwnd := 0) {
    global TargetWindowHwnd
    prevDHW := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    try {
        if (!hwnd) {
            if (IsSet(TargetWindowHwnd) && TargetWindowHwnd && WinExist("ahk_id " . TargetWindowHwnd))
                hwnd := TargetWindowHwnd
            else
                hwnd := WinActive("A")
        }
        if (!hwnd)
            return false

        ; 1. Windows Shell / Desktop / Explorer (never paste text into shell surfaces)
        winClass := WinGetClass("ahk_id " . hwnd)
        if (winClass = "CabinetWClass" || winClass = "ExploreWClass" 
         || winClass = "Progman" || winClass = "WorkerW" || winClass = "Shell_TrayWnd")
            return false

        ; 2. Dedicated PDF and Document Viewers (read-only viewers)
        procName := StrLower(WinGetProcessName("ahk_id " . hwnd))
        static pdfProcs := "acrobat.exe,acrord32.exe,sumatrapdf.exe,foxitreader.exe,foxitpdfreader.exe,pdfxedit.exe,nitropdf.exe"
        if (InStr("," . pdfProcs . ",", "," . procName . ","))
            return false

        ; 3. Window Title Inspection (Browser PDF Tabs, Office Protected View, Read-Only docs)
        title := WinGetTitle("ahk_id " . hwnd)
        if RegExMatch(title, "i)(\.pdf\b|\[Read-Only\]|\(Read-Only\)|\[Protected View\]|Protected Mode)")
            return false

        ; 4. Web Browsers (Universal: Chrome_WidgetWin_1, MozillaWindowClass, or known browser process)
        ; Web browsers view static HTML pages where in-place text replacement is not possible.
        static browserProcs := "ulaa.exe,chrome.exe,msedge.exe,firefox.exe,brave.exe,opera.exe,vivaldi.exe,arc.exe,zen.exe,librewolf.exe,floorp.exe,waterfox.exe,tor.exe"
        if (winClass = "Chrome_WidgetWin_1" || winClass = "Chrome_WidgetWin_0" || winClass = "MozillaWindowClass" 
         || InStr("," . browserProcs . ",", "," . procName . ",")) {
            return false
        }

        ; 5. Win32 Focused Control Read-Only Style (ES_READONLY = 0x0800)
        ctrl := ControlGetFocus("ahk_id " . hwnd)
        if (ctrl) {
            style := WinGetStyle(ctrl, "ahk_id " . hwnd)
            if (style & 0x0800) ; ES_READONLY
                return false
        }

        return true
    } catch {
        return false
    } finally {
        DetectHiddenWindows(prevDHW)
    }
}

TransformSelectedText(transformerFunc) {
    selText := SafeGetSelection()
    if (Trim(selText) = "") {
        ib := OfficeInputBox("Enter or paste text to transform:", AppTitle . " - Text Input")
        if (ib.Result != "OK" || Trim(ib.Value) = "")
            return
        selText := ib.Value
        
        ; Smart Paste-Intent Detector:
        ; When user pastes multiline text in single-line box, Windows truncates after Line 1.
        ; If the dialog value matches the 1st line of A_Clipboard (which has multiline content),
        ; the user intended to transform their complete multiline clipboard text.
        if (Trim(A_Clipboard) != "" && InStr(A_Clipboard, "`n")) {
            clipFirstLine := Trim(StrSplit(A_Clipboard, ["`r`n", "`n", "`r"])[1])
            if (clipFirstLine != "" && (selText == clipFirstLine || InStr(selText, clipFirstLine))) {
                selText := A_Clipboard
            }
        }
    }
    try {
        newText := transformerFunc.Call(selText)
        InsertText(newText)
    } catch as err {
        if IsSet(LogAppError)
            LogAppError("TransformSelectedText", err)
        ShowToast("Transformation Error: " . err.Message, 2500)
    }
}

PositionAndShowHud(guiObj, mX, mY, estW := 340, estH := 50, showOptions := "NoActivate AutoSize") {
    monIdx := 1
    try {
        monCount := MonitorGetCount()
        loop monCount {
            MonitorGetWorkArea(A_Index, &mL, &mT, &mR, &mB)
            if (mX >= mL && mX <= mR && mY >= mT && mY <= mB) {
                monIdx := A_Index
                break
            }
        }
    }
    MonitorGetWorkArea(monIdx, &mL, &mT, &mR, &mB)

    ; Position near cursor with 16px offset
    posX := mX + 16
    posY := mY + 16

    ; Clamp strictly within monitor work area (flip above cursor if bottom boundary reached)
    if (posX + estW > mR - 10)
        posX := mR - estW - 10
    if (posY + estH > mB - 10)
        posY := mY - estH - 16
    if (posX < mL + 10)
        posX := mL + 10
    if (posY < mT + 10)
        posY := mT + 10

    guiObj.Show("x" . Integer(posX) . " y" . Integer(posY) . " " . showOptions)
}

CalculateErgonomicDuration(msg, explicitDuration := 0) {
    if (explicitDuration > 0)
        return explicitDuration
    charLen := StrLen(msg)
    words := StrSplit(Trim(msg), [" ", "`t", "`n"]).Length
    calcMs := 800 + (charLen * 45) + (words * 150)
    if (InStr(msg, "❌") || InStr(msg, "Error"))
        calcMs := Integer(calcMs * 1.3)
    else if (InStr(msg, "⚠️"))
        calcMs := Integer(calcMs * 1.15)
    else if (charLen <= 15 && (InStr(msg, "✔") || InStr(msg, "🗑️")))
        calcMs := 1200
    return Max(1000, Min(calcMs, 4500))
}

GetBottomRightAnchorPos(width, height, offsetInches := 2.0, &posX := 0, &posY := 0) {
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    
    monIdx := 1
    try {
        monCount := MonitorGetCount()
        loop monCount {
            MonitorGetWorkArea(A_Index, &mL, &mT, &mR, &mB)
            if (mX >= mL && mX <= mR && mY >= mT && mY <= mB) {
                monIdx := A_Index
                break
            }
        }
    }
    MonitorGetWorkArea(monIdx, &mL, &mT, &mR, &mB)

    dpiFactor := A_ScreenDPI ? (A_ScreenDPI / 96) : 1.0
    offsetPx := Integer(96 * offsetInches * dpiFactor)

    posX := mR - width - offsetPx
    posY := mB - height - offsetPx

    if (posX < mL + 10)
        posX := mL + 10
    if (posY < mT + 10)
        posY := mT + 10
}

global ActiveTooltipTimerSlot1 := false

_DismissCursorTooltipSlot1() {
    global ActiveTooltipTimerSlot1
    ToolTip(,,, 1)
    ActiveTooltipTimerSlot1 := false
}

ShowCursorTooltip(msg, durationMs := 0, which := 1) {
    global ActiveTooltipTimerSlot1
    dur := CalculateErgonomicDuration(msg, durationMs)
    ToolTip(msg,,, which)
    if (which == 1) {
        SetTimer(_DismissCursorTooltipSlot1, 0)
        SetTimer(_DismissCursorTooltipSlot1, -dur)
        ActiveTooltipTimerSlot1 := true
    } else {
        SetTimer(() => ToolTip(,,, which), -dur)
    }
}

DismissCursorTooltip(which := 1) {
    global ActiveTooltipTimerSlot1
    if (which == 1) {
        SetTimer(_DismissCursorTooltipSlot1, 0)
        ActiveTooltipTimerSlot1 := false
    }
    ToolTip(,,, which)
}

_DismissToastHudTimer() {
    DismissToastHud()
}

ShowToast(msg, durationMs := 0, pos := "BottomRight") {
    global ToastHudGui, ToastTextCtrl, ThemeSurface, ThemeBorder, ThemeText, ThemeMuted, ThemeAccent
    
    dur := CalculateErgonomicDuration(msg, durationMs)
    
    posX := 0, posY := 0
    if (pos = "Cursor") {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mX, &mY)
    } else {
        GetBottomRightAnchorPos(340, 42, 2.0, &posX, &posY)
    }
    
    ; Smooth in-place text update without window destroy/recreate churn if already visible
    if (IsToastHudVisible() && IsObject(ToastTextCtrl)) {
        try {
            ToastTextCtrl.Text := msg
            if (pos = "Cursor") {
                CoordMode("Mouse", "Screen")
                MouseGetPos(&mX, &mY)
                PositionAndShowHud(ToastHudGui, mX, mY, 340, 42, "NoActivate AutoSize")
            } else {
                ToastHudGui.Show("x" . Integer(posX) . " y" . Integer(posY) . " NoActivate AutoSize")
            }
            SetTimer(_DismissToastHudTimer, 0)
            SetTimer(_DismissToastHudTimer, -dur)
            return
        }
    }
    
    if IsObject(ToastHudGui) {
        try ToastHudGui.Destroy()
    }
    
    ToastHudGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    ToastHudGui.BackColor := ThemeSurface
    
    ToastHudGui.SetFont("s10 bold c" . ThemeAccent, "Segoe UI Emoji")
    ToastHudGui.Add("Text", "x12 y8 w24 h20", "⚡")
    
    ToastHudGui.SetFont("s9.5 norm c" . ThemeText, "Segoe UI")
    ToastTextCtrl := ToastHudGui.Add("Text", "x38 y8 w320", msg)
    
    if (pos = "Cursor") {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mX, &mY)
        PositionAndShowHud(ToastHudGui, mX, mY, 340, 42, "NoActivate AutoSize")
    } else {
        ToastHudGui.Show("x" . Integer(posX) . " y" . Integer(posY) . " NoActivate AutoSize")
    }
    
    SetTimer(_DismissToastHudTimer, 0)
    SetTimer(_DismissToastHudTimer, -dur)
}

ShowSystemNotice(msg, durationMs := 0, offsetInches := 2.0) {
    ShowToast(msg, durationMs, "BottomRight")
}

DismissToastHud() {
    global ToastHudGui, ToastTextCtrl
    SetTimer(_DismissToastHudTimer, 0)
    if IsObject(ToastHudGui) {
        try ToastHudGui.Destroy()
        ToastHudGui := ""
        ToastTextCtrl := ""
    }
}

IsToastHudVisible() {
    global ToastHudGui
    try {
        return IsObject(ToastHudGui) && WinExist("ahk_id " . ToastHudGui.Hwnd) && DllCall("user32\IsWindowVisible", "ptr", ToastHudGui.Hwnd)
    } catch {
        return false
    }
}

DismissAllNotifications() {
    DismissToastHud()
    DismissCursorTooltip(1)
}

CenterGuiOnActiveMonitor(guiObj, width, height) {
    try {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mX, &mY)
        monCount := MonitorGetCount()
        targetMon := 1
        Loop monCount {
            MonitorGetWorkArea(A_Index, &mL, &mT, &mR, &mB)
            if (mX >= mL && mX <= mR && mY >= mT && mY <= mB) {
                targetMon := A_Index
                break
            }
        }
        MonitorGetWorkArea(targetMon, &mL, &mT, &mR, &mB)
        posX := mL + ((mR - mL - width) // 2)
        posY := mT + ((mB - mT - height) // 2)
        guiObj.Move(posX, posY, width, height)
    }
}
OfficeInputBox(prompt, title := "", defaultVal := "", isMultiline := false, ownerGui := "") {
    if IsObject(ownerGui) {
        ownerGui.Opt("+AlwaysOnTop +OwnDialogs")
    }
    opt := isMultiline ? "w380 h135" : "w380 h115"
    return InputBox(prompt, title != "" ? title : AppTitle, opt, defaultVal)
}

; ==================================================================================================
; Windows Clipboard History (Win+V) Exclusion
; Sets clipboard data while registering Win32 formats that instruct Windows 10/11 Clipboard History
; and Cloud Clipboard to ignore the content, preventing test/transient data pollution.
; ==================================================================================================
SetClipboardWithoutHistory(text) {
    if !DllCall("OpenClipboard", "ptr", 0) {
        A_Clipboard := text
        return
    }
    try {
        DllCall("EmptyClipboard")

        ; 1. Register format ExcludeClipboardContentFromMonitorProcessing
        uFormatExclude := DllCall("RegisterClipboardFormat", "str", "ExcludeClipboardContentFromMonitorProcessing", "uint")
        if (uFormatExclude) {
            hMemExclude := DllCall("GlobalAlloc", "uint", 0x0042, "uptr", 4, "ptr")
            if (hMemExclude) {
                pMemExclude := DllCall("GlobalLock", "ptr", hMemExclude, "ptr")
                if (pMemExclude) {
                    NumPut("uint", 0, pMemExclude)
                    DllCall("GlobalUnlock", "ptr", hMemExclude)
                }
                DllCall("SetClipboardData", "uint", uFormatExclude, "ptr", hMemExclude)
            }
        }

        ; 2. Register format CanIncludeInClipboardHistory
        uFormatHistory := DllCall("RegisterClipboardFormat", "str", "CanIncludeInClipboardHistory", "uint")
        if (uFormatHistory) {
            hMemHistory := DllCall("GlobalAlloc", "uint", 0x0042, "uptr", 4, "ptr")
            if (hMemHistory) {
                pMemHistory := DllCall("GlobalLock", "ptr", hMemHistory, "ptr")
                if (pMemHistory) {
                    NumPut("uint", 0, pMemHistory)
                    DllCall("GlobalUnlock", "ptr", hMemHistory)
                }
                DllCall("SetClipboardData", "uint", uFormatHistory, "ptr", hMemHistory)
            }
        }

        ; 3. Register format CanUploadToCloudClipboard
        uFormatCloud := DllCall("RegisterClipboardFormat", "str", "CanUploadToCloudClipboard", "uint")
        if (uFormatCloud) {
            hMemCloud := DllCall("GlobalAlloc", "uint", 0x0042, "uptr", 4, "ptr")
            if (hMemCloud) {
                pMemCloud := DllCall("GlobalLock", "ptr", hMemCloud, "ptr")
                if (pMemCloud) {
                    NumPut("uint", 0, pMemCloud)
                    DllCall("GlobalUnlock", "ptr", hMemCloud)
                }
                DllCall("SetClipboardData", "uint", uFormatCloud, "ptr", hMemCloud)
            }
        }

        ; 4. Set Unicode text CF_UNICODETEXT (13)
        if (text != "") {
            byteCount := (StrLen(text) + 1) * 2
            hMemText := DllCall("GlobalAlloc", "uint", 0x0042, "uptr", byteCount, "ptr")
            if (hMemText) {
                pMemText := DllCall("GlobalLock", "ptr", hMemText, "ptr")
                if (pMemText) {
                    StrPut(text, pMemText, "UTF-16")
                    DllCall("GlobalUnlock", "ptr", hMemText)
                }
                DllCall("SetClipboardData", "uint", 13, "ptr", hMemText)
            }
        }
    } finally {
        DllCall("CloseClipboard")
    }
}
