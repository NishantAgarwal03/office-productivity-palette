#Requires AutoHotkey v2.0

; ======================================================================================================================
; Title:   DateFormatGui.ahk
; Version: 2.0.0 (Concept A: Compact Settings Modal)
; AHK Ver: v2.0+
; Core Purpose:
; Compact, non-intrusive Settings Modal (~420 x 280) for configuring the remembered Default Date Format.
; Features single-key (1-9) instant persistence to office_productivity_settings.ini, keyboard navigation,
; live previews rendered with today's real date, active default tagging [✔ Default], and global Escape dismissal.
; Everyday conversions occur in-place silently with zero toast and zero HUD.
; ======================================================================================================================

global DateFormatGui := ""
global DateFormatListView := ""
global DateFormatCurrentItems := []

ShowDateFormatSettingsGui() {
    global DateFormatGui, DateFormatListView, DateFormatCurrentItems, DefaultDateFormatId
    global ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemeAccent, ThemePrimary, ThemeBorder

    if IsObject(DateFormatGui) {
        try DateFormatGui.Destroy()
        DateFormatGui := ""
    }

    ; Ensure current default is loaded from settings INI
    if IsSet(LoadAppSettings)
        LoadAppSettings()

    DateFormatGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Border")
    DateFormatGui.BackColor := ThemeSurface
    DateFormatGui.Title := "Set Default Date Format"

    ; Header
    DateFormatGui.SetFont("s11 bold c" . ThemeAccent, "Segoe UI Emoji")
    DateFormatGui.Add("Text", "x16 y10 w26 h22", "📅")

    DateFormatGui.SetFont("s10.5 bold c" . ThemeText, "Segoe UI")
    DateFormatGui.Add("Text", "x44 y10 w360 h22", "Set Default Date Format")

    DateFormatGui.SetFont("s8.5 norm c" . ThemeMuted, "Segoe UI")
    DateFormatGui.Add("Text", "x44 y30 w360 h18", "Used for silent in-place conversions (office_productivity_settings.ini)")

    ; Generate live previews of all 9 formats with today's date
    todayYmd := FormatTime(A_Now, "yyyyMMdd")
    todayParsed := DateFormatConverter.ParseIndianDate(todayYmd)
    if (!todayParsed.valid)
        todayParsed := DateFormatConverter.ParseIndianDate("20260906")

    DateFormatCurrentItems := DateFormatConverter.GetAllFormats(todayParsed, DefaultDateFormatId)

    DateFormatGui.SetFont("s9 norm c" . ThemeText, "Segoe UI")
    DateFormatListView := DateFormatGui.AddListView("x14 y52 w392 h155 Background" . ThemeBg . " c" . ThemeText . " -Multi +Report +LV0x14000 -Hdr", ["Key", "Sample Output", "Format Spec"])
    
    try {
        DllCall("uxtheme\SetWindowTheme", "ptr", DateFormatListView.Hwnd, "str", "DarkMode_Explorer", "str", "Explorer")
    }

    for item in DateFormatCurrentItems {
        prefix := "[" . item["id"] . "]"
        specLabel := item["name"] . (item["isCurrent"] ? "  [✔ Default]" : "")
        DateFormatListView.Add("", prefix, item["value"], specLabel)
    }

    DateFormatListView.ModifyCol(1, 38)
    DateFormatListView.ModifyCol(2, 200)
    DateFormatListView.ModifyCol(3, 150)

    ; Highlight currently saved default row
    selRow := (DefaultDateFormatId >= 1 && DefaultDateFormatId <= 9) ? DefaultDateFormatId : 6
    DateFormatListView.Modify(selRow, "Select Focus")

    DateFormatListView.OnEvent("DoubleClick", (*) => OnSubmitDateFormatSetting())

    ; Action Buttons & Keyboard Hints
    DateFormatGui.SetFont("s9 bold c" . ThemeText, "Segoe UI")
    btnSave := DateFormatGui.Add("Button", "x14 y214 w190 h26 Default", "✔ Set Default (Enter)")
    btnSave.OnEvent("Click", (*) => OnSubmitDateFormatSetting())

    btnCancel := DateFormatGui.Add("Button", "x216 y214 w190 h26", "✖ Cancel (Esc)")
    btnCancel.OnEvent("Click", (*) => DismissDateFormatSettingsGui())

    DateFormatGui.SetFont("s8 norm c" . ThemeMuted, "Segoe UI")
    DateFormatGui.Add("Text", "x14 y246 w392 h18 Center", "Press 1-9 for instant save & close | Enter: Select | Esc: Cancel")

    DateFormatGui.OnEvent("Escape", (*) => DismissDateFormatSettingsGui())

    ; Center near cursor or monitor work area
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mX, &mY)
    PositionAndShowHud(DateFormatGui, mX, mY, 420, 280, "AutoSize")
}

; Backward-compatible alias for existing test harnesses & runners
ShowDateFormatPicker(textToProcess := "") {
    ShowDateFormatSettingsGui()
}

DismissDateFormatSettingsGui() {
    global DateFormatGui
    if IsObject(DateFormatGui) {
        try DateFormatGui.Destroy()
        DateFormatGui := ""
    }
}

DismissDateFormatPicker() {
    DismissDateFormatSettingsGui()
}

OnQuickKeyDateFormatSetting(keyId) {
    idNum := Integer(keyId)
    if (idNum < 1 || idNum > 9)
        return

    SaveDefaultDateFormat(idNum)
    fmtName := (idNum >= 1 && idNum <= 9) ? DateFormatConverter.Formats[idNum].name : "Format " . idNum
    DismissDateFormatSettingsGui()
    ShowToast("✔ Default Date Format saved: [" . idNum . "] " . fmtName, 1500)
}

OnSubmitDateFormatSetting() {
    global DateFormatListView
    if (!IsObject(DateFormatListView))
        return

    row := DateFormatListView.GetNext(0, "Focused")
    if (row < 1 || row > 9)
        row := 1

    OnQuickKeyDateFormatSetting(row)
}

; Context-sensitive hotkeys when DateFormatGui is active
#HotIf IsObject(DateFormatGui) && WinActive("ahk_id " . DateFormatGui.Hwnd)
1::OnQuickKeyDateFormatSetting(1)
2::OnQuickKeyDateFormatSetting(2)
3::OnQuickKeyDateFormatSetting(3)
4::OnQuickKeyDateFormatSetting(4)
5::OnQuickKeyDateFormatSetting(5)
6::OnQuickKeyDateFormatSetting(6)
7::OnQuickKeyDateFormatSetting(7)
8::OnQuickKeyDateFormatSetting(8)
9::OnQuickKeyDateFormatSetting(9)
#HotIf
