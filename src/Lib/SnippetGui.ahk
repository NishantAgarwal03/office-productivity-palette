; ======================================================================================================================
; Module: SnippetGui.ahk - Modern Dark-Themed Visual Snippet & Hotstring Manager
; Part of Office Productivity Hub (v2.0.0)
; ======================================================================================================================

#Requires AutoHotkey v2.0

; --- Global References for Layout & Events ---
global SnippetGui        := ""
global SnippetListView   := ""
global SnippetSearchEdit := ""
global SnippetStatusBar  := ""
global BtnAdd            := ""
global BtnEdit           := ""
global BtnDelete         := ""
global BtnToggle         := ""
global BtnImport         := ""
global BtnExport         := ""
global BtnHelp           := ""
global SnippetPos        := {x: 100, y: 100, w: 720, h: 440}

ShowSnippetManagerGui() {
    global SnippetGui
    if IsObject(SnippetGui) && WinExist("ahk_id " . SnippetGui.Hwnd) {
        if WinActive("ahk_id " . SnippetGui.Hwnd) {
            CloseSnippetGui()
            return
        }
        SnippetGui.Show()
        RefreshSnippetListView()
        return
    }
    CreateSnippetGui()
}

IsSnippetGuiVisible() {
    global SnippetGui
    return IsObject(SnippetGui) && WinExist("ahk_id " . SnippetGui.Hwnd) && DllCall("user32\IsWindowVisible", "ptr", SnippetGui.Hwnd)
}

CloseSnippetGui() {
    global SnippetGui
    if IsObject(SnippetGui) {
        try SnippetGui.Destroy()
        SnippetGui := ""
    }
}

CreateSnippetGui() {
    global SnippetGui, SnippetListView, SnippetSearchEdit, SnippetStatusBar, SnippetPos
    global BtnAdd, BtnEdit, BtnDelete, BtnToggle, BtnImport, BtnExport, BtnHelp
    global ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemeAccent, ThemePrimary

    if IsObject(SnippetGui) {
        try SnippetGui.Destroy()
        SnippetGui := ""
    }

    SnippetGui := Gui("+Resize +MinSize680x360", "Snippet & Text Replacement Manager")
    SnippetGui.BackColor := ThemeBg
    SnippetGui.SetFont("s10 c" . ThemeText, "Segoe UI")

    SnippetGui.OnEvent("Close", (*) => CloseSnippetGui())
    SnippetGui.OnEvent("Escape", (*) => CloseSnippetGui())
    SnippetGui.OnEvent("Size", (g, MinMax, W, H) => OnSnippetGuiSize(g, MinMax, W, H))

    SnippetGui.SetFont("s10 bold c" . ThemeMuted, "Segoe UI")
    SnippetGui.Add("Text", "x12 y12 w55 h26 0x200", "🔍 Filter:")
    
    SnippetGui.SetFont("s10 norm c" . ThemeText, "Segoe UI")
    SnippetSearchEdit := SnippetGui.Add("Edit", "x70 y10 w638 h28 Background" . ThemeSurface . " c" . ThemeText . " -E0x200 vSearchFilter", "")
    DllCall("user32\SendMessage", "ptr", SnippetSearchEdit.Hwnd, "uint", 0x1501, "ptr", 1, "wstr", "Type to search snippets (by trigger abbreviation or expansion text)...")
    SnippetSearchEdit.OnEvent("Change", (ctrl, *) => RefreshSnippetListView(ctrl.Value))

    ; Column headers: 3 exact columns without phantom empty column
    SnippetGui.SetFont("s9.5 norm c" . ThemeText, "Segoe UI")
    SnippetListView := SnippetGui.AddListView("x10 y46 w698 h310 Background" . ThemeSurface . " c" . ThemeText . " -Multi +Report +LV0x14000", ["Trigger", "Replacement Preview", "Status"])
    SnippetListView.OnEvent("DoubleClick", (*) => EditSelectedSnippet())
    SnippetListView.OnEvent("ContextMenu", (lv, item, isRightClick, x, y) => ShowSnippetContextMenu(item, x, y))

    try {
        DllCall("uxtheme\SetWindowTheme", "ptr", SnippetListView.Hwnd, "str", "DarkMode_Explorer", "str", "Explorer")
    }

    ; Responsive Bottom Action Buttons
    SnippetGui.SetFont("s9.5 bold c" . ThemeText, "Segoe UI")
    BtnAdd    := SnippetGui.AddButton("x10 y364 w75 h30", "➕ Add")
    BtnAdd.OnEvent("Click", (*) => AddNewSnippet())
    
    BtnEdit   := SnippetGui.AddButton("x90 y364 w75 h30", "✏️ Edit")
    BtnEdit.OnEvent("Click", (*) => EditSelectedSnippet())
    
    BtnDelete := SnippetGui.AddButton("x170 y364 w75 h30", "🗑️ Del")
    BtnDelete.OnEvent("Click", (*) => DeleteSelectedSnippet())
    
    BtnToggle := SnippetGui.AddButton("x250 y364 w90 h30", "⚡ Toggle")
    BtnToggle.OnEvent("Click", (*) => ToggleSelectedSnippet())

    BtnImport := SnippetGui.AddButton("x450 y364 w75 h30", "📥 Import")
    BtnImport.OnEvent("Click", (*) => ImportSnippetsPrompt())
    
    BtnExport := SnippetGui.AddButton("x530 y364 w75 h30", "📤 Export")
    BtnExport.OnEvent("Click", (*) => ExportSnippetsPrompt())
    
    BtnHelp   := SnippetGui.AddButton("x610 y364 w75 h30", "❓ Help")
    BtnHelp.OnEvent("Click", (*) => ShowSnippetHelpDialog())

    SnippetGui.SetFont("s9 norm c" . ThemeMuted, "Segoe UI")
    SnippetStatusBar := SnippetGui.Add("StatusBar",, "Ready")

    RefreshSnippetListView()

    w := Max(720, SnippetPos.w)
    h := Max(440, SnippetPos.h)
    CenterGuiOnActiveMonitor(SnippetGui, w, h)
    SnippetGui.Show("w" . w . " h" . h)
}

OnSnippetGuiSize(guiObj, minMax, width, height) {
    global SnippetListView, SnippetSearchEdit, SnippetStatusBar
    global BtnAdd, BtnEdit, BtnDelete, BtnToggle, BtnImport, BtnExport, BtnHelp
    if (minMax = -1)
        return

    ; 1. Search Edit Box (top)
    if IsObject(SnippetSearchEdit)
        SnippetSearchEdit.Move(,, width - 82)

    ; 2. ListView (middle - leaves exactly 76px at bottom for buttons + status bar)
    lvHeight := Max(100, height - 126)
    if IsObject(SnippetListView) {
        SnippetListView.Move(,, width - 20, lvHeight)
        
        ; Exact 3-column distribution without horizontal scroll or phantom extra column
        col1W := 150
        col3W := 110
        col2W := Max(180, width - 20 - col1W - col3W - 22)
        try {
            SnippetListView.ModifyCol(1, col1W . " Left")
            SnippetListView.ModifyCol(2, col2W . " Left")
            SnippetListView.ModifyCol(3, col3W . " Center")
        }
    }

    ; 3. Button Bar (anchored above status bar)
    btnY := height - 68
    if IsObject(BtnAdd)
        BtnAdd.Move(10, btnY)
    if IsObject(BtnEdit)
        BtnEdit.Move(90, btnY)
    if IsObject(BtnDelete)
        BtnDelete.Move(170, btnY)
    if IsObject(BtnToggle)
        BtnToggle.Move(250, btnY)

    rightAnchor := width - 10
    if IsObject(BtnHelp)
        BtnHelp.Move(rightAnchor - 75, btnY)
    if IsObject(BtnExport)
        BtnExport.Move(rightAnchor - 155, btnY)
    if IsObject(BtnImport)
        BtnImport.Move(rightAnchor - 235, btnY)
}

RefreshSnippetListView(filter := "") {
    global SnippetListView, SnippetStatusBar, Snippets
    if !IsObject(SnippetListView)
        return

    SnippetListView.Delete()
    filterLower := StrLower(Trim(filter))

    activeCount := 0
    for s in Snippets {
        if (filterLower != "" && !InStr(StrLower(s.trigger), filterLower) && !InStr(StrLower(s.replacement), filterLower))
            continue
            
        statusStr := s.enabled ? "✔ Enabled" : "○ Disabled"
        if s.enabled
            activeCount++
            
        cleanRepl := StrReplace(s.replacement, "`r`n", " ↵ ")
        cleanRepl := StrReplace(cleanRepl, "`n", " ↵ ")
        
        SnippetListView.Add("", s.trigger, cleanRepl, statusStr)
    }

    try {
        col1W := 150
        col3W := 110
        col2W := Max(180, SnippetListView.Gui.ClientWidth - col1W - col3W - 22)
        SnippetListView.ModifyCol(1, col1W . " Left")
        SnippetListView.ModifyCol(2, col2W . " Left")
        SnippetListView.ModifyCol(3, col3W . " Center")
    }

    if IsObject(SnippetStatusBar) {
        SnippetStatusBar.Text := Format("Total Snippets: {} | Active: {} | (Press [Esc] or [Win + Esc] to close)", Snippets.Length, activeCount)
    }
}

AddNewSnippet() {
    ShowSnippetEditorModal("", "", true)
}

EditSelectedSnippet() {
    global SnippetListView, Snippets
    if !IsObject(SnippetListView)
        return
    row := SnippetListView.GetNext()
    if (row <= 0) {
        ShowToast("⚠️ Please select a snippet from the list first", 1800)
        return
    }

    trig := SnippetListView.GetText(row, 1)
    for s in Snippets {
        if (s.trigger = trig) {
            ShowSnippetEditorModal(s.trigger, s.replacement, s.enabled, true)
            return
        }
    }
}

DeleteSelectedSnippet() {
    global SnippetListView
    if !IsObject(SnippetListView)
        return
    row := SnippetListView.GetNext()
    if (row <= 0) {
        ShowToast("⚠️ Please select a snippet to delete", 1800)
        return
    }

    trig := SnippetListView.GetText(row, 1)
    res := MsgBox("Are you sure you want to delete snippet '::" . trig . "'?", "Confirm Snippet Deletion", "YesNo Icon?")
    if (res = "Yes") {
        DeleteSnippet(trig)
        RefreshSnippetListView()
        ShowToast("🗑️ Snippet Deleted: " . trig, 1500)
    }
}

ToggleSelectedSnippet() {
    global SnippetListView, Snippets
    if !IsObject(SnippetListView)
        return
    row := SnippetListView.GetNext()
    if (row <= 0) {
        ShowToast("⚠️ Please select a snippet to toggle", 1800)
        return
    }

    trig := SnippetListView.GetText(row, 1)
    for s in Snippets {
        if (s.trigger = trig) {
            s.enabled := !s.enabled
            SaveSnippets()
            RegisterDynamicHotstrings()
            RefreshSnippetListView()
            ShowToast((s.enabled ? "✔ Enabled: " : "○ Disabled: ") . trig, 1500)
            return
        }
    }
}

ShowSnippetEditorModal(origTrigger, origReplacement, origEnabled := true, isEdit := false) {
    global SnippetGui, ThemeBg, ThemeSurface, ThemeText, ThemeMuted, ThemeAccent
    
    ownerHwnd := (IsObject(SnippetGui) && WinExist("ahk_id " . SnippetGui.Hwnd)) ? SnippetGui.Hwnd : 0
    modal := Gui("+Owner" . ownerHwnd . " +ToolWindow -Caption +Border")
    modal.BackColor := ThemeBg
    modal.SetFont("s10.5 bold c" . ThemeAccent, "Segoe UI")
    modal.Add("Text", "x15 y12 w480", isEdit ? "✏️ Edit Snippet / Expansion" : "➕ Add New Snippet")

    modal.SetFont("s9 bold c" . ThemeMuted, "Segoe UI")
    modal.Add("Text", "x15 y40 w120", "Trigger Keyword:")
    modal.SetFont("s10 norm c" . ThemeText, "Segoe UI")
    editTrig := modal.Add("Edit", "x15 y60 w480 h28 Background" . ThemeSurface . " c" . ThemeText . " -E0x200", origTrigger)

    modal.SetFont("s9 bold c" . ThemeMuted, "Segoe UI")
    modal.Add("Text", "x15 y98 w150", "Expansion Text:")
    modal.SetFont("s10 norm c" . ThemeText, "Segoe UI")
    editRepl := modal.Add("Edit", "x15 y118 w480 h125 Background" . ThemeSurface . " c" . ThemeText . " -E0x200 WantTab", origReplacement)

    modal.SetFont("s9.5 norm c" . ThemeText, "Segoe UI")
    chkEn := modal.Add("CheckBox", "x15 y255 w120 c" . ThemeText . (origEnabled ? " Checked" : ""), "Active / Enabled")

    modal.SetFont("s9.5 bold c" . ThemeText, "Segoe UI")
    btnSave := modal.Add("Button", "x315 y255 w90 h32 Default", "✔ Save")
    btnSave.OnEvent("Click", (*) => SaveSnippetModal(modal, origTrigger, editTrig.Value, editRepl.Value, chkEn.Value, isEdit))

    btnCancel := modal.Add("Button", "x410 y255 w85 h32", "Cancel")
    btnCancel.OnEvent("Click", (*) => modal.Destroy())

    modal.OnEvent("Escape", (g) => g.Destroy())
    CenterGuiOnActiveMonitor(modal, 510, 305)
    modal.Show("w510 h305")
}

SaveSnippetModal(modal, origTrigger, newTrigger, newReplacement, isEnabled, isEdit) {
    trig := Trim(newTrigger)
    repl := newReplacement

    if (trig = "") {
        MsgBox("Please specify a trigger keyword.", "Input Required", "Icon!")
        return
    }

    if isEdit && (trig != origTrigger) {
        DeleteSnippet(origTrigger)
    }

    UpsertSnippet(trig, repl, isEnabled)
    modal.Destroy()
    RefreshSnippetListView()
    ShowToast("✔ Snippet Saved: " . trig, 1500)
}

ShowSnippetContextMenu(itemIndex, x, y) {
    if (itemIndex <= 0)
        return

    m := Menu()
    m.Add("✏️ Edit Snippet", (*) => EditSelectedSnippet())
    m.Add("⚡ Toggle Active State", (*) => ToggleSelectedSnippet())
    m.Add()
    m.Add("🗑️ Delete Snippet", (*) => DeleteSelectedSnippet())
    m.Show(x, y)
}

ImportSnippetsPrompt() {
    selectedFile := FileSelect(3, A_ScriptDir, "Select Snippets CSV to Import", "CSV Files (*.csv)")
    if (selectedFile = "")
        return
    ImportSnippetsFromCsv(selectedFile)
    RefreshSnippetListView()
    ShowToast("✔ Imported Snippets successfully", 2000)
}

ExportSnippetsPrompt() {
    defaultName := "office_snippets_export_" . FormatTime(A_Now, "yyyyMMdd_HHmmss") . ".csv"
    destFile := FileSelect("S16", defaultName, "Export Snippets to CSV", "CSV Files (*.csv)")
    if (destFile = "")
        return
    if !RegExMatch(destFile, "i)\.csv$")
        destFile .= ".csv"
    ExportSnippetsToCsv(destFile)
    ShowToast("✔ Exported to: " . destFile, 2000)
}

ShowSnippetHelpDialog() {
    help := "
    (
Office Snippet & Hotstring Manager Guide:
=========================================
• Trigger abbreviations auto-expand cleanly at word boundaries in ANY application.
• Example: Typing 'myemail ' or 'myemail.' expands into your full text.
• Press [Win + Esc] anytime to open / close this manager.
• Press [Esc] to dismiss this manager or any open tool.
• Use [Space] to toggle, [F2]/[Enter] to edit, and [Del] to delete selected snippets.
    )"
    MsgBox(help, "Snippet Manager Help", "Iconi")
}

IsSnippetListViewFocused() {
    global SnippetListView
    if !IsObject(SnippetListView)
        return false
    try {
        hwnd := SnippetListView.Hwnd
        guiHwnd := SnippetListView.Gui.Hwnd
        return (hwnd && WinActive("ahk_id " . guiHwnd) && (hwnd = ControlGetFocus(guiHwnd)))
    } catch {
        return false
    }
}

