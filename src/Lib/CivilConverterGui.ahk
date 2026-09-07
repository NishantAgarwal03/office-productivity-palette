; ======================================================================================================================
; Module: CivilConverterGui.ahk
; Production UX & GUI Layer: Floating HUD, Non-Destructive PDF Tooltip & Single-Prompt Parameter Disclosure
; Part of Office Productivity Hub & Action Board (v2.0.0)
;
; ======================================================================================================================
;                                          USER UX PRINCIPLES & SPECIFICATIONS
; ======================================================================================================================
; 1. Frictionless Single-Action Trigger:
;    - If text is highlighted (e.g., in PDF, CAD, Excel, browser, site WhatsApp group, Word):
;      User presses shortcut (Ctrl+Shift+U / Double-Shift action) -> Engine instantly captures & parses.
;    - If no text is selected:
;      A sleek, centered Omni-Input box appears immediately ("Enter civil query: 10m to ft, 36 sqm to m3, 10mm@150...").
;
; 2. Non-Destructive PDF / Read-Only Environment Protection:
;    - Evaluates the target window/control class. If target is non-editable (PDF viewer, browser, CAD, read-only pane),
;      the system displays results in a floating, non-intrusive dark HUD at the caret/mouse and syncs to clipboard.
;      It NEVER blindly fires SendInput("{Ctrl Down}v{Ctrl Up}") into read-only surfaces.
;
; 3. Single-Prompt Progressive Parameter Disclosure:
;    - If a cross-dimensional transformation requires a secondary parameter (e.g. Length -> Area, Area -> Volume,
;      Volume -> Mass, Rebar substitution, Force -> Pressure), exactly ONE compact floating micro-dialog appears.
;    - Zero-block default fallback: If user presses [Enter] with blank input or clicks outside, intelligent defaults
;      (Square geometry, Cube depth, Concrete 2400 kg/m³, Uttarakhand 770m² Bigha) are automatically applied.
;    - User can input in ANY unit (e.g. "150mm", "6 inch", "2m x 3m", "sand", "diesel", "1.5 m/s").
;
; 4. Escape & Auto-Dismissal:
;    - All floating HUDs and parameter prompts respond instantly to Esc or global dismissal.
; ======================================================================================================================

#Requires AutoHotkey v2.0

global CivilPromptGui := ""
global CivilResultHudGui := ""
global CivilPendingQuery := ""

; ----------------------------------------------------------------------------------------------------------------------
; 1. Main Entrypoint: Process Civil Conversion / Engineering Request
; ----------------------------------------------------------------------------------------------------------------------
ShowCivilConverter(providedText := "") {
    global CivilPromptGui, CivilResultHudGui, CivilPendingQuery
    global ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemeAccent, ThemeBorder

    textToProcess := providedText
    targetHwnd := WinActive("A")

    if (textToProcess == "") {
        textToProcess := SafeGetSelection(0.25)
    }

    if (Trim(textToProcess) == "") {
        ib := OfficeInputBox("Enter civil conversion or engineering query:`n(e.g., 10m to ft, 36 sqm to m3, 10 cum to kg, 10mm@150 to 12mm, 500 kN to MPa, pythagoras 3 4, 500 per sqft to sqm, cost 1500 sqft)", "Civil & Construction Instant Converter")
        if (ib.Result != "OK" || Trim(ib.Value) == "")
            return
        textToProcess := ib.Value
    }

    ; First-pass evaluation (with blank secondary parameter to check if progressive prompt is needed)
    res := CivilConverterEngine.Evaluate(textToProcess, "")

    if (!res.success) {
        if (res.HasOwnProp("isIncompatible") && res.isIncompatible) {
            ShowCivilResultHud(textToProcess, "⚠️ " . res.message, res.category, targetHwnd, false)
        } else {
            ShowToast("⚠️ " . res.message, 3000)
        }
        return
    }

    ; Check if progressive parameter disclosure prompt is needed
    if (res.HasOwnProp("needsParam") && res.needsParam) {
        ShowCivilParameterPrompt(textToProcess, res.paramPrompt, res.defaultApplied, targetHwnd)
        return
    }

    ; Immediate result display
    ShowCivilResultHud(res.displayExpr, res.resultStr, res.category, targetHwnd, true)
}

; ----------------------------------------------------------------------------------------------------------------------
; 2. Single-Prompt Floating Micro-Dialog (Progressive Parameter Disclosure)
; ----------------------------------------------------------------------------------------------------------------------
ShowCivilParameterPrompt(rawQuery, promptTitle, defaultApplied, targetHwnd) {
    global CivilPromptGui, CivilPendingQuery
    global ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemeAccent, ThemeBorder

    CivilPendingQuery := rawQuery

    if IsObject(CivilPromptGui) {
        try CivilPromptGui.Destroy()
    }

    CivilPromptGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    CivilPromptGui.BackColor := ThemeSurface
    CivilPromptGui.Title := "Civil Engineering Parameter"

    ; Header Icon & Prompt Label
    CivilPromptGui.SetFont("s10.5 bold c" . ThemeAccent, "Segoe UI Emoji")
    CivilPromptGui.Add("Text", "x14 y12 w26 h22", "📐")

    CivilPromptGui.SetFont("s10 bold c" . ThemeText, "Segoe UI")
    CivilPromptGui.Add("Text", "x44 y12 w380 h22", promptTitle)

    ; Helper subtitle showing default fallback
    CivilPromptGui.SetFont("s8.5 norm c" . ThemeMuted, "Segoe UI")
    CivilPromptGui.Add("Text", "x44 y34 w380 h18", "Press [Enter] to use default (" . defaultApplied . ") or type value:")

    ; Freeform Input Box
    CivilPromptGui.SetFont("s10 norm c" . ThemeText, "Segoe UI")
    paramEdit := CivilPromptGui.Add("Edit", "x14 y56 w410 h30 Background" . ThemeBg . " c" . ThemeText . " -E0x200 vParamInput")

    ; Buttons: [Use Default / Apply] & [Dismiss (Esc)]
    CivilPromptGui.SetFont("s9 bold c" . ThemeText, "Segoe UI")
    btnApply := CivilPromptGui.Add("Button", "x14 y94 w200 h28 Default", "✔ Accept / Apply (Enter)")
    btnApply.OnEvent("Click", (*) => OnSubmitCivilParameter(paramEdit.Value, targetHwnd))

    btnEsc := CivilPromptGui.Add("Button", "x224 y94 w200 h28", "✖ Cancel (Esc)")
    btnEsc.OnEvent("Click", (*) => DismissCivilPrompt())

    ; Position GUI near cursor / caret
    PositionGuiNearCursor(CivilPromptGui, 440, 134)
    CivilPromptGui.Show("w440 h134")
    paramEdit.Focus()
}

OnSubmitCivilParameter(paramValue, targetHwnd) {
    global CivilPromptGui, CivilPendingQuery
    query := CivilPendingQuery
    DismissCivilPrompt()

    finalParam := (Trim(paramValue) == "") ? "DEFAULT" : Trim(paramValue)

    ; Re-evaluate with supplied parameter (or DEFAULT for default)
    res := CivilConverterEngine.Evaluate(query, finalParam)
    if (!res.success) {
        ShowToast("⚠️ " . res.message, 3000)
        return
    }

    ShowCivilResultHud(res.displayExpr, res.resultStr, res.category, targetHwnd, true)
}

DismissCivilPrompt() {
    global CivilPromptGui
    if IsObject(CivilPromptGui) {
        try CivilPromptGui.Destroy()
        CivilPromptGui := ""
    }
}

; ----------------------------------------------------------------------------------------------------------------------
; 3. Non-Destructive Floating Result HUD / Tooltip
; ----------------------------------------------------------------------------------------------------------------------
ShowCivilResultHud(exprStr, resultStr, categoryStr, targetHwnd, isSuccess := true) {
    global CivilResultHudGui
    global ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemeAccent, ThemeBorder

    ; Always copy cleanly to clipboard
    if (isSuccess) {
        try A_Clipboard := resultStr
    }

    if IsObject(CivilResultHudGui) {
        try CivilResultHudGui.Destroy()
    }

    CivilResultHudGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    CivilResultHudGui.BackColor := ThemeSurface
    CivilResultHudGui.Title := "Civil Conversion Result"

    ; Multi-line vs Single-line formatting
    lineCount := 1
    Loop Parse, resultStr, "`n"
        lineCount++

    isDetailedReport := (lineCount > 6)
    cardW := isDetailedReport ? 560 : 356
    estH := isDetailedReport ? Min(lineCount * 17 + 50, 480) : 70

    ; Header Icon & Category
    icon := isSuccess ? "🏗️" : "⚠️"
    CivilResultHudGui.SetFont("s10 bold c" . ThemeAccent, "Segoe UI Emoji")
    CivilResultHudGui.Add("Text", "x12 y9 w24 h20", icon)

    CivilResultHudGui.SetFont("s9 bold c" . ThemeMuted, "Segoe UI")
    CivilResultHudGui.Add("Text", "x38 y9 w" . (cardW - 50) . " h18", categoryStr . (isSuccess ? " • Copied" : ""))

    ; Display Expression (if provided and different from resultStr)
    currY := 28
    if (exprStr != "" && exprStr != resultStr && !InStr(resultStr, exprStr)) {
        CivilResultHudGui.SetFont("s9 norm c" . ThemeMuted, "Segoe UI")
        CivilResultHudGui.Add("Text", "x12 y" . currY . " w" . (cardW - 24), exprStr)
        currY += 20
    }

    ; Main Result Body
    if (isDetailedReport) {
        CivilResultHudGui.SetFont("s9 norm c" . ThemeText, "Consolas")
        editH := estH - currY - 10
        CivilResultHudGui.Add("Edit", "x12 y" . currY . " w" . (cardW - 24) . " h" . editH . " ReadOnly -E0x200 Background" . ThemeSurface, resultStr)
    } else {
        CivilResultHudGui.SetFont("s10 bold c" . (isSuccess ? ThemeText : "FF6B6B"), "Segoe UI")
        CivilResultHudGui.Add("Text", "x12 y" . currY . " w" . (cardW - 24), resultStr)
    }

    ; Position near active caret/mouse with strict monitor bounds clamping
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)

    if IsSet(PositionAndShowHud)
        PositionAndShowHud(CivilResultHudGui, mX, mY, cardW + 24, estH, "AutoSize NoActivate")
    else
        CivilResultHudGui.Show("AutoSize NoActivate")

    ; Auto-dismiss: 5s in editable fields, 12s for rich detailed BOQ reports
    isEditable := IsTargetControlEditable(targetHwnd)
    dismissDuration := isDetailedReport ? -12000 : ((isSuccess && isEditable) ? -5000 : -7000)
    SetTimer(() => DismissCivilResultHud(), dismissDuration)
}

DismissCivilResultHud() {
    global CivilResultHudGui
    if IsObject(CivilResultHudGui) {
        try CivilResultHudGui.Destroy()
        CivilResultHudGui := ""
    }
}

; ----------------------------------------------------------------------------------------------------------------------
; 4. Target Window & Control Analysis Helpers (Non-Editable / PDF Detection)
; ----------------------------------------------------------------------------------------------------------------------
IsTargetControlEditable(hwnd) {
    if (!hwnd || !WinExist("ahk_id " . hwnd))
        return false

    try {
        focusedCtrl := ControlGetFocus("ahk_id " . hwnd)
        if (!focusedCtrl)
            return false

        ctrlClass := ControlGetClassNN(focusedCtrl, "ahk_id " . hwnd)
        ctrlStyle := ControlGetStyle(focusedCtrl, "ahk_id " . hwnd)

        ; If control has ES_READONLY style (0x0800), it is non-editable
        if (ctrlStyle & 0x0800)
            return false

        ; Standard editable control classes
        if (InStr(ctrlClass, "Edit") = 1 || InStr(ctrlClass, "RichEdit") || InStr(ctrlClass, "Scintilla"))
            return true

        ; Known document reader classes (Acrobat, Foxit, Edge/Chrome PDF canvas)
        wClass := WinGetClass("ahk_id " . hwnd)
        if (InStr(wClass, "Acrobat") || InStr(wClass, "PDF") || InStr(wClass, "FoxitReader") || InStr(wClass, "Chrome_WidgetWin"))
            return false
    }
    return false
}

PositionGuiNearCursor(guiObj, defaultW, defaultH) {
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

    posX := Min(mX + 16, mR - defaultW - 20)
    posY := Min(mY + 16, mB - defaultH - 20)
    if (posX < mL + 10)
        posX := mL + 10
    if (posY < mT + 10)
        posY := mT + 10

    guiObj.Move(posX, posY)
}
