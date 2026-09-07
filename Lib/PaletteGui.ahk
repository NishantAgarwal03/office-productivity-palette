; ======================================================================================================================
; Module: PaletteGui.ahk - Universal Command Palette (Unified Dark Mode Theme & Instant 1..9 Execution)
; ======================================================================================================================

#Requires AutoHotkey v2.0

ShowCommandPalette() {
    global PaletteGui, PaletteSearch, PaletteListView, PaletteStatus, TargetWindowHwnd, IsPaletteExpanded, PalettePlaceholder
    global ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemeAccent, ThemePrimary
    
    if IsPaletteVisible() {
        CloseCommandPalette()
        return
    }

    TargetWindowHwnd := WinActive("A")

    if IsObject(PaletteGui) {
        PaletteSearch.Value := ""
        UpdatePlaceholderState(true)
        IsPaletteExpanded := false
        FilterPaletteItems("", false)
        CenterGuiOnActiveMonitor(PaletteGui, 800, 56)
        PaletteGui.Show("w800 h56")
        SetPaletteTransparency(255)
        PaletteSearch.Focus()
        SetTimer(MonitorOfficePaletteTransparency, 150)
        return
    }

    PaletteGui := Gui("+AlwaysOnTop -Caption +Border +ToolWindow")
    PaletteGui.Title := "Command Palette"
    PaletteGui.BackColor := ThemeBg
    PaletteGui.SetFont("s11 c" . ThemeText, "Segoe UI")

    PaletteSearch := PaletteGui.Add("Edit", "x10 y10 w780 h36 Background" . ThemeSurface . " c" . ThemeText . " -E0x200 vSearchQuery")
    DllCall("user32\SendMessage", "ptr", PaletteSearch.Hwnd, "uint", 0x1501, "ptr", 1, "wstr", "🔍 Type to search 50+ tools (press ↓ for top 5 most used, 1-9 to run, Esc to close)...")
    
    PaletteGui.SetFont("s10 c" . ThemeMuted, "Segoe UI")
    PalettePlaceholder := PaletteGui.Add("Text", "x24 y18 w750 h22 BackgroundTrans c" . ThemeMuted, "🔍 Type to search 50+ tools (press ↓ for top 5 most used, 1-9 to run, Esc to close)...")
    PalettePlaceholder.OnEvent("Click", (*) => (PalettePlaceholder.Visible := false, PaletteSearch.Focus()))
    DllCall("user32\BringWindowToTop", "ptr", PalettePlaceholder.Hwnd)
    
    PaletteSearch.OnEvent("Change", (ctrl, *) => OnPaletteSearchChange(ctrl.Value))

    PaletteGui.SetFont("s10 c" . ThemeText, "Segoe UI")
    PaletteListView := PaletteGui.AddListView("x10 y52 w780 h300 Background" . ThemeSurface . " c" . ThemeText . " -Multi -Hdr +LV0x14000", ["#", "Name", "Category", "Description & Usage Tip", "Shortcut"])
    PaletteListView.OnEvent("DoubleClick", (*) => PaletteExecuteSelection())
    PaletteListView.Visible := false

    try {
        DllCall("uxtheme\SetWindowTheme", "ptr", PaletteListView.Hwnd, "str", "DarkMode_Explorer", "str", "Explorer")
    }

    PaletteGui.SetFont("s9 c" . ThemeMuted, "Segoe UI")
    PaletteStatus := PaletteGui.Add("Text", "x14 y358 w770 h24", "Tap [1..9] or [Enter] to Execute | [↑↓] Navigate | [Esc] Dismiss")
    PaletteStatus.Visible := false

    CenterGuiOnActiveMonitor(PaletteGui, 800, 56)
    PaletteGui.Show("w800 h56")
    SetPaletteTransparency(255)
    PaletteSearch.Focus()
    
    IsPaletteExpanded := false
    SetTimer(MonitorOfficePaletteTransparency, 150)
}

UpdatePlaceholderState(show) {
    global PalettePlaceholder, PaletteSearch
    if !IsObject(PalettePlaceholder) || !IsObject(PaletteSearch)
        return
    if (show && PaletteSearch.Value == "") {
        PalettePlaceholder.Visible := true
        DllCall("user32\BringWindowToTop", "ptr", PalettePlaceholder.Hwnd)
        try PalettePlaceholder.Redraw()
    } else {
        PalettePlaceholder.Visible := false
    }
}

OnPaletteSearchChange(query) {
    global IsPaletteExpanded, PalettePlaceholder
    if (Trim(query) != "") {
        UpdatePlaceholderState(false)
        IsPaletteExpanded := true
        FilterPaletteItems(query, true)
    } else {
        if (!IsPaletteExpanded)
            FilterPaletteItems("", false)
        else
            FilterPaletteItems("", true)
    }
}

ExpandTopUsedTools() {
    global IsPaletteExpanded, PaletteSearch
    IsPaletteExpanded := true
    FilterPaletteItems(PaletteSearch.Value, true)
}

FilterPaletteItems(query, forceExpand := false) {
    global BuiltInActions, Snippets, PaletteListView, PaletteItems, PaletteStatus, PaletteGui, IsPaletteExpanded
    if !IsObject(PaletteListView) || !IsObject(PaletteGui)
        return

    qTrim := Trim(query)
    qLower := StrLower(qTrim)

    if (qTrim = "") {
        if (!forceExpand && !IsPaletteExpanded) {
            PaletteListView.Visible := false
            PaletteStatus.Visible := false
            PaletteGui.Move(,, 800, 56)
            CenterGuiOnActiveMonitor(PaletteGui, 800, 56)
            PaletteItems := []
            return
        }
        PaletteItems := GetTopUsedOfficeActions(5)
    } else {
        PaletteItems := []
        Matches(item) {
            return InStr(StrLower(item.name), qLower) 
                || InStr(StrLower(item.category), qLower) 
                || InStr(StrLower(item.description), qLower)
                || (item.HasOwnProp("keywords") && InStr(StrLower(item.keywords), qLower))
        }

        for act in BuiltInActions {
            if Matches(act)
                PaletteItems.Push(act)
        }

        for snip in Snippets {
            if (snip.enabled) {
                snipObj := {
                    name: "Snippet: " . snip.trigger,
                    category: "⚡ Snippet",
                    description: "Expands: " . StrReplace(SubStr(snip.replacement, 1, 60), "`n", " ↵ "),
                    keywords: snip.trigger . " snippet " . snip.replacement,
                    callback: ((r) => (*) => InsertText(r))(snip.replacement),
                    chord: "",
                    triggerName: snip.trigger,
                    isCustom: true
                }
                if Matches(snipObj)
                    PaletteItems.Push(snipObj)
            }
        }
    }

    PaletteListView.Delete()

    for idx, item in PaletteItems {
        numBadge := (idx <= 9) ? ("A+" . idx) : ""
        shortcutText := FormatShortcutBadge(item)
        cleanDesc := item.description

        PaletteListView.Add("", numBadge, item.name, item.category, cleanDesc, shortcutText)
    }

    if (PaletteItems.Length > 0) {
        rowH := 24
        calcH := Min(390, 56 + (Min(PaletteItems.Length, 12) * rowH) + 36)
        PaletteListView.Move(,, 780, calcH - 88)
        PaletteStatus.Move(, calcH - 28, 770)
        
        PaletteListView.Visible := true
        PaletteStatus.Visible := true
        PaletteGui.Move(,, 800, calcH)
        
        PaletteListView.Modify(1, "Select Focus")
    } else {
        PaletteListView.Visible := false
        PaletteStatus.Visible := true
        PaletteStatus.Move(, 56, 770)
        PaletteGui.Move(,, 800, 86)
        PaletteStatus.Text := "No matching tools found for '" . qTrim . "'"
        LogZeroMatchQuery(qTrim)
    }

    try {
        PaletteListView.ModifyCol(1, "42 Center")
        PaletteListView.ModifyCol(2, 251)
        PaletteListView.ModifyCol(3, 95)
        PaletteListView.ModifyCol(4, 270)
        PaletteListView.ModifyCol(5, "100 Right")
    }

    if (PaletteItems.Length > 0 && IsObject(PaletteStatus)) {
        if (qTrim == "")
            PaletteStatus.Text := "⚡ Top " . PaletteItems.Length . " Most Used Tools  |  Tap [Alt+1.." . PaletteItems.Length . "] or [Enter]  |  [↑↓] Navigate  |  [Esc] Dismiss"
        else
            PaletteStatus.Text := "Found " . PaletteItems.Length . " tools  |  Tap [Alt+1..9] or [Enter] to Execute  |  [↑↓] Navigate  |  [Esc] Dismiss"
    }
}

PaletteExecuteSelection(targetIndex := 0) {
    global PaletteGui, PaletteListView, PaletteItems, TargetWindowHwnd, LastExecutedAction
    if !IsObject(PaletteGui)
        return

    if (targetIndex = 0)
        targetIndex := PaletteListView.GetNext()

    if (targetIndex <= 0 || targetIndex > PaletteItems.Length)
        return

    selectedItem := PaletteItems[targetIndex]
    CloseCommandPalette()

    if (TargetWindowHwnd && WinExist("ahk_id " . TargetWindowHwnd)) {
        WinActivate("ahk_id " . TargetWindowHwnd)
        Sleep(50)
    }

    LastExecutedAction := selectedItem
    execStart := A_TickCount

    try {
        selectedItem.callback.Call()
        LogToolExecution(selectedItem.name, selectedItem.category, "Palette", A_TickCount - execStart, true)
    } catch as err {
        LogToolExecution(selectedItem.name, selectedItem.category, "Palette", A_TickCount - execStart, false)
        LogAppError("PaletteExecuteSelection (" . selectedItem.name . ")", err)
        MsgBox("Error executing action '" . selectedItem.name . "':`n" . err.Message, "Execution Error", "Icon!")
    }
}

PaletteNavigate(delta) {
    global PaletteListView, PaletteItems, IsPaletteExpanded
    if (!IsPaletteExpanded) {
        ExpandTopUsedTools()
        return
    }

    if !IsObject(PaletteListView) || PaletteItems.Length = 0
        return

    current := PaletteListView.GetNext()
    next := current + delta

    if (next < 1)
        next := PaletteItems.Length
    else if (next > PaletteItems.Length)
        next := 1

    PaletteListView.Modify(current, "-Select -Focus")
    PaletteListView.Modify(next, "Select Focus")
    PaletteListView.Focus()
}

CloseCommandPalette() {
    global PaletteGui
    SetTimer(MonitorOfficePaletteTransparency, 0)
    if IsObject(PaletteGui) {
        PaletteGui.Hide()
    }
}

MonitorOfficePaletteTransparency() {
    global PaletteGui, PalettePlaceholder, PaletteSearch
    if !IsObject(PaletteGui) || !WinExist("ahk_id " . PaletteGui.Hwnd)
        return
        
    isActive := WinActive("ahk_id " . PaletteGui.Hwnd)
    MouseGetPos(&mX, &mY, &hoverWin)
    isHovered := (hoverWin == PaletteGui.Hwnd)
    
    if (isActive || isHovered) {
        SetPaletteTransparency(255)
        if (IsObject(PaletteSearch) && PaletteSearch.Value != "") {
            UpdatePlaceholderState(false)
        }
    } else {
        SetPaletteTransparency(190)
        if (IsObject(PaletteSearch) && PaletteSearch.Value == "") {
            UpdatePlaceholderState(true)
        }
    }
}

SetPaletteTransparency(alpha) {
    global PaletteGui
    static currentAlpha := 255
    if (alpha != currentAlpha && IsObject(PaletteGui)) {
        try {
            WinSetTransparent(alpha, "ahk_id " . PaletteGui.Hwnd)
            currentAlpha := alpha
        }
    }
}

IsPaletteVisible() {
    global PaletteGui
    return IsObject(PaletteGui) && WinExist("ahk_id " . PaletteGui.Hwnd) && DllCall("user32\IsWindowVisible", "ptr", PaletteGui.Hwnd)
}

IsPaletteActive() {
    global PaletteGui
    return IsObject(PaletteGui) && WinActive("ahk_id " . PaletteGui.Hwnd)
}

HasPaletteResults() {
    global PaletteListView, PaletteItems
    return IsPaletteActive() && IsObject(PaletteListView) && PaletteListView.Visible && PaletteItems.Length > 0
}
