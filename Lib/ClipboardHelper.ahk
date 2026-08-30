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

ShowToast(msg, durationMs := 2000) {
    global ToastHudGui, ThemeSurface, ThemeBorder, ThemeText, ThemeMuted, ThemeAccent
    
    if IsObject(ToastHudGui) {
        try ToastHudGui.Destroy()
    }
    
    ToastHudGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    ToastHudGui.BackColor := ThemeSurface
    
    ToastHudGui.SetFont("s10 bold c" . ThemeAccent, "Segoe UI Emoji")
    ToastHudGui.Add("Text", "x12 y8 w24 h20", "⚡")
    
    ToastHudGui.SetFont("s9.5 norm c" . ThemeText, "Segoe UI")
    ToastHudGui.Add("Text", "x38 y8 w320", msg)
    
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    
    PositionAndShowHud(ToastHudGui, mX, mY, 340, 42, "NoActivate AutoSize")
    SetTimer(() => DismissToastHud(), -durationMs)
}

DismissToastHud() {
    global ToastHudGui
    if IsObject(ToastHudGui) {
        try ToastHudGui.Destroy()
    }
}

IsToastHudVisible() {
    global ToastHudGui
    return IsObject(ToastHudGui) && WinExist("ahk_id " . ToastHudGui.Hwnd) && DllCall("user32\IsWindowVisible", "ptr", ToastHudGui.Hwnd)
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
OfficeInputBox(prompt, title := "", defaultVal := "", isMultiline := false) {
    opt := isMultiline ? "w380 h135" : "w380 h115"
    return InputBox(prompt, title != "" ? title : AppTitle, opt, defaultVal)
}
